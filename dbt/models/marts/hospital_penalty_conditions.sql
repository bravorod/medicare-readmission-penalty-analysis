with points as (
    select
        *,
        penalty_points / nullif(sum(penalty_points) over (partition by facility_id), 0) as share_of_hospital_penalty
    from {{ ref('int_penalty_points') }}
)

select
    concat(c.facility_id, '-', c.condition_code) as hospital_condition_id,
    c.facility_id,
    h.facility_name,
    h.city,
    h.state,
    c.condition_code,
    c.condition,
    c.eligible_discharges,
    c.excess_readmission_ratio,
    c.peer_median_ratio,
    c.counts_toward_penalty,
    c.payment_share,
    c.penalty_points,
    c.share_of_hospital_penalty,
    h.estimated_penalty_usd * c.share_of_hospital_penalty as estimated_penalty_usd,
    c.reduction_needed_to_clear,
    c.neutrality_modifier,
    h.penalty_pct as hospital_penalty_pct,
    h.medicare_payments_usd as hospital_medicare_payments_usd,
    c.predicted_readmission_rate,
    c.expected_readmission_rate,
    c.n_readmissions,
    c.excess_readmissions
from points as c
left join {{ ref('hospital_readmission_penalty') }} as h on h.facility_id = c.facility_id
