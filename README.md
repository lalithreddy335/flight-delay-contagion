# ✈️ Flight Delay Contagion: How One Late Plane Ruins the Whole Day

## Business Problem
Flight delays cost U.S. airlines billions each year. Every minute an aircraft
is delayed costs about $98 in crew, fuel, and maintenance (Airlines for
America, 2025). The biggest hidden driver is **delay propagation**: when one
aircraft runs late, every later flight in its rotation inherits the delay.

Most delay analyses stop at "which airline is worst." This project traces
**33M+ flights (2021–2025) aircraft by aircraft** using tail numbers to find
where delay chains start, how far they spread, and where schedule buffers
would break them at the lowest cost.

## Stakeholder
VP of Operations at a major U.S. airline

## Key Business Questions
1. Which airlines, airports, and routes have the worst on-time performance, and is it improving?
2. What drives delay minutes, and which causes can the airline control?
3. Where do delay chains start, and how many downstream flights does one delay affect?
4. What is the **true cost** of a delay, including its knock-on effects?
5. Where would schedule buffers save the most money?

## KPIs
| KPI | Definition |
|---|---|
| On-Time Performance (OTP) | % of flights arriving less than 15 min late (DOT standard) |
| Avg Arrival Delay | Mean delay minutes among delayed flights |
| Delay Cost ($) | Delay minutes × A4A cost per block minute (year-specific) |
| Cancellation Rate | % of scheduled flights cancelled |
| Delay Cause Mix | % share: carrier, weather, NAS, security, late aircraft |
| Propagation Share | Late-aircraft delay minutes ÷ total delay minutes |
| Chain Length | Avg number of downstream flights delayed by one initial delay |
| Delay Multiplier | Total chain delay minutes ÷ initial delay minutes |

## Scope
- **Data:** BTS On-Time Performance, Jan 2021 – Dec 2025 (~33M flights)
- **Coverage:** U.S. domestic flights by BTS-reporting carriers
- **Cost basis:** Airlines for America U.S. Passenger Carrier Delay Costs

## Tools
SQL (Snowflake) · Python (pandas, scipy) · Excel · Power BI

## Deliverables
- SQL analysis with delay-chain tracing
- Statistical tests on key findings
- Excel buffer scenario model
- Power BI executive dashboard
- 1-page executive memo and 6-slide deck

## Key Findings
*Coming soon*
