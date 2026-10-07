with hospitals as (
    select
        h.facility_id,
        case
            when h.penalty_pct = 0 then 'No penalty'
            when h.penalty_pct < 1 then 'Penalty under 1%'
            else 'Penalty 1% or more'
        end as penalty_group,
        case
            when h.penalty_pct = 0 then 1
            when h.penalty_pct < 1 then 2
            else 3
        end as group_order,
        s.patient_experience_stars,
        d.death_rate_pct
    from {{ ref('hospital_readmission_penalty') }} as h
    left join {{ ref('stg_patient_survey') }} as s on s.facility_id = h.facility_id
    left join {{ ref('stg_death_rates') }} as d on d.facility_id = h.facility_id
)

select
    penalty_group,
    group_order,
    count(*) as n_hospitals,
    count(patient_experience_stars) as n_with_patient_rating,
    avg(case when patient_experience_stars >= 4 then 1 when patient_experience_stars is not null then 0 end) as share_4_5_star_patient_rating,
    count(death_rate_pct) as n_with_death_rate,
    avg(death_rate_pct) as avg_death_rate_pct
from hospitals
group by penalty_group, group_order
