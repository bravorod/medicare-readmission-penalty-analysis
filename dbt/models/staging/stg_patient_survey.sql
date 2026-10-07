select
    trim(facility_id) as facility_id,
    safe_cast(trim(patient_survey_star_rating) as int64) as patient_experience_stars
from {{ source('raw', 'patient_survey') }}
where hcahps_measure_id = 'H_STAR_RATING'
