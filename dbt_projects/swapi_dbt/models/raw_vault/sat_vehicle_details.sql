{{ automate_dv.sat(
    src_pk='vehicle_hk',
    src_hashdiff='vehicle_details_hashdiff',
    src_payload=['name', 'model', 'manufacturer', 'vehicle_class', 'cost_in_credits', 'length', 'crew', 'passengers', 'cargo_capacity', 'consumables', 'max_atmosphering_speed'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_vehicles'
) }}
