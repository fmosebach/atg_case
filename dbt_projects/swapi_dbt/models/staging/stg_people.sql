{{ automate_dv.stage(
    include_source_columns=true,
    source_model='base_people',
    derived_columns={'record_source': '!swapi.people'},
    hashed_columns={
        'person_hk': 'person_id',
        'person_details_hashdiff': {
            'is_hashdiff': true,
            'columns': ['name', 'height', 'mass', 'hair_color', 'skin_color', 'eye_color', 'birth_year', 'gender']
        }
    }
) }}
