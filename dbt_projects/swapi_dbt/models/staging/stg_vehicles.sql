{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_vehicles',
    derived_columns={'record_source': '!swapi.vehicles'},
    hashed_columns={
        'vehicle_hk': 'vehicle_id',
        'vehicle_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['name', 'model', 'manufacturer', 'vehicle_class', 'cost_in_credits', 'length', 'crew', 'passengers', 'cargo_capacity', 'consumables', 'max_atmosphering_speed']
        }
    }
) }}
