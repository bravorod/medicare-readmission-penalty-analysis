with points as (
    select * from {{ ref('int_penalty_points') }}
),

totals as (
    select
        facility_id,
        max(payment_adjustment_factor) as payment_adjustment_factor,
        max(neutrality_modifier) as neutrality_modifier,
        max(peer_group) as peer_group,
        sum(penalty_points) as penalty_points,
        count(excess_readmission_ratio) as n_conditions_measured,
        sum(case when counts_toward_penalty then 1 else 0 end) as n_conditions_penalized,
        sum(excess_readmissions) as excess_readmissions
    from points
    group by facility_id
),

main_driver as (
    select
        facility_id,
        condition as main_driver_condition,
        penalty_points as main_driver_points
    from points
    where penalty_points > 0
    qualify row_number() over (partition by facility_id order by penalty_points desc, condition_code) = 1
),

recalculated as (
    select
        *,
        least(0.03, neutrality_modifier * penalty_points) as recalculated_penalty
    from totals
)

select
    r.facility_id,
    coalesce(h.facility_name, upper(p.provider_name)) as facility_name,
    coalesce(p.provider_name, h.facility_name) as display_name,
    coalesce(h.city, upper(p.city)) as city,
    coalesce(h.state, p.state) as state,
    r.peer_group,
    r.payment_adjustment_factor,
    round(100 * (1 - r.payment_adjustment_factor), 2) as penalty_pct,
    round(100 * r.recalculated_penalty, 2) as recalculated_penalty_pct,
    abs((1 - r.payment_adjustment_factor) - r.recalculated_penalty) <= 0.00011 as matches_cms,
    r.payment_adjustment_factor < 1 as is_penalized,
    r.n_conditions_measured,
    r.n_conditions_penalized,
    d.main_driver_condition,
    d.main_driver_points / nullif(r.penalty_points, 0) as main_driver_share,
    r.excess_readmissions,
    p.medicare_discharges,
    p.medicare_payments_usd,
    (1 - r.payment_adjustment_factor) * p.medicare_payments_usd as estimated_penalty_usd,
    2026 as penalty_fiscal_year,
    p.payment_year
from recalculated as r
left join main_driver as d on d.facility_id = r.facility_id
left join {{ ref('stg_payments') }} as p on p.facility_id = r.facility_id
left join {{ ref('stg_hospitals') }} as h on h.facility_id = r.facility_id
