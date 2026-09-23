# Statistical Test Results

Loaded 110,931 late-arriving AA turns at DFW

## Test 1: Chi-square (tight <60 min vs buffered 75+ min)
- Tight turns:    16,055 flights, 93.9% passed delay on
- Buffered turns: 58,674 flights, 49.1% passed delay on
- Difference: 44.8 percentage points
- Tight turns are 1.91x as likely to pass delay on
- Chi-square = 10,426.4, p < 0.001

## Test 2: Regression (departure delay ~ incoming delay + turnaround + controls)
- Sample: 97,288 turns (30-180 min scheduled turnaround)
- Each extra scheduled turnaround minute changes departure delay by -0.573 min (95% CI -0.597 to -0.550)
- In plain terms: 1 buffer minute absorbs ~0.57 min of delay; 15 buffer minutes absorb ~8.6 min
- Each incoming delay minute adds 0.724 min of departure delay
- R-squared = 0.341, p < 0.001

## Test 3: Two-proportion z-test (AA @ DFW vs DL @ ATL, incoming 15+ min late)
- AA @ DFW: 64.0% passed on (110,931 flights)
- DL @ ATL: 56.3% passed on (105,108 flights)
- Difference: 7.8 percentage points
- z = 36.8, p < 0.001