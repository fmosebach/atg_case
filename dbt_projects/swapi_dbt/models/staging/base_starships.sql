{# Senaste batchen per rymdskepp. pilots/films används inte: relationerna hämtas från people.starships och films.starships (speglade). #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'starships') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'starships') }} as starship_id,
    raw_json:name::string as name,
    raw_json:model::string as model,
    raw_json:manufacturer::string as manufacturer,
    raw_json:starship_class::string as starship_class,
    {{ to_num('raw_json:cost_in_credits') }} as cost_in_credits,
    {{ to_num('raw_json:length') }} as length,
    raw_json:crew::string as crew,
    {{ to_num('raw_json:passengers') }} as passengers,
    {{ to_num('raw_json:cargo_capacity') }} as cargo_capacity,
    raw_json:consumables::string as consumables,
    {{ to_num('raw_json:max_atmosphering_speed') }} as max_atmosphering_speed,
    {{ to_num('raw_json:hyperdrive_rating') }} as hyperdrive_rating,
    {{ to_num('raw_json:MGLT') }} as mglt,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    source_url,
    load_ts,
    batch_id
from latest
