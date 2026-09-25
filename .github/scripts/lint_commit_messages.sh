#!/usr/bin/env bash
# lint_commit_messages.sh
#
# Validates ONLY the most recent commit on the branch/PR against Conventional
# Commits (https://www.conventionalcommits.org/en/v1.0.0/) and extracts the
# `Update-Type` trailer from that same commit. Earlier commits on the branch
# are NOT inspected - the last commit's message is treated as the sole,
# authoritative source of "what kind of update is this," so a messy string
# of WIP commits earlier in the branch won't block a PR or affect the flag.
#
# Usage (from a workflow step):
#   .github/scripts/lint_commit_messages.sh [sha]
# `sha` defaults to HEAD - i.e. whatever commit is currently checked out.
# For check-commit.yml, checkout is pinned to the PR's head commit first, so
# this checks exactly the tip of the PR branch.
#
# Exit code is non-zero if that commit's message fails the check. On
# success, writes `update_type` to $GITHUB_OUTPUT (defaults to "manual" if
# the commit carries no recognized `Update-Type:` trailer).

set -euo pipefail

SHA="${1:-HEAD}"

CONVENTIONAL_TYPE_RE='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9_-]+\))?!?: .{1,}'
UPDATE_TYPE_TRAILER_RE='^[Uu]pdate-[Tt]ype:[[:space:]]*(annual|biweekly|manual)[[:space:]]*$'

subject="$(git log -1 --format=%s "${SHA}")"
body="$(git log -1 --format=%b "${SHA}")"

echo "Checking last commit (${SHA}): \"${subject}\""

if [[ "${subject}" =~ ${CONVENTIONAL_TYPE_RE} ]]; then
  echo "  OK - follows Conventional Commits syntax."
else
  echo "::error::Last commit does not follow Conventional Commits syntax: \"${subject}\""
  echo "  Expected: <type>[(scope)][!]: <description>, e.g. \"feat(juvenile): add Battle Creek RST site\""
  echo "  Allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test"
  exit 1
fi

resolved_update_type=""
while IFS= read -r line; do
  if [[ "${line}" =~ ${UPDATE_TYPE_TRAILER_RE} ]]; then
    resolved_update_type="$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
  fi
done <<< "${body}"

if [ -z "${resolved_update_type}" ]; then
  resolved_update_type="manual"
  echo "No 'Update-Type:' trailer on the last commit - defaulting update_type to 'manual'."
else
  echo "Resolved update_type='${resolved_update_type}' from the last commit's trailer."
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "update_type=${resolved_update_type}" >> "${GITHUB_OUTPUT}"
fi

echo "Commit message OK."