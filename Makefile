PKG := liminal2
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL := $(PKG)_$(VERSION).tar.gz

.PHONY: document test build check benchmark clean

document:
	Rscript -e 'roxygen2::roxygenise()'

test:
	Rscript -e 'testthat::test_local(".")'

build:
	R CMD build .

check: build
	R CMD check --as-cran --no-manual $(TARBALL)

benchmark:
	Rscript bench/run_benchmark.R --seed 42 --out bench/results.csv

clean:
	rm -rf $(PKG).Rcheck ..Rcheck $(TARBALL)
