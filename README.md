# liminal2

<!-- Describe the new implementation here. -->

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
make document
make test
make check
```

`make check` builds the tarball and runs `R CMD check` with `--no-manual`.

## License

MIT (c) 2026 ixpantia.
