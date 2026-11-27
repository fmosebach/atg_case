select
    {{ hex_key('h.person_hk') }} as person_key,
    h.person_id,
    s.name,
    s.height,
    s.mass,
    s.hair_color,
    s.skin_color,
    s.eye_color,
    s.birth_year,
    s.gender
from {{ ref('hub_person') }} as h
inner join {{ latest_sat('sat_person_details', 'person_hk') }} as s
    on h.person_hk = s.person_hk
