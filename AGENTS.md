# AGENTS.md – ATG Case: SWAPI → Data Vault → Power BI

## Projektöversikt
Pipeline som hämtar data från swapi.dev, landar rått JSON i Snowflake,
modellerar enligt Data Vault 2.0 (hub/link/satellite) med dbt, och
exponerar ett star schema för Power BI.

## Stack
- Snowflake (databas: FMOSEBACH_SWAPI_DB, schemas: RAW, STAGING, RAW_VAULT, MARTS)
- dbt-core + dbt-snowflake + automate_dv-paketet
- Python för ingestion (requests, snowflake-connector-python)
- Power BI för visualisering

## Konventioner
- Inga secrets i kod. Allt via miljövariabler från .env (aldrig committad).
- Naming: snake_case för alla SQL-objekt och Python-moduler.
- Commit-meddelanden: beskriv VAD och VARFÖR, inte bara "update files".
- Skapa alltid en egen branch per uppgift, aldrig direkt på main.

## Mappar och ansvar
- /ingestion → ägs av ingestion-agenten (se ingestion/AGENTS.md)
- /dbt_projects/swapi_dbt → ägs av transform-agenten (se dbt_projects/AGENTS.md)
- Granskning sker via PR, inte direkt på main.
