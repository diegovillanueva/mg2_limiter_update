# 🧊🛠️ mg2_limiter_update: CESM 2.1.5 runs of the dust-ice limiter letter

🎯🧬 This repository rebuilds the seven CESM2 (CAM6, MG2 microphysics) runs of the main manuscript on a stock `release-cesm2.1.5` checkout.
🔗📦 It extends [Sppe_revision_public](https://github.com/diegovillanueva/Sppe_revision_public): that package holds the 20 SPPE microphysics controls only, while this one adds the code of the letter (dust INP limiter, Niemand schemes, ice-number cap switch, history diagnostics).
✂️🌿 This is the branch `minimal-patches`: it keeps only the code that the namelists of the seven runs use (11 patches, 23 namelist variables). The branch `main` holds the complete CAM development branch `dv_diag` (19 patches).

## 📌🧱 Versions

| Component | Version |
|---|---|
| CESM | `release-cesm2.1.5` (`7a6c5b0d`) |
| CAM base | `cam_cesm2_1_rel_60` (`a03b84b7`) |
| CAM source state | development branch `dv_diag` at `e3bd85da` (tag `dv_diag-frozen-20261105`), reduced to the 11 patches the runs need (full export of 19 patches on `main`) |
| Configuration | compset `F2000climo`, grid `f09_g17`, `CAM_CONFIG_OPTS="-phys cam6 -cosp"`, startup run from 2000-01-01, ERA5 U/V nudging |

🧾📋 The pins are in `versions.env`.

## 🏃📋 Runs

| Run | Ice-number cap | Dust INP limit |
|---|---|---|
| Default | on | none (stock CAM6) |
| Default-NoCap | off | `limfacdu = 0.05` |
| DustOnly-Cap | on | none |
| DustOnly-Weak | off | `limfacdu = 0.05` |
| DustOnly-Strong | off | `limfacdu = 6.25e-5` |
| DustOnly-NieSing | off | singular Niemand et al. (2012), max 100 % |
| DustOnly-NieCont | off | continuous Niemand et al. (2012), max 100 % |

🧪🧊 All DustOnly runs set the SPPE block: dust immersion freezing is the only heterogeneous mixed-phase ice source (other `hclas_*` factors zero, no Hallett–Mossop, no contact or rain freezing, `micro_mg_num_steps = 8`).
🔢🧊 The letter's INP-factor sweeps scale dust immersion freezing with `hclas_du_imm` (10⁻⁴ to 10⁴); set that line in a run's `user_nl_cam` to reproduce them.
🗂️📄 `cases/runs.tsv` lists every run with its settings and the name of the archived case it reproduces.
⚠️🔢 The archived runs used `limfacdu = 0.051`; this repository uses `0.05`, the value quoted in the letter, wherever `limfacdu` is set (DustOnly-Strong keeps `0.0000625`; Default and DustOnly-Cap keep the code default).
🕰️🧩 Default-NoCap, DustOnly-Cap and DustOnly-Strong were built from intermediate states of the development branch; `e3bd85da` contains all their options at neutral defaults, and this branch keeps every option that a run sets.
🚫🔬 No numerical comparison with the archived runs was made: the runs are reproducible in configuration, not bit-for-bit, because of the `limfacdu` change and the intermediate build states.

## 🚀⚙️ Quick start

```bash
# 📥 stock CESM 2.1.5
git clone -b release-cesm2.1.5 https://github.com/ESCOMP/CESM.git cesm215
cd cesm215 && ./manage_externals/checkout_externals
# 🩹 patch CAM
/path/to/mg2_limiter_update/scripts/apply_patches.sh "$PWD/components/cam"
# 🏗️ create, build and submit one case (machine options as for any CESM case)
export CESM_ROOT=$PWD NUDGING_DIR=/path/to/era5_nudging MACH=<machine> PROJECT=<account>
/path/to/mg2_limiter_update/scripts/create_case.sh DustOnly-NieSing /path/to/cases/niesing
cd /path/to/cases/niesing && ./case.build && ./case.submit
```

🌬️📂 Nudging needs 6-hourly ERA5 U/V files regridded to the f09 grid with 32 levels, named `ERA5_x_fv1x1_L32_rgC2_WO.%y-%m-%d-%s.nc`; they are not redistributed here and can be generated with the CAM nudging tools from ERA5.
🧮🖥️ `create_case.sh` uses 512 MPI tasks (16 for WAV), the layout of the letter runs; override with `NTASKS`.

## 🗂️📦 Contents

| Path | Content |
|---|---|
| `patches/` | 🩹 one unified diff per file vs `cam_cesm2_1_rel_60`: `namelist_definition.xml` and 10 files in `src/physics/cam/` (new `micro_dv_nml.F90`) |
| `namelists/<Run>/user_nl_cam` | 📝 complete `user_nl_cam` per run: microphysics, nudging (`NUDGING_DIR` placeholder), history output |
| `cases/runs.tsv` | 📋 runs, settings and archived case names |
| `scripts/apply_patches.sh` | 🩹 checks the CAM commit, then `git apply` |
| `scripts/create_case.sh` | 🏗️ `create_newcase`, PE layout, `-cosp`, start date, `user_nl_cam`, `preview_namelists` |

🧹🚫 Excluded from the branch export: build products, test harnesses, notes and unreferenced XML defaults.

## ✂️🧩 What the minimal patch set keeps

🎛️📋 The seven `user_nl_cam` files set 23 variables of the namelist group `micro_dv_nl`; only these remain in `micro_dv_nml.F90` and `namelist_definition.xml`, with unchanged defaults:

| Variables | Used in | Role |
|---|---|---|
| `limfacdu`, `limfacdu_niemand_singular`, `limfacdu_niemand_continuous`, `limfacdu_niemand_factor`, `limfacdu_niemand_max`, `depr_point_frz` | `hetfrz_classnuc.F90` | 🧊 dust INP limiter, Niemand et al. (2012) schemes, freezing point depression |
| `hclas_du_imm`, `hclas_du_dep`, `hclas_du_cnt`, `hclas_bc_imm`, `hclas_bc_dep`, `hclas_bc_cnt` | `hetfrz_classnuc_cam.F90` | 🧪 factors on the heterogeneous freezing rates |
| `enable_nimax`, `naai_het_also_in_mpc`, `micro_mg_ice_berg_ice_factor`, `micro_mg_ice_berg_snow_factor`, `auto_liq_factor`, `riming_factor` | `micro_mg2_0.F90` | 🔢 ice-number cap and MG2 process factors |
| `onoff_contact_freezing`, `onoff_sip`, `factor_HM`, `rain_freeze` | `micro_mg_utils.F90` | ❄️ contact freezing, Hallett–Mossop, rain freezing |
| `detrainment_ramp_liq` | `clubb_intr.F90`, `macrop_driver.F90`, `micro_mg2_0.F90` | 🌡️ phase of detrained condensate |

📊🧾 `micro_mg_cam.F90` keeps the history fields that the namelists request (`ICNUMC`, `SCNUMC`, `RDNUMC`, `CDMASS`, `ICMASS`, `SCMASS`, `RDMASS`, 25 `*_PATH` column integrals) and the changed cloud-top diagnostics (`ACTNI`, `ACTREI`, `FCTI`).
🛡️🔢 `nucleate_ice.F90` keeps only the guard against `log(0)` when no soot or dust is present; `microp_aero.F90` keeps the call that reads `micro_dv_nl`.

## 🗑️📋 What was cut and why

| Cut | Reason |
|---|---|
| `cospsimulator_intr.F90`, `physpkg.F90`, `radiation.F90` patches, `cosp_15m` | 🛰️ COSP at every time step and CALIPSO cloud-top fields: off by default, no run sets `cosp_15m` or requests the fields |
| `micro_mg1_0.F90`, `zm_microphysics.F90` patches | 🚫 MG1 and the Zhang–McFarlane convective microphysics are not active in these CAM6 runs |
| `nucleate_ice_cam.F90` patch (`enable_dst_num_cirrus`) | 🎚️ switch for dust in cirrus ice nucleation, never set, default `.true.` = stock behaviour |
| `phys_control.F90`, `zm_conv_intr.F90` patches | 📝 extra lines in `atm.log` only |
| 33 further `micro_dv_nl` variables (e.g. `limfacdu_niemand`, `tc_ramp_*`, `du_background`, `cirr_*`, `fi_factor*`, `sublim_factor*`, `hom_frz_qc_early`, `auto_ice_factor`, `enable_nimax_only_cirrus`, `detr_mpc_ice_frac`, `theta_imm_dust*`, `hclas_min_t_imm*`, `hclas_max_t_imm`) with their code paths | 🎚️ no run sets them, so the code always took the default path; constants that the kept code still needs are now local parameters with the former default values (Niemand `a = 0.517`, `b = 8.934`, ramp limits −42 °C and −6 °C, contact angle 46°, 263.15 K) |
| history fields `ACTT`, `ACTP`, `ACT_NITF`, `ACT_ITMF`, `CC_*_PATH` | 📉 not requested by any run |
| namelist definitions outside `micro_dv_nl` (`bimm`, `zm_frz`, `micro_mg_ice_sub_eff_factor`, …) | 🧾 no code in the patches reads them |

⚖️🧊 Kept on purpose although they look redundant: the temperature ramp arithmetic in `hetfrz_classnuc.F90` and the second multiplication by `micro_mg_berg_eff_factor` in `micro_mg2_0.F90`, because removing them could change the results in the last bits.

## ✅🧪 Validation

🩹✅ On `main`, the 19 patches apply cleanly to a clean `cam_cesm2_1_rel_60` checkout, and the patched files are byte-identical to the CAM `dv_diag` state used for the letter (commit `e3bd85da`).
🩹✅ The 11 minimal patches apply cleanly to a clean `cam_cesm2_1_rel_60` checkout (`git apply --check`).
🔁✅ Bit-for-bit test of `minimal-patches` vs `main`: one f09_g17 case per patch set (Euler, 128 tasks), 1-day runs of Default, DustOnly-NieSing, Default-NoCap and DustOnly-NieCont. Every variable of every history file (`cam.h0`–`h4`, `clm2`, `cice`, `mosart`, `cpl`) is identical; the restart files differ only in strings holding the case name and paths. The other three namelists request no history field and set no variable that these four do not already cover.
🏗️✅ A CESM 2.1.5 F2000climo f09_g17 case (DustOnly-NieSing) builds from a tree prepared with `apply_patches.sh` and `create_case.sh` (Euler, Intel, 512 tasks); the build log compiles the patched `micro_dv_nml.F90`.
🧾✅ `preview_namelists` for all seven cases: sorted `atm_in` equals the archived letter cases except `limfacdu` 0.051 → 0.05 (Default-NoCap, DustOnly-Weak, DustOnly-NieSing, DustOnly-NieCont); Default, DustOnly-Cap and DustOnly-Strong are identical.
🏃✅ A 5-day smoke run of DustOnly-NieSing finished (`case.run success`, 6.7 min on 4 nodes): `atm_in` has `limfacdu = 0.05` and `limfacdu_niemand_singular = .true.`, h1–h4 files are written daily, and `FRZIMM_PATH` and `ICNUMC` are finite everywhere (h0 is monthly and not reached in 5 days).
🧭⚠️ Use `--res f09_g17` (as `create_case.sh` does): `f09_f09_mg17` gives a different hybrid start and initial file. If the CESM tree has externals that are not SVN/git checkouts, `case.build --skip-provenance-check` is needed.
🔐🧮 `SHA256SUMS` lists the checksums of all distributed files (`sha256sum -c SHA256SUMS`).
🧾⚠️ No numerical comparison with the archived letter runs is made: those runs used `limfacdu = 0.051` (here 0.05) and some were built from intermediate code states.

## ⚖️📚 Licence and citation

⚖️🧾 The patches modify CESM2 source code and are distributed under the CESM2 terms of use (https://www.cesm.ucar.edu/models/cesm2/copyright); scripts and namelists are free to reuse with attribution.
🏷️📚 DOI to be minted at publication.
