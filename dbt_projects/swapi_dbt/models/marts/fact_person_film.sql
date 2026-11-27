-- Grain: en rad per person och film. Summera character_count för t.ex. karaktärer per film/planet/art.
select
    {{ hex_key('lpf.link_person_film_hk') }} as person_film_key,
    {{ hex_key('lpf.person_hk') }} as person_key,
    {{ hex_key('lpf.film_hk') }} as film_key,
    {{ hex_key('lpp.planet_hk') }} as homeworld_planet_key,
    coalesce({{ hex_key('lps.species_hk') }}, {{ unknown_key() }}) as species_key,
    1 as character_count
from {{ ref('link_person_film') }} as lpf
left join {{ ref('link_person_planet') }} as lpp
    on lpf.person_hk = lpp.person_hk
left join {{ ref('link_person_species') }} as lps
    on lpf.person_hk = lps.person_hk
