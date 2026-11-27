{{ automate_dv.sat(
    src_pk='planet_hk',
    src_hashdiff='planet_details_hashdiff',
    src_payload=['name', 'climate', 'terrain', 'gravity', 'diameter', 'rotation_period', 'orbital_period', 'surface_water', 'population'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_planets'
) }}
