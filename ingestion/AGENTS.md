# AGENTS.md – Ingestion

## Uppdrag
Hämta data från swapi.tech (people, films, planets, species, starships,
vehicles) och landa den RÅ (otransformerad) i Snowflake-schemat RAW.

## Regler
- Rör ALDRIG filer utanför /ingestion.
- Ingen transformering eller tolkning av data här – bara hämta och landa.
  All transformering sker i dbt.
- Varje rad som skrivs till RAW ska innehålla: raw_json (variant),
  source_url, load_ts, batch_id.
- API:et paginerar via `next`-fältet – hantera det med en loop, inte
  hårdkodade sidnummer.
- swapi.tech kan vara instabilt. Lägg in enkel retry (max 3 försök,
  exponential backoff) och tydlig loggning vid fel.
- Läs Snowflake-uppgifter enbart från miljövariabler (se .env.example
  i repo-roten), aldrig hårdkodat.
- Skriv ett script per entitet, eller ett generellt script som tar
  entitetsnamn som argument – motivera valet kort i en kommentar.

## Definition of done
- Kan köras med ett enda kommando, t.ex. `python ingestion/run.py`
- Skriver korrekt till RAW-tabellerna utan dubbletter vid omkörning
  (idempotent, t.ex. truncate+load eller append med batch_id)
- Har minst ett enkelt test/sanity check (t.ex. radantal > 0 efter körning)
