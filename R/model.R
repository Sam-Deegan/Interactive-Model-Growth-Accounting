################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Growth and Development Accounting: Model                                   ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Sourced automatically by app.R. Can be sourced alone from a lecture
##   .qmd so slide figures come from the same model:
##     source("R/model.R")
##
## Inputs:
##   None. C_01 functions are pure functions of a parameter list "par";
##   C_02 functions take the Irish data frames read by app.R.
##
## Outputs:
##   C_01_* functions: growth and development accounting, the synthetic
##   cross-section, convergence regressions, readouts.
##   C_02_* functions: the same identity on the CSO's Irish series.
##
## The model (Romer 2019, ch. 1 notation):
##   Production:  Y = A K^alpha (h L)^(1 - alpha)
##   Identity:    dlnY = dlnA + alpha dlnK + (1 - alpha)(dlnh + dlnL)
##   Per worker:  dln(Y/L) = dlnA + alpha dln(K/L) + (1 - alpha) dlnh
##   Levels:      y = (K/Y)^(alpha / (1 - alpha)) h A
##
##   Everything except dlnA is measured, so dlnA is what is left over: the
##   Solow residual (Solow 1957). Development accounting applies the same
##   arithmetic to levels: a country's income relative to the frontier
##   splits into capital intensity, human capital and productivity
##   (Romer 2019, ch. 4).
##
## Parameter list (par) elements:
##   alpha, g_y, g_k, g_l, g_h, y_rel, ky_rel, h_rel, n_countries, seed,
##   g_a, delta, noise, gap_lo
##
## References:
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 1 (growth
##     accounting, convergence), ch. 4 (development accounting).
##   Solow, R. (1957). Technical change and the aggregate production
##     function. Review of Economics and Statistics 39(3).
##   Abramovitz, M. (1956). Resource and output trends in the United States
##     since 1870. American Economic Review 46(2).

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C_01 and C_02 hold the model; app.R holds sections B, D, E, F and G.
#
#   C: Model
#     C_01  Accounting for growth and for levels
#       C_01_01  The growth decomposition
#       C_01_02  Per worker
#       C_01_03  The residual against the capital share
#       C_01_04  Development accounting
#       C_01_05  A synthetic cross-section
#       C_01_06  Convergence regressions
#       C_01_07  Readouts
#       C_01_08  Problems with the calibration
#     C_02  Ireland's growth accounts
#       C_02_01  Growth rates of the Irish series
#       C_02_02  The decomposition, year by year
#       C_02_03  Averages over a window
#       C_02_04  The counterfactual path
#       C_02_05  The CSO's own decomposition
#       C_02_06  Readouts for the Irish mode

################################################################################
## C: Model ####################################################################
################################################################################
# Note: Pure functions. Nothing here touches Shiny.

#### C_01: Accounting for Growth and for Levels ################################
# Note: The identity, the residual, and what it does and does not explain.

###### C_01_01: The Growth Decomposition #######################################
# Note: Contributions to growth in output. The residual is output growth
#   minus the measured inputs (Romer 2019, ch. 1; Solow 1957).

C_01_01_growth_fn <- function(par) {
  capital <- par$alpha * par$g_k
  labour  <- (1 - par$alpha) * par$g_l
  human   <- (1 - par$alpha) * par$g_h
  residual <- par$g_y - capital - labour - human

  data.frame(
    source = c("Capital", "Labour", "Human capital", "Residual (TFP)"),
    growth = c(capital, labour, human, residual),
    share  = c(capital, labour, human, residual) / par$g_y,
    stringsAsFactors = FALSE
  )
}

###### C_01_02: Per Worker #####################################################
# Note: The same identity for output per worker. Labour drops out and
#   capital deepening replaces capital.

C_01_02_worker_fn <- function(par) {
  deepening <- par$alpha * (par$g_k - par$g_l)
  human     <- (1 - par$alpha) * par$g_h
  g_worker  <- par$g_y - par$g_l
  residual  <- g_worker - deepening - human

  data.frame(
    source = c("Capital deepening", "Human capital", "Residual (TFP)"),
    growth = c(deepening, human, residual),
    share  = c(deepening, human, residual) / g_worker,
    stringsAsFactors = FALSE
  )
}

###### C_01_03: How the Residual Depends on the Capital Share ##################
# Note: The residual per worker at each capital share on a grid. It is
#   inferred, not measured, so it inherits every assumption about the inputs.

C_01_03_sensitivity_fn <- function(par, n = 200) {
  grid <- seq(0.15, 0.65, length.out = n)
  res  <- vapply(grid, function(a) {
    (par$g_y - par$g_l) - a * (par$g_k - par$g_l) - (1 - a) * par$g_h
  }, 0)
  data.frame(alpha = grid, residual = res,
             share = res / (par$g_y - par$g_l))
}

###### C_01_04: Development Accounting #########################################
# Note: The same arithmetic applied to levels (Romer 2019, ch. 4). Given
#   income, capital intensity and human capital relative to the frontier,
#   productivity is what is left.

C_01_04_levels_fn <- function(par) {
  power   <- par$alpha / (1 - par$alpha)
  capital <- par$ky_rel^power
  human   <- par$h_rel
  tfp     <- par$y_rel / (capital * human)

  ln_total <- log(par$y_rel)
  parts <- c(capital = log(capital), human = log(human), tfp = log(tfp))

  list(
    tfp_rel = tfp,
    parts   = parts,
    table   = data.frame(
      source = c("Capital intensity", "Human capital", "Productivity (TFP)"),
      ratio  = c(capital, human, tfp),
      log    = unname(parts),
      share  = unname(parts) / ln_total,
      stringsAsFactors = FALSE
    )
  )
}

###### C_01_05: A Synthetic Cross-Section ######################################
# Note: Solow economies that differ in saving rates and population growth,
#   and so in their steady states, each starting below its own steady state.

C_01_05_countries_fn <- function(par) {
  set.seed(par$seed)
  n <- par$n_countries

  saving <- stats::runif(n, 0.05, 0.45)
  pop    <- stats::runif(n, 0.005, 0.040)
  be     <- pop + par$g_a + par$delta
  k_star <- (saving / be)^(1 / (1 - par$alpha))
  y_star <- k_star^par$alpha

  # Starting position relative to the country's own steady state
  gap0   <- stats::runif(n, par$gap_lo, 1)
  y0     <- y_star * gap0^par$alpha

  lambda <- (1 - par$alpha) * be
  growth <- par$g_a + lambda * (log(y_star) - log(y0)) +
    stats::rnorm(n, 0, par$noise)

  data.frame(
    country = seq_len(n),
    saving  = saving,
    pop     = pop,
    y_start = y0,
    y_star  = y_star,
    growth  = growth
  )
}

###### C_01_06: Convergence Regressions ########################################
# Note: Growth on initial income, without and with controls for saving and
#   population growth: absolute and conditional convergence (Romer ch. 1).

C_01_06_convergence_fn <- function(df) {
  uncond <- stats::lm(growth ~ log(y_start), data = df)
  cond   <- stats::lm(growth ~ log(y_start) + log(saving) + log(pop),
                      data = df)

  list(
    uncond_slope = unname(stats::coef(uncond)[2]),
    cond_slope   = unname(stats::coef(cond)[2]),
    uncond_r2    = summary(uncond)$r.squared,
    cond_r2      = summary(cond)$r.squared,
    uncond_fit   = uncond,
    cond_fit     = cond,
    residuals    = data.frame(
      y_resid = stats::resid(stats::lm(log(y_start) ~ log(saving) + log(pop),
                                       data = df)),
      g_resid = stats::resid(stats::lm(growth ~ log(saving) + log(pop),
                                       data = df))
    )
  )
}

###### C_01_07: Readouts #######################################################
# Note: The numbers shown in the tiles above the figures.

C_01_07_diagnostics_fn <- function(par) {
  grow <- C_01_01_growth_fn(par)
  work <- C_01_02_worker_fn(par)
  lev  <- C_01_04_levels_fn(par)
  cty  <- C_01_05_countries_fn(par)
  con  <- C_01_06_convergence_fn(cty)

  list(
    g_worker    = par$g_y - par$g_l,
    residual    = grow$growth[grow$source == "Residual (TFP)"],
    res_share   = work$share[work$source == "Residual (TFP)"],
    deepening   = work$growth[work$source == "Capital deepening"],
    tfp_rel     = lev$tfp_rel,
    tfp_share   = lev$table$share[lev$table$source == "Productivity (TFP)"],
    cap_share   = lev$table$share[lev$table$source == "Capital intensity"],
    uncond      = con$uncond_slope,
    cond        = con$cond_slope,
    absolute    = con$uncond_slope < -0.002,
    problems    = C_01_08_problems_fn(par)
  )
}

###### C_01_08: Problems with the Calibration ##################################
# Note: Warnings shown above the figures when the calibration stops making
#   sense.

C_01_08_problems_fn <- function(par) {
  out <- character(0)

  if (isTRUE(abs(par$g_y - par$g_l) < 1e-6)) {
    out <- c(out, paste(
      "Output and employment are growing at the same rate, so output per",
      "worker is not growing and the shares below have nothing to divide."
    ))
  }
  if (isTRUE(par$y_rel <= 0) || isTRUE(par$y_rel > 1.5)) {
    out <- c(out, paste(
      "Relative income should be a positive fraction of the frontier's.",
      "Set it between 0.02 and 1."
    ))
  }
  out
}

#### C_02: Ireland's Growth Accounts ###########################################
# Note: The same identity as C_01, applied to the CSO series in data/ rather
#   than to slider values. The series are described in README.md.

###### C_02_01: Growth Rates of the Irish Series ###############################
# Note: Log differences of output, capital and employment; the identity is
#   additive in logs.

C_02_01_irl_rates_fn <- function(df, measure = "gdp") {
  y <- df[[measure]]
  n <- nrow(df)
  g <- function(v) c(NA_real_, diff(log(v)))

  data.frame(
    year    = df$year,
    output  = y,
    g_y     = g(y),
    g_k     = g(df$capital),
    g_l     = g(df$emp),
    stringsAsFactors = FALSE
  )
}

###### C_02_02: The Decomposition, Year by Year ################################
# Note: alpha is one chosen number or the CSO's GVA capital share for the
#   year (PIA09, 2000 to 2019); missing years carry the nearest share, flagged.

C_02_02_irl_decomp_fn <- function(rates, alpha, cso = NULL,
                                  use_cso = FALSE) {
  a <- rep(alpha, nrow(rates))
  carried <- rep(FALSE, nrow(rates))

  if (use_cso && !is.null(cso)) {
    tot <- cso[cso$sector == "total", c("year", "capital_share")]
    a   <- tot$capital_share[match(rates$year, tot$year)]
    carried <- is.na(a)
    if (all(is.na(a))) {
      a <- rep(alpha, nrow(rates))
      carried <- rep(FALSE, nrow(rates))
    } else {
      # Carry the nearest available share backward and forward
      ok <- which(!is.na(a))
      a[seq_len(min(ok) - 1)]            <- a[min(ok)]
      if (max(ok) < length(a)) {
        a[(max(ok) + 1):length(a)]       <- a[max(ok)]
      }
      for (i in seq_along(a)) if (is.na(a[i])) a[i] <- a[i - 1]
    }
  }

  out <- rates
  out$alpha    <- a
  out$carried  <- carried
  out$capital  <- a * rates$g_k
  out$labour   <- (1 - a) * rates$g_l
  out$residual <- rates$g_y - out$capital - out$labour
  out
}

###### C_02_03: Averages Over a Window #########################################
# Note: Means of the annual log changes over the window, which is the
#   average annual compound rate.

C_02_03_irl_avg_fn <- function(dec, from, to) {
  d <- dec[dec$year >= from & dec$year <= to & !is.na(dec$g_y), ]
  if (nrow(d) == 0) {
    return(list(years = 0, g_y = NA, capital = NA, labour = NA,
                residual = NA, share = NA))
  }
  list(
    years    = nrow(d),
    g_y      = mean(d$g_y),
    capital  = mean(d$capital),
    labour   = mean(d$labour),
    residual = mean(d$residual),
    share    = if (abs(mean(d$g_y)) > 1e-9) {
      mean(d$residual) / mean(d$g_y)
    } else {
      NA_real_
    }
  )
}

###### C_02_04: The Counterfactual Path ########################################
# Note: Index paths of measured output and of the level capital and labour
#   alone imply; the gap between them is the cumulated residual.

C_02_04_irl_path_fn <- function(dec, from, to) {
  d <- dec[dec$year >= from & dec$year <= to & !is.na(dec$g_y), ]
  if (nrow(d) == 0) return(d)
  inputs <- cumsum(d$capital + d$labour)
  actual <- cumsum(d$g_y)
  data.frame(
    year     = d$year,
    actual   = 100 * exp(actual),
    inputs   = 100 * exp(inputs),
    stringsAsFactors = FALSE
  )
}

###### C_02_05: The CSO's Own Decomposition ####################################
# Note: PIA09, the CSO's productivity accounts, 2000 to 2019, indices on
#   2000 = 100. Hours, capital services and GVA rather than heads, stock, GDP.

C_02_05_irl_cso_fn <- function(cso, sector = "total") {
  d <- cso[cso$sector == sector, ]
  d <- d[order(d$year), ]
  g <- function(v) c(NA_real_, diff(log(v)))
  data.frame(
    year         = d$year,
    sector       = sector,
    g_mfp        = g(d$mfp),
    g_prod       = g(d$labour_prod),
    g_gva        = g(d$gva),
    g_capital    = g(d$capital_services),
    g_hours      = g(d$labour_hours),
    capital_share = d$capital_share,
    stringsAsFactors = FALSE
  )
}

###### C_02_06: Readouts for the Irish Mode ####################################
# Note: The tiles above the Irish figures.

C_02_06_irl_tiles_fn <- function(avg, measure_lab, from, to) {
  list(
    g_y      = avg$g_y,
    capital  = avg$capital,
    labour   = avg$labour,
    residual = avg$residual,
    share    = avg$share,
    label    = measure_lab,
    window   = paste0(from, " to ", to),
    years    = avg$years
  )
}

#--------------------------------- Script End ---------------------------------#
