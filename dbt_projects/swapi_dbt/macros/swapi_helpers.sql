{# Hämtar numeriskt id ur en SWAPI-URL, t.ex. .../people/4/ eller .../people/4 -> 4 #}
{% macro swapi_id(column, entity) -%}
    try_to_number(regexp_substr({{ column }}, '/{{ entity }}/([0-9]+)/?$', 1, 1, 'e', 1))
{%- endmacro %}

{# Parsar numeriska textfält; 'unknown', 'n/a' och intervall blir null. Tusentalsavgränsare tas bort.
   OBS: 'unknown' och saknat värde blir därmed samma sak (null) i satellitens hashdiff. #}
{% macro to_num(column) -%}
    try_to_decimal(trim(replace({{ column }}::string, ',', '')), 38, 2)
{%- endmacro %}

{# Parsar SWAPI-tidsstämplar, t.ex. 2014-12-09T13:50:51.644000Z #}
{% macro to_ts(column) -%}
    try_to_timestamp_ntz(replace(replace({{ column }}::string, 'T', ' '), 'Z', ''))
{%- endmacro %}

{# Dimensionsnyckel som hex-sträng (Power BI stödjer inte binära relationsnycklar) #}
{% macro hex_key(column) -%}
    lower(to_varchar({{ column }}, 'HEX'))
{%- endmacro %}

{# Nyckel för okänd medlem i dimensioner #}
{% macro unknown_key() -%}
    '{{ "0" * 32 }}'
{%- endmacro %}
