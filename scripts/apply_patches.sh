#!/usr/bin/env bash
# 🩹🧊 Apply the mg2_limiter_update CAM patches to a clean cam_cesm2_1_rel_60 checkout.
# 🧭📌 Usage: scripts/apply_patches.sh /path/to/cesm2.1.5/components/cam
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cam="${1:?usage: apply_patches.sh <CESM_ROOT>/components/cam}"
# shellcheck source=/dev/null
source "${repo}/versions.env"

cd "${cam}"
head="$(git rev-parse HEAD)"
if [[ "${head}" != "${CAM_COMMIT}" ]]; then
    echo "⚠️ CAM HEAD ${head} is not ${CAM_TAG} (${CAM_COMMIT})" >&2
    exit 1
fi
git apply --check "${repo}"/patches/*.patch
git apply --whitespace=nowarn "${repo}"/patches/*.patch
echo "✅ patched files:"
git status --short
