with by_condition as (
    select
        condition_code,
        condition,
        count(excess_readmission_ratio) as n_hospitals_measured,
        sum(case when counts_toward_penalty then 1 else 0 end) as n_hospitals_penalized,
        sum(estimated_penalty_usd) as estimated_penalty_usd,
        avg(case when counts_toward_penalty then reduction_needed_to_clear end) as avg_reduction_needed_to_clear,
        sum(case when excess_readmissions > 0 then excess_readmissions else 0 end) as excess_readmissions
    from {{ ref('hospital_penalty_conditions') }}
    group by condition_code, condition
)

select
    *,
    n_hospitals_penalized / nullif(n_hospitals_measured, 0) as share_of_hospitals_penalized,
    estimated_penalty_usd / nullif(sum(estimated_penalty_usd) over (), 0) as share_of_penalty_dollars
from by_condition
