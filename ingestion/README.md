# Ingestion: SWAPI → Snowflake RAW

Hämtar people, films, planets, species, starships och vehicles från https://swapi.dev/api/ och landar dem otransformerade i `RAW`.

## Körning
```
pip install -r ingestion/requirements.txt        # runtime
pip install -r ingestion/requirements-dev.txt    # + pytest
python ingestion/run.py                          # alla entiteter
python ingestion/run.py people planets           # valda entiteter
python -m pytest ingestion                       # tester (fungerar från valfri katalog)
```
Snowflake-uppgifter läses från miljövariabler (`SNOWFLAKE_ACCOUNT`, `_USER`, `_ROLE`, `_WAREHOUSE`, `_DATABASE`), se `.env` i repo-roten. Inloggning sker via `externalbrowser`. Bas-URL kan åsidosättas med miljövariabeln `SWAPI_BASE_URL` (måste vara satt i miljön, inte bara i `.env`).

## RAW-tabeller
`RAW.PEOPLE`, `RAW.FILMS`, `RAW.PLANETS`, `RAW.SPECIES`, `RAW.STARSHIPS`, `RAW.VEHICLES` med kolumnerna `raw_json` (VARIANT), `source_url`, `load_ts`, `batch_id`.

## Append-only: RAW innehåller avsiktliga dubbletter över batcher
Varje körning skapar ett nytt `batch_id` och **lägger till** en komplett kopia av alla poster. Inget raderas, så historiken bevaras och satelliterna kan fånga ändringar över tid. Konsekvenser:

- Samma `source_url` förekommer en gång per batch. Omkörning är idempotent på batchnivå (en batch laddas atomiskt, allt eller inget, i en transaktion), men radantalet i RAW växer.
- **Staging i dbt måste välja senaste batch per `source_url`**, t.ex.:
  ```sql
  select * from {{ source('raw', 'people') }}
  qualify row_number() over (partition by source_url order by load_ts desc) = 1
  ```
- **Satelliter dedupliceras via hashdiff**, så att en oförändrad post i en ny batch inte ger en ny satellitrad.
- Gamla batcher kan rensas manuellt när historiken inte behövs, t.ex. `delete from RAW.PEOPLE where load_ts < ...`.

## Felhantering och kontroller
- Retry: max 3 försök med exponentiell backoff (1s, 2s); `Retry-After` vid 429 respekteras (max 60s).
- `next` måste börja med `<BASE_URL>/<entitet>/` och får inte upprepas; annars avbryts körningen med tydligt fel.
- All data hämtas först, sedan laddas alla entiteter i en transaktion. Sanity checks (radantal i batchen > 0 och lika med både det som laddades och API:ets `count`) körs före `COMMIT`; vid fel görs `ROLLBACK`.
- Inserts chunkas (1000 rader per `INSERT`) pga Snowflakes gräns på 16 384 uttryck per `VALUES`-lista.
