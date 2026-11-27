{{ automate_dv.link(
    src_pk='link_film_species_hk',
    src_fk=['film_hk', 'species_hk'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_film_species'
) }}
