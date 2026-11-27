import pytest
import requests

import run


class FakeResponse:
    def __init__(self, status=200, payload=None):
        self.status_code = status
        self._payload = payload

    def raise_for_status(self):
        if self.status_code >= 400:
            raise requests.HTTPError(f"HTTP {self.status_code}", response=self)

    def json(self):
        return self._payload


class FakeSession:
    def __init__(self, responses):
        self.responses = list(responses)
        self.urls = []

    def get(self, url, timeout=None):
        self.urls.append(url)
        item = self.responses.pop(0)
        if isinstance(item, Exception):
            raise item
        return item


def test_fetch_entity_follows_next_until_null():
    session = FakeSession([
        FakeResponse(payload={"count": 3, "next": f"{run.BASE_URL}/planets/?page=2", "results": [{"url": "a"}, {"url": "b"}]}),
        FakeResponse(payload={"count": 3, "next": None, "results": [{"url": "c"}]}),
    ])
    records, expected = run.fetch_entity("planets", session, sleep=lambda s: None)
    assert [r["url"] for r in records] == ["a", "b", "c"]
    assert expected == 3
    assert session.urls[1].endswith("?page=2")


def test_retry_with_exponential_backoff_then_success():
    session = FakeSession([
        requests.ConnectionError("boom"),
        FakeResponse(status=503),
        FakeResponse(payload={"ok": True}),
    ])
    delays = []
    assert run.get_json("http://x", session, sleep=delays.append) == {"ok": True}
    assert delays == [1, 2]


def test_gives_up_after_max_attempts():
    session = FakeSession([FakeResponse(status=500)] * run.MAX_ATTEMPTS)
    with pytest.raises(requests.HTTPError):
        run.get_json("http://x", session, sleep=lambda s: None)
    assert session.responses == []


def test_no_retry_on_404():
    session = FakeSession([FakeResponse(status=404), FakeResponse(payload={})])
    with pytest.raises(requests.HTTPError):
        run.get_json("http://x", session, sleep=lambda s: None)
    assert len(session.urls) == 1
