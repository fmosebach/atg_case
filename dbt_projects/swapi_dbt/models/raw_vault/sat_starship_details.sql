{{ automate_dv.sat(
    src_pk='starship_hk',
    src_hashdiff='starship_details_hashdiff',
    src_payload=['name', 'model', 'manufacturer', 'starship_class', 'cost_in_credits', 'length', 'crew', 'passengers', 'cargo_capacity', 'consumables', 'max_atmosphering_speed', 'hyperdrive_rating', 'mglt'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_starships'
) }}
