"""
stats_tests.py
Statistical validation of the turnaround buffer findings (AA @ DFW).
  Test 1: Chi-square  - tight (<60 min) vs buffered (75+ min) turns
  Test 2: Regression  - minutes absorbed per extra buffer minute
  Test 3: Z-test      - AA @ DFW vs DL @ ATL pass-on rate
Results print to screen and save to docs/stats_results.md
"""

import warnings
from getpass import getpass

import pandas as pd
import psycopg2
import statsmodels.formula.api as smf
from scipy.stats import chi2_contingency
from statsmodels.stats.proportion import proportions_ztest

warnings.filterwarnings("ignore")

conn = psycopg2.connect(host="localhost", port=5432, dbname="flights",
                        user="postgres", password=getpass("Postgres password: "))
out = ["# Statistical Test Results\n"]


def log(line=""):
    print(line)
    out.append(line)


def fmt_p(p):
    return "p < 0.001" if p < 0.001 else f"p = {p:.4f}"


# ---------- Load AA @ DFW turns where the incoming plane was 15+ min late ----------
df = pd.read_sql("""
    SELECT sched_turn_min, incoming_delay_min, dep_delay_minutes, time_of_day, year
    FROM analytics.linked_legs
    WHERE airline = 'AA' AND origin = 'DFW' AND incoming_delay_min >= 15
""", conn)
df["passed_on"] = df["dep_delay_minutes"] >= 15
log(f"Loaded {len(df):,} late-arriving AA turns at DFW\n")

# ---------- Test 1: Chi-square ----------
tight = df[df["sched_turn_min"] < 60]
buffered = df[df["sched_turn_min"] >= 75]
table = [[tight["passed_on"].sum(), (~tight["passed_on"]).sum()],
         [buffered["passed_on"].sum(), (~buffered["passed_on"]).sum()]]
chi2, p1, _, _ = chi2_contingency(table)
rate_t, rate_b = tight["passed_on"].mean(), buffered["passed_on"].mean()

log("## Test 1: Chi-square (tight <60 min vs buffered 75+ min)")
log(f"- Tight turns:    {len(tight):,} flights, {rate_t:.1%} passed delay on")
log(f"- Buffered turns: {len(buffered):,} flights, {rate_b:.1%} passed delay on")
log(f"- Difference: {100 * (rate_t - rate_b):.1f} percentage points")
log(f"- Tight turns are {rate_t / rate_b:.2f}x as likely to pass delay on")
log(f"- Chi-square = {chi2:,.1f}, {fmt_p(p1)}\n")

# ---------- Test 2: Regression ----------
reg = df[(df["sched_turn_min"] >= 30) & (df["sched_turn_min"] <= 180)]
model = smf.ols(
    "dep_delay_minutes ~ incoming_delay_min + sched_turn_min + C(time_of_day) + C(year)",
    data=reg,
).fit(cov_type="HC1")
coef = model.params["sched_turn_min"]
lo, hi = model.conf_int().loc["sched_turn_min"]

log("## Test 2: Regression (departure delay ~ incoming delay + turnaround + controls)")
log(f"- Sample: {len(reg):,} turns (30-180 min scheduled turnaround)")
log(f"- Each extra scheduled turnaround minute changes departure delay by "
    f"{coef:.3f} min (95% CI {lo:.3f} to {hi:.3f})")
log(f"- In plain terms: 1 buffer minute absorbs ~{-coef:.2f} min of delay; "
    f"15 buffer minutes absorb ~{-15 * coef:.1f} min")
log(f"- Each incoming delay minute adds "
    f"{model.params['incoming_delay_min']:.3f} min of departure delay")
log(f"- R-squared = {model.rsquared:.3f}, {fmt_p(model.pvalues['sched_turn_min'])}\n")

# ---------- Test 3: AA @ DFW vs DL @ ATL ----------
bench = pd.read_sql("""
    SELECT airline, origin,
           COUNT(*)                              AS n,
           SUM((dep_delay_minutes >= 15)::int)   AS passed
    FROM analytics.linked_legs
    WHERE incoming_delay_min >= 15
      AND ((airline = 'AA' AND origin = 'DFW') OR (airline = 'DL' AND origin = 'ATL'))
    GROUP BY airline, origin
""", conn).set_index("airline")
z, p3 = proportions_ztest(count=[bench.loc["AA", "passed"], bench.loc["DL", "passed"]],
                          nobs=[bench.loc["AA", "n"], bench.loc["DL", "n"]])
aa_rate = bench.loc["AA", "passed"] / bench.loc["AA", "n"]
dl_rate = bench.loc["DL", "passed"] / bench.loc["DL", "n"]

log("## Test 3: Two-proportion z-test (AA @ DFW vs DL @ ATL, incoming 15+ min late)")
log(f"- AA @ DFW: {aa_rate:.1%} passed on ({bench.loc['AA', 'n']:,} flights)")
log(f"- DL @ ATL: {dl_rate:.1%} passed on ({bench.loc['DL', 'n']:,} flights)")
log(f"- Difference: {100 * (aa_rate - dl_rate):.1f} percentage points")
log(f"- z = {z:.1f}, {fmt_p(p3)}")

conn.close()
with open("docs/stats_results.md", "w", encoding="utf-8") as f:
    f.write("\n".join(out))
print("\nSaved to docs/stats_results.md")