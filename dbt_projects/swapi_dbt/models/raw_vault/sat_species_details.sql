{{ automate_dv.sat(
    src_pk='species_hk',
    src_hashdiff='species_details_hashdiff',
    src_payload=['name', 'classification', 'designation', 'language', 'average_height', 'average_lifespan', 'skin_colors', 'hair_colors', 'eye_colors'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_species'
) }}
