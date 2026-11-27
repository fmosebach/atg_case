{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_starships',
    derived_columns={'record_source': '!swapi.starships'},
    hashed_columns={
        'starship_hk': 'starship_id',
        'starship_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['name', 'model', 'manufacturer', 'starship_class', 'cost_in_credits', 'length', 'crew', 'passengers', 'cargo_capacity', 'consumables', 'max_atmosphering_speed', 'hyperdrive_rating', 'mglt']
        }
    }
) }}
