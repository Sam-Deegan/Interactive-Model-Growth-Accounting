################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Growth and Development Accounting: Interactive Shiny App                   ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Open app.R in RStudio and click Run App, or from this folder:
##     shiny::runApp()
##   Needs R 4.1 or later with shiny, bslib and ggplot2 installed. A hosted
##   copy runs in the browser at
##     https://sam-deegan.com/toy-models/growth-accounting/
##   The mode switch chooses between the model on chosen numbers and the
##   same identity on Ireland's accounts. In the model, the stage selector
##   adds one layer at a time:
##     1  the accounting identity, and where the residual comes from
##     2  per worker: capital deepening, better workers, and the rest
##     3  how much the residual depends on the capital share
##     4  development accounting: why some countries are rich
##     5  convergence, and proximate against fundamental causes
##   All text (scenarios, prompts, equations, notation) lives in B_03.
##
## Inputs:
##   R/model.R (the model) and R/toolkit.R (shared layout and helpers),
##   both sourced automatically by Shiny. data/ holds the two Irish CSVs,
##   read once at load (B_04).
##
## Version:
##   B_03_14_version_chr; history in CHANGELOG.md; git tag vX.Y.Z.
##
## Outputs:
##   None. The app is interactive only.
##
## Packages:
##   shiny, bslib, ggplot2.
##
## References:
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 1 (growth
##     accounting, convergence), ch. 4 (development accounting).
##   Solow, R. (1957). Technical change and the aggregate production
##     function. Review of Economics and Statistics 39(3).
##   Abramovitz, M. (1956). Resource and output trends in the United States
##     since 1870. American Economic Review 46(2).
##   CSO tables NA002, NA006, CSA02, QLF01, PIA09 (PxStat), for data/.
##   Penn World Table 10.01 (rgdpna, rnna, emp), for the decade figure.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C (the model) is in R/model.R and T (the toolkit) in R/toolkit.R.
#
#   B: Setup
#     B_01  Packages
#     B_02  Settings
#     B_03  Soft-coded objects
#     B_04  Paths and data
#   C: Model (R/model.R)
#   T: Toolkit (R/toolkit.R)
#   D: Plots
#     D_01  The decompositions
#     D_02  The residual and the levels
#     D_03  Convergence
#     D_04  Ireland's growth accounts
#   E: User Interface
#   F: Server
#   G: Run

################################################################################
## B: Setup ####################################################################
################################################################################
# Note: Packages, options and every soft-coded value.

#### B_01: Packages ############################################################
# Note: Shiny for the app, bslib for the look, ggplot2 for the figures.

###### B_01_01: Load Packages ##################################################
# Note: All three run under shinylive.

library(shiny)
library(bslib)
library(ggplot2)

###### B_01_02: Load the Model #################################################
# Note: Shiny sources R/ itself; this covers sourcing app.R by hand.

if (!exists("C_01_01_growth_fn")) {
  source(file.path("R", "model.R"))
}

###### B_01_03: Load the Toolkit ###############################################
# Note: The shared palette, plot theme, CSS and builders.

if (!exists("T_01_01_palette_vec")) {
  source(file.path("R", "toolkit.R"))
}

#### B_02: Settings ############################################################
# Note: Standard options.

###### B_02_01: Global Options #################################################
# Note: No scientific notation; three digits in the console.

options(scipen = 999, digits = 3)

###### B_02_02: Seed ###########################################################
# Note: The stage 5 cross-section takes its own seed from a control
#   (B_03_01); this one is kept for consistency.

set.seed(42)

#### B_03: Soft-Coded Objects ##################################################
# Note: Calibration, stages, scenarios, controls, equations, text, version.

###### B_03_01: Input Defaults #################################################
# Note: Starting value of every control; Reset returns here. Output growth
#   of 3%, capital 4%, employment 1%, human capital 1%, capital share a third;
#   the development-accounting defaults put a country at a quarter of
#   frontier income with nine-tenths of its capital-output ratio (Romer 2019,
#   ch. 4). g_a and delta set the steady states of the stage 5 cross-section.

B_03_01_defaults_lst <- list(
  alpha       = 0.33,  # capital share
  g_y         = 0.030,   # growth in output
  g_k         = 0.04,   # growth in the capital stock
  g_l         = 0.010,   # growth in employment
  g_h         = 0.01,   # growth in human capital per worker
  y_rel       = 0.25,    # income per worker relative to the frontier
  ky_rel      = 0.90,    # capital-output ratio relative to the frontier
  h_rel       = 0.70,    # human capital relative to the frontier
  n_countries = 120,     # countries in the simulated cross-section
  seed        = 42,      # which draw of them
  g_a         = 0.02,    # common technology growth
  delta       = 0.06,    # depreciation
  noise       = 0.01,   # other shocks to growth
  gap_lo      = 0.60     # how far below its own steady state a country starts
)

###### B_03_02: Stages #########################################################
# Note: One layer of the model each, all within lecture 3.2.

B_03_02_stages_vec <- c(
  "Stage 1: The Accounting Identity"     = "1",
  "Stage 2: Per Worker"                  = "2",
  "Stage 3: What the Residual Rests On"  = "3",
  "Stage 4: Development Accounting"      = "4",
  "Stage 5: Convergence and Causes"      = "5"
)

###### B_03_03: Scenarios ######################################################
# Note: Worked examples. Each sets a stage and overrides some defaults;
#   unlisted controls return to B_03_01. Story order and wording follow
#   CONVENTIONS.md sections 3 to 5. The Irish presets take the CSO's
#   published growth rates for 2015 and 2023 and the three readings of the
#   Irish capital share that the on-screen note (F_01_01, irish_note) sources.

B_03_03_scenarios_lst <- list(
  investment = list(
    label  = "An Investment Boom",
    stage  = "1",
    values = list(g_k = 0.06, g_y = 0.035),
    story  = paste(
      "Firms invest heavily for a year, so the measured capital stock",
      "grows faster than measured output (Δln&nbsp;K = 6%, Δln&nbsp;Y =",
      "3.5%), and the capital term of the identity, α&nbsp;Δln&nbsp;K,",
      "lengthens. It lengthens by only the capital share of the increase,",
      "but that is enough to take nearly the whole of the 3.5% on the",
      "contributions axis, so on the source axis the capital bar becomes",
      "much the longest of the four and the residual (Δln&nbsp;A)",
      "collapses to the shortest, its share of growth falling with it.",
      "How much of the boom the capital term can claim is set by the",
      "capital share (α); how little is left over depends on the gap",
      "between Δln&nbsp;K and Δln&nbsp;Y."
    ),
    prompt = paste(
      "This is what an accumulation-driven boom looks like in the accounts.",
      "What does it predict about whether the growth can continue?"
    )
  ),
  ireland2015 = list(
    label  = "Ireland 2015: The Residual Breaks",
    stage  = "1",
    values = list(g_y = 0.22, g_k = 0.22, g_l = 0.03, alpha = 0.33),
    story  = paste(
      "Multinationals moved intellectual property and aircraft-leasing",
      "balance sheets onto the Irish books in 2015, so measured output",
      "and the measured net capital stock jumped together (Δln&nbsp;Y =",
      "22%, Δln&nbsp;K = 22%) because they moved for the same reason. The",
      "capital term α&nbsp;Δln&nbsp;K can claim only the capital share of",
      "that jump, so on the contributions axis the residual (Δln&nbsp;A)",
      "takes most of the remaining twenty-two points and on the source",
      "axis it becomes the longest of the four bars: the identity reports",
      "a productivity boom. How much lands in Δln&nbsp;A rather than in",
      "capital is decided entirely by the capital share (α), which is an",
      "assumption, not a measurement. Real GNI*, which strips out the",
      "depreciation and profits of relocated foreign capital, grew under",
      "two per cent in the same year."
    ),
    prompt = paste(
      "The identity cannot tell a relocated balance sheet from a new",
      "factory, because it never sees either: it sees a capital series and",
      "an output series. Which of the two terms is doing the work here, and",
      "what would the residual say if the capital series had not moved?"
    )
  ),
  miracle = list(
    label  = "Growth Without Accumulation",
    stage  = "2",
    values = list(g_y = 0.045, g_k = 0.03, g_l = 0.01),
    story  = paste(
      "An economy gets more out of the plant and the workers it already",
      "has: output grows well ahead of its inputs (Δln&nbsp;Y = 4.5%,",
      "Δln&nbsp;K = 3%, Δln&nbsp;L = 1%), so capital per worker,",
      "Δln&nbsp;K − Δln&nbsp;L, barely moves and the capital-deepening",
      "term α(Δln&nbsp;K − Δln&nbsp;L) stays short. Output per worker",
      "still grows by three and a half points, so on the contributions",
      "axis the residual (Δln&nbsp;A) has to carry most of that total,",
      "and on the source axis it dwarfs both measured bars. How much the",
      "deepening bar can take is set by the capital share (α) and by the",
      "gap between Δln&nbsp;K and Δln&nbsp;L; the human-capital bar is",
      "held down by how slowly schooling (Δln&nbsp;h) moves."
    ),
    prompt = paste(
      "Growth that is mostly residual is the kind that can continue. Growth",
      "that is mostly capital deepening runs into diminishing returns. Which",
      "is which is exactly what growth accounting is for."
    )
  ),
  ireland2023 = list(
    label  = "Ireland 2023: Everything Points the Wrong Way",
    stage  = "2",
    values = list(g_y = -0.03, g_k = 0.00, g_l = 0.03, alpha = 0.33),
    story  = paste(
      "A handful of large foreign-owned plants shipped less in 2023, so",
      "measured output fell while the capital stock at constant prices",
      "was flat and employment kept rising (Δln&nbsp;Y = −3%, Δln&nbsp;K",
      "= 0, Δln&nbsp;L = 3%). Output per worker, Δln&nbsp;Y − Δln&nbsp;L,",
      "is therefore six points down, and capital per worker is falling",
      "too, so the capital-deepening term α(Δln&nbsp;K − Δln&nbsp;L) is",
      "itself negative: on the contributions axis the residual",
      "(Δln&nbsp;A) has to absorb the rest and runs well to the left of",
      "zero, and on the source axis it is the only bar of any length.",
      "Irish workers did not forget how to work; the size of the fall is",
      "set by the capital share (α) and by which output series is fed in,",
      "since real GNI* grew about six per cent in the same year."
    ),
    prompt = paste(
      "Switch to per worker and watch the number get worse. The CSO's own",
      "multifactor productivity measure, which uses hours and capital",
      "services rather than headcount and the capital stock, puts the fall",
      "at about a fifth of this. What does the gap between the two tell you",
      "about what the crude identity is capable of?"
    )
  ),
  assumption = list(
    label  = "How Much It Rests on the Capital Share",
    stage  = "3",
    values = list(alpha = 0.5),
    story  = paste(
      "Nothing about the economy changes here: the four measured growth",
      "rates stay where they were and only the reading of the national",
      "accounts moves, with the capital share raised from a third to a",
      "half (α = 0.5). That slides the marked point rightwards along the",
      "horizontal axis of this figure, and because the line slopes down",
      "it carries the vertical axis with it: the residual growth in",
      "output per worker (Δln&nbsp;A) falls to nothing, the whole of the",
      "per-worker growth now credited to capital deepening and schooling",
      "instead. The slope of that line is the gap between capital growth",
      "and employment growth, Δln&nbsp;K − Δln&nbsp;L, net of Δln&nbsp;h,",
      "so the steeper that gap, the more a disagreement about α costs."
    ),
    prompt = paste(
      "Slide the capital share and watch the residual move; the faded curve",
      "and faded point are where this example left them, so the gap to them",
      "is the whole of what your assumption bought. Nothing about the",
      "economy changed. What does that say about a literature built on the",
      "size of the residual?"
    )
  ),
  irishalpha = list(
    label  = "Which Irish Capital Share?",
    stage  = "3",
    values = list(alpha = 0.68, g_y = -0.03, g_k = -0.01, g_l = 0.03),
    story  = paste(
      "The capital share is supposed to be read off the national",
      "accounts, but Ireland offers three defensible readings of the same",
      "year: the CSO's total-economy labour share of gross value added",
      "implies a capital share (α) of about 0.68, the domestic sector",
      "alone about 0.47, and the ESRI's work on GNI* between 0.4 and 0.5.",
      "This preset takes 2023's measured growth rates (Δln&nbsp;Y = −3%,",
      "Δln&nbsp;K = −1%, Δln&nbsp;L = 3%) and the largest of the three (α",
      "= 0.68), which moves the marked point to the far right of the",
      "horizontal axis. Capital per worker is falling here, Δln&nbsp;K",
      "&lt; Δln&nbsp;L, so the line slopes <i>up</i> rather than down and",
      "the vertical axis rises with it: the residual (Δln&nbsp;A) is less",
      "negative at 0.68 than at a third, with not a single measurement",
      "changed."
    ),
    prompt = paste(
      "Slide α from 0.33 to 0.68 and back, reading the gap to the faded",
      "curve as you go. Nothing about Ireland changed;",
      "the residual moved anyway. This is the same problem as the",
      "developing-country case, except that here the measurement is good",
      "and the economy is the thing that is strange."
    )
  ),
  poor = list(
    label  = "A Country at a Quarter of Frontier Income",
    stage  = "4",
    values = list(y_rel = 0.25, ky_rel = 0.9, h_rel = 0.7),
    story  = paste(
      "The question turns from growth to levels, and the sliders place a",
      "country at a quarter of the frontier's output per worker",
      "(y<sub>i</sub>/y<sub>US</sub> = 0.25) with nine-tenths of its",
      "capital-output ratio ((K/Y)<sub>i</sub>/(K/Y)<sub>US</sub> = 0.9)",
      "and seven-tenths of its human capital",
      "(h<sub>i</sub>/h<sub>US</sub> = 0.7). The capital ratio enters",
      "raised to α/(1 − α), which flattens it, so on the log-contribution",
      "axis the capital-intensity bar is barely visible and human capital",
      "takes only a modest slice, while relative productivity",
      "(A<sub>i</sub>/A<sub>US</sub>) is inferred as the remainder and on",
      "the source axis is much the longest bar. Raise the capital ratio",
      "to 1 and watch how little of the gap closes: the split is decided",
      "by the capital share (α) through that exponent, and by how much of",
      "the income gap survives once the two measured ratios have been",
      "credited. These are the numbers you have set, not a measured",
      "country."
    ),
    prompt = paste(
      "Set the capital ratio to 1 and watch how little the gap closes.",
      "Giving a poor country the frontier's capital stock would not make it",
      "rich, which is the central finding of this literature."
    )
  ),
  convergence = list(
    label  = "Absolute Against Conditional Convergence",
    stage  = "5",
    values = list(gap_lo = 0.6),
    story  = paste(
      "The app now draws its own cross-section rather than reading one: a",
      "simulated set of Solow economies differing in their saving rates",
      "(s) and population growth (n), and so in the resting point each is",
      "heading for, with every one of them starting somewhere between 0.6",
      "of its own steady state and the steady state itself. In the",
      "absolute figure the horizontal axis is log output per worker at",
      "the start and the vertical axis is growth in output per worker,",
      "and the fitted line is close to flat, because a country's starting",
      "income records mostly where it is heading rather than how far it",
      "has to go. The conditional figure is the same countries with s and",
      "n taken out of both axes, and the line then slopes clearly down.",
      "Raise the floor on that starting gap towards 1, so every economy",
      "begins near its own resting point, and the flat line stays flat",
      "while the sloped one survives — in the model's own cross-section,",
      "which is a simulation and not a claim about the world."
    ),
    prompt = paste(
      "Raise the lower bound on the starting gap towards 1, so every country",
      "starts near its own steady state. The unconditional relationship",
      "disappears entirely while the conditional one stays. That is the",
      "distinction in one slider."
    )
  )
)

###### B_03_04: Controls #######################################################
# Note: One entry per numeric control: label (HTML), slider range and step,
#   and the stage from which it appears.

B_03_04_controls_lst <- list(
  # Output and capital ranges reach the Ireland 2015 values
  g_y         = list(label = "Growth in Output (Δln Y)",
                     min = -0.10, max = 0.30, step = 0.01, from = 1),
  g_k         = list(label = "Growth in Capital (Δln K)",
                     min = -0.10, max = 0.60, step = 0.01, from = 1),
  g_l         = list(label = "Growth in Employment (Δln L)",
                     min = -0.05, max = 0.10, step = 0.01, from = 1),
  g_h         = list(label = "Growth in Human Capital (Δln h)",
                     min = 0, max = 0.03, step = 0.01, from = 1),
  alpha       = list(label = "Capital Share (α)",
                     min = 0.15, max = 0.70, step = 0.01, from = 1),
  y_rel       = list(label = "Income per Worker, Frontier = 1",
                     min = 0.02, max = 1, step = 0.01, from = 4),
  ky_rel      = list(label = "Capital-Output Ratio, Frontier = 1",
                     min = 0.2, max = 1.4, step = 0.05, from = 4),
  h_rel       = list(label = "Human Capital, Frontier = 1",
                     min = 0.3, max = 1, step = 0.05, from = 4),
  n_countries = list(label = "Countries in the Sample",
                     min = 40, max = 300, step = 20, from = 5),
  gap_lo      = list(label = "How Far Below Their Own Steady State",
                     min = 0.2, max = 0.98, step = 0.02, from = 5),
  noise       = list(label = "Other Shocks to Growth",
                     min = 0, max = 0.02, step = 0.01, from = 5),
  seed        = list(label = "Which Draw of Countries",
                     min = 1, max = 200, step = 1, from = 5)
)

###### B_03_05: Parameter Explanations #########################################
# Note: What each control is and what raising it does.

B_03_05_help_lst <- list(
  g_y = "Growth in total output, from the national accounts.",
  g_k = paste(
    "Growth in the capital stock. Measured, but with a good deal of",
    "judgement in it: depreciation rates, the quality of new capital, and",
    "how intensively it is used."
  ),
  g_l = "Growth in employment, or in hours worked.",
  g_h = paste(
    "Growth in human capital per worker, usually from years of schooling",
    "weighted by returns. It moves slowly, so it rarely explains much."
  ),
  alpha = paste(
    "The share of output paid to capital, which under competition equals the",
    "elasticity of output with respect to capital. It is taken from the",
    "accounts, and the residual is very sensitive to it."
  ),
  y_rel = paste(
    "The country's output per worker as a fraction of the frontier's. This",
    "is the gap the accounting is trying to explain."
  ),
  ky_rel = paste(
    "The capital-output ratio relative to the frontier. Note that this is",
    "the ratio to OUTPUT, not to workers: poor countries have much less",
    "capital per worker, but their capital-output ratios are surprisingly",
    "close to rich countries'."
  ),
  h_rel = paste(
    "Human capital per worker relative to the frontier, from schooling. It",
    "varies much less across countries than income does, which is why it",
    "cannot explain much of the gap."
  ),
  n_countries = "How many countries are in the simulated cross-section.",
  gap_lo = paste(
    "How far below its own steady state the poorest-placed country starts.",
    "Closer to 1 means every country is near its own destination, which is",
    "what kills absolute convergence in the data."
  ),
  noise = "Everything else moving growth: wars, commodities, luck.",
  seed = "Redraws the simulated countries."
)

###### B_03_06: Prompts ########################################################
# Note: One "what to try" prompt per stage, shown above the figures.

B_03_06_prompts_lst <- list(
  "1" = paste(
    "Everything on the right-hand side except the residual is measured, so",
    "the residual is whatever is needed to make the identity hold. Move the",
    "growth rate of capital and watch it absorb the difference."
  ),
  "2" = paste(
    "Per worker, the question is how much of rising living standards comes",
    "from more capital per head, how much from better-educated workers, and",
    "how much from neither. The answer for most countries is: mostly",
    "neither."
  ),
  "3" = paste(
    "Slide the capital share. Nothing about the economy has changed, and the",
    "residual has moved a long way. Any claim resting on the size of the",
    "residual is resting on this number."
  ),
  "4" = paste(
    "Set the capital-output ratio to 1, so this country has as much capital",
    "per unit of output as the frontier. It is still poor. That is the",
    "finding: differences in income are mostly differences in productivity,",
    "not in inputs."
  ),
  "5" = paste(
    "Look at the two scatters side by side. The same countries, the same",
    "growth rates. Without controls there is no convergence; with them there",
    "is. Whether you believe in convergence depends on which question you",
    "asked."
  )
)

###### B_03_07: The Model, Stage by Stage ######################################
# Note: The equations panel: each entry has a group, a label, one version
#   per stage that changes it, and a note in words.

B_03_07_equations_lst <- list(

  # --- The model's equations --------------------------------------------------
  list(
    group = "model", label = "Production",
    versions = list("1" = "Y = A\\,K^{\\alpha}(hL)^{1-\\alpha}"),
    notes = list(
      "1" = paste("Constant returns, Cobb-Douglas, with human capital",
                  "raising the effectiveness of each worker.")
    )
  ),
  list(
    group = "model", label = "The Identity",
    versions = list("1" = paste0("\\Delta\\ln Y = \\Delta\\ln A + \\alpha",
                                 "\\Delta\\ln K + (1-\\alpha)(\\Delta\\ln h",
                                 " + \\Delta\\ln L)")),
    notes = list(
      "1" = paste("Logs and differences. It is an identity, not a theory: it",
                  "holds by construction whatever is true of the economy.")
    )
  ),
  list(
    group = "model", label = "Levels",
    versions = list("4" = paste0("y = \\left(\\frac{K}{Y}\\right)^{\\alpha/",
                                 "(1-\\alpha)} h\\,A")),
    notes = list(
      "4" = paste("The same production function rearranged. Written this way",
                  "the capital term uses the capital-OUTPUT ratio, which",
                  "varies far less across countries than capital per worker",
                  "does.")
    )
  ),

  # --- Assumptions ------------------------------------------------------------
  list(
    group = "assumption", label = "Factors Are Paid Their Products",
    versions = list("1" = "\\alpha = \\text{capital's share of income}"),
    notes = list(
      "1" = paste("Needed to read the elasticity off the national accounts.",
                  "It assumes competitive factor markets and constant",
                  "returns, neither of which is obviously true.")
    )
  ),
  list(
    group = "assumption", label = "Inputs Are Measured",
    versions = list("3" = "K, L, h \\text{ observed without error}"),
    notes = list(
      "3" = paste("The residual absorbs every measurement error in every",
                  "input: utilisation, capital quality, hours, skill. It is",
                  "a residual first and a measure of technology second.")
    )
  ),
  list(
    group = "assumption", label = "No Reallocation",
    versions = list("3" = "\\text{one representative sector}"),
    notes = list(
      "3" = paste("Moving workers from low to high productivity uses shows",
                  "up as TFP growth in the aggregate, though nothing has",
                  "been invented. For a developing economy this can be most",
                  "of the residual.")
    )
  ),

  # --- Solved forms -----------------------------------------------------------
  list(
    group = "solved", label = "The Residual",
    versions = list("1" = paste0("\\Delta\\ln A = \\Delta\\ln Y - \\alpha",
                                 "\\Delta\\ln K - (1-\\alpha)(\\Delta\\ln h",
                                 " + \\Delta\\ln L)")),
    notes = list(
      "1" = paste("Solow's residual: what growth is left once the measured",
                  "inputs have been credited. Abramovitz called it the",
                  "measure of our ignorance.")
    )
  ),
  list(
    group = "solved", label = "Per Worker",
    versions = list("2" = paste0("\\Delta\\ln(Y/L) = \\Delta\\ln A + \\alpha",
                                 "\\Delta\\ln(K/L) + (1-\\alpha)\\Delta",
                                 "\\ln h")),
    notes = list(
      "2" = paste("Living standards split into capital deepening, better",
                  "workers, and the residual. This is the version the",
                  "literature reports.")
    )
  ),
  list(
    group = "solved", label = "Relative Income",
    versions = list("4" = paste0("\\frac{y_i}{y_{US}} = \\left(\\frac{",
                                 "(K/Y)_i}{(K/Y)_{US}}\\right)^{\\alpha/",
                                 "(1-\\alpha)} \\frac{h_i}{h_{US}}",
                                 " \\frac{A_i}{A_{US}}")),
    notes = list(
      "4" = paste("Development accounting. Everything but the last term is",
                  "measured, so relative productivity is inferred, and it",
                  "turns out to carry most of the weight.")
    )
  ),
  list(
    group = "solved", label = "Conditional Convergence",
    versions = list("5" = paste0("g_i = \\text{const} - \\lambda \\ln y_{i0}",
                                 " + \\beta_s \\ln s_i + \\beta_n \\ln n_i")),
    notes = list(
      "5" = paste("The regression the literature runs. The coefficient on",
                  "initial income is negative only once the determinants of",
                  "the steady state are held fixed.")
    )
  ),

  # --- Descriptors ------------------------------------------------------------
  list(
    group = "descriptor", label = "What the Literature Finds",
    versions = list("2" = "\\text{most of growth is residual}"),
    notes = list(
      "2" = paste("For most countries over most periods, the majority of",
                  "growth in output per worker is not accounted for by",
                  "measured inputs. The East Asian economies were the famous",
                  "partial exception, where accumulation did most of the",
                  "work.")
    )
  ),
  list(
    group = "descriptor", label = "Absolute Against Conditional",
    versions = list("5" = paste0("\\text{absolute: } \\frac{\\partial g}",
                                 "{\\partial \\ln y_0} < 0 \\text{ for all}")),
    notes = list(
      "5" = paste("Absolute convergence says poor countries grow faster,",
                  "full stop, and the data reject it. Conditional",
                  "convergence says a country below ITS OWN steady state",
                  "grows faster, and the data support it. The Solow model",
                  "only ever predicted the second.")
    )
  ),
  list(
    group = "descriptor", label = "Proximate and Fundamental",
    versions = list("5" = "\\text{inputs} \\leftarrow \\text{institutions}"),
    notes = list(
      "5" = paste("Capital, schooling and productivity are PROXIMATE causes:",
                  "they are the things that immediately produce output. Why",
                  "one country accumulates and innovates and another does",
                  "not is the FUNDAMENTAL question, and the answers offered",
                  "are institutions, geography and culture.")
    )
  ),
  list(
    group = "descriptor", label = "The Colonial Experiment",
    versions = list(
      "5" = "\\text{settler mortality} \\to \\text{institutions}"),
    notes = list(
      "5" = paste("Where Europeans could settle, they built institutions",
                  "that protected property; where they could not, they built",
                  "extractive ones, and those persisted. Mortality rates",
                  "faced by early settlers therefore predict institutions",
                  "today, and are plausibly unrelated to income today except",
                  "through them — which makes them an instrument.")
    )
  )
)

###### B_03_08: Equation Group Titles ##########################################
# Note: Group headings in the equations tabs.

B_03_08_groups_vec <- c(
  model      = "Model Equations",
  assumption = "Assumptions",
  solved     = "Solved Forms",
  descriptor = "Descriptors"
)

###### B_03_09: Notation Key ###################################################
# Note: Notation tab. Groups: var, par, flw (results); "from" is the first
#   stage a symbol appears in.

B_03_09_notation_lst <- list(
  list(grp = "var", sym = "Y", txt = "output", from = 1),
  list(grp = "var", sym = "K", txt = "capital", from = 1),
  list(grp = "var", sym = "L", txt = "employment", from = 1),
  list(grp = "var", sym = "h", txt = "human capital per worker", from = 1),
  list(grp = "var", sym = "A", txt = "total factor productivity", from = 1),
  list(grp = "par", sym = "\\alpha", txt = "capital share", from = 1),
  list(grp = "var", sym = "y", txt = "output per worker", from = 2),
  list(grp = "flw", sym = "\\Delta\\ln A", txt = "the Solow residual",
       from = 1),
  list(grp = "flw", sym = "K/Y", txt = "the capital-output ratio", from = 4),
  list(grp = "par", sym = "s", txt = "saving rate", from = 5),
  list(grp = "par", sym = "n", txt = "population growth", from = 5),
  list(grp = "flw", sym = "\\lambda", txt = "speed of convergence", from = 5)
)

###### B_03_10: Notation Columns ###############################################
# Note: How the notation tab is split into columns.

B_03_10_nota_cols_lst <- list(
  "Variables"  = "var",
  "Parameters" = "par",
  "Results"    = "flw"
)

###### B_03_11: Figure Heights #################################################
# Note: Height of the main figures in the browser.

B_03_11_tall_chr <- "400px"

###### B_03_12: Recalculation Delay ############################################
# Note: Milliseconds to wait before recalculating after a change.

B_03_12_debounce_ms_int <- 250L

###### B_03_13: Ireland, Decade by Decade ######################################
# Note: Average annual growth rates by decade, Penn World Table 10.01
#   (rgdpna, rnna, emp), the one source carrying all three series back to
#   the 1950s. CSO constant-price GDP runs from 1970, the net capital stock
#   from 1985 and ILO-basis employment from 1998, so the long run is not CSO
#   and the app says so on screen (F_01_01, decades_note). The capital share
#   is left to the slider: the Penn World Table's Irish labour share is one
#   imputed figure repeated for every year to 1995.

B_03_13_ireland_df <- data.frame(
  decade = c("1950s", "1960s", "1970s", "1980s", "1990s", "2000s", "2010s"),
  g_y    = c(0.0110, 0.0460, 0.0463, 0.0311, 0.0694, 0.0369, 0.0628),
  g_k    = c(0.0435, 0.0525, 0.0621, 0.0347, 0.0420, 0.0625, 0.0503),
  g_l    = c(-0.0150, 0.0006, 0.0099, -0.0042, 0.0337, 0.0195, 0.0153),
  stringsAsFactors = FALSE
)

###### B_03_14: Version ########################################################
# Note: Semantic version, shown in the footer; CHANGELOG.md has the history.

B_03_14_version_chr <- "1.0.7"

###### B_03_15: Source Repository ##############################################
# Note: The GitHub repo, linked from the footer.

B_03_15_repo_chr <- paste0("https://github.com/Sam-Deegan/",
                        "Interactive-Model-Growth-Accounting")

#### B_04: Paths and Data ######################################################
# Note: The QR code and the two Irish CSVs.

###### B_04_01: QR Code Source #################################################
# Note: Resolved by the toolkit.

B_04_01_qr_src_chr <- T_07_04_qr_fn()

###### B_04_02: The Irish Annual Series ########################################
# Note: year, gdp, gnp, gnistar (NA006, NA002), capital (CSA02), emp (QLF01),
#   from the CSO's PxStat and shipped in data/. Read once at load.

B_04_02_irl_df <- utils::read.csv(file.path("data", "ireland_annual.csv"),
                                  stringsAsFactors = FALSE)

###### B_04_03: The CSO's Productivity Accounts ################################
# Note: year, sector and the PIA09 series for the whole economy and its
#   foreign- and domestic-dominated halves, 2000 to 2019, plus the GVA shares.

B_04_03_irl_cso_df <- utils::read.csv(file.path("data", "ireland_cso.csv"),
                                      stringsAsFactors = FALSE)

###### B_04_04: Output Measures ################################################
# Note: The output series the Irish mode can decompose.

B_04_04_irl_measures_vec <- c(
  "Gross Domestic Product"            = "gdp",
  "Modified Gross National Income (GNI*)" = "gnistar",
  "Gross National Product"            = "gnp"
)

###### B_04_05: Years the Identity Covers ######################################
# Note: First and last year with output, capital and employment all present;
#   the window starts a year later, at the first growth rate.

B_04_05_irl_years_int <- local({
  d <- B_04_02_irl_df
  ok <- !is.na(d$capital) & !is.na(d$emp) & !is.na(d$gdp)
  range(d$year[ok])
})

################################################################################
## D: Plots ####################################################################
################################################################################
# Note: Builders only; each returns a ggplot for the server to draw. Figure
#   conventions follow CONVENTIONS.md 6.

#### D_01: The Decompositions ##################################################
# Note: Where growth came from, in total and per worker.

###### D_01_01: A Decomposition Bar ############################################
# Note: Shared by the two decomposition figures: labelled contributions with
#   the residual in the accent colour. "sym" marks the measured-growth line.

D_01_01_bars_fn <- function(df, total, title, caption, ylab, sym) {
  df$source <- factor(df$source, levels = rev(df$source))
  df$kind   <- ifelse(grepl("Residual", df$source), "Residual", "Measured")
  # Window: zero, the benchmark, and room for the labels outside the bars
  lo0  <- min(0, total * 1.06)
  hi0  <- max(0, total * 1.06)
  span <- max(hi0 - lo0, 2 * max(abs(df$growth)), 1e-9)
  hi   <- max(hi0, if (any(df$growth > 0)) {
    max(df$growth) + 0.55 * span } else -Inf)
  lo   <- min(lo0, if (any(df$growth < 0)) {
    min(df$growth) - 0.55 * span } else Inf)

  ggplot(df, aes(x = source, y = growth, fill = kind)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = total) +
    geom_col(width = 0.6) +
    geom_text(aes(label = paste0(T_02_06_pct_fn(growth, 2), "  (",
                                 round(share * 100), "%)")),
              hjust = ifelse(df$growth >= 0, -0.1, 1.1), size = 3.9,
              colour = T_01_01_palette_vec[["navy"]]) +
    T_02_02_mark_y_fn(total, sym) +
    coord_flip(ylim = c(lo, hi)) +
    scale_fill_manual(values = c(
      "Measured" = T_01_02_series_vec[["band"]],
      "Residual" = T_01_02_series_vec[["main"]]
    )) +
    labs(
      x = NULL, y = ylab,
      caption = caption
    ) +
    # Flipped bars take no grid; each bar carries its own number
    T_02_01_theme_fn(grid = "none") +
    theme(legend.position = "none")
}

###### D_01_02: Total Growth ###################################################
# Note: The identity as it is usually first written.

D_01_02_total_fn <- function(par) {
  D_01_01_bars_fn(
    C_01_01_growth_fn(par), par$g_y,
    "Growth accounting for output",
    paste("Everything but the residual is measured. The residual is what is",
          "needed to make the identity hold."),
    ylab = expression(bold("Contribution to output growth (" *
                             Delta * "ln" ~ Y * ")")),
    sym  = expression(Delta * "ln" ~ Y)
  )
}

###### D_01_03: Per Worker #####################################################
# Note: The version the literature reports: output per worker.

D_01_03_worker_fn <- function(par) {
  D_01_01_bars_fn(
    C_01_02_worker_fn(par), par$g_y - par$g_l,
    "Growth accounting for output per worker",
    paste("Capital deepening is capital growing faster than employment.",
          "Human capital is better-educated workers. The rest is residual."),
    ylab = expression(bold("Contribution to growth per worker (" *
                             Delta * "ln" ~ (Y / L) * ")")),
    sym  = expression(Delta * "ln" ~ (Y / L))
  )
}

###### D_01_04: Ireland, Decade by Decade ######################################
# Note: The identity on seven Irish decades (B_03_13) at the chosen capital
#   share: the bars are data, the split between them is an assumption.

D_01_04_decades_fn <- function(par) {
  d <- B_03_13_ireland_df
  a <- par$alpha
  d$capital  <- a * d$g_k
  d$labour   <- (1 - a) * d$g_l
  d$residual <- d$g_y - d$capital - d$labour

  long <- rbind(
    data.frame(decade = d$decade, part = "Capital",  value = d$capital),
    data.frame(decade = d$decade, part = "Labour",   value = d$labour),
    data.frame(decade = d$decade, part = "Residual", value = d$residual)
  )
  long$part   <- factor(long$part, levels = c("Capital", "Labour",
                                              "Residual"))
  long$decade <- factor(long$decade, levels = d$decade)

  ggplot(long, aes(x = decade, y = value, fill = part)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    geom_col(width = 0.68) +
    geom_point(data = d, inherit.aes = FALSE,
               aes(x = decade, y = g_y), shape = 18, size = 3.4,
               colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = c(
      Capital  = T_01_02_series_vec[["band"]],
      Labour   = T_01_02_series_vec[["compare"]],
      Residual = T_01_02_series_vec[["main"]]
    )) +
    scale_y_continuous(labels = function(v) T_02_06_pct_fn(v, 0)) +
    labs(
      x = NULL,
      y = expression(bold("Average annual growth (" *
                            Delta * "ln" ~ Y * ")")),
      fill = NULL,
      caption = paste(
        "Diamonds are measured output growth; the bars are the identity's",
        "split of it. Move the capital share and watch the whole of Irish",
        "history redistribute between the light bar and the dark one",
        "without a single measurement changing. The 1950s are the decade",
        "capital grew and the workforce shrank; the 2010s average is",
        "dominated by 2015 alone."
      )
    ) +
    T_02_01_theme_fn()
}

#### D_02: The Residual and the Levels #########################################
# Note: What the residual rests on, and what it says about income levels.

###### D_02_01: The Residual Against the Capital Share #########################
# Note: The residual per worker against the capital share, with a ghost of
#   the curve and marked point at the loaded worked example's settings.

D_02_01_sensitivity_fn <- function(par, ref = NULL) {
  df  <- C_01_03_sensitivity_fn(par, 300)
  now <- C_01_02_worker_fn(par)
  res <- now$growth[now$source == "Residual (TFP)"]

  # Ghost of the same curve at the reference settings, drawn underneath
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    ref_now <- C_01_02_worker_fn(ref)
    list(
      T_02_03a_ghost_line_fn(
        C_01_03_sensitivity_fn(ref, 300), aes(x = alpha, y = residual),
        colour = T_01_02_series_vec[["main"]], linewidth = 1.2),
      T_02_03a_ghost_point_fn(
        ref$alpha, ref_now$growth[ref_now$source == "Residual (TFP)"],
        colour = T_01_02_series_vec[["main"]])
    )
  }

  ggplot(df, aes(x = alpha, y = residual)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(v = par$alpha) +
    ghost_lyr +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.2) +
    T_02_03_point_fn(par$alpha, res) +
    T_02_02_mark_x_fn(par$alpha, expression(alpha)) +
    scale_y_continuous(labels = function(x) paste0(round(x * 100, 1), "%")) +
    labs(
      x = expression(bold("Capital share (" * alpha * ")")),
      y = expression(bold("Residual growth per worker (" *
                            Delta * "ln" ~ A * ")")),
      caption = paste(
        "No new data: only a different reading of the national accounts.",
        "The residual inherits every assumption made about the inputs."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_02_02: Development Accounting #########################################
# Note: What explains a country's income gap. Logs, so the three bars add up
#   to the whole gap (Romer 2019, ch. 4).

D_02_02_levels_fn <- function(par) {
  lv <- C_01_04_levels_fn(par)
  df <- lv$table
  df$source <- factor(df$source, levels = rev(df$source))
  df$kind   <- ifelse(grepl("Productivity", df$source), "Residual",
                      "Measured")

  # Window: zero, every bar and room for the ratio labels on either side
  lo   <- min(min(df$log) * 2.1, 0)
  hi   <- max(max(df$log) * 2.1, 0.05)
  span <- hi - lo
  lo   <- lo - 0.13 * span
  hi   <- hi + 0.13 * span

  ggplot(df, aes(x = source, y = log, fill = kind)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    geom_col(width = 0.6) +
    geom_text(aes(label = paste0("ratio ", T_02_05_num_fn(ratio, 2),
                                 "   (", round(share * 100), "% of the gap)")),
              hjust = ifelse(df$log >= 0, -0.08, 1.08), size = 3.9,
              colour = T_01_01_palette_vec[["navy"]]) +
    T_02_02_mark_y_fn(0, expression(y[i] == y[US])) +
    coord_flip(ylim = c(lo, hi)) +
    scale_fill_manual(values = c(
      "Measured" = T_01_02_series_vec[["band"]],
      "Residual" = T_01_02_series_vec[["main"]]
    )) +
    labs(
      x = NULL,
      y = expression(bold("Contribution to the income gap (" *
                            log(y[i] / y[US]) * ")")),
      caption = paste0(
        "Implied relative productivity: ", T_02_05_num_fn(lv$tfp_rel, 2),
        ". The three ratios multiply back to ", T_02_05_num_fn(par$y_rel, 2),
        "."
      )
    ) +
    # Flipped bars take no grid, as in D_01_01
    T_02_01_theme_fn(grid = "none") +
    theme(legend.position = "none")
}

#### D_03: Convergence #########################################################
# Note: The same countries, asked two different questions.

###### D_03_01: Absolute Convergence ###########################################
# Note: Growth against initial income in the simulated cross-section, with
#   nothing held fixed. The fitted line carries its name; see CONVENTIONS.md 6.

D_03_01_absolute_fn <- function(par) {
  df  <- C_01_05_countries_fn(par)
  con <- C_01_06_convergence_fn(df)

  x_lim <- range(log(df$y_start)) +
    c(-1, 1) * 0.08 * diff(range(log(df$y_start)))
  y_lim <- range(df$growth) + c(-1, 1) * 0.10 * diff(range(df$growth))
  x_at  <- x_lim[1] + 0.97 * diff(x_lim)

  ggplot(df, aes(x = log(y_start), y = growth)) +
    geom_point(colour = T_01_02_series_vec[["reference"]], size = 1.9,
               alpha = 0.75) +
    geom_abline(intercept = stats::coef(con$uncond_fit)[1],
                slope = con$uncond_slope,
                colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    annotate("label", x = x_at,
             y = stats::coef(con$uncond_fit)[1] + con$uncond_slope * x_at,
             label = "Fitted line",
             # Name below a falling line, above a rising one
             size = 3.2, hjust = 1,
             vjust = if (con$uncond_slope < 0) 1.4 else -0.7,
             colour = T_01_01_palette_vec[["muted"]],
             fill = "white", label.size = 0,
             label.padding = grid::unit(0.12, "lines")) +
    scale_y_continuous(labels = function(x) paste0(round(x * 100, 1), "%")) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    labs(
      x = expression(bold("Log income per worker at the start (" *
                            log(y[i0]) * ")")),
      y = expression(bold("Growth in output per worker (" * g[i] * ")")),
      caption = paste(
        "Simulated economies, drawn from saving rates and population growth",
        "rates the sliders set, with nothing held fixed. Poor countries do",
        "not systematically grow faster, because they are not all heading",
        "for the same place."
      )
    ) +
    T_02_01_theme_fn(grid = "none") +
    theme(aspect.ratio = 2 / 3)
}

###### D_03_02: Conditional Convergence ########################################
# Note: The same regression with saving and population growth held fixed,
#   drawn as a partial-residual plot; zero on both axes is the prediction.

D_03_02_conditional_fn <- function(par) {
  df  <- C_01_05_countries_fn(par)
  con <- C_01_06_convergence_fn(df)
  res <- con$residuals

  x_lim <- range(res$y_resid) + c(-1, 1) * 0.08 * diff(range(res$y_resid))
  y_lim <- range(res$g_resid) + c(-1, 1) * 0.10 * diff(range(res$g_resid))
  x_at  <- x_lim[1] + 0.97 * diff(x_lim)

  ggplot(res, aes(x = y_resid, y = g_resid)) +
    T_02_02_zero_fn() +
    geom_point(colour = T_01_02_series_vec[["reference"]], size = 1.9,
               alpha = 0.75) +
    geom_abline(intercept = 0, slope = con$cond_slope,
                colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    annotate("label", x = x_at, y = con$cond_slope * x_at,
             label = "Fitted line",
             # Name below a falling line, above a rising one
             size = 3.2, hjust = 1,
             vjust = if (con$cond_slope < 0) 1.4 else -0.7,
             colour = T_01_01_palette_vec[["muted"]],
             fill = "white", label.size = 0,
             label.padding = grid::unit(0.12, "lines")) +
    T_02_02_mark_x_fn(0, expression("Predicted " * y[i0])) +
    scale_y_continuous(labels = function(x) paste0(round(x * 100, 1), "%")) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    labs(
      x = expression(bold("Initial income net of " * s ~ "and" ~ n * " (" *
                            tilde(y)[i0] * ")")),
      y = expression(bold("Growth net of " * s ~ "and" ~ n * " (" *
                            tilde(g)[i] * ")")),
      caption = paste(
        "The same simulated economies, with the determinants of the steady",
        "state held fixed. A country below its own steady state does grow",
        "faster."
      )
    ) +
    T_02_01_theme_fn(grid = "none") +
    theme(aspect.ratio = 2 / 3)
}

#### D_04: Ireland's Growth Accounts ###########################################
# Note: The identity applied to the CSO's own series, year by year: the
#   figures of the Ireland's Accounts mode.

###### D_04_01: Contributions Year by Year #####################################
# Note: One stacked bar per year with a diamond on measured growth; negative
#   parts sit below the axis, so the diamond is the net of the three.

D_04_01_irl_years_fn <- function(dec, from, to, lab) {
  d <- dec[dec$year >= from & dec$year <= to & !is.na(dec$g_y), ]
  if (nrow(d) == 0) return(T_02_02_placeholder_fn("No years in this window"))

  long <- rbind(
    data.frame(year = d$year, part = "Capital",  value = d$capital),
    data.frame(year = d$year, part = "Labour",   value = d$labour),
    data.frame(year = d$year, part = "Residual", value = d$residual)
  )
  long$part <- factor(long$part, levels = c("Capital", "Labour", "Residual"))

  # Drop missing parts here so position_stack does not warn
  long <- long[!is.na(long$value), , drop = FALSE]

  ggplot(long, aes(x = year, y = value, fill = part)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    geom_col(width = 0.75) +
    geom_point(data = d, inherit.aes = FALSE, aes(x = year, y = g_y),
               shape = 18, size = 2.6,
               colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = c(
      Capital  = T_01_02_series_vec[["band"]],
      Labour   = T_01_02_series_vec[["compare"]],
      Residual = T_01_02_series_vec[["main"]]
    )) +
    scale_y_continuous(labels = function(v) T_02_06_pct_fn(v, 0)) +
    labs(
      x = NULL,
      # Two lines with atop(), so the rotated title fits the panel
      y = expression(atop(bold("Contribution to growth"),
                          bold("(" * Delta * "ln" ~ Y * ")"))),
      fill = NULL,
      caption = paste(
        "Diamonds are measured growth; the bars are the identity's split of",
        "it. Bars below the axis are negative contributions, so the diamond",
        "is the net of the three rather than the top of the stack. On GDP,",
        "2015 is the year to look at: output and the capital stock both jump",
        "because the same multinational balance sheets moved onshore, and",
        "the identity has no way to know that."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_04_02: What the Inputs Alone Would Have Delivered #####################
# Note: Index paths of measured output and of capital and labour alone; the
#   gap at the last year is braced. "ref" ghosts the inputs line only.

D_04_02_irl_path_fn <- function(path, lab, ref = NULL) {
  if (nrow(path) == 0) return(T_02_02_placeholder_fn("No years in this window"))

  ghost_lyr <- if (is.null(ref) || nrow(ref) == 0 ||
                     T_02_03b_ghost_off_fn(path$inputs, ref$inputs)) {
    NULL
  } else {
    T_02_03a_ghost_path_fn(ref, aes(x = year, y = inputs),
                           colour = T_01_02_series_vec[["compare"]],
                           linewidth = 1.1)
  }

  long <- rbind(
    data.frame(year = path$year, line = "Measured output", value = path$actual),
    data.frame(year = path$year, line = "Capital and labour alone",
               value = path$inputs)
  )
  long$line <- factor(long$line,
                      levels = c("Measured output", "Capital and labour alone"))
  # Read the gap at the last year both lines reach
  both <- which(is.finite(path$actual) & is.finite(path$inputs))
  last <- if (length(both) == 0) NULL else path[max(both), ]
  gap  <- if (is.null(last)) NA_real_ else last$actual / last$inputs - 1

  # Brace in data units: r is the reach of the point, h the depth of the curls
  brace_lyr <- if (is.null(last) || last$actual == last$inputs) NULL else {
    arc   <- seq(0, pi / 2, length.out = 20)
    y_lo  <- min(last$actual, last$inputs)
    y_hi  <- max(last$actual, last$inputs)
    y_mid <- (y_lo + y_hi) / 2
    r     <- max(diff(range(path$year)), 1) * 0.012
    h     <- (y_hi - y_lo) * 0.14
    x_s   <- last$year - r
    brace_df <- data.frame(
      x = c(x_s + r * cos(arc), x_s, x_s,
            x_s - r * sin(arc), x_s - r * cos(arc), x_s, x_s,
            x_s + r * sin(arc)),
      y = c(y_lo + h * sin(arc), y_lo + h, y_mid - h,
            y_mid - h * cos(arc), y_mid + h * sin(arc), y_mid + h, y_hi - h,
            y_hi - h * cos(arc)))

    # Colour of whichever curve is on top at that year
    brace_chr <- if (last$actual > last$inputs) {
      T_01_02_series_vec[["main"]]
    } else {
      T_01_02_series_vec[["compare"]]
    }

    list(
      geom_path(data = brace_df, inherit.aes = FALSE, aes(x = x, y = y),
                colour = brace_chr, linewidth = 0.5),
      annotate("text", x = x_s - 2 * r, y = y_mid,
               label = "Cumulated residual", size = 3.2, hjust = 1,
               vjust = 0.5, colour = brace_chr)
    )
  }

  ggplot(long, aes(x = year, y = value, colour = line, linetype = line)) +
    T_02_02_rest_fn(h = 100) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    brace_lyr +
    T_02_02_mark_y_fn(100, expression(Y[t] == Y[0])) +
    scale_colour_manual(values = c(
      "Measured output"          = T_01_02_series_vec[["main"]],
      "Capital and labour alone" = T_01_02_series_vec[["compare"]]
    )) +
    scale_linetype_manual(values = c(
      "Measured output"          = "solid",
      "Capital and labour alone" = "22"
    )) +
    labs(
      x = NULL,
      y = expression(bold("Index of output (" * Y[t] / Y[0] %*% 100 * ")")),
      colour = NULL, linetype = NULL,
      caption = paste0(
        "The braced gap is everything the measured inputs do not explain. ",
        "On ", lab, " it is the number the whole growth-accounting ",
        "literature is arguing about: name it technology and it is the ",
        "engine of growth; name it what we failed to measure and it is an ",
        "admission. It is the same arithmetic either way."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_04_03: Your Residual Against the CSO's Own Measure ####################
# Note: The app's residual beside the CSO's multifactor productivity (PIA09).
#   "ref" ghosts the app's line only; the CSO's series is published.

D_04_03_irl_mfp_fn <- function(dec, cso_rates, from, to, ref = NULL) {
  a <- dec[dec$year >= from & dec$year <= to & !is.na(dec$residual),
           c("year", "residual")]
  b <- cso_rates[cso_rates$year >= from & cso_rates$year <= to &
                   !is.na(cso_rates$g_mfp), c("year", "g_mfp")]
  if (nrow(b) == 0) {
    return(T_02_02_placeholder_fn(
      "The CSO's own measure covers 2001 to 2019"))
  }

  ghost_lyr <- if (is.null(ref)) NULL else {
    ra <- ref[ref$year >= from & ref$year <= to & !is.na(ref$residual),
              c("year", "residual")]
    if (nrow(ra) == 0 || T_02_03b_ghost_off_fn(a$residual, ra$residual)) {
      NULL
    } else {
      T_02_03a_ghost_path_fn(ra, aes(x = year, y = residual),
                             colour = T_01_02_series_vec[["main"]],
                             linewidth = 1.1)
    }
  }

  long <- rbind(
    data.frame(year = a$year, line = "This app's residual", value = a$residual),
    data.frame(year = b$year, line = "CSO multifactor productivity",
               value = b$g_mfp)
  )
  long$line <- factor(long$line,
                      levels = c("This app's residual",
                                 "CSO multifactor productivity"))

  ggplot(long, aes(x = year, y = value, colour = line, linetype = line)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    geom_point(size = 1.6) +
    scale_colour_manual(values = c(
      "This app's residual"          = T_01_02_series_vec[["main"]],
      "CSO multifactor productivity" = T_01_02_series_vec[["compare"]]
    )) +
    scale_linetype_manual(values = c(
      "This app's residual"          = "solid",
      "CSO multifactor productivity" = "22"
    )) +
    scale_y_continuous(labels = function(v) T_02_06_pct_fn(v, 0)) +
    labs(
      x = NULL,
      y = expression(bold("Annual productivity growth (" *
                            Delta * "ln" ~ A * ")")),
      colour = NULL, linetype = NULL,
      caption = paste(
        "Both lines claim to measure the same thing. The CSO uses hours",
        "worked rather than heads, capital services rather than the capital",
        "stock, and gross value added rather than GDP. Everywhere they",
        "part, the difference is measurement rather than economics. The",
        "CSO series runs to 2019 only."
      )
    ) +
    T_02_01_theme_fn()
}

###### D_04_04: The Two-Speed Economy ##########################################
# Note: PIA09 split into the foreign-dominated sectors and the rest, as
#   indices on 2000 = 100.

D_04_04_irl_split_fn <- function(cso, what = "mfp") {
  d <- cso[cso$sector %in% c("foreign", "domestic"), ]
  if (nrow(d) == 0) return(T_02_02_placeholder_fn("No sector data"))
  d$value <- d[[what]]
  d$label <- ifelse(d$sector == "foreign",
                    "Foreign-dominated sectors", "Domestic and other")
  lab <- c(mfp = "Multifactor productivity",
           labour_prod = "Labour productivity",
           capital_services = "Capital services")[[what]]
  # The base year is the benchmark; A only where the series is productivity
  sym  <- if (what == "mfp") expression(A[t] == A[2000]) else
    expression("2000 level")
  # Two lines with atop(), so the rotated title fits the panel
  ylab <- if (what == "mfp") {
    expression(atop(bold("Index of productivity"),
                    bold("(" * A[t] / A[2000] %*% 100 * ")")))
  } else {
    expression(bold("Index (2000 = 100)"))
  }

  ggplot(d, aes(x = year, y = value, colour = label, linetype = label)) +
    T_02_02_rest_fn(h = 100) +
    geom_line(linewidth = 1.15) +
    T_02_02_mark_y_fn(100, sym) +
    scale_colour_manual(values = c(
      "Foreign-dominated sectors" = T_01_02_series_vec[["main"]],
      "Domestic and other"        = T_01_02_series_vec[["compare"]]
    )) +
    scale_linetype_manual(values = c(
      "Foreign-dominated sectors" = "solid",
      "Domestic and other"        = "22"
    )) +
    labs(
      x = NULL, y = ylab,
      colour = NULL, linetype = NULL,
      caption = paste(
        "The foreign-dominated sectors are NACE 18-21, 26-27, 31-33, 58-63",
        "and 95: pharmaceuticals, electronics, medical devices, software and",
        "computer services. Averaging these two lines into one national",
        "number is what produces an Irish productivity statistic that",
        "describes nobody's experience of working in Ireland."
      )
    ) +
    T_02_01_theme_fn()
}

################################################################################
## E: User Interface ###########################################################
################################################################################
# Note: The sidebar, the worked-example presets and the page.

#### E_01: Sidebar #############################################################
# Note: Mode switch, stage selector, then the controls. The sidebar chooses
#   the model; the presets in the main window (E_01_03) choose what to run.

###### E_01_01: Control Shorthand ##############################################
# Note: Saves passing the same three lists at every call.

E_01_01_ctl_fn <- function(id) {
  T_03_01_control_fn(id, B_03_04_controls_lst, B_03_05_help_lst,
                     B_03_01_defaults_lst)
}

###### E_01_02: Sidebar ########################################################
# Note: conditionalPanel reveals controls as the stages add layers.

E_01_02_sidebar_lst <- sidebar(
  width = 380,
  radioButtons("mode", NULL, inline = TRUE,
               choices = c("Explore the Model" = "model",
                           "Ireland's Accounts" = "ireland"),
               selected = "model"),
  T_03_05_note_fn(paste(
    "The model runs on numbers you choose. Ireland's accounts run the same",
    "identity on the CSO's own series, year by year.")),

  conditionalPanel(
    "input.mode == 'ireland'",
    selectInput("irl_measure", "What to Decompose",
                choices = B_04_04_irl_measures_vec, selected = "gdp"),
    T_03_05_note_fn(paste(
      "GDP is what the identity is usually written for. For Ireland it is",
      "also the measure the multinationals move, so GNI* is the one that",
      "tracks income that stays in the country.")),
    sliderInput("irl_years", "Years",
                min = B_04_05_irl_years_int[1] + 1,
                max = B_04_05_irl_years_int[2],
                value = c(B_04_05_irl_years_int[1] + 1,
                          B_04_05_irl_years_int[2]),
                step = 1, sep = "", width = "100%"),
    T_03_05_note_fn(paste(
      "The window starts where employment does: the Labour Force Survey",
      "begins in 1998, so the first year with a growth rate is 1999.")),
    checkboxInput("irl_cso_alpha",
                  "Use the CSO's own capital share, year by year", FALSE),
    T_03_05_note_fn(paste(
      "The CSO publishes the capital share of gross value added for 2000 to",
      "2019. It runs from about 0.40 to about 0.70, so it is nothing like",
      "the textbook third, and it moves.")),
    E_01_01_ctl_fn("alpha"),
    actionButton("irl_reset", "Reset the Window",
                 class = "btn-outline-secondary btn-sm w-100")
  ),

  conditionalPanel(
    "input.mode == 'model'",
  radioButtons("stage", "Stage of the Model",
               choices = B_03_02_stages_vec, selected = "1"),
  T_03_05_note_fn(paste(
    "Each stage adds one piece to the model and leaves the rest",
    "alone. Start at the top; the equations panel marks what is new.")),
  accordion(
    open = c("What Was Measured"),
    accordion_panel(
      "What Was Measured",
      E_01_01_ctl_fn("g_y"),
      E_01_01_ctl_fn("g_k"),
      E_01_01_ctl_fn("g_l"),
      E_01_01_ctl_fn("g_h"),
      tags$h6("And What Was Assumed"),
      E_01_01_ctl_fn("alpha")
    ),
    accordion_panel(
      "The Country's Position",
      conditionalPanel(
        "parseFloat(input.stage) >= 4",
        E_01_01_ctl_fn("y_rel"),
        E_01_01_ctl_fn("ky_rel"),
        E_01_01_ctl_fn("h_rel")
      ),
      conditionalPanel("parseFloat(input.stage) < 4",
                       tags$p(class = "stat-caption",
                              "Levels appear at stage 4."))
    ),
    accordion_panel(
      "The Cross-Section",
      conditionalPanel(
        "parseFloat(input.stage) >= 5",
        E_01_01_ctl_fn("gap_lo"),
        E_01_01_ctl_fn("n_countries"),
        E_01_01_ctl_fn("noise"),
        E_01_01_ctl_fn("seed")
      ),
      conditionalPanel("parseFloat(input.stage) < 5",
                       tags$p(class = "stat-caption",
                              "Convergence appears at stage 5."))
    )
  ),
  actionButton("reset", "Reset Everything",
               class = "btn-outline-secondary btn-sm w-100"),
  T_07_10b_sidebarqr_fn(B_04_01_qr_src_chr)
  )
)

###### E_01_03: Worked-Example Presets #########################################
# Note: The card of presets for the stage on screen, built by the toolkit
#   (T_05_04 to T_05_07) and mounted above the prompt in the model mode.

E_01_03_presets_lst <- T_05_04_presets_fn(
  B_03_03_scenarios_lst, B_03_02_stages_vec, stage_word = "Stage"
)

#### E_02: Main Panel ##########################################################
# Note: Equations, prompt, readouts, then the figures for this stage.

###### E_02_01: Page ###########################################################
# Note: The full UI object passed to shinyApp().

E_02_01_app_ui_lst <- tagList(
  T_07_08b_nav_fn(),
  page_sidebar(
  title        = T_07_09_title_fn("Growth and Development Accounting",
                                  B_04_01_qr_src_chr),
  window_title = paste("Growth Accounting ·", T_07_01_author_chr),
  fillable     = FALSE,
  theme        = T_07_05_theme_fn(),
  sidebar      = E_01_02_sidebar_lst,
  T_07_08_head_fn(),
  tags$head(
    tags$style(HTML(T_05_07_preset_css_chr)),
    tags$script(HTML(T_05_05_preset_js_chr))
  ),
  navset_card_tab(
    title = textOutput("eq_title", inline = TRUE),
    nav_panel("Equations", uiOutput("eq_model")),
    nav_panel("Notation", uiOutput("eq_notation")),
    nav_panel("In Words", uiOutput("eq_explain"))
  ),
  # --- Ireland's growth accounts ---------------------------------------------
  conditionalPanel(
    "input.mode == 'ireland'",
    uiOutput("irl_intro"),
    uiOutput("irl_tiles"),
    # "irl_years" is the slider's id, so the figure is "irl_bars"
    T_07_07c_figcard_fn("irl_bars", "Contributions, Year by Year",
                        B_03_11_tall_chr),
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("irl_path", "What the Inputs Alone Would Explain",
                          B_03_11_tall_chr),
      T_07_07c_figcard_fn("irl_mfp", "Against the CSO's Own Measure",
                          B_03_11_tall_chr)
    ),
    uiOutput("irl_break"),
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("irl_split", "The Two-Speed Economy",
                          B_03_11_tall_chr),
      T_07_07c_figcard_fn("decades", "The Long View, Decade by Decade",
                          B_03_11_tall_chr)
    ),
    uiOutput("decades_note"),
    card(
      card_header("Year by Year"),
      div(class = "table-responsive", tableOutput("irl_table"))
    ),
    uiOutput("irl_sources")
  ),

  # --- The model --------------------------------------------------------------
  conditionalPanel(
    "input.mode == 'model'",
  E_01_03_presets_lst,
  uiOutput("prompt"),
  uiOutput("problems"),
  uiOutput("tiles"),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(6, 6)),
    T_07_07c_figcard_fn("total", "Growth in Output",
                          B_03_11_tall_chr),
    conditionalPanel(
      "parseFloat(input.stage) >= 2",
      T_07_07c_figcard_fn("worker", "Growth in Output per Worker",
                          B_03_11_tall_chr)
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 3",
    card(
      card_header("What the Residual Rests On"),
      plotOutput("sensitivity", height = B_03_11_tall_chr),
      uiOutput("residual_note")
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 4",
    T_07_07c_figcard_fn("levels", "Why Are Some Countries Rich?",
                          B_03_11_tall_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 5",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("absolute", "Absolute Convergence",
                          B_03_11_tall_chr),
      T_07_07c_figcard_fn("conditional", "Conditional Convergence",
                          B_03_11_tall_chr)
    ),
    uiOutput("causes_note")
  ),
  uiOutput("irish_note")
  ),
  T_07_11_footer_fn(paste0("Notation follows the Part 3 exam questions.",
                           " Version ", B_03_14_version_chr, "."),
                    repo = B_03_15_repo_chr),
))

################################################################################
## F: Server ###################################################################
################################################################################
# Note: Builds the parameter list, runs the model and the Irish accounts,
#   draws.

#### F_01: Server Function #####################################################
# Note: Everything reactive lives inside this function.

###### F_01_01: Server #########################################################
# Note: Local objects use plain snake_case.

F_01_01_app_server_fn <- function(input, output, session) {

  # --- Figure captions --------------------------------------------------------
  # Captions are printed under each figure, not inside the graphics device
  T_07_07d_cap_fn(output)

  # --- Stage as a number ------------------------------------------------------
  stage_num <- reactive(as.numeric(input$stage))

  # --- Controls ---------------------------------------------------------------
  val <- function(id) T_03_04_val_fn(input, id)
  T_03_02_sync_fn(input, session, B_03_04_controls_lst)

  set_control <- function(id, value) {
    T_03_03_set_fn(session, B_03_04_controls_lst, id, value)
  }

  # --- Worked-example presets -------------------------------------------------
  # One observer per preset; the loaded key is set in one place
  scenario <- reactiveVal(names(B_03_03_scenarios_lst)[1])

  # Guarded lookup of the loaded scenario, NULL when none is loaded
  scn_now <- reactive({
    k <- scenario()
    if (is.null(k) || !k %in% names(B_03_03_scenarios_lst)) NULL
    else B_03_03_scenarios_lst[[k]]
  })

  set_scenario_fn <- function(key) {
    scenario(if (is.null(key)) "custom" else key)
    session$sendCustomMessage("dgPreset", if (is.null(key)) "" else key)
    invisible(NULL)
  }

  load_preset_fn <- function(key) {
    if (is.null(key) || !key %in% names(B_03_03_scenarios_lst)) {
      return(invisible(NULL))
    }
    scn <- B_03_03_scenarios_lst[[key]]
    set_scenario_fn(key)
    vals <- utils::modifyList(B_03_01_defaults_lst, scn$values)
    for (id in names(B_03_04_controls_lst)) set_control(id, vals[[id]])
    invisible(NULL)
  }

  lapply(names(B_03_03_scenarios_lst), function(key) {
    observeEvent(input[[paste0("preset_", key)]],
                 load_preset_fn(key), ignoreInit = TRUE)
  })

  # The first example of a stage, or NULL where a stage has none
  first_preset_fn <- function(stage) {
    hits <- names(B_03_03_scenarios_lst)[vapply(
      B_03_03_scenarios_lst, function(x) identical(x$stage, stage), TRUE)]
    if (length(hits) == 0L) NULL else hits[[1L]]
  }

  # Every stage opens on its first worked example; see CONVENTIONS.md 2
  observeEvent(input$stage, {
    first <- first_preset_fn(input$stage)
    if (is.null(first)) set_scenario_fn(NULL) else load_preset_fn(first)
  })

  output$preset_title <- renderUI({
    T_05_06_preset_title_fn(scn_now(), input$stage, B_03_02_stages_vec,
                            stage_word = "")
  })

  # --- Reset ------------------------------------------------------------------
  observeEvent(input$reset, {
    set_scenario_fn(NULL)
    for (id in names(B_03_04_controls_lst)) {
      set_control(id, B_03_01_defaults_lst[[id]])
    }
  })

  # --- Parameters -------------------------------------------------------------
  # A function of a values list, run over the sliders and over the loaded
  # example's values alike; g_a and delta stay at their defaults
  assemble_fn <- function(v) {
    list(
      alpha       = v$alpha,
      g_y         = v$g_y,
      g_k         = v$g_k,
      g_l         = v$g_l,
      g_h         = v$g_h,
      y_rel       = v$y_rel,
      ky_rel      = v$ky_rel,
      h_rel       = v$h_rel,
      n_countries = round(v$n_countries),
      seed        = round(v$seed),
      g_a         = B_03_01_defaults_lst$g_a,
      delta       = B_03_01_defaults_lst$delta,
      noise       = v$noise,
      gap_lo      = v$gap_lo
    )
  }

  par_raw <- reactive({
    req(!is.null(input$alpha))
    vals <- stats::setNames(lapply(names(B_03_04_controls_lst), val),
                            names(B_03_04_controls_lst))
    assemble_fn(vals)
  })

  par_now  <- debounce(par_raw, B_03_12_debounce_ms_int)
  diag_now <- reactive(C_01_07_diagnostics_fn(par_now()))
  ok_now   <- reactive(length(diag_now()$problems) == 0)

  # --- The ghost: each figure at the worked example's own settings ------------
  # Reference values are the loaded example's, or the defaults when none is
  # loaded, so the Irish mode keeps its ghost
  ref_vals <- reactive({
    key <- scenario()
    if (is.null(key) || !key %in% names(B_03_03_scenarios_lst)) {
      return(B_03_01_defaults_lst)
    }
    utils::modifyList(B_03_01_defaults_lst,
                      B_03_03_scenarios_lst[[key]]$values)
  })

  ref_par <- reactive(assemble_fn(ref_vals()))

  ghost_par <- reactive({
    ref <- ref_par()
    if (T_02_03b_ghost_off_fn(par_now(), ref)) NULL else ref
  })

  # --- Scenario story ---------------------------------------------------------
  output$scenario_story <- renderUI({
    T_05_02_story_fn(scn_now(), B_03_04_controls_lst, B_03_05_help_lst)
  })

  # --- The model so far -------------------------------------------------------
  output$eq_title <- renderText({
    T_05_04_stage_name_fn(B_03_02_stages_vec, input$stage)
  })

  eq_items <- reactive(T_06_03_items_fn(B_03_07_equations_lst, stage_num()))

  output$eq_model <- renderUI({
    T_06_04_model_fn(eq_items(), B_03_08_groups_vec,
                     "These appear as the later stages add to the model.")
  })

  output$eq_notation <- renderUI({
    T_06_05_notation_fn(B_03_09_notation_lst, stage_num(),
                        B_03_10_nota_cols_lst, first_stage = 1)
  })

  output$eq_explain <- renderUI({
    T_06_06_explain_fn(eq_items(), B_03_08_groups_vec)
  })

  # --- Prompt and problems ----------------------------------------------------
  output$prompt <- renderUI({
    T_07_12_prompt_fn(scn_now(), input$stage, B_03_06_prompts_lst)
  })

  output$problems <- renderUI(T_07_13_problems_fn(diag_now()$problems))

  # --- Readouts ---------------------------------------------------------------
  output$tiles <- renderUI({
    d <- diag_now()
    s <- stage_num()
    T_04_03_row_fn(
      T_04_01_tile_fn(
        "The residual", T_02_06_pct_fn(d$residual, 2),
        paste0("Of ", T_02_06_pct_fn(par_now()$g_y, 1), " output growth")
      ),
      if (s >= 2) {
        T_04_01_tile_fn(
          "Growth per worker", T_02_06_pct_fn(d$g_worker, 2),
          paste0("Capital deepening: ", T_02_06_pct_fn(d$deepening, 2))
        )
      },
      if (s >= 2) {
        T_04_01_tile_fn(
          "Residual's share of it", T_02_06_pct_fn(d$res_share, 0),
          if (d$res_share > 0.5) "Most of growth is unexplained" else
            "Most of growth is accounted for",
          class = if (d$res_share > 0.5) "bad" else "good"
        )
      },
      if (s >= 4) {
        T_04_01_tile_fn(
          "Implied relative TFP", T_02_05_num_fn(d$tfp_rel, 2),
          paste0(round(d$tfp_share * 100), "% of the income gap"),
          class = "bad"
        )
      },
      if (s >= 5) {
        T_04_01_tile_fn(
          "Absolute convergence", T_02_05_num_fn(d$uncond, 3),
          if (d$absolute) "Poor countries do grow faster here" else
            "No relationship in the raw data",
          class = if (d$absolute) "good" else "bad"
        )
      },
      if (s >= 5) {
        T_04_01_tile_fn(
          "Conditional convergence", T_02_05_num_fn(d$cond, 3),
          "Holding saving and population growth fixed",
          class = "good"
        )
      }
    )
  })

  # --- Figures ----------------------------------------------------------------
  output$total <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_02_total_fn(par_now())
  }) })

  output$worker <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 2)
    D_01_03_worker_fn(par_now())
  }) })

  # --- Ireland's growth accounts ----------------------------------------------
  # The same identity on the CSO's series, at the slider's capital share or
  # the CSO's own
  irl_rates <- reactive({
    C_02_01_irl_rates_fn(
      B_04_02_irl_df,
      if (is.null(input$irl_measure)) "gdp" else input$irl_measure
    )
  })

  irl_dec <- reactive({
    C_02_02_irl_decomp_fn(irl_rates(), val("alpha"), B_04_03_irl_cso_df,
                          isTRUE(input$irl_cso_alpha))
  })

  # Ghost: the same decomposition at the reference share; none when the
  # CSO's share is in use
  irl_dec_ref <- reactive({
    if (isTRUE(input$irl_cso_alpha)) return(NULL)
    a_ref <- ref_vals()$alpha
    if (T_02_03b_ghost_off_fn(val("alpha"), a_ref)) return(NULL)
    C_02_02_irl_decomp_fn(irl_rates(), a_ref, B_04_03_irl_cso_df, FALSE)
  })

  irl_window <- reactive({
    w <- input$irl_years
    if (is.null(w)) c(B_04_05_irl_years_int[1] + 1, B_04_05_irl_years_int[2])
    else w
  })

  irl_avg <- reactive({
    w <- irl_window()
    C_02_03_irl_avg_fn(irl_dec(), w[1], w[2])
  })

  irl_lab <- reactive({
    m <- if (is.null(input$irl_measure)) "gdp" else input$irl_measure
    names(B_04_04_irl_measures_vec)[B_04_04_irl_measures_vec == m]
  })

  observeEvent(input$irl_reset, {
    updateSliderInput(session, "irl_years",
                      value = c(B_04_05_irl_years_int[1] + 1,
                                B_04_05_irl_years_int[2]))
    updateSelectInput(session, "irl_measure", selected = "gdp")
    updateCheckboxInput(session, "irl_cso_alpha", value = FALSE)
    set_control("alpha", B_03_01_defaults_lst$alpha)
  })

  # GDP against GNI* over the window, for the opening narrative
  irl_contrast <- reactive({
    w <- irl_window()
    f <- function(m) {
      d <- C_02_02_irl_decomp_fn(C_02_01_irl_rates_fn(B_04_02_irl_df, m),
                                 val("alpha"), B_04_03_irl_cso_df,
                                 isTRUE(input$irl_cso_alpha))
      C_02_03_irl_avg_fn(d, w[1], w[2])
    }
    list(gdp = f("gdp"), gni = f("gnistar"))
  })

  output$irl_intro <- renderUI({
    k <- irl_contrast()
    w <- irl_window()
    req(k$gdp$years > 0, k$gni$years > 0)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "The Identity, on Ireland's Own Numbers"),
      tags$p(HTML(paste(
        "Everything below is CSO data, decomposed by the identity in the",
        "equations panel. The capital share is still yours to set, because",
        "no dataset settles it. Move it and a faded copy of each line stays",
        "at the share you started from."
      ))),
      tags$p(HTML(paste0(
        "Over ", w[1], " to ", w[2], " Irish GDP grew ",
        T_02_06_pct_fn(k$gdp$g_y, 1), " a year, of which ",
        T_02_06_pct_fn(k$gdp$residual, 1), " is residual",
        if (is.na(k$gdp$share)) "" else
          paste0(", about ", round(abs(k$gdp$share) * 100),
                 "% of measured growth"),
        ", attributed to technology. On GNI* growth is ",
        T_02_06_pct_fn(k$gni$g_y, 1), " a year and the residual ",
        T_02_06_pct_fn(k$gni$residual, 1), ". Capital and employment ",
        "account for almost all of it."
      ))),
      tags$p(HTML(paste(
        "Nothing was revised between those two sentences. Same economy,",
        "same identity, same capital share; a different output series, and",
        "the productivity story is in one and not the other. Whether",
        "Ireland has had a productivity miracle depends on which line of",
        "the national accounts you read."
      )))
    )
  })

  output$irl_tiles <- renderUI({
    a <- irl_avg()
    req(a$years > 0)
    w <- irl_window()
    d <- irl_dec()
    a_bar <- mean(d$alpha[d$year >= w[1] & d$year <= w[2]], na.rm = TRUE)
    T_04_03_row_fn(
      T_04_01_tile_fn(paste0("Growth in ", irl_lab()),
                      T_02_06_pct_fn(a$g_y, 1),
                      paste0("a year, ", w[1], " to ", w[2])),
      T_04_01_tile_fn("From capital", T_02_06_pct_fn(a$capital, 1),
                      paste0("at a capital share of ",
                             T_02_05_num_fn(a_bar, 2))),
      T_04_01_tile_fn("From employment", T_02_06_pct_fn(a$labour, 1),
                      "persons, not hours"),
      T_04_01_tile_fn("The residual", T_02_06_pct_fn(a$residual, 1),
                      if (is.na(a$share)) "everything unexplained" else
                        paste0(round(a$share * 100),
                               "% of measured growth"))
    )
  })

  output$irl_bars <- renderPlot({ T_02_01c_draw_fn({
    w <- irl_window()
    D_04_01_irl_years_fn(irl_dec(), w[1], w[2], irl_lab())
  }) })

  output$irl_path <- renderPlot({ T_02_01c_draw_fn({
    w  <- irl_window()
    rd <- irl_dec_ref()
    D_04_02_irl_path_fn(
      C_02_04_irl_path_fn(irl_dec(), w[1], w[2]), irl_lab(),
      ref = if (is.null(rd)) NULL else C_02_04_irl_path_fn(rd, w[1], w[2]))
  }) })

  output$irl_mfp <- renderPlot({ T_02_01c_draw_fn({
    w <- irl_window()
    D_04_03_irl_mfp_fn(irl_dec(), C_02_05_irl_cso_fn(B_04_03_irl_cso_df),
                       w[1], w[2], ref = irl_dec_ref())
  }) })

  output$irl_split <- renderPlot({ T_02_01c_draw_fn({
    D_04_04_irl_split_fn(B_04_03_irl_cso_df, "mfp")
  }) })

  output$irl_break <- renderUI({
    d <- irl_dec()
    r <- d[d$year == 2015, ]
    if (nrow(r) == 0 || is.na(r$g_y)) return(NULL)
    w <- irl_window()
    if (w[1] > 2015 || w[2] < 2015) return(NULL)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "2015, and What an Identity Cannot See"),
      tags$p(HTML(paste0(
        "In 2015 measured ", irl_lab(), " grew ",
        T_02_06_pct_fn(r$g_y, 1), " and the net capital stock grew ",
        T_02_06_pct_fn(r$g_k, 1), ", both because multinationals moved ",
        "intellectual property and aircraft-leasing balance sheets into ",
        "the Irish accounts. No factory was built and no job changed. The ",
        "identity sees only a capital series and an output series, so it ",
        "cannot tell a relocated balance sheet from a new machine."
      ))),
      tags$p(HTML(paste0(
        "On GNI*, which strips out the depreciation and profits of ",
        "foreign-owned capital, 2015 is unremarkable. That is the case for ",
        "GNI* in one slider."
      )))
    )
  })

  output$irl_table <- renderTable({
    w <- irl_window()
    d <- irl_dec()
    d <- d[d$year >= w[1] & d$year <= w[2] & !is.na(d$g_y), ]
    data.frame(
      Year          = as.integer(d$year),
      `Output`      = T_02_06_pct_fn(d$g_y, 1),
      `Capital`     = T_02_06_pct_fn(d$g_k, 1),
      `Employment`  = T_02_06_pct_fn(d$g_l, 1),
      `Capital share` = T_02_05_num_fn(d$alpha, 2),
      `From capital`  = T_02_06_pct_fn(d$capital, 1),
      `From labour`   = T_02_06_pct_fn(d$labour, 1),
      `Residual`      = T_02_06_pct_fn(d$residual, 1),
      check.names = FALSE, stringsAsFactors = FALSE
    )
  }, striped = TRUE, hover = TRUE, width = "100%", align = "lrrrrrrr")

  output$irl_sources <- renderUI({
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Where Every Number Comes From"),
      tags$p(HTML(paste(
        "Output is GDP and GNP at constant market prices, CSO table NA006,",
        "and modified gross national income (GNI*) at constant market",
        "prices, CSO table NA002, both from 1995. Capital is the net stock",
        "of fixed assets at constant prices, all assets and all NACE",
        "sectors, CSO table CSA02, from 1985. Labour is persons aged 15 and",
        "over in employment, averaged over the four quarters, CSO table",
        "QLF01, from 1998."
      ))),
      tags$p(HTML(paste(
        "The CSO's own productivity accounts, table PIA09, 2000 to 2019,",
        "give multifactor productivity, labour and capital input and the",
        "GVA factor shares, for the whole economy and for its foreign- and",
        "domestic-dominated halves. They use capital services and hours;",
        "this app uses the capital stock and heads, which is why the two",
        "residuals differ."
      ))),
      tags$p(class = "nar-source", HTML(paste(
        "All series come from the CSO's PxStat API and ship with the app,",
        "so nothing here depends on being online. Growth rates are log",
        "differences. Chain-linked volume series are revised between",
        "vintages, so the CSO has published more than one figure for the",
        "same year."
      )))
    )
  })

  output$decades_note <- renderUI({
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Behind the Decade Figure"),
      tags$p(HTML(paste(
        "The three series are the Penn World Table's, because no Irish",
        "source carries all three back that far. The CSO's constant-price",
        "GDP and GNP run from 1970, its net capital stock from 1985 and",
        "employment on the ILO definition from 1998, so before those dates",
        "the numbers here are not Irish official statistics. The 2010s bar",
        "is dominated by 2015 alone."
      ))),
      tags$p(class = "nar-source", HTML(paste(
        "Sources: Penn World Table 10.01 (rgdpna, rnna, emp), Ireland,",
        "decade averages. CSO coverage from",
        "<em>Historical National Income and Expenditure Tables",
        "1970&ndash;1995</em>,",
        "<em>Estimates of the Capital Stock of Fixed Assets</em> (CSA02,",
        "1985&ndash;) and the <em>Labour Force Survey</em>",
        "(QLF01, 1998&ndash;). The capital share is yours to set: the Penn",
        "World Table's Irish labour share is one imputed figure repeated",
        "for every year before 1996, so it is not used here."
      )))
    )
  })

  output$decades <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_04_decades_fn(par_now())
  }) })

  output$sensitivity <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 3)
    D_02_01_sensitivity_fn(par_now(), ref = ghost_par())
  }) })

  output$levels <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_02_02_levels_fn(par_now())
  }) })

  output$absolute <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 5)
    D_03_01_absolute_fn(par_now())
  }) })

  output$conditional <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 5)
    D_03_02_conditional_fn(par_now())
  }) })

  output$residual_note <- renderUI({
    req(stage_num() >= 3)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "What Is in the Residual"),
      tags$p(HTML(paste(
        "The residual is not measured. It is whatever makes the identity",
        "hold, so it contains technical progress along with unmeasured",
        "capital utilisation, quality changes in capital and labour that",
        "the input series miss, economies of scale and the reallocation of",
        "workers to more productive uses. Abramovitz called it the measure",
        "of our ignorance, and the name has stuck because it is accurate."
      ))),
      tags$p(HTML(paste(
        "This is why the East Asian debate mattered. Growth that is mostly",
        "accumulation must slow, because capital has diminishing returns;",
        "growth that is mostly residual need not. The accounting cannot",
        "settle which, because the answer turns on the capital share and",
        "the capital series, and both are contested. Growth accounting",
        "organises the question rather than answering it."
      )))
    )
  })

  # --- Where the Irish numbers come from --------------------------------------
  # Shown while an Irish worked example is loaded; CSO figures, and the
  # ESRI's labour-share range
  output$irish_note <- renderUI({
    req(isTRUE(scenario() %in% c("ireland2015", "ireland2023", "irishalpha")))
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Where These Numbers Come From"),
      tags$p(HTML(paste(
        "In 2015 real GDP grew 24.6% and the net capital stock at constant",
        "prices 24.7%, together and for the same reason. Employment rose",
        "3.4%. Real GNI*, which excludes the depreciation and profits of",
        "relocated foreign capital, grew 1.8%. The first estimate of 2015",
        "GDP growth, published in July 2016, was 26.3%."
      ))),
      tags$p(HTML(paste(
        "In 2023 real GDP fell 3.3%, the net capital stock was flat,",
        "employment rose 3.4% and real GNI* rose 6.1%. The Ireland's",
        "Accounts mode shows every year on the same basis, with this app's",
        "residual beside the CSO's own multifactor productivity measure."
      ))),
      tags$p(HTML(paste(
        "The CSO puts the labour share of gross value added in 2023 at",
        "about 32% for the total economy, 53.5% in the domestic sector and",
        "10.2% in the foreign sector. The ESRI, working on GNI*, recommends",
        "a labour share of 0.5 to 0.6 for Irish macroeconomic modelling. So",
        "&alpha; is 0.68, 0.47 or 0.4 to 0.5, depending on the question."
      ))),
      tags$p(class = "nar-source", HTML(paste(
        "Sources: CSO, <em>Annual National Accounts</em>;",
        "<em>Estimates of the Capital Stock of Fixed Assets</em>;",
        "<em>Productivity in Ireland 2022&ndash;2023</em>;",
        "<em>Labour Force Survey</em>. ESRI Research Note,",
        "<em>Estimating Ireland's Labour Share</em> (2024).",
        "Growth rates are revised between vintages: the CSO has published",
        "&minus;5.5%, &minus;2.5% and &minus;3.3% for 2023 GDP in three",
        "successive releases."
      )))
    )
  })

  output$causes_note <- renderUI({
    req(stage_num() >= 5)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Proximate and Fundamental Causes"),
      tags$p(HTML(paste(
        "Capital, human capital and productivity are proximate causes of",
        "income: they produce output directly, and the accounting above",
        "measures them. They are also outcomes. Asking why one country has",
        "more of them than another is asking about fundamental causes,",
        "usually institutions, geography and culture. Testing this is hard",
        "because countries with good institutions are rich, rich countries",
        "can afford good institutions, and something else may drive both; a",
        "regression of income on institutions cannot separate the three."
      ))),
      tags$p(HTML(paste(
        "European colonisation supplies variation in institutions that is",
        "plausibly unrelated to income today except through institutions.",
        "Where the disease environment let Europeans settle in numbers they",
        "built institutions that protected property, because they expected",
        "to live under them; where it did not they built extractive ones.",
        "Those arrangements persisted through independence, so early",
        "settler mortality predicts the quality of institutions centuries",
        "later and can serve as an instrument for them."
      ))),
      tags$p(HTML(paste(
        "The instrument is valid only if settler mortality affects income",
        "today through nothing but institutions. Disease environments also",
        "affect health, agriculture and human capital directly, which is",
        "the main objection to the result, along with the quality of the",
        "historical mortality data."
      )))
    )
  })
}

################################################################################
## G: Run ######################################################################
################################################################################
# Note: Launch.

#### G_01: Launch ##############################################################
# Note: Returns the app object.

###### G_01_01: The App ########################################################
# Note: UI from E, server from F.

G_01_01_app_lst <- shinyApp(E_02_01_app_ui_lst, F_01_01_app_server_fn)

G_01_01_app_lst

#--------------------------------- Script End ---------------------------------#
