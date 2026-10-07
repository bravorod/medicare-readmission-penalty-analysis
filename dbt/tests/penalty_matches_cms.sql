select facility_id, penalty_pct, recalculated_penalty_pct
from {{ ref('hospital_readmission_penalty') }}
where not matches_cms
