# AGENTS.md – dbt / Data Vault Transformationer

## Uppdrag
Transformera rådata från RAW till Data Vault 2.0-modell (RAW_VAULT)
och exponera ett star schema (MARTS) för Power BI.

## Regler
- Rör ALDRIG filer utanför /dbt_projects/swapi_dbt.
- Använd automate_dv-paketet för hub/link/satellite – skriv inte
  hash-key-logik manuellt.
- Lagerordning: staging (views) → raw_vault (hub/link/sat, tables)
  → marts (star schema, tables). Hoppa inte över lager.
- Staging-modeller extraherar natural keys ur SWAPI-URL:er (regex på
  t.ex. `/people/(\d+)/`) och exponerar hash-keys/hashdiffs.
- Varje hub/link ska ha minst: not_null + unique-test på sin primary
  hash-key. Satelliter är historiserade (flera rader per hash-key), så
  de testas med not_null på hash-key och load_ts samt
  dbt_utils.unique_combination_of_columns på [hash-key, load_ts].
- Namngivning: hub_<entitet>, link_<entitet1>_<entitet2>,
  sat_<entitet>_<beskrivning>, dim_<entitet>, fact_<händelse>.
- Materialisering: staging = view, raw_vault = table, marts = table.
- Dokumentera varje modell kort i en .yml (description + kolumntester).

## Definition of done
- `dbt build` körs utan fel och utan att hoppa över tester
- Minst: hub_person, hub_film, hub_planet, link_person_film,
  sat_person_details, sat_film_details, + en mart med dim/fact
- dbt docs genererar lineage-graf utan brutna referenser
