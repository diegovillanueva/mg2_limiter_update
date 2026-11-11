#!/usr/bin/env bash
# 🏗️🧊 Create one CESM 2.1.5 F2000climo f09_g17 case for a run of the letter (see cases/runs.tsv).
# 🧭📌 Usage: scripts/create_case.sh <RUN> <CASE_DIR>
#   RUN         Default | Default-NoCap | DustOnly-Cap | DustOnly-Weak | DustOnly-Strong | DustOnly-NieSing | DustOnly-NieCont
#   CASE_DIR    new case directory
# 🌍🔧 Environment:
#   CESM_ROOT   (required) release-cesm2.1.5 checkout whose components/cam was patched by scripts/apply_patches.sh
#   NUDGING_DIR (required) directory with ERA5 nudging files ERA5_x_fv1x1_L32_rgC2_WO.%y-%m-%d-%s.nc
#   MACH, PROJECT, COMPILER, MPILIB, CIME_OUTPUT_ROOT (optional, passed to create_newcase); NTASKS (default 512)
#   STOP_OPTION/STOP_N (default nmonths/6), RUN_STARTDATE (default 2000-01-01)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run="${1:?usage: create_case.sh <RUN> <CASE_DIR>}"
case_dir="${2:?usage: create_case.sh <RUN> <CASE_DIR>}"
: "${CESM_ROOT:?set CESM_ROOT}"
: "${NUDGING_DIR:?set NUDGING_DIR}"
nl="${repo}/namelists/${run}/user_nl_cam"
[[ -f "${nl}" ]] || { echo "❌ unknown run ${run}" >&2; exit 1; }
[[ -e "${case_dir}" ]] && { echo "❌ ${case_dir} exists" >&2; exit 1; }

ntasks="${NTASKS:-512}"
opts=()
[[ -n "${MACH:-}" ]] && opts+=(--mach "${MACH}")
[[ -n "${PROJECT:-}" ]] && opts+=(--project "${PROJECT}")
[[ -n "${COMPILER:-}" ]] && opts+=(--compiler "${COMPILER}")
[[ -n "${MPILIB:-}" ]] && opts+=(--mpilib "${MPILIB}")
[[ -n "${CIME_OUTPUT_ROOT:-}" ]] && opts+=(--output-root "${CIME_OUTPUT_ROOT}")

"${CESM_ROOT}/cime/scripts/create_newcase" --case "${case_dir}" --compset F2000climo \
    --res f09_g17 --srcroot "${CESM_ROOT}" --run-unsupported "${opts[@]}"
cd "${case_dir}"
./xmlchange "NTASKS_CPL=${ntasks},NTASKS_ATM=${ntasks},NTASKS_LND=${ntasks},NTASKS_ICE=${ntasks},NTASKS_OCN=${ntasks},NTASKS_ROF=${ntasks},NTASKS_GLC=${ntasks},NTASKS_WAV=16,NTASKS_ESP=1"
./xmlchange "ROOTPE_CPL=0,ROOTPE_ATM=0,ROOTPE_LND=0,ROOTPE_ICE=0,ROOTPE_OCN=0,ROOTPE_ROF=0,ROOTPE_GLC=0,ROOTPE_WAV=0,ROOTPE_ESP=0"
./xmlchange --append CAM_CONFIG_OPTS=-cosp
./xmlchange RUN_TYPE=startup
./xmlchange "RUN_STARTDATE=${RUN_STARTDATE:-2000-01-01}"
./xmlchange "STOP_OPTION=${STOP_OPTION:-nmonths},STOP_N=${STOP_N:-6}"
./xmlchange "REST_OPTION=${STOP_OPTION:-nmonths},REST_N=${STOP_N:-6}"
./case.setup

sed "s#NUDGING_DIR/#${NUDGING_DIR%/}/#" "${nl}" > user_nl_cam
./preview_namelists > /dev/null
echo "✅ case ready: $(pwd)"
echo "🏗️ next: ./case.build && ./case.submit"
