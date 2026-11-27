select
    {{ hex_key('h.film_hk') }} as film_key,
    h.film_id,
    s.title,
    s.episode_id,
    s.director,
    s.producer,
    s.release_date,
    s.opening_crawl
from {{ ref('hub_film') }} as h
inner join {{ latest_sat('sat_film_details', 'film_hk') }} as s
    on h.film_hk = s.film_hk
