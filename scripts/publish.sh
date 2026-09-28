#!/usr/bin/env bash
set -euo pipefail

normalize_boolean() {
  local name="$1"
  local value="$2"

  case "$value" in
    true|TRUE|True)
      printf 'true'
      ;;
    false|FALSE|False)
      printf 'false'
      ;;
    *)
      echo "::error::$name must be either true or false."
      exit 1
      ;;
  esac
}

posts_pathspec="${INPUT_POSTS:-:(glob)posts/**/*.md}"
changed_only="$(normalize_boolean changed-only "${INPUT_CHANGED_ONLY:-true}")"
local_mode="$(normalize_boolean local "${INPUT_LOCAL:-false}")"
dry_run="$(normalize_boolean dry-run "${INPUT_DRY_RUN:-false}")"
cli_version="${INPUT_CLI_VERSION:-1.1.1}"
endpoint="${INPUT_ENDPOINT:-}"

if [[ ! "$cli_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "::error::cli-version must be an exact semantic version, for example 1.1.1."
  exit 1
fi

if [[ "$dry_run" != "true" && -z "${ZYVOP_TOKEN:-}" ]]; then
  echo "::error::ZYVOP_TOKEN is required unless dry-run is true."
  exit 1
fi

if ! git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "::error::The workspace is not a Git repository. Run actions/checkout before this action."
  exit 1
fi
cd "$git_root"

before_sha="${BEFORE_SHA:-}"
after_sha="${AFTER_SHA:-HEAD}"
declare -a files=()

if [[ "$changed_only" == "false" ]] ||
  [[ -z "$before_sha" ]] ||
  [[ "$before_sha" =~ ^0+$ ]] ||
  ! git cat-file -e "${before_sha}^{commit}" 2>/dev/null; then
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <(git ls-files -z -- "$posts_pathspec")
else
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <(
    git diff --name-only -z --diff-filter=ACMR \
      "$before_sha" "$after_sha" -- "$posts_pathspec"
  )
fi

if (( ${#files[@]} == 0 )); then
  echo "No Markdown articles matched $posts_pathspec."
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "published-count=0" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

npx_bin="${ZYVOP_ACTION_NPX_BIN:-npx}"
if ! command -v "$npx_bin" >/dev/null 2>&1; then
  echo "::error::npx is unavailable. Ensure Node.js 20 or newer is installed."
  exit 1
fi

processed_count=0
for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  echo "Publishing $file with zyvop@$cli_version..."
  command_args=(--yes "zyvop@$cli_version" publish "$file")

  if [[ "$local_mode" == "true" ]]; then
    command_args+=(--local)
  fi
  if [[ "$dry_run" == "true" ]]; then
    command_args+=(--dry-run)
  fi
  if [[ -n "$endpoint" ]]; then
    command_args+=(--endpoint "$endpoint")
  fi

  "$npx_bin" "${command_args[@]}"
  processed_count=$((processed_count + 1))
done

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "published-count=$processed_count" >> "$GITHUB_OUTPUT"
fi

echo "Successfully processed $processed_count Markdown article(s)."
