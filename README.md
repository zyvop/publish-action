# ZyVOP Publish Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-ZyVOP%20Publish-blue?logo=github&logoColor=white)](https://github.com/marketplace/actions/zyvop-publish)

Publish Markdown posts from your repository to [ZyVOP](https://zyvop.com) on
every push, and cross-post them to Dev.to, Hashnode, Medium, WordPress and
Bluesky. Each article chooses its destinations in its own frontmatter.

Core publishing and syndication are free. See [pricing](https://zyvop.com/pricing).

## Quick start

1. Create a ZyVOP developer token (see the [docs](https://docs.zyvop.com)) and
   save it as a repository secret named `ZYVOP_TOKEN`.
2. Connect the destinations you want in ZyVOP under Settings > Integrations,
   or use [direct provider mode](#direct-provider-mode) to keep those
   credentials in GitHub Actions instead.
3. Add a Markdown file under `posts/`:

   ```markdown
   ---
   title: My first post
   canonical_url: https://example.com/my-first-post
   cross_post:
     devto: true
     hashnode: true
   ---

   Post body in Markdown.
   ```

4. Add `.github/workflows/publish.yml`:

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

5. Push to `main`. The action publishes the Markdown files changed in that push.

To check a setup without publishing anything, set `dry-run: "true"`. A dry run
does not need `ZYVOP_TOKEN`.

Example output (abridged):

```text
Publishing posts/my-first-post.md with zyvop@1.1.1...
Article published successfully!
ZyVOP Live URL:  https://zyvop.com/...
Action:          Created new article
dev.to           Live (https://dev.to/...)
Hashnode         Live (https://...)
```

## How it works

The action publishes only Markdown files changed by a push. On a manual run,
first push, or unavailable base commit, it safely processes all tracked files
matching `posts`.

Give every article a stable `canonical_url`, `zyvop_id`, or `slug` so future
runs update the existing article rather than creating another one.

The canonical URL is set on Dev.to, Hashnode and supported Medium flows.
WordPress copies get an "Originally published at" line that links to the
source. Bluesky receives a link post.

Medium's API cannot update a published story, so republishing an article to
Medium in direct provider mode can create another story there.

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

## Run your publication on your own domain

Founding Pro adds a custom domain with automatic SSL, standalone publication
mode, and removable ZyVOP branding. See [plans and pricing](https://zyvop.com/pricing).

## License

MIT
