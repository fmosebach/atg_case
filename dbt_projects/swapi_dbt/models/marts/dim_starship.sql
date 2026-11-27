select
    {{ hex_key('h.starship_hk') }} as starship_key,
    h.starship_id,
    s.name,
    s.model,
    s.manufacturer,
    s.starship_class,
    s.cost_in_credits,
    s.length,
    s.crew,
    s.passengers,
    s.cargo_capacity,
    s.consumables,
    s.max_atmosphering_speed,
    s.hyperdrive_rating,
    s.mglt
from {{ ref('hub_starship') }} as h
inner join {{ latest_sat('sat_starship_details', 'starship_hk') }} as s
    on h.starship_hk = s.starship_hk
