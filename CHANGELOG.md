# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

## [1.0.5] - 2026-09-28

### App
- Cards have no border or header rule: figures, equations and stories sit
  on the page separated by whitespace alone.

## [1.0.4] - 2026-09-28

### App
- Cards, panels, tiles and buttons are square with no shadow: they organise
  the page rather than decorate it.

## [1.0.3] - 2026-09-28

### App
- The QR code returns to the foot of the sidebar, with the name and site
  address, alongside the small one in the title bar.

## [1.0.2] - 2026-09-28

### App
- No figure carries a title or subtitle inside the image; the card header
  and the caption under it name and explain the figure (CONVENTIONS.md 6).
- Figures are drawn on a white ground, so the image sits flat in its card
  instead of showing as a tinted tile.
- The two square figures are drawn at 3:2.

## [1.0.1] - 2026-09-28

### App
- The In Words tab lays out its three columns at fixed widths, so an
  equation no longer collapses to one term per line beside its note.
- The preset card no longer doubles the word "Stage" in front of a stage
  name that already carries it.

## [1.0.0] - 2026-09-28

First public release as a standalone repository.

### Model
- Growth accounting identity, per-worker form and residual following
  Solow (1957) and Romer (2019) ch. 1; the residual against the capital
  share on a grid.
- Development accounting on levels (Romer ch. 4): the income gap split into
  capital intensity, human capital and productivity.
- A simulated cross-section of Solow economies with absolute and
  conditional convergence regressions.
- Ireland's growth accounts: the same identity on the CSO's annual series,
  at a chosen capital share or the CSO's own year-by-year share, with window
  averages, a counterfactual index path and the CSO's PIA09 productivity
  accounts for comparison.

### App
- Two modes: Explore the Model (five stages that add one layer at a time)
  and Ireland's Accounts (GDP, GNP or GNI* over a chosen window).
- Eight worked examples, including Ireland in 2015 and 2023 and the three
  readings of the Irish capital share.
- Equations, Notation and In Words tabs that track the model at each stage.
- Ghost curves showing the loaded worked example alongside the live
  sliders, in both modes.
- Bundled CSO data in data/ so the Irish mode runs offline; a decade table
  from the Penn World Table for the long view.
