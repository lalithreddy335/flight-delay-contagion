\# Findings Log



\## 1. Data validation

\- Total flights loaded: 33,653,101 (Jan 2021 – Dec 2025, all 60 months)

\- Missing tail numbers: 0.29%

\- Data issue fixed: Aug 2024 file had a null flight number that turned the

&#x20; column into decimals; caught via row-count reconciliation and reloaded.



\## 2. On-time performance and cancellations by year

| Year | On-time % | Cancelled % |

|---|---|---|

| 2021 | 82.8 | 1.72 |

| 2022 | 78.9 | 2.69 |

| 2023 | 79.4 | 1.28 |

| 2024 | 79.2 | 1.36 |

| 2025 | 77.7 | 1.47 |



\*\*Findings:\*\*

\- On-time performance fell from 82.8% (2021) to 77.7% (2025). 2025 was the

&#x20; worst year of the period despite fewer flights than 2024.

\- 2021 is an easy baseline: fewer flights meant less congestion.

\- 2022 was the cancellation crisis year (2.69%, roughly double other years).



\*Note: On-time % is measured among flights that operated (excludes cancelled).\*





\## 3. Estimated airline delay cost by year (2025 dollars, $98.41/min)

| Year | Flights | Delay cost |

|---|---|---|

| 2021 | 6.00M | $7.12B |

| 2022 | 6.73M | $9.79B |

| 2023 | 6.85M | $10.11B |

| 2024 | 7.08M | $10.90B |

| 2025 | 7.00M | $11.69B |



\*\*Findings:\*\*

\- \~$49.6B in estimated airline delay costs over 5 years.

\- Costs rose 64% from 2021 to 2025.

\- 2025 cost more than 2024 despite fewer flights: cost per flight rose \~8%

&#x20; ($1,540 to $1,670), so delays are getting worse per flight.



\*Method: arrival delay minutes × A4A 2025 cost per block minute. Direct airline

cost only; excludes passenger time.\*



\## 4. Delay chains (aircraft-level tracing)

\- 4.1M delay chains; 37.6% spread to at least one more flight; longest = 20 flights.

\- 41.5% of chain delay minutes were inherited. Validates against BTS's own

&#x20; late-aircraft share (38.8%), within 3 points.

\- Chains cost an estimated $46.3B (2021-2025).



| Start time | % spread | Multiplier | Avg chain cost |

|---|---|---|---|

| Early Morning (5-9) | 42.2% | 2.35x | $14,131 |

| Morning (9-12) | 51.7% | 2.51x | $13,072 |

| Afternoon (12-5) | 48.9% | 2.08x | $11,685 |

| Evening (5-9) | 19.6% | 1.31x | $8,265 |

| Night (9-5) | 7.1% | 1.22x | $7,779 |



\*\*Findings:\*\*

\- 9 AM-noon delays spread most (52% chance; 1 min becomes \~2.5 min).

\- Early-morning chains cost the most per chain ($14.1K).

\- Chains starting before 5 PM = \~76% of chain cost (\~$35.4B).

\- Hypothesis correction: expected early morning to spread most; data showed

&#x20; late morning does.



\## 5. Where chains start: airports, airlines, hotspots

\*\*Airports:\*\* DFW is #1: $2.88B chain cost, $1.21B downstream, and the highest

chain-start rate of any major hub (169.5 per 1K departures).



\*\*Airlines:\*\*

| Airline | Flights | Chain cost | Cost per flight |

|---|---|---|---|

| American | 4.42M | $8.28B | \~$1,870 |

| Southwest | 6.52M | $7.42B | \~$1,140 |

| Delta | 4.61M | $5.30B | \~$1,150 |

| United | 3.31M | $4.61B | \~$1,390 |



\- American has the highest chain cost despite flying 2.1M fewer flights than

&#x20; Southwest; \~63% higher cost per flight than Delta.

\- Including wholly owned regionals Envoy + PSA: \~$11.5B.

\- Southwest spreads delays most among big carriers (49.7%, 2.45x).



\*\*Top hotspots (downstream cost, 5 yrs):\*\* DFW afternoon $529M, ATL afternoon

$359M, ORD afternoon $333M, CLT afternoon $317M, DEN afternoon $313M.

DFW appears 3x in the top 8 (\~$1.11B combined). MCO morning has the highest

multiplier (3.05x).



\*\*Decision:\*\* Stakeholder = VP of Operations, American Airlines. Focus = DFW.



\## 6. Turnaround analysis: American at DFW

\*\*Buffer effect (AA @ DFW, incoming 15+ min late):\*\*

| Turnaround | % passed on | Min absorbed |

|---|---|---|

| Under 40 | 98.9% | -44.3 |

| 40-49 | 98.7% | -22.8 |

| 50-59 | 90.7% | -13.1 |

| 60-74 | 74.9% | -2.4 |

| 75-89 | 56.7% | +10.4 |

| 90-119 | 46.9% | +23.8 |

| 120+ | 44.8% | +77.5 |

\- Clear dose-response; tipping point \~75 min. Tight turns amplify delays.

\- \~12-13 min absorbed per extra \~15 min of turnaround (to confirm via regression).

\- Caveat: incoming delay differs by bucket; control for it in Python.



\*\*Benchmark (median turn / % under 45 / % passed on when late):\*\*

\- AA @ DFW: 68 / 7.0% / 64.0%

\- DL @ ATL: 75 / 3.6% / 56.3%

\- UA @ ORD: 75 / 2.8% / 55.0%

\- WN @ DEN: 50 / 24.3% / 85.5%

\- AA schedules \~7 min tighter than Delta, 2x the sub-45 turns, passes on

&#x20; 8 pts more delays.



\*\*DFW by time of day:\*\* afternoon has the tightest turns (65 min median,

8.7% under 45) as late arrivals rise, which explains DFW afternoon as the #1 hotspot.



\*\*Draft recommendation:\*\* raise AA DFW afternoon turnarounds to 75+ min.

