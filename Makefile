PKG := liminal2
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL := $(PKG)_$(VERSION).tar.gz

.PHONY: document test build check clean

document:
	Rscript -e 'roxygen2::roxygenise()'

test:
	Rscript -e 'testthat::test_local(".")'

build:
	R CMD build .

check: build
	R CMD check --as-cran --no-manual $(TARBALL)

clean:
	rm -rf $(PKG).Rcheck ..Rcheck $(TARBALL)
