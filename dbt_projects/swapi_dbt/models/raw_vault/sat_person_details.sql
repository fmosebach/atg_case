{{ automate_dv.sat(
    src_pk='person_hk',
    src_hashdiff='person_details_hashdiff',
    src_payload=['name', 'height', 'mass', 'hair_color', 'skin_color', 'eye_color', 'birth_year', 'gender'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_people'
) }}
