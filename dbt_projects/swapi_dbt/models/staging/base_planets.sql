{# Senaste batchen per planet. residents/films används inte: relationerna hämtas från people.homeworld och films.planets (speglade). #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'planets') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'planets') }} as planet_id,
    raw_json:name::string as name,
    raw_json:climate::string as climate,
    raw_json:terrain::string as terrain,
    raw_json:gravity::string as gravity,
    {{ to_num('raw_json:diameter') }} as diameter,
    {{ to_num('raw_json:rotation_period') }} as rotation_period,
    {{ to_num('raw_json:orbital_period') }} as orbital_period,
    {{ to_num('raw_json:surface_water') }} as surface_water,
    {{ to_num('raw_json:population') }} as population,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    source_url,
    load_ts,
    batch_id
from latest
