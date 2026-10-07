select
    trim(rndrng_prvdr_ccn) as facility_id,
    nullif(trim(rndrng_prvdr_org_name), '') as provider_name,
    nullif(trim(rndrng_prvdr_city), '') as city,
    upper(nullif(trim(rndrng_prvdr_state_abrvtn), '')) as state,
    safe_cast(trim(tot_dschrgs) as int64) as medicare_discharges,
    safe_cast(replace(trim(tot_mdcr_pymt_amt), ',', '') as float64) as medicare_payments_usd,
    2024 as payment_year
from {{ source('raw', 'inpatient_payments') }}
where trim(rndrng_prvdr_ccn) != ''
