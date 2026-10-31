"""
Script xuất hợp đồng API chuẩn OpenAPI 3.1 ra file `backend/swagger.json` (Pitfall #4).
Chạy lệnh: `python export_swagger.py`
"""

import json
from pathlib import Path

from app.main import app


def export_swagger_json() -> Path:
    output_path = Path(__file__).resolve().parent / "swagger.json"
    schema = app.openapi()
    output_path.write_text(
        json.dumps(schema, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return output_path


if __name__ == "__main__":
    out = export_swagger_json()
    print(f"Exported OpenAPI 3.1 contract to: {out}")
