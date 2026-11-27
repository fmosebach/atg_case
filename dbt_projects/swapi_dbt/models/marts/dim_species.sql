with species as (
    select
        {{ hex_key('h.species_hk') }} as species_key,
        h.species_id,
        s.name,
        s.classification,
        s.designation,
        s.language,
        s.average_height,
        s.average_lifespan,
        s.skin_colors,
        s.hair_colors,
        s.eye_colors
    from {{ ref('hub_species') }} as h
    inner join {{ latest_sat('sat_species_details', 'species_hk') }} as s
        on h.species_hk = s.species_hk
)

select * from species

union all by name

-- Okänd medlem för personer utan art (fact_person_film.species_key pekar hit).
-- BY NAME: kolumner som inte anges blir null.
select
    {{ unknown_key() }} as species_key,
    'Unknown' as name
