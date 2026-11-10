# Scenario 1 — Execution indicators

**Business request:** "Give us indicators of project execution built from the data we already have: number of tasks opened and closed, and hours assigned by person and by project. We want to know which projects are running well."

**Situation:** Task and timesheet data are complete, in-house, and mature, covering roughly three years with stable definitions. Project codes are consistent, hours are booked against tasks rather than projects, and closures are timestamped. The business has not stated what it means by "execution," what decisions the indicator drives, or who acts when a project is flagged, and there is no agreed baseline for what normal looks like.

**Correct expert output:** Build, but decline to model. Nothing here requires a learned model, and proposing one would be the primary failure mode: the values are descriptive and the sample is one organisation, so any classifier trained on it would be fitting noise. The real work is (a) a short definitional session that fixes the construct — throughput, cycle time, or plan-versus-actual — and the decision that consumes it; (b) a small set of transparent, versioned metrics with documented formulas: task closure rate, median cycle time from open to close, hours variance against estimate, rework rate from reopened tasks, and a per-project ratio of booked to assigned hours; (c) segment cuts by project, team and role, with minimum-sample thresholds so small projects aren't flagged on noise; (d) an explicit caveat that task counts and hours measure recording discipline as much as execution, so a team that books poorly looks fast. Deliver as a dashboard with definitions attached, plus a periodic review meeting that owns the thresholds. The only defensible statistical work is a control chart or simple robust z-score per project to distinguish drift from ordinary variation — not a predictive model.

# Scenario 2 — Contractual churn model

**Business request:** "Build us a churn model so we can prioritise retention spend across the subscriber base."

**Situation:** The business is a subscription service with monthly and annual plans. A cancel event exists and is timestamped, and there are 24 months of history with a stable product catalogue for the last 18. Billing, login, support and usage data are available and joinable at customer level. The requested target is ambiguous in ways that change the answer materially: whether to count voluntary cancellations only or also involuntary churn from payment failure, whether a downgrade counts, whether logo churn or revenue churn is the target, and whether a customer who cancels and returns within 30 days is churn. No retention intervention has been defined, so nobody has yet stated what action the score will trigger or what the acceptable false-positive rate is.

**Correct expert output:** Build, after a definition workshop that precedes any modelling. The workshop must produce a signed-off churn definition, the prediction horizon (monthly churn over a 30- or 60-day window is the usual practical choice), the unit of analysis (account rather than user), and the treatment of the cancellation-then-reactivation case. Then build a discrete-time hazard model or a gradient-boosted classifier over a fixed horizon, with a point-in-time feature store so no feature uses post-cancellation information — the most common and most damaging leakage in this project type is features derived from data generated *during* the cancellation flow. Validate on an out-of-time holdout rather than a random split, since churn base rates drift with cohorts, and report lift at the top decile rather than AUC alone, because the deliverable is a ranked contact list. Deliver the score with the horizon and definition embedded in its name, a monitoring report on population stability, and a stated dependency: the score's value cannot be measured until a retention campaign with a control group exists. Recommend that control group be created in the same engagement.

# Scenario 3 — Credit risk scorecard

**Business request:** "Build a credit scoring model for our lending portfolio so we can approve, price and set limits."

**Situation:** A regulated lender with 60 months of disbursement and performance history, bureau data at application, and complete repayment records. Default is externally defined: 90 days past due, consistent with regulatory practice, so the label itself is not in question. Volumes are adequate but approval volumes were historically constrained by a manual policy, so the observed portfolio is a selected sample. Two decisions remain genuinely undefined: the performance horizon for the score (12 versus 24 months changes the label population), and the use of the output — approve/decline only, or approve/decline plus pricing and limit assignment, each requiring different calibration and different cut-off analysis. The business also expects a single score to serve both new applicants and existing-customer limit management, which are different populations with different available features.

**Correct expert output:** Build, with model risk governance as a first-class deliverable rather than a follow-on. Fix the horizon and the decision use in writing before modelling. Handle the selected-sample problem explicitly — reject inference or a documented statement of the survivor bias in the development sample — since the portfolio only contains loans the manual policy approved. Use a logistic regression scorecard with coarse-binned, monotonic weight-of-evidence features as the primary model for explainability and regulatory acceptance, with a gradient-boosted challenger for benchmarking only. Validate out-of-time across at least two economic periods where available, and report discrimination, calibration, and stability separately: Gini, the KS statistic, a calibration curve, and population stability index by feature and by score band. Document reason codes for adverse action, the cut-off analysis against approval rate and expected loss, and a retraining and monitoring policy with named owners. Explicitly deliver two models rather than one if application scoring and behavioural limit management are both required. Flag that the model's performance cannot be validated against the counterfactual of the declined population, and state that limitation in the model documentation rather than resolving it.

# Scenario 4 — Intermittent demand forecasting

**Business request:** "Predict tomorrow's purchases for each of our 1,800 SKUs across 50,000 customers."

**Situation:** Roughly 90 million customer-SKU-day cells, of which the overwhelming majority are zero. Most SKUs sell irregularly, with gaps longer than a week, and a meaningful share sell fewer than ten times a year in total. Historical sales are available for three years but are censored by stockouts, which were not recorded, so zero sales and zero demand are indistinguishable. Promotions, assortment changes and price changes are documented unevenly. Two large ambiguities remain unresolved: the intended use — replenishment, assortment decisions, or campaign targeting — and therefore the loss function, since a replenishment use penalises under-forecast asymmetry while a targeting use needs calibrated probabilities. The business has asked for daily granularity for all combinations, including customers with fewer than five purchase events.

**Correct expert output:** Decline the request as specified and renegotiate scope before modelling. Three separate corrections are required, in order. First, establish hierarchical baselines at the levels where signal actually exists — SKU-total and customer-total weekly demand — and measure the value of the requested daily, customer-SKU granularity against those baselines; in most data of this shape the bottom level is not forecastable and aggregation is the correct answer. Second, produce a censored-demand estimate or at minimum an explicit stockout mask, because without it the model learns the supply chain rather than demand. Third, agree the loss function with the business, since intermittent demand methods are not interchangeable: Croston and Syntetos-Boylan approximation for expected size, Tweedie or hurdle models for the zero-inflated structure, and quantile forecasts if safety stock is the objective. Exclude cold-start customers and slow-moving SKUs from the model output and route them to a policy rule — carry stock, or use the category mean — rather than emitting a spurious per-cell prediction. Deliver a probabilistic forecast with explicit intervals and a backtest on rolling origins, with bias reported alongside error. The correct framing of the deliverable is "which decision does each level of granularity improve," not "a prediction for every cell."

# Scenario 5 — Real-time adversarial decisioning

**Business request:** "Score every transaction in the payment path and block fraud before authorisation."

**Situation:** A payments environment with a 200 ms end-to-end budget including network and fallback. The confirmed-fraud rate is under 0.5%, and labels arrive 60 to 120 days later through chargebacks and investigation outcomes. The three fraud types in scope — stolen instrument, account takeover, and first-party abuse — have different costs and different label paths, and the business has not supplied a cost matrix or a review-capacity constraint, so the trade-off between a false decline and an unreviewed fraud case is currently undefined. Analyst review capacity is fixed at roughly 400 cases per day, which silently imposes the real operating threshold. Critically, the model's own blocks remove cases from the observed population, so labels are missing not at random.

**Correct expert output:** Build, but sequence it as a decisioning programme rather than a model project, and refuse to launch in blocking mode first. Obtain from the business the cost matrix and the daily review capacity in writing; without these the threshold is arbitrary and unauditable. Start in shadow mode against the incumbent rules for a full quarter, so that performance is measurable against a live baseline without financial exposure. Address the selection bias structurally: log every decision with its features and the model version, maintain a small random holdout of allowed transactions for unbiased estimation, and never train on blocked transactions as negatives. Choose a model class that fits the latency budget with a documented feature computation plan and a deterministic timeout fallback that defaults to the existing rule, since a timeout in the payment path is a decline and therefore a real cost. Design for adversarial drift as a standing requirement: population stability and score-distribution monitoring on a daily cadence, a challenger model in parallel, and a scheduled retraining cycle with a documented rollback path. Deliver reason codes per decision for dispute handling, a fairness and disparate-impact assessment, and an alert-triage prioritisation layer that fits the 400-case capacity. State plainly at project outset that no business-impact figure will be defensible for at least one full label lag, and that acceptance must be granted against shadow-mode metrics rather than realised savings.

Now please present the first 5 scenarios in the format you used for scenario 6.

# Scenario 6
Business request: "Tell us the price elasticity of each of our 400,000 customers so we can set individual prices before next quarter."

Situation: A 12% price increase was applied to the entire customer base in all regions on the same date, eight months ago. No phased rollout, no holdout, no comparison market. Prices were uniform for the preceding five years, so there is no historical price variation. Sales, transaction and margin data are complete and readily available. The business has stated it cannot run an experiment and needs the answer in two weeks.

Correct expert output: Refuse. The estimand — own-price elasticity — requires price variation that is independent of demand. There is none: the single price change is perfectly collinear with seasonality, macro conditions, trend, and any concurrent commercial action, and there is no counterfactual. Per-customer elasticity is additionally infeasible in principle: even a well-designed experiment identifies elasticity at segment level, not at individual level. The correct deliverable is a written refusal with the identification argument, plus an alternative: an interrupted time-series or synthetic-control estimate at market or segment level with stated assumptions, or a prospective geo-split test on a minority of customers. Never a per-customer coefficient table.


# Expected output

## Revised ladder — monotone on all five criteria

Three changes were needed to make the set strictly increasing:

- **Churn moved ahead of credit risk.** Credit risk has *lower* definitional ambiguity (default is externally fixed at 90 DPD by regulation) but *higher* technical and statistical load. Keeping it at position 2 as you had it made the ladder non-monotone.
- **The credit risk scenario was re-scoped** so its ambiguity sits in the *downstream decision target* (PD horizon, segment scope, cut-off and limit-setting policy, forbearance treatment) rather than in the definition of default itself. That is a real and defensible ambiguity, and it lets the scenario sit above churn without inflating the label question.
- **The intermittent-demand scenario was sharpened** to include the unresolved business use (replenishment vs. assortment vs. campaign targeting), which is what supplies its ambiguity.

### Scoring conventions

Direction: **all columns are scored 1–10 where 10 = most difficult / least clear.** "Target clarity" is therefore scored **inverted** (10 = target opaque) so the row total is additive. The scale is 1–10 rather than 1–5 deliberately: with five scenarios on a 1–5 scale, strict monotonicity forces every column to run exactly 1,2,3,4,5 and produces perfectly linear totals (15/20/25/30/35), which destroys the discriminating power you need from a benchmark.

| # | Scenario | Technical difficulty | Statistical difficulty | Definitional ambiguity | Target clarity (inv.) | Data readiness (inv.) | **Row total** | Executability index¹ |
|---|---|---|---|---|---|---|---|---|
| 1 | Execution indicators (tasks opened/closed, hours by person and project), complete in-house data | 2 | 2 | 2 | 1 | 1 | **8** | 93.3 |
| 2 | Contractual churn model for a subscription business; cancel event recorded, 24 months of history | 4 | 4 | 3 | 3 | 3 | **17** | 73.3 |
| 3 | Credit risk scorecard for a regulated lender; 90-DPD default, bureau + internal data | 5 | 6 | 4 | 4 | 4 | **23** | 60.0 |
| 4 | Intermittent demand forecasting, 1,800 SKU × 50,000 customers, daily; business use undecided | 7 | 8 | 5 | 5 | 5 | **30** | 44.4 |
| 5 | Real-time adversarial decisioning (fraud / AML triage), sub-200 ms, labels via chargebacks 60–120 days later | 9 | 9 | 7 | 8 | 7 | **40** | 22.2 |

¹ Executability index = $(50 - \text{total}) / 45 \times 100$. Additive inverse on the same 0–100 scale; 100 = trivially executable, 0 = not executable.

### Column definitions used for scoring

These must be fixed before you let anyone rate, otherwise columns 3 and 4 collapse into each other:

| Column | What it measures | What it does **not** measure |
|---|---|---|
| Technical difficulty | Engineering, scale, latency, integration, MLOps, deployment and monitoring burden | Statistics, stakeholder work |
| Statistical difficulty | Risk of a poor estimate: rarity, sparsity, censoring, non-stationarity, confounding, validation design | Implementation effort |
| Definitional ambiguity | How much of the *decision target and its scope* must be negotiated with stakeholders before modelling can begin | Whether a dictionary definition exists |
| Target clarity (inv.) | Observability of the label: latency, censoring, bias | Business terminology |
| Data readiness (inv.) | Availability, coverage, lineage, auditability | Data volume |

### What each rung is probing

- **1 — floor anchor.** Near-guaranteed execution. Use it to calibrate raters on the bottom of the scale.
- **2 — ambiguity probe, low technical load.** Deliberately isolates stakeholder definition work (voluntary vs. involuntary, logo vs. revenue, partial churn) from engineering.
- **3 — governance and validation probe.** Label is defined but slow and censored; the burden is out-of-time validation, calibration, stability and auditability.
- **4 — pure statistical probe.** ~90M mostly-zero cells, censored demand from stockouts, cold start, no agreed loss function.
- **5 — ceiling anchor.** Label incomplete *by construction* because the deployed model determines which cases are ever investigated, plus adversarial drift and hard latency constraints.

### Construct-validity cautions

- **Columns 3 and 4 remain correlated** (Pearson ≈ 0.95 on these scores) even with the narrow definitions above. If your indicator weights them equally you are effectively double-counting. Either drop one and keep definitional ambiguity, or reduce target clarity to a qualitative flag rather than a score.
- **These scores are my judgement, not measurements.** Before use, have three raters score blind and report Kendall's W. A W below ~0.6 means the criteria descriptions are not yet operational.
- **Add a sixth, deliberately non-executable control** — e.g. "estimate the causal effect of a pricing intervention with no control group" — where the correct expert output is *refuse and reframe*. An executability indicator that cannot detect refusal conditions will score low clarity and high difficulty identically, which is not the same thing.
