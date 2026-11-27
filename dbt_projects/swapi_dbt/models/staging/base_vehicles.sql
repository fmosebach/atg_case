{# Senaste batchen per fordon. pilots/films används inte: relationerna hämtas från people.vehicles och films.vehicles (speglade). #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'vehicles') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'vehicles') }} as vehicle_id,
    raw_json:name::string as name,
    raw_json:model::string as model,
    raw_json:manufacturer::string as manufacturer,
    raw_json:vehicle_class::string as vehicle_class,
    {{ to_num('raw_json:cost_in_credits') }} as cost_in_credits,
    {{ to_num('raw_json:length') }} as length,
    raw_json:crew::string as crew,
    {{ to_num('raw_json:passengers') }} as passengers,
    {{ to_num('raw_json:cargo_capacity') }} as cargo_capacity,
    raw_json:consumables::string as consumables,
    {{ to_num('raw_json:max_atmosphering_speed') }} as max_atmosphering_speed,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    source_url,
    load_ts,
    batch_id
from latest
