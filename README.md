# Reconciling droplet freezing parameterizations with cloud top phase and ice number observations: code and run configurations

This repository contains the CESM2 code changes and the run configurations of Villanueva et al. (in review), "Reconciling droplet freezing parameterizations with cloud top phase and ice number observations".

## Purpose

The repository rebuilds the CESM2 (CAM6, MG2 microphysics) runs of Villanueva et al. (in review) on a stock `release-cesm2.1.5` checkout: the seven runs of Table 1 and the two 1979-2006 runs of Fig. 3.
The code adds to CAM6 a limiter on the fraction of dust that may freeze per call (`limfacdu`), the singular and continuous Niemand et al. (2012) dust immersion freezing schemes, a switch for the MG2 ice-number cap (`enable_nimax`), factors on the heterogeneous freezing and microphysical process rates, and history diagnostics.
It extends [Sppe_revision_public](https://github.com/diegovillanueva/Sppe_revision_public), which holds the 20 microphysics controls of an earlier study; this repository adds the code of Villanueva et al. (in review).

The default branch `main` holds the minimal patch set: only the code that the run namelists use (11 patches, 23 namelist variables). The branch `full-dv-diag` (tag `v0-full-dv-diag`) holds the complete export of `dv_diag`, the author's CAM development branch (19 patches).

## Requirements

- A CESM 2.1.5 installation ported to your machine (`release-cesm2.1.5`, see the CESM documentation for porting), with its standard input data (F2000climo, f09_g17).
- Fortran and C compilers and MPI supported by CESM 2.1.5. The runs were made on the ETH Zurich Euler cluster (Intel compilers).
- 6-hourly ERA5 U/V nudging files on the f09 grid with 32 levels (see Quick start); they are not redistributed here.
- Compute: `create_case.sh` uses 512 MPI tasks (16 for WAV). On Euler, one simulated year took about 4-7 h on 4 nodes (about 22 node-hours).

## Versions

| Component | Version |
|---|---|
| CESM | `release-cesm2.1.5` (`7a6c5b0d`) |
| CAM base | `cam_cesm2_1_rel_60` (`a03b84b7`) |
| CAM source state | development branch `dv_diag` at `e3bd85da` (tag `dv_diag-frozen-20261105`), reduced to the 11 patches the runs need (full export of 19 patches on `full-dv-diag`) |
| Configuration | compset `F2000climo`, grid `f09_g17`, `CAM_CONFIG_OPTS="-phys cam6 -cosp"`, startup run, ERA5 U/V nudging |

The pins are in `versions.env`.

## Runs

| Name | Ice sources | Freezing rule | Cap | Limiter |
|---|---|---|---|---|
| Default | all | CNT | on | none |
| Default-NoCap | all | CNT | off | 0.05 |
| DustOnly-Cap | dust only | CNT | on | none |
| DustOnly-Weak | dust only | CNT | off | 0.05 |
| DustOnly-Strong | dust only | CNT | off | 0.05/1000 |
| DustOnly-NieSing | dust only | Niemand, once per particle | off | existing ice |
| DustOnly-NieCont | dust only | Niemand, every step | off | none |

The rows match Table 1 of Villanueva et al. (in review). Cap: MG2 ice-number cap (`enable_nimax`). Limiter: fraction of the cloud-borne dust that may freeze per call (`limfacdu`, CNT runs only); the Niemand runs allow a frozen fraction of up to 100 % (`limfacdu_niemand_max = 100`), and `limfacdu` is not used when a Niemand switch is set.
The last two rows are the long nudged runs of Fig. 3 (start 1979-01-01, create them with `RUN_STARTDATE=1979-01-01`): DustOnly-NieSing, and the same run with dust immersion freezing switched off (`hclas_du_imm = 0`). Fig. 3 uses the standard COSP fields `CLD_CAL_TMPICE` and `CLD_CAL_TMPLIQ`; the model cloud-top diagnostics of the Supporting Information (`ctd_*` namelist variables) come from the patch set in [cam6_cosp_calipso_diag](https://github.com/diegovillanueva/cam6_cosp_calipso_diag) and are left out of these two namelists.

All DustOnly runs set the same block of switches: dust immersion freezing is the only heterogeneous mixed-phase ice source (other `hclas_*` factors zero, no Hallett-Mossop, no contact or rain freezing, `micro_mg_num_steps = 8`).

### INP-factor members

Every run of Table 1 has members at five INP factors, 10⁻⁴, 10⁻², 1, 10² and 10⁴ (Default-NoCap: factor 1 only in the original runs). The factor multiplies the dust immersion freezing rate through the namelist variable `hclas_du_imm` (in all runs, including Default, where it is the only change from the stock namelist). To create a member, set `INP_FACTOR` when calling `create_case.sh`, for example `INP_FACTOR=1e-4`; the script replaces the `hclas_du_imm` line of the run's `user_nl_cam`.

### Run length

`create_case.sh` sets 6-month segments starting on 2000-01-01 (`STOP_OPTION=nmonths`, `STOP_N=6`). Villanueva et al. (in review) analyse the second simulation year (2001) and, for the water-path changes, both years; run at least two years, for example with `RESUBMIT=3`.

### Run table

`cases/runs.tsv` lists every run with the following columns:

| Column | Meaning |
|---|---|
| `run` | run name (directory in `namelists/`) |
| `ice_sources`, `freezing_rule`, `cap`, `limiter` | as in the table above |
| `limfacdu_active` | `yes` if `limfacdu` acts in the run (CNT runs with `limfacdu` below 1) |
| `hclas_du_imm`, `enable_nimax`, `limfacdu` | namelist values in this repository |
| `start_date` | `RUN_STARTDATE` |
| `limfacdu_original` | `limfacdu` of the original run |
| `original_case_name` | name of the original CESM case |

The original case names use internal labels: `Sppe` is the series of microphysics sensitivity experiments, `ori` the stock model, `du5pdN` a limiter of 0.05/N (`du5pd1000` = DustOnly-Strong), and `niesing`/`niecont` the Niemand schemes.

### Differences from the original runs

- The original runs used `limfacdu = 0.051`; this repository uses `0.05`, the value quoted in Villanueva et al. (in review), wherever `limfacdu` is set (DustOnly-Strong uses `0.00005` = 0.05/1000, as in its original run; Default and DustOnly-Cap keep the code default).
- Default-NoCap, DustOnly-Cap and DustOnly-Strong were built from intermediate states of the development branch; `e3bd85da` contains all their options at neutral defaults, and this patch set keeps every option that a run sets.
- No numerical comparison with the original runs was made: the runs are reproducible in configuration, not bit for bit, because of the `limfacdu` change and the intermediate build states.

## Quick start

```bash
# stock CESM 2.1.5
git clone -b release-cesm2.1.5 https://github.com/ESCOMP/CESM.git cesm215
cd cesm215 && ./manage_externals/checkout_externals
# patch CAM
/path/to/mg2_limiter_update/scripts/apply_patches.sh "$PWD/components/cam"
# create, build and submit one case (machine options as for any CESM case)
export CESM_ROOT=$PWD NUDGING_DIR=/path/to/era5_nudging MACH=<machine> PROJECT=<account>
/path/to/mg2_limiter_update/scripts/create_case.sh DustOnly-NieSing /path/to/cases/niesing
cd /path/to/cases/niesing && ./case.build && ./case.submit
```

Nudging needs 6-hourly ERA5 U/V files regridded to the f09 grid with 32 levels, named `ERA5_x_fv1x1_L32_rgC2_WO.%y-%m-%d-%s.nc`; they can be generated with the CAM nudging tools from ERA5.
`create_case.sh` documents its environment variables (`NTASKS`, `STOP_OPTION`, `STOP_N`, `RESUBMIT`, `RUN_STARTDATE`, `INP_FACTOR`) in its header.

## Contents

| Path | Content |
|---|---|
| `patches/` | one unified diff per file against `cam_cesm2_1_rel_60`: `namelist_definition.xml` and 10 files in `src/physics/cam/` (new `micro_dv_nml.F90`) |
| `namelists/<Run>/user_nl_cam` | complete `user_nl_cam` per run: microphysics, nudging (`NUDGING_DIR` placeholder), history output |
| `cases/runs.tsv` | runs, settings and original case names |
| `scripts/apply_patches.sh` | checks the CAM commit, then applies the patches with `git apply` |
| `scripts/create_case.sh` | `create_newcase`, PE layout, `-cosp`, start date, `user_nl_cam`, `preview_namelists` |
| `docs/patch-set.md` | which variables, history fields and code paths the minimal patch set keeps, what was cut and why |
| `versions.env` | CESM and CAM tags and commits checked by `apply_patches.sh` |
| `LICENSE`, `NOTICE` | BSD 3-Clause License for the changes; CESM2 copyright notice for the modified source |
| `CITATION.cff`, `.zenodo.json` | citation and archive metadata |
| `SHA256SUMS` | checksums of all distributed files |

The kept variables (by source file), the kept history fields, the list of cut patches and variables with reasons, and the two redundant-looking pieces of arithmetic kept for bit-for-bit safety are in [`docs/patch-set.md`](docs/patch-set.md).

## Validation

- On `full-dv-diag`, the 19 patches apply cleanly to a clean `cam_cesm2_1_rel_60` checkout, and the patched files are byte-identical to the CAM `dv_diag` state used for the original runs (commit `e3bd85da`).
- The 11 minimal patches apply cleanly to a clean `cam_cesm2_1_rel_60` checkout (`git apply --check`).
- Bit-for-bit test of the minimal patch set (`main`) against the full one (`full-dv-diag`): one f09_g17 case per patch set (Euler, 128 tasks), 1-day runs of Default, DustOnly-NieSing, Default-NoCap and DustOnly-NieCont. Every variable of every history file (`cam.h0`-`h4`, `clm2`, `cice`, `mosart`, `cpl`) is identical; the restart files differ only in strings holding the case name and paths. The other three namelists of Table 1 request no history field and set no variable that these four do not already cover.
- A CESM 2.1.5 F2000climo f09_g17 case (DustOnly-NieSing) builds from a tree prepared with `apply_patches.sh` and `create_case.sh` (Euler, Intel, 512 tasks); the build log compiles the patched `micro_dv_nml.F90`.
- `preview_namelists` for the seven cases of Table 1: sorted `atm_in` equals the original cases except `limfacdu` 0.051 to 0.05 (Default-NoCap, DustOnly-Weak, DustOnly-NieSing, DustOnly-NieCont); Default, DustOnly-Cap and DustOnly-Strong are identical.
- A 5-day smoke run of DustOnly-NieSing finished (`case.run success`, 6.7 min on 4 nodes): `atm_in` has `limfacdu = 0.05` and `limfacdu_niemand_singular = .true.`, h1-h4 files are written daily, and `FRZIMM_PATH` and `ICNUMC` are finite everywhere (h0 is monthly and not reached in 5 days).
- Use `--res f09_g17` (as `create_case.sh` does): `f09_f09_mg17` gives a different hybrid start and initial file. If the CESM tree has externals that are not SVN or git checkouts, `case.build --skip-provenance-check` is needed.
- The minimal patch set changes the cloud-top definition (total condensate), so the stock `ACT*` and `FCT*` diagnostics differ from stock CAM.

Checksums: `SHA256SUMS` was generated with

```bash
git ls-files | grep -v '^SHA256SUMS$' | sort | xargs sha256sum > SHA256SUMS
```

and is verified with `sha256sum -c SHA256SUMS`.

## Related repositories

| Repository | Content | Relation to this one |
|---|---|---|
| [Sppe_revision_public](https://github.com/diegovillanueva/Sppe_revision_public) | the 20 SPPE microphysics controls | this repository extends it |
| [cam6_cosp_calipso_diag](https://github.com/diegovillanueva/cam6_cosp_calipso_diag) | COSP every time step, CALIPSO/CloudSat and MG2 cloud-top diagnostics | applies on top of this patch set |

## Data availability

Model output of the runs is available from the author on request.

## Licence and citation

The changes in this repository are released under the BSD 3-Clause License (`LICENSE`). The patches modify CESM2/CAM6 source code, copyright UCAR, which remains under the CESM2 terms of use; see `NOTICE`.

Please cite Villanueva et al. (in review) and this software (`CITATION.cff`). A Zenodo DOI is minted for release v1.0.1.

## Contact

Diego Villanueva, Institute for Atmospheric and Climate Science, ETH Zurich (GitHub: diegovillanueva).
