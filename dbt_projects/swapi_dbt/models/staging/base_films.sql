{# Senaste batchen per film. characters-listan används inte: relationen person-film hämtas från people.films (identisk, speglad). #}
with latest as (
    select raw_json, source_url, load_ts, batch_id
    from {{ source('swapi', 'films') }}
    qualify row_number() over (partition by source_url order by load_ts desc, batch_id desc) = 1
)

select
    {{ swapi_id('source_url', 'films') }} as film_id,
    raw_json:title::string as title,
    raw_json:episode_id::number as episode_id,
    raw_json:director::string as director,
    raw_json:producer::string as producer,
    try_to_date(raw_json:release_date::string) as release_date,
    raw_json:opening_crawl::string as opening_crawl,
    {{ to_ts('raw_json:created') }} as created_at,
    {{ to_ts('raw_json:edited') }} as edited_at,
    raw_json:planets as planets_urls,
    raw_json:species as species_urls,
    raw_json:starships as starships_urls,
    raw_json:vehicles as vehicles_urls,
    source_url,
    load_ts,
    batch_id
from latest
