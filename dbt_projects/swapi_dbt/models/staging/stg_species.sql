{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_species',
    derived_columns={'record_source': '!swapi.species'},
    hashed_columns={
        'species_hk': 'species_id',
        'species_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['name', 'classification', 'designation', 'language', 'average_height', 'average_lifespan', 'skin_colors', 'hair_colors', 'eye_colors']
        }
    }
) }}
