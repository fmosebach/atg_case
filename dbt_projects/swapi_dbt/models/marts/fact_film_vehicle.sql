-- Grain: en rad per film och fordon som förekommer i filmen.
select
    {{ hex_key('link_film_vehicle_hk') }} as film_vehicle_key,
    {{ hex_key('film_hk') }} as film_key,
    {{ hex_key('vehicle_hk') }} as vehicle_key,
    1 as vehicle_count
from {{ ref('link_film_vehicle') }}
