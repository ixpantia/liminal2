# liminal2

<!-- badges: start -->
[![R-CMD-check](https://github.com/ixpantia/liminal2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ixpantia/liminal2/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/ixpantia/liminal2/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/ixpantia/liminal2/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

`liminal2` estimates the size of the liminal space of challenges in data
science and engineering.

## Installation

This project uses [`rv`](https://a2-ai.github.io/rv-docs/) to manage
dependencies.

```sh
rv sync
R CMD INSTALL .
```

## Development

```sh
rv sync
Rscript -e 'roxygen2::roxygenise()'
R CMD build .
R CMD check --no-manual liminal2_0.0.0.9000.tar.gz
```

Reference documentation is generated with roxygen2 and the website with
pkgdown.

## License

MIT (c) 2026 ixpantia.
