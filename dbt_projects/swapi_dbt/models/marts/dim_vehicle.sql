select
    {{ hex_key('h.vehicle_hk') }} as vehicle_key,
    h.vehicle_id,
    s.name,
    s.model,
    s.manufacturer,
    s.vehicle_class,
    s.cost_in_credits,
    s.length,
    s.crew,
    s.passengers,
    s.cargo_capacity,
    s.consumables,
    s.max_atmosphering_speed
from {{ ref('hub_vehicle') }} as h
inner join {{ latest_sat('sat_vehicle_details', 'vehicle_hk') }} as s
    on h.vehicle_hk = s.vehicle_hk
