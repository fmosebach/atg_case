{# Senaste versionen per hash-key ur en (historiserad) satellit. #}
{% macro latest_sat(sat_model, pk) -%}
(
    select *
    from {{ ref(sat_model) }}
    qualify row_number() over (partition by {{ pk }} order by load_ts desc) = 1
)
{%- endmacro %}
