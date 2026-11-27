# atg_case

## Run the full pipeline

Hela pipelinen (SWAPI → Snowflake RAW → dbt) körs med ett enda kommando från repo-roten i PowerShell (scriptet är bara för PowerShell):

```powershell
./run.ps1
```

Scriptet gör, i ordning:

1. Laddar `.env` och kontrollerar att de obligatoriska `SNOWFLAKE_*`-variablerna är satta.
2. Aktiverar `.venv` om ingen venv redan är aktiv.
3. `python ingestion/run.py` (alla sex SWAPI-entiteter till `RAW`).
4. `dbt deps` och `dbt build` i `dbt_projects/swapi_dbt`.

Om något steg misslyckas avbryts körningen med ett felmeddelande och steget exitkod (aldrig 0). Misslyckas ingestion körs dbt inte alls.

### Förutsättningar

1. **Virtuell miljö och beroenden** (Python, ingestion-paketen samt dbt-snowflake):
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
2. **`.env` ifylld** utifrån mallen:
   ```powershell
   Copy-Item .env.example .env
   ```
   Fyll i `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE` och `SNOWFLAKE_DATABASE`. `SWAPI_BASE_URL` är valfri och är `https://swapi.dev/api` som standard. Använd inte swapi.tech, som har ett annat svarsformat och avvisas av scriptet. Committa aldrig `.env`.
   - Variabler som redan är satta i miljön skrivs inte över av `.env` (samma beteende som python-dotenv), och tomma värden i `.env` ignoreras.
3. **Nätverksåtkomst** till swapi.dev, Snowflake och dbt Hub. `dbt deps` körs automatiskt av scriptet (idempotent) och hämtar `automate_dv` och `dbt_utils`, så inget manuellt steg behövs på en ny maskin.
4. **Snowflake SSO:** autentisering sker via `externalbrowser`. Ingestion och dbt loggar in var för sig, så en webbläsarflik öppnas två gånger under en körning (en per steg). Scriptet är därför inte helt obevakat.

### Felsökning

- *"running scripts is disabled"*: kör `Set-ExecutionPolicy -Scope Process Bypass` och försök igen.
- Exitkoden från `./run.ps1` är ingestions respektive dbts exitkod vid fel, annars 0.
- dbt hittar sin `profiles.yml` i `dbt_projects/swapi_dbt` eftersom scriptet kör därifrån.