{{ automate_dv.link(
    src_pk='link_species_planet_hk',
    src_fk=['species_hk', 'planet_hk'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_species_planet'
) }}
