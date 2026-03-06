# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`regmedint` is an R package for regression-based causal mediation analysis with interaction and effect modification terms. It extends Valeri & VanderWeele (2013, 2015) to support effect measure modification by covariates (Li et al 2023). Compatible with the SAS `%mediation` macro and `PROC CAUSALMED`.

## Build & Development Commands

All commands run from the repo root. The `Makefile` automates most workflows:

```
make test             # Run testthat tests via devtools::test()
make build            # Build .tar.gz package
make check            # R CMD check --as-cran
make check_devtools   # devtools::check()
make install          # Install package locally
make lint             # Run lintr
make vignettes        # Build vignettes in inst/doc
make readme           # Render README.Rmd → README.md
make pkgdown          # Build package website
make clean            # Remove build artifacts
```

Run a single test file:

```r
Rscript -e 'devtools::test(filter = "01_regmedint_class_ui")'
```

Regenerate NAMESPACE and .Rd files after changing roxygen comments:

```r
Rscript -e 'devtools::document(".")'
```

## Architecture

### Pipeline

The package follows a three-step pipeline, orchestrated by `new_regmedint()` in `02_regmedint_class_constructor.R`:

1. **Mediator model** (`fit_mreg` in `03_`): fits linear (`lm`) or logistic (`glm`) regression for the mediator
2. **Outcome model** (`fit_yreg` in `04_`): fits one of 8 outcome models (linear, logistic, loglinear, poisson, negbin, survCox, survAFT_exp, survAFT_weibull)
3. **Mediation effects** (`calc_myreg` in `05_`): dispatches to one of 4 specialised calculators in `07_` files based on the (mreg, yreg) combination

### File Numbering Convention

Source files are numbered `00_`–`08_` to indicate dependency order:

- `00_`: Package-level docs and data documentation
- `01_`: User-facing `regmedint()` function and argument validation
- `02_`: Internal S3 constructor (`new_regmedint`)
- `03_`: Mediator model fitting
- `04_`: Outcome model fitting
- `05_`: Dispatcher — selects the correct calculator for the (mreg, yreg) pair
- `06_`: Helpers for coefficient extraction (`beta_hat`, `theta_hat`) and variance-covariance matrix construction (`Sigma_beta_hat`, `Sigma_theta_hat`). These pad vectors/matrices with zeros to maintain consistent dimensions across model configurations
- `07_`: Four specialised calculators (one per mreg×yreg-class combination), implementing VanderWeele 2015 Propositions 2.3–2.6. All non-linear yreg types share the logistic pathway
- `08_`: S3 methods (print, summary, coef, vcov, confint)

### Key Design Patterns

- **S3 class** with three-tier construction: user function `regmedint()` → constructor `new_regmedint()` → validator `validate_regmedint()`
- **Closure-based evaluation**: `calc_myreg_*` functions return `est_fun` and `se_fun` closures that capture model coefficients and covariance matrices, allowing re-evaluation at different (a0, a1, m_cde, c_cond) without refitting
- **Delta method SEs**: Standard errors computed via multivariate delta method (Jacobian × joint covariance × Jacobian^T)
- **Coefficient padding**: `beta_hat()` and `theta_hat()` in `06_` always return fixed-length vectors with zeros for absent terms (no interaction, no covariates, Cox missing intercept), ensuring downstream calculations work uniformly

### Model Dispatch

The 4 calculators cover all 16 model combinations:

| mreg \ yreg | linear | logistic/loglinear/poisson/negbin/survCox/AFT_exp/AFT_weibull |
|-------------|--------|--------------------------------------------------------------|
| linear      | `07_mreg_linear_yreg_linear` | `07_mreg_linear_yreg_logistic` |
| logistic    | `07_mreg_logistic_yreg_linear` | `07_mreg_logistic_yreg_logistic` |

### Effect Measures

Seven quantities are computed: cde (controlled direct effect), pnde (pure natural direct effect), tnie (total natural indirect effect), tnde (total natural direct effect), pnie (pure natural indirect effect), te (total effect), pm (proportion mediated).

## Testing

Tests use `testthat` with BDD-style `describe`/`it` blocks. Test files mirror source file numbering. The key validation approach:

- `tests/reference_results/` contains SAS macro output (`.txt` extracted from `.lst` files) for all 16 model combinations × interaction/no-interaction × with/without covariates
- `test-09_cross_check_with_sas_macro.R` compares R results against these SAS reference values
- `tests/reference_results/02_generate_sas_macro_calls.R` generates the SAS scripts; running SAS requires a Linux server with `sas` installed

## CI

GitHub Actions workflow (`.github/workflows/R-CMD-check.yaml`) runs on push/PR to main across Windows, macOS, and Ubuntu (release + devel). All actions are pinned to full commit SHAs. Fails on warnings.
