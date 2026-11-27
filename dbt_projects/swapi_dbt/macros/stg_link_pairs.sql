{# Länk-staging: en rad per relation. Hash-keys beräknas här så att raw_vault bara läser dem. #}

{# Array-relation: flatten av en URL-lista i base-modellen. #}
{% macro stg_link_from_array(base_model, left, right, array_column, right_url_entity) -%}
with pairs as (
    select
        b.{{ left }}_id,
        {{ swapi_id('f.value::string', right_url_entity) }} as {{ right }}_id,
        b.load_ts
    from {{ ref(base_model) }} as b,
        lateral flatten(input => b.{{ array_column }}) as f
)

select
    {{ automate_dv.hash(columns=[left ~ '_id', right ~ '_id'], alias='link_' ~ left ~ '_' ~ right ~ '_hk') }},
    {{ automate_dv.hash(columns=left ~ '_id', alias=left ~ '_hk') }},
    {{ automate_dv.hash(columns=right ~ '_id', alias=right ~ '_hk') }},
    {{ left }}_id,
    {{ right }}_id,
    load_ts,
    '{{ "swapi." ~ base_model | replace("base_", "") }}' as record_source
from pairs
where {{ right }}_id is not null
{%- endmacro %}

{# Enkel FK-kolumn (t.ex. homeworld) som redan är parsad till id i base-modellen. #}
{% macro stg_link_from_column(base_model, left, right, id_column) -%}
with pairs as (
    select
        {{ left }}_id,
        {{ id_column }} as {{ right }}_id,
        load_ts
    from {{ ref(base_model) }}
)

select
    {{ automate_dv.hash(columns=[left ~ '_id', right ~ '_id'], alias='link_' ~ left ~ '_' ~ right ~ '_hk') }},
    {{ automate_dv.hash(columns=left ~ '_id', alias=left ~ '_hk') }},
    {{ automate_dv.hash(columns=right ~ '_id', alias=right ~ '_hk') }},
    {{ left }}_id,
    {{ right }}_id,
    load_ts,
    '{{ "swapi." ~ base_model | replace("base_", "") }}' as record_source
from pairs
where {{ right }}_id is not null
{%- endmacro %}
