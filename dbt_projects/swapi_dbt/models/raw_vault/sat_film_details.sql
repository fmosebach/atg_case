{{ automate_dv.sat(
    src_pk='film_hk',
    src_hashdiff='film_details_hashdiff',
    src_payload=['title', 'episode_id', 'director', 'producer', 'release_date', 'opening_crawl'],
    src_ldts='load_ts',
    src_source='record_source',
    source_model='stg_films'
) }}
