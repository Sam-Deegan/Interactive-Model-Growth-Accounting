# Interactive Model: Growth and Development Accounting

A Shiny app for teaching growth accounting, development accounting and
convergence, with a second mode that runs the same accounting identity on
Ireland's national accounts year by year. Built by
[Sam Deegan](https://sam-deegan.com) for ECON42550 Macroeconomics,
University College Dublin.

**Try it in the browser (nothing to install):**
https://sam-deegan.com/toy-models/growth-accounting/

Current version: **1.0.4** (see [CHANGELOG.md](CHANGELOG.md)). The version
is shown in the app footer; releases are tagged `vX.Y.Z`.

## What it does

The app has two modes. **Explore the Model** runs on numbers you choose,
and the stage selector adds one layer of the model at a time:

| Stage | What is added |
|---|---|
| 1 | The accounting identity: growth in output split into capital, labour, human capital and the residual |
| 2 | Per worker: capital deepening, better workers, and the rest |
| 3 | What the residual rests on: the same data at every capital share, with a ghost of the worked example |
| 4 | Development accounting: a country's income gap split into capital intensity, human capital and productivity |
| 5 | Convergence in a simulated cross-section, absolute against conditional, and proximate against fundamental causes |

Each stage opens on a worked example (an investment boom, Ireland in 2015
and in 2023, the capital-share assumption, a country at a quarter of frontier
income, absolute against conditional convergence). Every slider has a box
beside it for an exact value, and a faded copy of each line stays behind at
the worked example's own settings so the cost of a changed assumption is on
screen.

**Ireland's Accounts** runs the same identity on the CSO's own series for
GDP, GNP or modified GNI (GNI*), over a window you choose, at the capital
share you choose or the CSO's own year-by-year share. It draws the
contributions year by year, measured output against what capital and labour
alone would have delivered, the app's residual against the CSO's multifactor
productivity measure, the foreign- and domestic-dominated halves of the
economy, and a long view by decade.

The Equations, Notation and In Words tabs show the model as it stands at the
chosen stage and flag what that stage changed.

## Run it locally

1. Install [R](https://cran.r-project.org/) (4.1 or later) and, ideally,
   [RStudio](https://posit.co/download/rstudio-desktop/).
2. Install the three packages once:

   ```r
   install.packages(c("shiny", "bslib", "ggplot2"))
   ```

3. Open `app.R` in RStudio and click **Run App**, or from R in this folder:

   ```r
   shiny::runApp()
   ```

Equations are typeset with MathJax from a CDN, so they need an internet
connection; everything else, including the Irish data, runs offline.

## Files

```
app.R                    the app: settings and text (section B), figures (D),
                         interface (E), server (F)
R/model.R                the model: the growth and development accounting
                         functions (C_01) and the Irish accounts (C_02).
                         Sources on its own, so slides can reuse it.
R/toolkit.R              layout and helpers shared with the other toy-model
                         apps
data/ireland_annual.csv  Irish output, capital and employment, annual
data/ireland_cso.csv     the CSO's productivity accounts, 2000 to 2019
www/                     logo and QR code
README.md                this file
CHANGELOG.md             version history
CONVENTIONS.md           how the figures and worked examples are laid out
LICENSE                  CC BY-NC-ND 4.0
```

All text on screen (worked examples, prompts, equations, notation) is in
section `B_03` of `app.R`, so it can be edited without touching the rest.

## Data

The Ireland's Accounts mode reads two small CSVs from `data/`. Both were
pulled from the CSO's PxStat API and shipped with the app so it needs no
network. They are a snapshot: chain-linked volume series are revised between
vintages, and the CSO has published more than one growth rate for the same
year across successive releases.

**`data/ireland_annual.csv`** — columns `year, gdp, gnp, gnistar, capital,
emp`:

- `gdp`, `gnp`: gross domestic product and gross national product at
  constant market prices, CSO table NA006, euro million, from 1995.
- `gnistar`: modified gross national income (GNI*) at constant market
  prices, CSO table NA002, euro million, from 1995.
- `capital`: net capital stock of fixed assets at constant prices, all fixed
  assets, all NACE sectors, CSO table CSA02, euro million, from 1985. The
  stock, not capital services.
- `emp`: persons aged 15 and over in employment, the mean of the four
  quarters, CSO table QLF01, thousands, from 1998. Heads, not hours.

The window the identity can cover is set by employment: QLF01 starts in
1998, so the first year with a growth rate is 1999.

**`data/ireland_cso.csv`** — columns `year, sector` and the CSO's own
productivity accounts, CSO table PIA09, 2000 to 2019: multifactor
productivity (`mfp`), labour productivity (`labour_prod`), gross value added
(`gva`), capital services (`capital_services`) and hours worked
(`labour_hours`) as indices on 2000 = 100, plus the GVA labour and capital
shares (`capital_share`), for the whole economy (`total`) and for the
foreign-dominated (`foreign`) and domestic (`domestic`) halves of it.

The decade figure in the same mode uses a small table typed into `app.R`
(`B_03_13`): average annual growth of output, capital and employment for
Ireland by decade from the 1950s, from the Penn World Table 10.01 (`rgdpna`,
`rnna`, `emp`), the one source that carries all three series back that far.

## The model

Growth accounting is Solow's (1957) decomposition of output growth into the
growth of measured inputs and a residual, and development accounting is the
same arithmetic applied to income levels across countries. Both are in
Romer's *Advanced Macroeconomics* (2019, chapters 1 and 4). Growth rates are
log differences, so `Δln Y` is the growth rate of `Y`; the capital share `α`
is a number between zero and one.

```
Production:   Y = A K^α (h L)^(1−α)
Identity:     Δln Y = Δln A + α Δln K + (1−α)(Δln h + Δln L)
Per worker:   Δln (Y/L) = Δln A + α Δln (K/L) + (1−α) Δln h
Levels:       y = (K/Y)^(α/(1−α)) h A
Relative:     y_i / y_US = [ (K/Y)_i / (K/Y)_US ]^(α/(1−α)) (h_i / h_US) (A_i / A_US)
Convergence:  g_i = const − λ ln y_i0 + β_s ln s_i + β_n ln n_i
```

**The production function** is Cobb-Douglas with constant returns: `Y` is
output, `K` capital, `L` employment, `h` human capital per worker and `A`
total factor productivity. `α` is capital's share of income, which under
competitive factor markets equals the elasticity of output with respect to
capital.

**The identity** is the production function in logs and differences. It
holds by construction whatever is true of the economy. Everything on the
right-hand side except `Δln A` is measured, so the residual is whatever is
needed to make the identity hold: technical progress, and also every
measurement error in every input. Abramovitz called it the measure of our
ignorance.

**Per worker** the labour term drops out and capital deepening
`α Δln (K/L)` replaces capital. This is the version the literature reports,
because it is about living standards.

**Levels** rearranges the production function so that the capital term uses
the capital-output ratio, which varies far less across countries than
capital per worker does. A country's income relative to the frontier (the
US) then splits into three ratios that multiply back to it: capital
intensity, human capital and productivity. The last is inferred, and turns
out to carry most of the gap.

**Convergence** is the regression the literature runs on a cross-section:
growth `g_i` on initial income `ln y_i0`, without and with controls for the
saving rate `s_i` and population growth `n_i`. The app draws its own
cross-section of Solow economies that differ in `s` and `n`, and so in their
steady states, each starting somewhere below its own steady state, and fits
both regressions to it.

The model is solved by arithmetic: each function in `R/model.R` takes the
parameter list and returns the decomposition as a data frame. The synthetic
cross-section draws saving rates and population growth from uniform
distributions, computes each economy's steady state, and adds a normal
shock to growth; the conditional figure is a partial-residual plot.

**What the stages show with it**

- *1* The identity, and where the residual comes from. Move the growth rate
  of capital and watch the residual absorb the difference. Ireland in 2015
  is the case where output and the capital stock jump together and the
  identity reports a productivity boom.
- *2* Per worker. Growth that is mostly residual can continue; growth that
  is mostly capital deepening runs into diminishing returns. Ireland in 2023
  is the case where every term points the wrong way.
- *3* What the residual rests on. Slide the capital share: nothing about the
  economy changes and the residual moves a long way, so any claim resting on
  its size is resting on `α`. Ireland offers three defensible readings of
  the same year's capital share.
- *4* Development accounting. Give a poor country the frontier's
  capital-output ratio and it is still poor: differences in income are
  mostly differences in productivity, not in inputs.
- *5* Convergence. The same simulated economies, asked two questions.
  Without controls there is no relationship between initial income and
  growth; with the determinants of the steady state held fixed there is a
  clear negative one. Only the second is what the Solow model predicts. The
  stage closes on proximate against fundamental causes and the colonial
  natural experiment on institutions.

**Where it departs from the textbook.** The identity, the per-worker form
and the levels decomposition are the textbook's. The stage 5 cross-section
is simulated, not data: it is what the Solow model implies when economies
differ in `s` and `n` and start below their steady states, and the app says
so on screen. The Ireland's Accounts mode uses the net capital stock rather
than capital services, heads rather than hours, and GDP (or GNP or GNI*)
rather than gross value added, so its residual differs from the CSO's own
multifactor productivity measure; the app draws the two side by side and
treats the gap as the lesson. The model has no dynamics of its own: growth
rates and levels are inputs, not the outcome of saving and accumulation, and
the convergence speed `λ` in the simulation is the Solow model's
`(1 − α)(n + g + δ)` with `g` and `δ` fixed at their defaults.

## References

- Romer, D. (2019). *Advanced Macroeconomics*, 5th ed. Chapters 1 and 4.
- Solow, R. M. (1957). Technical change and the aggregate production
  function. *Review of Economics and Statistics* 39(3).
- Abramovitz, M. (1956). Resource and output trends in the United States
  since 1870. *American Economic Review* 46(2).
- Central Statistics Office (Ireland). Tables NA002, NA006, CSA02, QLF01 and
  PIA09, via PxStat.
- Feenstra, R. C., Inklaar, R. and Timmer, M. P. (2015). The next generation
  of the Penn World Table. *American Economic Review* 105(10). Penn World
  Table 10.01.
- ESRI Research Note (2024). *Estimating Ireland's Labour Share*.

## Licence

© Sam Deegan. Released under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
free to use and share for teaching with attribution; not for commercial use
or redistribution in modified form.
