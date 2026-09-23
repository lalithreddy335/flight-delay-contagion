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

