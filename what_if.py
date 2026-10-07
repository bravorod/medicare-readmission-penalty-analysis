import pandas as pd

CAP = 0.03
CUTS = (0.05, 0.10, 0.20)


def penalty_rate(conditions, cuts):
    cut = conditions["condition_code"].map(cuts).fillna(0.0)
    ratio = conditions["excess_readmission_ratio"] * (1 - cut)
    above = (ratio - conditions["peer_median_ratio"]).clip(lower=0).fillna(0)
    points = (conditions["payment_share"].fillna(0) * above).where(conditions["counts_toward_penalty"], 0.0)
    total = points.groupby(conditions["facility_id"]).sum()
    modifier = conditions.groupby("facility_id")["neutrality_modifier"].max()
    return (modifier * total).clip(upper=CAP)


def main():
    conditions = pd.read_csv("tableau/extracts/hospital_penalty_conditions.csv", dtype={"facility_id": str})
    hospitals = pd.read_csv("tableau/extracts/hospital_readmission_penalty.csv", dtype={"facility_id": str})
    payments = hospitals.set_index("facility_id")["medicare_payments_usd"]

    before = (penalty_rate(conditions, {}) * payments).sum()
    rows = []
    for code in sorted(conditions["condition_code"].unique()):
        for cut in CUTS:
            after = (penalty_rate(conditions, {code: cut}) * payments).sum()
            rows.append({"condition": code, "cut": cut, "penalty_before_usd": before,
                         "penalty_after_usd": after, "savings_usd": before - after})

    table = pd.DataFrame(rows)
    table.to_csv("what_if.csv", index=False)
    money = ["penalty_before_usd", "penalty_after_usd", "savings_usd"]
    table[money] = table[money].round(0)
    print(table.to_string(index=False))


if __name__ == "__main__":
    main()
