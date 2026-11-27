-- Grain: en rad per person och film. Summera character_count för t.ex. karaktärer per film/planet/art.
-- Hemvärld och art deduplas per person före join så att grain person x film alltid bevaras.
select
    {{ hex_key('lpf.link_person_film_hk') }} as person_film_key,
    {{ hex_key('lpf.person_hk') }} as person_key,
    {{ hex_key('lpf.film_hk') }} as film_key,
    coalesce({{ hex_key('lpp.planet_hk') }}, {{ unknown_key() }}) as homeworld_planet_key,
    coalesce({{ hex_key('lps.species_hk') }}, {{ unknown_key() }}) as species_key,
    1 as character_count
from {{ ref('link_person_film') }} as lpf
left join (
    select person_hk, min(planet_hk) as planet_hk
    from {{ ref('link_person_planet') }}
    group by person_hk
) as lpp
    on lpf.person_hk = lpp.person_hk
left join (
    select person_hk, min(species_hk) as species_hk
    from {{ ref('link_person_species') }}
    group by person_hk
) as lps
    on lpf.person_hk = lps.person_hk
