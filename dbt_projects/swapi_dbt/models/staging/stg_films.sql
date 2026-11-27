{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_films',
    derived_columns={'record_source': '!swapi.films'},
    hashed_columns={
        'film_hk': 'film_id',
        'film_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['title', 'episode_id', 'director', 'producer', 'release_date', 'opening_crawl']
        }
    }
) }}
