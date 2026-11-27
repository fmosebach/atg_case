{# Senaste batchen per person: parsar raw_json till platta kolumner och extraherar id/FK ur URL:er. #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'people') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'people') }} as person_id,
    raw_json:name::string as name,
    {{ to_num('raw_json:height') }} as height,
    {{ to_num('raw_json:mass') }} as mass,
    raw_json:hair_color::string as hair_color,
    raw_json:skin_color::string as skin_color,
    raw_json:eye_color::string as eye_color,
    raw_json:birth_year::string as birth_year,
    raw_json:gender::string as gender,
    {{ swapi_id('raw_json:homeworld::string', 'planets') }} as homeworld_planet_id,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    raw_json:films as films_urls,
    raw_json:species as species_urls,
    raw_json:starships as starships_urls,
    raw_json:vehicles as vehicles_urls,
    source_url,
    load_ts,
    batch_id
from latest
