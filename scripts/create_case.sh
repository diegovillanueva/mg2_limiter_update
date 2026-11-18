#!/usr/bin/env bash
# Create one CESM 2.1.5 F2000climo f09_g17 case for a run of Villanueva et al. (in review); see cases/runs.tsv.
# Usage: scripts/create_case.sh <RUN> <CASE_DIR>
#   RUN         one of the directory names in namelists/ (Default, Default-NoCap, DustOnly-Cap, DustOnly-Weak,
#               DustOnly-Strong, DustOnly-NieSing, DustOnly-NieCont)
#   CASE_DIR    new case directory (must not exist)
# Environment:
#   CESM_ROOT     (required) release-cesm2.1.5 checkout whose components/cam was patched by scripts/apply_patches.sh
#   NUDGING_DIR   (required) directory with the ERA5 nudging files ERA5_x_fv1x1_L32_rgC2_WO.%y-%m-%d-%s.nc
#   MACH, PROJECT, COMPILER, MPILIB, CIME_OUTPUT_ROOT  (optional) passed to create_newcase
#   NTASKS        MPI tasks per component (default 512; WAV uses 16)
#   STOP_OPTION, STOP_N  segment length (default nmonths, 6); RESUBMIT (default 0)
#   RUN_STARTDATE start date (default 2000-01-01)
#   INP_FACTOR    optional factor on the dust immersion freezing rate (hclas_du_imm); Villanueva et al. (in review) use
#                 1e-4, 1e-2, 1, 1e2 and 1e4. Default: the value in the run's user_nl_cam.
set -euo pipefail

usage="usage: create_case.sh <RUN> <CASE_DIR>"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run="${1:?${usage}}"
case_dir="${2:?${usage}}"
: "${CESM_ROOT:?set CESM_ROOT}"
: "${NUDGING_DIR:?set NUDGING_DIR}"
nl="${repo}/namelists/${run}/user_nl_cam"
[[ -f "${nl}" ]] || { echo "ERROR: unknown run ${run} (see ${repo}/namelists)" >&2; exit 1; }
[[ -e "${case_dir}" ]] && { echo "ERROR: ${case_dir} exists" >&2; exit 1; }
[[ -f "${CESM_ROOT}/components/cam/src/physics/cam/micro_dv_nml.F90" ]] || {
    echo "ERROR: ${CESM_ROOT}/components/cam is not patched; run scripts/apply_patches.sh first" >&2; exit 1; }

ntasks="${NTASKS:-512}"
opts=()
[[ -n "${MACH:-}" ]] && opts+=(--mach "${MACH}")
[[ -n "${PROJECT:-}" ]] && opts+=(--project "${PROJECT}")
[[ -n "${COMPILER:-}" ]] && opts+=(--compiler "${COMPILER}")
[[ -n "${MPILIB:-}" ]] && opts+=(--mpilib "${MPILIB}")
[[ -n "${CIME_OUTPUT_ROOT:-}" ]] && opts+=(--output-root "${CIME_OUTPUT_ROOT}")

"${CESM_ROOT}/cime/scripts/create_newcase" --case "${case_dir}" --compset F2000climo \
    --res f09_g17 --srcroot "${CESM_ROOT}" --run-unsupported ${opts[@]+"${opts[@]}"}
cd "${case_dir}"
./xmlchange "NTASKS_CPL=${ntasks},NTASKS_ATM=${ntasks},NTASKS_LND=${ntasks},NTASKS_ICE=${ntasks},NTASKS_OCN=${ntasks},NTASKS_ROF=${ntasks},NTASKS_GLC=${ntasks},NTASKS_WAV=16,NTASKS_ESP=1"
./xmlchange "ROOTPE_CPL=0,ROOTPE_ATM=0,ROOTPE_LND=0,ROOTPE_ICE=0,ROOTPE_OCN=0,ROOTPE_ROF=0,ROOTPE_GLC=0,ROOTPE_WAV=0,ROOTPE_ESP=0"
./xmlchange --append CAM_CONFIG_OPTS=-cosp
./xmlchange RUN_TYPE=startup
./xmlchange "RUN_STARTDATE=${RUN_STARTDATE:-2000-01-01}"
./xmlchange "STOP_OPTION=${STOP_OPTION:-nmonths},STOP_N=${STOP_N:-6}"
./xmlchange "REST_OPTION=${STOP_OPTION:-nmonths},REST_N=${STOP_N:-6}"
./xmlchange "RESUBMIT=${RESUBMIT:-0}"
./case.setup

# Insert the nudging directory without sed, so that any character in the path is safe.
nudging="${NUDGING_DIR%/}/"
while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ -n "${INP_FACTOR:-}" && "${line}" =~ ^hclas_du_imm[[:space:]]*= ]]; then
        continue
    fi
    printf '%s\n' "${line//NUDGING_DIR\//${nudging}}"
done < "${nl}" > user_nl_cam
if [[ -n "${INP_FACTOR:-}" ]]; then
    printf '\n! INP factor set by create_case.sh\nhclas_du_imm = %s\n' "${INP_FACTOR}" >> user_nl_cam
fi
./preview_namelists > /dev/null
echo "Case ready: $(pwd)"
echo "Next: ./case.build && ./case.submit"
