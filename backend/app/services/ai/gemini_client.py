"""Client HTTP tới Gemini API (không dùng SDK — SDK Dart/Python không ổn định bằng HTTP thuần).

Nguyên tắc:
- Model **không hardcode**: nếu env trống thì hỏi `GET /models` và chọn model
  đầu tiên hỗ trợ `generateContent`.
- `thinkingBudget = 0` cho model suy luận: đã đo thực tế, `gemini-3.8-flash`
  mất ~140 giây nếu để mặc định, ~7 giây với `gemini-3.5-flash` + budget 0.
- Key chỉ nằm ở server, gửi qua header `x-goog-api-key` (không dùng `?key=`).
"""

import json
from typing import Any, Dict, List, Optional

import httpx

from app.core.config import settings


class GeminiError(RuntimeError):
    def __init__(self, message: str, code: str = "AI_ERROR", status: int = 502):
        super().__init__(message)
        self.code = code
        self.status = status


_MODEL_CACHE: Dict[str, List[Dict[str, Any]]] = {}


class GeminiClient:
    def __init__(self) -> None:
        self.base = settings.GEMINI_API_BASE.rstrip("/")
        self.key = settings.GEMINI_API_KEY

    # ------------------------------------------------------------------
    def is_configured(self) -> bool:
        return bool(self.key)

    def _headers(self) -> Dict[str, str]:
        return {"x-goog-api-key": self.key, "Content-Type": "application/json"}

    async def list_models(self) -> List[Dict[str, Any]]:
        if "all" in _MODEL_CACHE:
            return _MODEL_CACHE["all"]
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.get(f"{self.base}/models?pageSize=200", headers=self._headers())
        except httpx.HTTPError as exc:
            raise GeminiError(f"Không gọi được Gemini: {exc}", "AI_UNAVAILABLE", 503) from exc
        if resp.status_code != 200:
            raise GeminiError(
                f"Gemini trả {resp.status_code}: {resp.text[:200]}", "AI_UNAVAILABLE", 503
            )
        models = resp.json().get("models", [])
        _MODEL_CACHE["all"] = models
        return models

    async def resolve_model(self, preferred: Optional[str]) -> str:
        if preferred:
            return preferred
        models = await self.list_models()
        usable = [
            m["name"].replace("models/", "")
            for m in models
            if "generateContent" in m.get("supportedGenerationMethods", [])
            and not any(
                token in m["name"]
                for token in ("image", "tts", "live", "audio", "embedding", "robotics", "nano-banana")
            )
        ]
        if not usable:
            raise GeminiError("Không có model text khả dụng", "AI_NO_MODEL", 503)
        # Ưu tiên Flash ổn định trước, rồi mới tới model mới nhất
        priority = ["gemini-3.5-flash", "gemini-2.5-flash", "gemini-3.1-flash-lite"]
        for name in priority:
            if name in usable:
                return name
        return usable[0]

    # ------------------------------------------------------------------
    async def generate_json(
        self,
        prompt: str,
        schema: Dict[str, Any],
        model: Optional[str] = None,
        max_output_tokens: Optional[int] = None,
        temperature: float = 0.4,
        timeout: Optional[float] = None,
    ) -> Dict[str, Any]:
        if not self.is_configured():
            raise GeminiError("Chưa cấu hình GEMINI_API_KEY", "AI_NOT_CONFIGURED", 503)

        name = await self.resolve_model(model)
        body = {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "temperature": temperature,
                "maxOutputTokens": max_output_tokens or settings.GEMINI_MAX_OUTPUT_TOKENS,
                # Tắt suy luận để giữ độ trễ thấp (đo thực tế: 140s -> ~7s)
                "thinkingConfig": {"thinkingBudget": 0},
            },
            "safetySettings": [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
            ],
        }

        url = f"{self.base}/models/{name}:generateContent"
        try:
            async with httpx.AsyncClient(timeout=timeout or settings.GEMINI_TIMEOUT_SECONDS) as client:
                resp = await client.post(url, headers=self._headers(), json=body)
        except httpx.TimeoutException as exc:
            raise GeminiError("AI trả lời quá lâu", "AI_TIMEOUT", 504) from exc
        except httpx.HTTPError as exc:
            raise GeminiError(f"Lỗi mạng khi gọi AI: {exc}", "AI_UNAVAILABLE", 503) from exc

        if resp.status_code == 429:
            raise GeminiError("AI đang bận (quota)", "AI_BUSY", 429)
        if resp.status_code != 200:
            raise GeminiError(f"AI lỗi {resp.status_code}: {resp.text[:300]}", "AI_ERROR", 502)

        data = resp.json()
        candidate = (data.get("candidates") or [{}])[0]
        finish = candidate.get("finishReason")
        if finish == "SAFETY":
            raise GeminiError("Nội dung bị chặn bởi bộ lọc an toàn", "AI_BLOCKED", 422)
        if finish == "MAX_TOKENS":
            raise GeminiError("Phản hồi bị cắt do giới hạn token", "AI_TRUNCATED", 502)

        parts = (candidate.get("content") or {}).get("parts") or []
        text = "".join(p.get("text", "") for p in parts).strip()
        if not text:
            raise GeminiError("AI trả về rỗng", "AI_EMPTY", 502)

        try:
            parsed = json.loads(text)
        except json.JSONDecodeError as exc:
            raise GeminiError("AI trả JSON không hợp lệ", "AI_BAD_JSON", 502) from exc

        usage = data.get("usageMetadata") or {}
        parsed["_meta"] = {
            "model": name,
            "tokens_in": usage.get("promptTokenCount", 0),
            "tokens_out": usage.get("candidatesTokenCount", 0),
            "latency_ms": int(resp.elapsed.total_seconds() * 1000) if resp.elapsed else None,
        }
        return parsed


gemini_client = GeminiClient()
