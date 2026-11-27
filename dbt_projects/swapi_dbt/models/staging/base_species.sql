{# Senaste batchen per art. people/films används inte: relationerna hämtas från people.species och films.species (speglade). #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'species') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'species') }} as species_id,
    raw_json:name::string as name,
    raw_json:classification::string as classification,
    raw_json:designation::string as designation,
    raw_json:language::string as language,
    {{ to_num('raw_json:average_height') }} as average_height,
    {{ to_num('raw_json:average_lifespan') }} as average_lifespan,
    raw_json:skin_colors::string as skin_colors,
    raw_json:hair_colors::string as hair_colors,
    raw_json:eye_colors::string as eye_colors,
    {{ swapi_id('raw_json:homeworld::string', 'planets') }} as homeworld_planet_id,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    source_url,
    load_ts,
    batch_id
from latest
