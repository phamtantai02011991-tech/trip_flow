"""Kiểm thử tích hợp eSMS (mock HTTP) và chặn simulator ở production."""

from __future__ import annotations

import pytest

from app.core.config import settings
from app.services import sms_service


class _FakeResponse:
    def __init__(self, payload: dict):
        self._payload = payload

    def json(self) -> dict:
        return self._payload


def _configure_esms(monkeypatch) -> None:
    monkeypatch.setattr(settings, "SMS_PROVIDER", "esms")
    monkeypatch.setattr(settings, "ESMS_API_KEY", "test-api-key")
    monkeypatch.setattr(settings, "ESMS_SECRET_KEY", "test-secret")
    monkeypatch.setattr(settings, "ESMS_BRANDNAME", "TripFlow")


def test_esms_sends_correct_payload(monkeypatch):
    _configure_esms(monkeypatch)
    captured: dict = {}

    def fake_post(url, json, timeout):
        captured["url"] = url
        captured["payload"] = json
        return _FakeResponse({"CodeResult": "100"})

    monkeypatch.setattr(sms_service.httpx, "post", fake_post)
    message = sms_service.dispatch_sms("0912345678", "123456")

    assert "123456" in message
    assert captured["url"] == sms_service.ESMS_ENDPOINT
    payload = captured["payload"]
    assert payload["Phone"] == "0912345678"
    assert payload["Brandname"] == "TripFlow"
    assert payload["SmsType"] == "2"
    assert payload["IsUnicode"] == "1"


def test_esms_rejection_raises(monkeypatch):
    _configure_esms(monkeypatch)
    monkeypatch.setattr(
        sms_service.httpx,
        "post",
        lambda *a, **k: _FakeResponse({"CodeResult": "99", "ErrorMessage": "Bad brandname"}),
    )
    with pytest.raises(sms_service.SMSDeliveryError):
        sms_service.dispatch_sms("0912345678", "123456")


def test_simulator_forbidden_in_production(monkeypatch):
    monkeypatch.setattr(settings, "SMS_PROVIDER", "simulator")
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    with pytest.raises(sms_service.SMSDeliveryError):
        sms_service.dispatch_sms("0912345678", "123456")
