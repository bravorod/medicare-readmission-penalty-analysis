{% set conditions = [
    ('ami', 'AMI', 'Heart attack'),
    ('copd', 'COPD', 'COPD'),
    ('hf', 'HF', 'Heart failure'),
    ('pneumonia', 'PN', 'Pneumonia'),
    ('cabg', 'CABG', 'Heart bypass surgery (CABG)'),
    ('tha_tka', 'HIP-KNEE', 'Hip/knee replacement'),
] %}

with source as (
    select * from {{ source('raw', 'hrrp_penalties') }}
    where length(trim(hospital_ccn)) = 6
)

{% for suffix, code, label in conditions %}
select
    trim(hospital_ccn) as facility_id,
    '{{ code }}' as condition_code,
    '{{ label }}' as condition,
    safe_cast(trim(payment_adjustment_factor) as float64) as payment_adjustment_factor,
    safe_cast(trim(neutrality_modifier) as float64) as neutrality_modifier,
    safe_cast(trim(peer_group_assignment) as int64) as peer_group,
    safe_cast(replace(trim(number_of_eligible_discharges_for_{{ suffix }}), ',', '') as float64) as eligible_discharges,
    safe_cast(trim(err_for_{{ suffix }}) as float64) as excess_readmission_ratio,
    safe_cast(trim(peer_group_median_err_for_{{ suffix }}) as float64) as peer_median_ratio,
    coalesce(upper(trim(penalty_indicator_for_{{ suffix }})) = 'Y', false) as counts_toward_penalty,
    safe_cast(trim(drg_payment_ratio_for_{{ suffix }}) as float64) as payment_share
from source
{{ 'union all' if not loop.last }}
{% endfor %}
