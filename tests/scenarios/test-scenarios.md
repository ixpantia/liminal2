# Scenario 1 — Execution indicators

**Business request:** "Give us indicators of project execution built from the data we already have: number of tasks opened and closed, and hours assigned by person and by project. We want to know which projects are running well."

**Situation:** Task and timesheet data are complete, in-house, and mature, covering roughly three years with stable definitions. Project codes are consistent, hours are booked against tasks rather than projects, and closures are timestamped. The business has not stated what it means by "execution," what decisions the indicator drives, or who acts when a project is flagged, and there is no agreed baseline for what normal looks like.


# Scenario 2 — Contractual churn model

**Business request:** "Build us a churn model so we can prioritise retention spend across the subscriber base."

**Situation:** The business is a subscription service with monthly and annual plans. A cancel event exists and is timestamped, and there are 24 months of history with a stable product catalogue for the last 18. Billing, login, support and usage data are available and joinable at customer level. The requested target is ambiguous in ways that change the answer materially: whether to count voluntary cancellations only or also involuntary churn from payment failure, whether a downgrade counts, whether logo churn or revenue churn is the target, and whether a customer who cancels and returns within 30 days is churn. No retention intervention has been defined, so nobody has yet stated what action the score will trigger or what the acceptable false-positive rate is.


# Scenario 3 — Credit risk scorecard

**Business request:** "Build a credit scoring model for our lending portfolio so we can approve, price and set limits."

**Situation:** A regulated lender with 60 months of disbursement and performance history, bureau data at application, and complete repayment records. Default is externally defined: 90 days past due, consistent with regulatory practice, so the label itself is not in question. Volumes are adequate but approval volumes were historically constrained by a manual policy, so the observed portfolio is a selected sample. Two decisions remain genuinely undefined: the performance horizon for the score (12 versus 24 months changes the label population), and the use of the output — approve/decline only, or approve/decline plus pricing and limit assignment, each requiring different calibration and different cut-off analysis. The business also expects a single score to serve both new applicants and existing-customer limit management, which are different populations with different available features.


# Scenario 4 — Intermittent demand forecasting

**Business request:** "Predict tomorrow's purchases for each of our 1,800 SKUs across 50,000 customers."

**Situation:** Roughly 90 million customer-SKU-day cells, of which the overwhelming majority are zero. Most SKUs sell irregularly, with gaps longer than a week, and a meaningful share sell fewer than ten times a year in total. Historical sales are available for three years but are censored by stockouts, which were not recorded, so zero sales and zero demand are indistinguishable. Promotions, assortment changes and price changes are documented unevenly. Two large ambiguities remain unresolved: the intended use — replenishment, assortment decisions, or campaign targeting — and therefore the loss function, since a replenishment use penalises under-forecast asymmetry while a targeting use needs calibrated probabilities. The business has asked for daily granularity for all combinations, including customers with fewer than five purchase events.


# Scenario 5 — Real-time adversarial decisioning

**Business request:** "Score every transaction in the payment path and block fraud before authorisation."

**Situation:** A payments environment with a 200 ms end-to-end budget including network and fallback. The confirmed-fraud rate is under 0.5%, and labels arrive 60 to 120 days later through chargebacks and investigation outcomes. The three fraud types in scope — stolen instrument, account takeover, and first-party abuse — have different costs and different label paths, and the business has not supplied a cost matrix or a review-capacity constraint, so the trade-off between a false decline and an unreviewed fraud case is currently undefined. Analyst review capacity is fixed at roughly 400 cases per day, which silently imposes the real operating threshold. Critically, the model's own blocks remove cases from the observed population, so labels are missing not at random.

# Scenario 6
**Business request:** "Tell us the price elasticity of each of our 400,000 customers so we can set individual prices before next quarter."

**Situation:** A 12% price increase was applied to the entire customer base in all regions on the same date, eight months ago. No phased rollout, no holdout, no comparison market. Prices were uniform for the preceding five years, so there is no historical price variation. Sales, transaction and margin data are complete and readily available. The business has stated it cannot run an experiment and needs the answer in two weeks.

