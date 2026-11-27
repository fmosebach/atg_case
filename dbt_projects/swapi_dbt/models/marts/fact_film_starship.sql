-- Grain: en rad per film och rymdskepp som förekommer i filmen.
select
    {{ hex_key('link_film_starship_hk') }} as film_starship_key,
    {{ hex_key('film_hk') }} as film_key,
    {{ hex_key('starship_hk') }} as starship_key,
    1 as starship_count
from {{ ref('link_film_starship') }}
