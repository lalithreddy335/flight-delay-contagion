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

