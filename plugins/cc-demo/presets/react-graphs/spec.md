# Spec: React Interactive Graphing Platform

**Project name:** GraphBoard
**Slug:** graph-board
**Tech stack:** React 18, Vite, Recharts, CSS Modules, Vitest, Testing Library

---

## Overview

A browser-based interactive dashboard that renders four live-updating charts simultaneously. Users configure each chart independently, toggle between light and dark themes, and export any chart to PNG. All data is simulated locally — no backend required.

---

## Requirements

| # | Requirement | Priority |
|---|-------------|----------|
| R1 | Dashboard layout with four chart panels arranged in a 2×2 responsive grid | Must |
| R2 | Line chart — animated, multi-series, with zoom and pan on mouse drag | Must |
| R3 | Bar chart — grouped, animated on data update, labelled axes | Must |
| R4 | Pie chart — donut style, animated segments, percentage labels on hover | Must |
| R5 | Scatter plot — variable-radius bubbles, hover tooltip showing x/y/value | Must |
| R6 | Data simulator — generates realistic time-series data, updates all charts on a configurable tick interval (default 1 s) | Must |
| R7 | Per-chart config panel — slide-in drawer with: chart title, primary colour, update speed multiplier, pause/resume toggle | Must |
| R8 | Global theme toggle (light / dark) in the header — persisted to localStorage | Must |
| R9 | Export chart to PNG — button on each chart captures the panel at 2× resolution | Must |
| R10 | Smooth animated transitions on data update — no jarring repaints | Should |
| R11 | Performance — all four charts updating at 1 Hz must stay above 50 fps | Should |

---

## Out of Scope

- Real backend or API data sources
- User authentication or saved dashboards
- Mobile layout (desktop ≥ 1024 px is the target)
- CSV/SVG export
- Chart type switching at runtime

---

## Key User Flows

### Flow 1 — First Load

1. App loads at `localhost:5173`
2. Header: "GraphBoard" title, theme toggle (sun/moon icon), version badge
3. Dashboard shows four charts with live-updating simulated data
4. Simulator starts immediately — all charts refresh on the same tick

### Flow 2 — Configure a Chart

1. User clicks the settings icon (⚙) on a chart panel
2. Slide-in config drawer appears from the right: title input, colour picker (8 presets), speed slider (0.5× – 5×), pause/resume toggle
3. Changes apply instantly with no page reload
4. Drawer closes on Escape or clicking outside

### Flow 3 — Export a Chart

1. User clicks the download icon (↓) on a chart panel
2. The chart panel is captured via `html2canvas` at 2× device pixel ratio
3. PNG downloads as `{chart-title}-{timestamp}.png`

### Flow 4 — Theme Toggle

1. User clicks the theme toggle in the header
2. All four charts and the dashboard background swap to dark/light in < 200 ms
3. Theme preference saved to `localStorage` and restored on next load

---

## Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC1 | On first load all four charts render with simulated data within 2 seconds |
| AC2 | Changing chart title in config drawer updates the chart header within 100 ms |
| AC3 | Changing colour preset updates the chart fill colour within 100 ms |
| AC4 | Setting speed multiplier to 0.5× halves the update frequency |
| AC5 | Pause/resume toggle stops and restarts data updates for that chart only |
| AC6 | Theme toggle changes the background and chart colours within 200 ms |
| AC7 | Theme preference persists across page reloads |
| AC8 | Exporting a chart produces a PNG file with correct chart title in the filename |
| AC9 | All four charts running at default 1 Hz — browser DevTools shows no layout thrash |
| AC10 | Vitest unit test suite passes with no failures |

---

## Component Architecture (top-level)

```
src/
  main.jsx                  App entry
  App.jsx                   Theme provider, layout root
  components/
    Dashboard/
      Dashboard.jsx         2×2 grid of ChartPanel instances
      Dashboard.module.css
    ChartPanel/
      ChartPanel.jsx        Container: chart + header + export + config trigger
      ChartPanel.module.css
    ConfigDrawer/
      ConfigDrawer.jsx      Slide-in settings panel
      ConfigDrawer.module.css
    charts/
      LineChart.jsx
      BarChart.jsx
      PieChart.jsx
      ScatterChart.jsx
    Header/
      Header.jsx            Title + theme toggle
      Header.module.css
  hooks/
    useSimulator.js         Data generation + tick loop
    useTheme.js             Theme toggle + localStorage
    useExport.js            html2canvas PNG export
  utils/
    dataGen.js              Time-series data generators per chart type
    colours.js              Colour preset palette
tests/
  unit/
    dataGen.test.js
    colours.test.js
    useSimulator.test.js
  e2e/
    dashboard.spec.js
    config-drawer.spec.js
    theme-toggle.spec.js
    export.spec.js
```

---

## Risks

| Risk | Mitigation |
|------|-----------|
| React re-render thrash at 1 Hz across 4 charts | Use `React.memo` on chart components; `useMemo` on data slices |
| `html2canvas` failing on cross-origin SVGs inside Recharts | Pre-rasterise chart to canvas or use inline SVG only |
| Colour contrast in dark theme | Define CSS custom properties for both themes; test with browser accessibility checker |

---

*Confirmed by: simulated spec interview — preset: react-graphs*
