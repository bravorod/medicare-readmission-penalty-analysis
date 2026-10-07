select
    trim(facility_id) as facility_id,
    replace(replace(trim(measure_name), 'READM-30-', ''), '-HRRP', '') as condition_code,
    safe_cast(trim(number_of_discharges) as int64) as n_discharges,
    safe_cast(trim(predicted_readmission_rate) as float64) as predicted_readmission_rate,
    safe_cast(trim(expected_readmission_rate) as float64) as expected_readmission_rate,
    safe_cast(trim(number_of_readmissions) as int64) as n_readmissions
from {{ source('raw', 'hrrp_readmissions') }}
