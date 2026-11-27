with planets as (
    select
        {{ hex_key('h.planet_hk') }} as planet_key,
        h.planet_id,
        s.name,
        s.climate,
        s.terrain,
        s.gravity,
        s.diameter,
        s.rotation_period,
        s.orbital_period,
        s.surface_water,
        s.population
    from {{ ref('hub_planet') }} as h
    inner join {{ latest_sat('sat_planet_details', 'planet_hk') }} as s
        on h.planet_hk = s.planet_hk
)

select * from planets

union all by name

-- Okänd medlem för personer utan hemvärld (fact_person_film.homeworld_planet_key pekar hit).
-- BY NAME: kolumner som inte anges blir null.
select
    {{ unknown_key() }} as planet_key,
    'Unknown' as name
