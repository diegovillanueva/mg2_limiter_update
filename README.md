# 🧊🛠️ mg2_limiter_update: CESM 2.1.5 runs of the dust-ice limiter letter

🎯🧬 This repository rebuilds the seven CESM2 (CAM6, MG2 microphysics) runs of the main manuscript on a stock `release-cesm2.1.5` checkout.
🔗📦 It extends [Sppe_revision_public](https://github.com/diegovillanueva/Sppe_revision_public): that package holds the 20 SPPE microphysics controls only, while this one ships the complete CAM development branch used for the letter (Niemand singular dust limiter, nimax switches, history diagnostics, COSP fields).

## 📌🧱 Versions

| Component | Version |
|---|---|
| CESM | `release-cesm2.1.5` (`7a6c5b0d`) |
| CAM base | `cam_cesm2_1_rel_60` (`a03b84b7`) |
| CAM source state | development branch `dv_diag` at `e3bd85da` (tag `dv_diag-frozen-20261105`), exported as 19 patches |
| Configuration | compset `F2000climo`, grid `f09_g17`, `CAM_CONFIG_OPTS="-phys cam6 -cosp"`, startup run from 2000-01-01, ERA5 U/V nudging |

🧾📋 The pins are in `versions.env`; `SHA256SUMS` lists the checksums of all tracked files.

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
🕰️🧩 Default-NoCap, DustOnly-Cap and DustOnly-Strong were built from intermediate states of the development branch; `e3bd85da` contains all their options at neutral defaults.
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
| `patches/` | 🩹 one unified diff per file vs `cam_cesm2_1_rel_60`: `namelist_definition.xml`, 17 files in `src/physics/cam/` (new `micro_dv_nml.F90`), `src/physics/rrtmg/radiation.F90` |
| `namelists/<Run>/user_nl_cam` | 📝 complete `user_nl_cam` per run: microphysics, nudging (`NUDGING_DIR` placeholder), history output |
| `cases/runs.tsv` | 📋 runs, settings and archived case names |
| `scripts/apply_patches.sh` | 🩹 checks the CAM commit, then `git apply` |
| `scripts/create_case.sh` | 🏗️ `create_newcase`, PE layout, `-cosp`, start date, `user_nl_cam`, `preview_namelists` |

🧹🚫 Excluded from the branch export: build products, test harnesses, notes and unreferenced XML defaults.

## ✅🧪 Validation

VALIDATION_PLACEHOLDER

## ⚖️📚 Licence and citation

⚖️🧾 The patches modify CESM2 source code and are distributed under the CESM2 terms of use (https://www.cesm.ucar.edu/models/cesm2/copyright); scripts and namelists are free to reuse with attribution.
🏷️📚 DOI to be minted at publication.
