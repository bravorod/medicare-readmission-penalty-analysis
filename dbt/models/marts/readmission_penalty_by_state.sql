select
    state,
    count(*) as n_hospitals,
    sum(case when is_penalized then 1 else 0 end) as n_penalized,
    sum(case when is_penalized then 1 else 0 end) / count(*) as share_penalized,
    avg(penalty_pct) as avg_penalty_pct,
    sum(estimated_penalty_usd) as estimated_penalty_usd
from {{ ref('hospital_readmission_penalty') }}
where state is not null
group by state
