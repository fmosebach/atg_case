"""Hämtar data från SWAPI (swapi.dev) och landar den rått i Snowflake-schemat RAW.

Ett generellt script som tar entitetsnamn som argument (istället för ett script
per entitet): alla sex resurser har samma form (paginerad lista via `next`,
varje post har `url`), så logiken för hämtning, retry och laddning delas och
en ny entitet kräver bara en rad i ENTITIES.

Användning:
    python ingestion/run.py                    # alla entiteter
    python ingestion/run.py people planets     # valda entiteter
"""
import argparse
import json
import logging
import os
import sys
import time
import uuid
from datetime import datetime, timezone

import requests

BASE_URL = os.environ.get("SWAPI_BASE_URL", "https://swapi.dev/api").rstrip("/")
ENTITIES = ["people", "films", "planets", "species", "starships", "vehicles"]
SCHEMA = "RAW"
MAX_ATTEMPTS = 3
BACKOFF_SECONDS = 1
REQUEST_TIMEOUT = 30
RETRY_STATUS = {429, 500, 502, 503, 504}
MAX_RETRY_AFTER = 60
INSERT_CHUNK_SIZE = 1000

log = logging.getLogger("ingestion")


def retry_after_seconds(exc):
    """Sekunder enligt Retry-After (endast heltalsformen), annars None."""
    resp = getattr(exc, "response", None)
    value = resp.headers.get("Retry-After") if resp is not None and getattr(resp, "headers", None) else None
    try:
        return min(max(int(value), 0), MAX_RETRY_AFTER)
    except (TypeError, ValueError):
        return None


def get_json(url, session, sleep=time.sleep):
    """GET med max MAX_ATTEMPTS försök och exponentiell backoff (1s, 2s, ...); Retry-After väger tyngre om den är längre."""
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            resp = session.get(url, timeout=REQUEST_TIMEOUT)
            if resp.status_code in RETRY_STATUS:
                raise requests.HTTPError(f"HTTP {resp.status_code}", response=resp)
            resp.raise_for_status()
            return resp.json()
        except (requests.RequestException, ValueError) as exc:
            retryable = not (
                isinstance(exc, requests.HTTPError)
                and exc.response is not None
                and exc.response.status_code not in RETRY_STATUS
            )
            if not retryable or attempt == MAX_ATTEMPTS:
                log.error("Misslyckades hämta %s (försök %d/%d): %s", url, attempt, MAX_ATTEMPTS, exc)
                raise
            delay = max(BACKOFF_SECONDS * 2 ** (attempt - 1), retry_after_seconds(exc) or 0)
            log.warning("Fel vid %s (försök %d/%d): %s - nytt försök om %ss", url, attempt, MAX_ATTEMPTS, exc, delay)
            sleep(delay)


def fetch_entity(entity, session, sleep=time.sleep):
    """Följer `next` tills den är null. Returnerar (poster, count enligt API)."""
    first_url = f"{BASE_URL}/{entity}/"
    url, seen = first_url, set()
    records, expected = [], None
    while url:
        # `next` måste stanna inom BASE_URL/<entitet>/ och får inte upprepas (skydd mot loopar/fel värd).
        if not url.startswith(first_url):
            raise RuntimeError(f"{entity}: oväntad next-URL {url!r}, förväntade prefix {first_url!r}")
        if url in seen:
            raise RuntimeError(f"{entity}: pagineringsloop vid {url!r}")
        seen.add(url)
        page = get_json(url, session, sleep)
        if not isinstance(page, dict) or not isinstance(page.get("results"), list):
            raise RuntimeError(f"{entity}: oväntat svar från {url}, saknar 'results'-lista")
        if expected is None:
            expected = page.get("count")
        records.extend(page["results"])
        log.info("%s: %d/%s poster hämtade", entity, len(records), expected)
        url = page.get("next")
    return records, expected


def connect():
    import snowflake.connector

    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        authenticator="externalbrowser",
        autocommit=False,
    )


def ensure_tables(cur, entities):
    # DDL committar implicit i Snowflake, så det görs före transaktionen.
    cur.execute(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}")
    for entity in entities:
        cur.execute(
            f"CREATE TABLE IF NOT EXISTS {SCHEMA}.{entity.upper()} ("
            "raw_json VARIANT, source_url STRING, load_ts TIMESTAMP_TZ, batch_id STRING)"
        )


def load_entity(cur, entity, records, batch_id, load_ts):
    """Append-only: lägger till en ny batch och rör aldrig tidigare rader (historik bevaras för satelliterna)."""
    if not records:
        raise ValueError(f"{entity}: API:et returnerade inga poster, inget att ladda")
    # Snowflake tillåter max 16 384 uttryck i en VALUES-lista (4 per rad här), så vi chunkar.
    for start in range(0, len(records), INSERT_CHUNK_SIZE):
        chunk = records[start:start + INSERT_CHUNK_SIZE]
        placeholders = ", ".join(["(%s, %s, %s, %s)"] * len(chunk))
        params = [p for r in chunk for p in (json.dumps(r), r["url"], load_ts.isoformat(), batch_id)]
        cur.execute(
            f"INSERT INTO {SCHEMA}.{entity.upper()} (raw_json, source_url, load_ts, batch_id) "
            f"SELECT PARSE_JSON(column1), column2, column3::TIMESTAMP_TZ, column4 FROM VALUES {placeholders}",
            params,
        )


def sanity_check(cur, entity, batch_id, loaded, expected):
    """Batchens radantal måste vara > 0, matcha det vi skickade in och det API:et uppger."""
    cur.execute(f"SELECT COUNT(*) FROM {SCHEMA}.{entity.upper()} WHERE batch_id = %s", (batch_id,))
    rows = cur.fetchone()[0]
    if rows == 0 or rows != loaded or (expected is not None and rows != expected):
        raise RuntimeError(
            f"Sanity check misslyckades för {entity}: {rows} rader i batch, laddade {loaded}, API count {expected}"
        )
    log.info("%s: %d rader i batch %s OK", entity, rows, batch_id)


def load_all(cur, fetched, batch_id, load_ts):
    """Alla entiteter i EN transaktion; sanity checks körs före COMMIT och ett fel ger ROLLBACK av allt."""
    ensure_tables(cur, fetched)
    cur.execute("BEGIN")
    try:
        for entity, (records, expected) in fetched.items():
            load_entity(cur, entity, records, batch_id, load_ts)
            sanity_check(cur, entity, batch_id, len(records), expected)
        cur.execute("COMMIT")
    except Exception:
        cur.execute("ROLLBACK")
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("entities", nargs="*", help=f"någon av {ENTITIES}; default: alla")
    args = parser.parse_args(argv)
    unknown = set(args.entities) - set(ENTITIES)
    if unknown:
        parser.error(f"okänd entitet: {sorted(unknown)}")
    entities = args.entities or ENTITIES

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    logging.getLogger("snowflake").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    try:
        from dotenv import load_dotenv

        load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))
    except ImportError:
        pass

    batch_id = str(uuid.uuid4())
    load_ts = datetime.now(timezone.utc)
    log.info("Startar batch %s mot %s", batch_id, BASE_URL)

    # Hämta allt först (API-fel) och ladda sedan allt i en transaktion (laddningsfel) – RAW blir aldrig halvladdad.
    with requests.Session() as session:
        fetched = {e: fetch_entity(e, session) for e in entities}

    conn = connect()
    try:
        load_all(conn.cursor(), fetched, batch_id, load_ts)
    finally:
        conn.close()
    log.info("Klart, batch %s", batch_id)


if __name__ == "__main__":
    sys.exit(main())
