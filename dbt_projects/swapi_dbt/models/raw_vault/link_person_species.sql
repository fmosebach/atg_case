{{ automate_dv.link(
    src_pk='link_person_species_hk',
    src_fk=['person_hk', 'species_hk'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_person_species'
) }}
