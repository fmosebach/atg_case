# swapi_dbt

dbt-projekt som transformerar SWAPI-data i Snowflake: `RAW` → `STAGING` → `RAW_VAULT` (Data Vault 2.0 med automate_dv) → `MARTS` (star schema för Power BI).

Regler och definition of done: [../AGENTS.md](../AGENTS.md).

## Lager
| Lager | Schema | Materialisering | Innehåll |
|---|---|---|---|
| staging | STAGING | view | `base_*` (dedup + parsning), `stg_<entitet>` (hash-keys/hashdiffs), `stg_<a>_<b>` (länkpar) |
| raw_vault | RAW_VAULT | incremental (insert-only) | 6 hubs, 10 links, 6 satellites |
| marts | MARTS | table | 6 dimensioner, `fact_person_film`, `fact_film_starship`, `fact_film_vehicle` |

Mart-nycklar är hash-keys som hex-strängar, eftersom Power BI inte stödjer binära relationsnycklar.

## Köra
Snowflake-uppgifter läses från miljövariabler (se `profiles.yml`), t.ex. via `.env` i repots rot.

```
dbt deps
dbt build
dbt docs generate
```

## Att känna till
- `base_*` tar bara senaste batchen per objekt. Körs ingestion flera gånger mellan dbt-körningar missar satelliterna mellanversionerna (acceptabelt för SWAPI).
- `'unknown'`, `'n/a'` och intervall i numeriska fält blir null (`to_num`), vilket gör dem likvärdiga i hashdiff.
- Hash-keys i link-staging beräknas med samma `automate_dv.hash` som i hubbarna; `relationships`-testerna i `_raw_vault.yml` skyddar mot att de glider isär.
- `threads: 1` i `profiles.yml` beror på att `externalbrowser` ger en inloggning per anslutning.
- Dimensionerna `dim_species` och `dim_planet` har en Unknown-medlem (nyckel = 32 nollor).

`dbt build --full-refresh` bygger om raw_vault från grunden (historiken i satelliterna tappas).
