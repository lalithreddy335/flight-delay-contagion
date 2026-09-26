# Flight Delay Contagion: Power BI Build Guide

Files (save all four in `flight-delay-contagion\dashboard\`):
`flight_delay_contagion_theme.json`, `page1_background.png`, `page2_background.png`, `page3_background.png`

The backgrounds already contain every title, KPI tile and text box. You only place the charts
inside the empty panels. The theme removes chart titles/backgrounds and sets colors automatically.

---

## 0. One-time setup (5 min)

1. **Apply the theme:** View → Themes (dropdown arrow) → **Browse for themes** → pick `flight_delay_contagion_theme.json`.
2. **Page size:** click an empty spot on the canvas → Format pane (paintbrush) → **Canvas settings** →
   Type: **Custom**, Width **1920**, Height **1080**.
3. **Background:** Format pane → **Canvas background** → Image: **Browse** → `page1_background.png` →
   Image fit: **Fit** → Transparency: **0%**.
4. **Wallpaper:** Format pane → **Wallpaper** → Color: `#0A1224`.
5. Rename the page (double-click the tab at the bottom): **The Problem**.
6. For pages 2 and 3: right-click the page tab → **Duplicate page**, delete its charts, swap the background image,
   and rename to **Where Chains Start** / **The Fix**.

### How to place a visual exactly
Select the visual → Format pane → **General** → **Properties** → **Size** and **Position** → type the numbers below.

### Standard settings for every chart
- Format → Visual → **Data labels: On** (unless told Off).
- If numbers show as "K" or "M": Data labels → Display units → **None**.
- Year / bucket axes: click **...** on the visual → **Sort axis** → pick the category field → **Sort ascending**.

---

## PAGE 1: The Problem

| # | Visual | Fields | Position (x, y) | Size (w, h) |
|---|---|---|---|---|
| 1 | **Line chart** | X-axis: `monthly.month_start` (click the field's dropdown → choose **month_start**, not *Date Hierarchy*). Y-axis: `monthly.otp_pct` | 66, 434 | 1114, 238 |
| 2 | **Clustered column chart** | X-axis: `yearly.year`. Y-axis: `yearly.delay_cost_billion` | 1240, 434 | 614, 238 |
| 3 | **Stacked column chart** | X-axis: `yearly.year`. Y-axis (in this order): `late_aircraft_delay_min_m`, `carrier_delay_min_m`, `nas_delay_min_m`, `weather_delay_min_m`, `security_delay_min_m` | 66, 794 | 1114, 224 |

Formatting:
- **Visual 1:** Data labels **Off**. Lines → Stroke width **3**. Markers **Off**. Y-axis range: Minimum **60**, Maximum **90**.
- **Visual 2:** Columns color **#FFA24C** (amber). Data labels On. Sort by year ascending.
- **Visual 3:** Data labels **Off**. Legend: **On, Top**. Rename each series (double-click it in the Y-axis well):
  *Late aircraft*, *Airline (carrier)*, *Air traffic system*, *Weather*, *Security*. Sort by year ascending.

---

## PAGE 2: Where Chains Start (background `page2_background.png`)

| # | Visual | Fields | Position (x, y) | Size (w, h) |
|---|---|---|---|---|
| 1 | **Line and clustered column chart** | X-axis: `time_of_day.time_of_day`. Column y-axis: `pct_spread`. Line y-axis: `avg_multiplier` | 66, 434 | 864, 238 |
| 2 | **Clustered bar chart** | Y-axis: `airports.airport`. X-axis: `airports.chain_cost_million` | 990, 434 | 864, 238 |
| 3 | **Clustered bar chart** | Y-axis: `airlines.airline`. X-axis: `airlines.chain_cost_per_flight` | 66, 794 | 864, 224 |
| 4 | **Clustered bar chart** | Y-axis: `hotspots.hotspot`. X-axis: `hotspots.downstream_cost_million` | 990, 794 | 864, 224 |

Formatting:
- **Visual 1:** Columns **#FF5D6C**, line **#FFA24C**, stroke width 3. Legend On, Top. Rename: *% of chains that spread*, *Avg delay multiplier*. Sort by time_of_day ascending.
- **Visuals 2–4 (Top N filter):** Filters pane → the Y-axis field → Filter type **Top N** → Show items **Top 8** →
  drag the X-axis field into "By value" → **Apply filter**. Then sort descending by the value.
- **Highlight the story bar:** Format → Bars → Colors → turn on **Show all**:
  Visual 2: **DFW = #FFA24C**, others **#3FD0E6**. Visual 3: **American = #FF5D6C**, others **#3FD0E6**.
  Visual 4: every **DFW** bar **#FFA24C**, others **#3FD0E6**.

---

## PAGE 3: The Fix (background `page3_background.png`)

| # | Visual | Fields | Position (x, y) | Size (w, h) |
|---|---|---|---|---|
| 1 | **Clustered column chart** | X-axis: `turn_buckets.turn_bucket`. Y-axis: `turn_buckets.pct_passed_on` | 66, 434 | 864, 238 |
| 2 | **Clustered bar chart** | Y-axis: `hub_benchmark.hub`. X-axis: `hub_benchmark.pct_passed_on_when_late` | 990, 434 | 864, 238 |
| 3 | **Clustered column chart** | X-axis: `risk_tiers.risk_tier_2024`. Y-axis: `risk_tiers.pct_inbound_late_2025` | 66, 794 | 544, 224 |
| 4 | **Clustered bar chart** | Y-axis: `buffer_strategies.strategy`. X-axis: `buffer_strategies.breakeven_per_min` | 670, 794 | 544, 224 |

Formatting:
- **Visual 1:** Columns → Color → **fx** → Format style **Gradient** → based on `pct_passed_on`:
  Lowest **#2FD69A** (green), Highest **#FF5D6C** (red). Sort by turn_bucket ascending.
- **Visual 2:** Sort descending. Show all colors: **American @ DFW = #FF5D6C**, **Delta @ ATL = #2FD69A**, others **#8C9BB8**.
- **Visual 3:** Filters pane → `risk_tier_2024` → untick **0. No 2024 history**. Columns **#FFA24C**. Sort ascending.
- **Visual 4:** Bars **#2FD69A**. Sort by strategy ascending (blanket at top).
  **Analytics pane** (magnifier icon) → **X-axis constant line** → Add → Value **24.60**, color **#FF5D6C**,
  Data label On, text: *Assumed ground cost $24.60*. This shows at a glance that no strategy clears the bar yet.

---

## Final polish (10 min)

**Clickable navigation pills** (on each page): Insert → Buttons → **Blank**. Turn off the button's fill, border and text.
Action: On → Type **Page navigation** → Destination: the page. Place over each pill:

| Pill | Position (x, y) | Size (w, h) |
|---|---|---|
| 01 The Problem | 1406, 84 | 145, 36 |
| 02 Where Chains Start | 1560, 84 | 197, 36 |
| 03 The Fix | 1764, 84 | 108, 36 |

(Ctrl + click to test navigation inside Power BI Desktop.)

**Export for LinkedIn:** File → Export → **Export to PDF** (one page per slide), or take a full-screen
screenshot of each page (View → Fit to page, then Win + Shift + S).

**Save:** `dashboard\flight_delay_contagion.pbix`, then push to GitHub.
