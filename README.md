# ZyVOP Publish Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-ZyVOP%20Publish-blue?logo=github&logoColor=white)](https://github.com/marketplace/actions/zyvop-publish)

Publish Markdown articles to [ZyVOP](https://zyvop.com) and optionally syndicate
them to the destinations selected in each article's frontmatter.

## Usage

```yaml
name: Publish with ZyVOP

on:
  push:
    branches: [main]
    paths:
      - "posts/**/*.md"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: zyvop/publish-action@v1
        env:
          ZYVOP_TOKEN: ${{ secrets.ZYVOP_TOKEN }}
```

The action publishes only Markdown files changed by a push. On a manual run,
first push, or unavailable base commit, it safely processes all tracked files
matching `posts`.

Give every article a stable `canonical_url`, `zyvop_id`, or `slug` so future
runs update the existing article rather than creating another one.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `posts` | `:(glob)posts/**/*.md` | Git pathspec selecting articles. |
| `changed-only` | `true` | Publish only files changed by the current push. |
| `local` | `false` | Publish directly to providers using runner secrets. |
| `dry-run` | `false` | Validate without publishing. |
| `endpoint` | empty | Optional custom ZyVOP GraphQL endpoint. |
| `cli-version` | `1.1.1` | Exact npm CLI version to execute. |

The `published-count` output contains the number of files successfully
processed.

## Direct provider mode

Set `local: "true"` to keep provider credentials in GitHub Actions instead of
using integrations connected in ZyVOP:

```yaml
- uses: zyvop/publish-action@v1
  with:
    local: "true"
  env:
    ZYVOP_TOKEN: ${{ secrets.ZYVOP_TOKEN }}
    ZYVOP_DEVTO_API_KEY: ${{ secrets.ZYVOP_DEVTO_API_KEY }}
    ZYVOP_HASHNODE_API_KEY: ${{ secrets.ZYVOP_HASHNODE_API_KEY }}
```

Add only the provider secrets selected by your articles. Supported variables
are documented in the [ZyVOP CLI repository](https://github.com/zyvop/zyvop-cli).

## Release checklist

1. Create a public GitHub repository named `zyvop/publish-action`.
2. Push this repository and tag the first release, for example `v1.0.0`.
3. Publish the release to GitHub Marketplace.
4. Create or update the moving `v1` tag after each compatible release.

## License

MIT
