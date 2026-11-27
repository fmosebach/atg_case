{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_planets',
    derived_columns={'record_source': '!swapi.planets'},
    hashed_columns={
        'planet_hk': 'planet_id',
        'planet_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['name', 'climate', 'terrain', 'gravity', 'diameter', 'rotation_period', 'orbital_period', 'surface_water', 'population']
        }
    }
) }}
