#!/usr/bin/env bash
# determine_version_bump.sh
#
# Computes the next semantic version tag for SRJPEdata, per the rules in
# "Data Versioning For SRJPEdata":
#   - update_type=annual   -> MAJOR bump  (adult + juvenile JPE refresh, ~Dec)
#   - update_type=biweekly -> MINOR bump  (within-season RST sync)
#   - update_type=manual   -> bump determined from the LAST commit's
#                              Conventional Commit message only:
#                                * "!" or a "BREAKING CHANGE:" footer -> MAJOR
#                                * "feat:" / "feat(scope):"           -> MINOR
#                                * otherwise (fix/chore/docs/etc.)    -> PATCH
#
# Only the last commit on the ref is inspected - not the full history since
# the last tag - so this assumes that commit is the authoritative summary of
# the change (true for a squash- or rebase-merged PR, or a single bot
# commit). See the note in release-and-news.yml about merge strategy.
#
# Usage (run after `actions/checkout` with fetch-depth: 0, fetch-tags: true):
#   .github/scripts/determine_version_bump.sh <update_type>
#
# Writes `new_version` (e.g. "1.4.0", no leading "v") and `bump_type`
# (major|minor|patch) to $GITHUB_OUTPUT.
#
# TODO(SRJPE): confirm the repo's tag prefix convention (this assumes "vX.Y.Z";
# adjust LATEST_TAG lookup below if SRJPEdata tags without the "v").

set -euo pipefail

UPDATE_TYPE="${1:?update_type required (annual|biweekly|manual)}"

LATEST_TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo 'v0.0.0')"
LATEST_TAG="${LATEST_TAG#v}"

IFS='.' read -r major minor patch <<< "${LATEST_TAG}"
major="${major:-0}"; minor="${minor:-0}"; patch="${patch:-0}"

bump_type=""

case "${UPDATE_TYPE}" in
  annual)
    bump_type="major"
    ;;
  biweekly)
    bump_type="minor"
    ;;
  manual)
    subject="$(git log -1 --format=%s HEAD)"
    body="$(git log -1 --format=%b HEAD)"
    if echo "${subject}" | grep -Eq '^[a-z]+(\([a-z0-9_-]+\))?!:' \
       || echo "${body}" | grep -q 'BREAKING CHANGE:'; then
      bump_type="major"
    elif echo "${subject}" | grep -Eq '^feat(\([a-z0-9_-]+\))?: '; then
      bump_type="minor"
    else
      bump_type="patch"
    fi
    echo "Last commit: \"${subject}\" -> bump_type=${bump_type}"
    ;;
  *)
    echo "::error::Unknown update_type '${UPDATE_TYPE}' - expected annual, biweekly, or manual."
    exit 1
    ;;
esac

case "${bump_type}" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

new_version="${major}.${minor}.${patch}"

echo "update_type=${UPDATE_TYPE} -> bump_type=${bump_type}"
echo "previous version: ${LATEST_TAG} -> new version: ${new_version}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "new_version=${new_version}"
    echo "bump_type=${bump_type}"
    echo "previous_version=${LATEST_TAG}"
  } >> "${GITHUB_OUTPUT}"
fi