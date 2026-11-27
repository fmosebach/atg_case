# swapi_dbt

dbt-projekt som transformerar SWAPI-data i Snowflake: RAW → staging → raw_vault (Data Vault 2.0) → marts (star schema för Power BI).

Se [../AGENTS.md](../AGENTS.md) för regler och definition of done.

```
dbt deps
dbt build
```

Anslutningen definieras i `profiles.yml` i repots rot (miljövariabler från `.env`).
