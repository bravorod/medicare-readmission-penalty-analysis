select
    trim(facility_id) as facility_id,
    safe_cast(trim(score) as float64) as death_rate_pct
from {{ source('raw', 'death_rates') }}
where measure_id = 'Hybrid_HWM'
