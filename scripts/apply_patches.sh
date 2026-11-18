#!/usr/bin/env bash
# Apply the mg2_limiter_update CAM patches to a clean cam_cesm2_1_rel_60 checkout.
# Usage: scripts/apply_patches.sh /path/to/cesm2.1.5/components/cam
# The CAM directory must be the git checkout created by manage_externals/checkout_externals
# for release-cesm2.1.5 (tag cam_cesm2_1_rel_60, see versions.env), without local changes.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cam="${1:?usage: apply_patches.sh <CESM_ROOT>/components/cam}"
# shellcheck source=/dev/null
source "${repo}/versions.env"

cd "${cam}" || { echo "ERROR: ${cam} not found" >&2; exit 1; }
head="$(git rev-parse HEAD 2>/dev/null)" || {
    echo "ERROR: ${cam} is not a git checkout; run manage_externals/checkout_externals in CESM_ROOT" >&2; exit 1; }
if [[ "${head}" != "${CAM_COMMIT}" ]]; then
    echo "ERROR: CAM HEAD ${head} is not ${CAM_TAG} (${CAM_COMMIT})" >&2
    echo "Check out the tag: git -C ${cam} checkout ${CAM_TAG}" >&2
    exit 1
fi
git apply --check "${repo}"/patches/*.patch || {
    echo "ERROR: patches do not apply; the CAM tree must be unmodified (git -C ${cam} status)" >&2; exit 1; }
git apply --whitespace=nowarn "${repo}"/patches/*.patch
echo "Patched files:"
git status --short
