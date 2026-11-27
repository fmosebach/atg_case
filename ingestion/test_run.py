from datetime import datetime, timezone

import pytest
import requests

import run


class FakeResponse:
    def __init__(self, status=200, payload=None):
        self.status_code = status
        self._payload = payload
        self.headers = {}

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


def test_retry_after_is_respected_and_capped():
    resp = FakeResponse(status=429)
    resp.headers = {"Retry-After": "7"}
    long = FakeResponse(status=429)
    long.headers = {"Retry-After": "9999"}
    session = FakeSession([resp, long, FakeResponse(payload={})])
    delays = []
    run.get_json("http://x", session, sleep=delays.append)
    assert delays == [7, run.MAX_RETRY_AFTER]


def test_next_outside_base_url_is_rejected():
    session = FakeSession([FakeResponse(payload={"count": 2, "next": "https://evil.example/api/planets/?page=2", "results": [{"url": "a"}]})])
    with pytest.raises(RuntimeError, match="next-URL"):
        run.fetch_entity("planets", session, sleep=lambda s: None)


def test_pagination_loop_is_detected():
    first = f"{run.BASE_URL}/planets/"
    session = FakeSession([FakeResponse(payload={"count": 1, "next": first, "results": [{"url": "a"}]})] * 2)
    with pytest.raises(RuntimeError, match="loop"):
        run.fetch_entity("planets", session, sleep=lambda s: None)


def test_missing_results_gives_clear_error():
    session = FakeSession([FakeResponse(payload={"detail": "oops"})])
    with pytest.raises(RuntimeError, match="results"):
        run.fetch_entity("planets", session, sleep=lambda s: None)


class FakeCursor:
    """Registrerar SQL; `count` styr vad sanity-checkens COUNT(*) returnerar."""

    def __init__(self, count=None):
        self.sql = []
        self.count = count

    def execute(self, sql, params=None):
        self.sql.append(sql)
        self.last = sql

    def fetchone(self):
        return (self.count,)


NOW = datetime.now(timezone.utc)


def test_load_entity_rejects_empty_records():
    with pytest.raises(ValueError, match="inga poster"):
        run.load_entity(FakeCursor(), "people", [], "b1", NOW)


def test_load_entity_is_append_only():
    cur = FakeCursor()
    run.load_entity(cur, "people", [{"url": "u1"}, {"url": "u2"}], "b1", NOW)
    assert len(cur.sql) == 1 and cur.sql[0].startswith("INSERT INTO RAW.PEOPLE")
    assert not any("DELETE" in s or "TRUNCATE" in s for s in cur.sql)


def test_load_entity_chunks_large_batches(monkeypatch):
    monkeypatch.setattr(run, "INSERT_CHUNK_SIZE", 2)
    cur = FakeCursor()
    run.load_entity(cur, "people", [{"url": f"u{i}"} for i in range(5)], "b1", NOW)
    assert len(cur.sql) == 3


def test_sanity_check_mismatch_raises():
    with pytest.raises(RuntimeError, match="Sanity check"):
        run.sanity_check(FakeCursor(count=1), "people", "b1", loaded=2, expected=2)
    with pytest.raises(RuntimeError, match="Sanity check"):
        run.sanity_check(FakeCursor(count=0), "people", "b1", loaded=0, expected=None)


def test_load_all_commits_after_all_checks_pass():
    cur = FakeCursor(count=1)
    run.load_all(cur, {"people": ([{"url": "u"}], 1), "films": ([{"url": "f"}], 1)}, "b1", NOW)
    assert cur.sql[-1] == "COMMIT" and "ROLLBACK" not in cur.sql
    assert cur.sql.index("BEGIN") > max(i for i, s in enumerate(cur.sql) if s.startswith("CREATE"))


def test_load_all_rolls_back_everything_when_sanity_check_fails():
    cur = FakeCursor(count=99)
    with pytest.raises(RuntimeError, match="Sanity check"):
        run.load_all(cur, {"people": ([{"url": "u"}], 1)}, "b1", NOW)
    assert "COMMIT" not in cur.sql and cur.sql[-1] == "ROLLBACK"
