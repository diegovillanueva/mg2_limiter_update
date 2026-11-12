# ✂️🧩 The minimal patch set: what it keeps and what was cut

🔙📘 Back to the [README](../README.md).
🎯🩹 The default branch `main` carries 11 patches and 23 namelist variables, the code that the namelists of the seven letter runs use; the complete CAM development branch `dv_diag` (19 patches) is on the branch `full-dv-diag` (tag `v0-full-dv-diag`).

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
| `cospsimulator_intr.F90`, `physpkg.F90`, `radiation.F90` patches, `cosp_15m` | 🛰️ COSP at every time step and CALIPSO cloud-top fields: off by default, no run sets `cosp_15m` or requests the fields; now in `cam6_cosp_calipso_diag` |
| `micro_mg1_0.F90`, `zm_microphysics.F90` patches | 🚫 MG1 and the Zhang–McFarlane convective microphysics are not active in these CAM6 runs |
| `nucleate_ice_cam.F90` patch (`enable_dst_num_cirrus`) | 🎚️ switch for dust in cirrus ice nucleation, never set, default `.true.` = stock behaviour |
| `phys_control.F90`, `zm_conv_intr.F90` patches | 📝 extra lines in `atm.log` only |
| 33 further `micro_dv_nl` variables (e.g. `limfacdu_niemand`, `tc_ramp_*`, `du_background`, `cirr_*`, `fi_factor*`, `sublim_factor*`, `hom_frz_qc_early`, `auto_ice_factor`, `enable_nimax_only_cirrus`, `detr_mpc_ice_frac`, `theta_imm_dust*`, `hclas_min_t_imm*`, `hclas_max_t_imm`) with their code paths | 🎚️ no run sets them, so the code always took the default path; constants that the kept code still needs are now local parameters with the former default values (Niemand `a = 0.517`, `b = 8.934`, ramp limits −42 °C and −6 °C, contact angle 46°, 263.15 K) |
| history fields `ACTT`, `ACTP`, `ACT_NITF`, `ACT_ITMF`, `CC_*_PATH` | 📉 not requested by any run; now in `cam6_cosp_calipso_diag` |
| namelist definitions outside `micro_dv_nl` (`bimm`, `zm_frz`, `micro_mg_ice_sub_eff_factor`, …) | 🧾 no code in the patches reads them |

⚖️🧊 Kept on purpose although they look redundant: the temperature ramp arithmetic in `hetfrz_classnuc.F90` and the second multiplication by `micro_mg_berg_eff_factor` in `micro_mg2_0.F90`, because removing them could change the results in the last bits.
