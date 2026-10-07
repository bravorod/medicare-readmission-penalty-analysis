select
    trim(facility_id) as facility_id,
    nullif(trim(facility_name), '') as facility_name,
    nullif(trim(city_town), '') as city,
    upper(nullif(trim(state), '')) as state
from {{ source('raw', 'hospitals') }}
