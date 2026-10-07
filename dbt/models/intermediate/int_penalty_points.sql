with penalties as (
    select * from {{ ref('stg_penalties') }}
),

readmissions as (
    select * from {{ ref('stg_readmissions') }}
)

select
    p.*,
    case
        when p.counts_toward_penalty and p.excess_readmission_ratio > p.peer_median_ratio
            then coalesce(p.payment_share, 0) * (p.excess_readmission_ratio - p.peer_median_ratio)
        else 0
    end as penalty_points,
    case
        when p.counts_toward_penalty then 1 - p.peer_median_ratio / p.excess_readmission_ratio
    end as reduction_needed_to_clear,
    r.predicted_readmission_rate,
    r.expected_readmission_rate,
    r.n_readmissions,
    (r.predicted_readmission_rate - r.expected_readmission_rate) * r.n_discharges / 100 as excess_readmissions
from penalties as p
left join readmissions as r
    on r.facility_id = p.facility_id
    and r.condition_code = p.condition_code
