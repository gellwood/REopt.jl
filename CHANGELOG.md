# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Guidelines
- When making a Pull Request into `develop` start a new double-hash header for "Develop - YYYY-MM-DD"
- When making a Pull Request into `master` change "Develop" to the next version number

### Formatting
- Use **bold** markup for field and model names (i.e. **outage_start_time_step**)
- Use `code` markup for  REopt-specific file names, classes and endpoints (e.g. `src/REopt.jl`)
- Use _italic_ for code terms (i.e. _list_)
- Prepend change with tag(s) directing where it is in the repository:  
`src`,`constraints`,`*.jl`

Classify the change according to the following categories:
    
    ### Added
    ### Changed
    ### Fixed
    ### Deprecated
    ### Removed

## Develop 11/21/2022
### Added
- throw error if outage_durations and outage_probabilities not the same length
- small incentive to minimize unserved load in each outage, not just the max over outage start times (makes expected outage results more realist and fixes same inputs giving different results)
- add `Outages` output **generator_fuel_used_per_outage** which is the sum over backup generators
### Changed
- remove _series from non-timeseries outage output names
- make the use of _ in multiple outages output names consistent
- updates multiple outage test values that changed due to fixing timestep bug
### Fixed
- fixed mulitple outages timestep off-by-one bug

# v0.22.0
### Added
- Simulated load function which mimicks the REopt_API /simulated_load endpoint for getting commercial reference building load data from annual or monthly energy data, or blended/hybrid buildings
- `AbsorptionChiller` default values for costs and thermal coefficient of performance (which depend on maximum cooling load and heat transfer medium)
### Changed
- Pruned the unnecessary chp_defaults data that were either zeros or not dependent on `prime_mover` or `size_class`, and reorganized the CHP struct.

## v0.21.0
### Changed
For `CHP` and `SteamTurbine`, the `prime_mover` and/or `size_class` is chosen (if not input) based on the average heating load and the type of heating load (hot water or steam).
 - This logic replicates the current REopt webtool behavior which was implemented based on CHP industry experts, effectively syncing the webtool and the REopt.jl/API behavior.
 - This makes `prime_mover` **NOT** a required input and avoids a lot of other required inputs if `prime_mover` is not input.
 - The two functions made for `CHP` and `SteamTurbine` are exported in `REopt.jl` so they can be exposed in the API for communication with the webtool (or other API users).
### Removed 
`ExistingBoiler.production_type_by_chp_prime_mover` because that is no longer consistent with the logic added above.
 - The logic from 1. is such that `ExistingBoiler.production_type` determines the `CHP.prime_mover` if not specified, not the other way around.
 - If `ExistingBoiler.production_type` is not input, `hot_water` is used as the default.

## v0.20.1
### Added
- `CoolingLoad` time series and annual summary data to results
- `HeatingLoad` time series and annual summary data to results

## v0.20.0
### Added
- `Boiler` tech from the REopt_API (known as NewBoiler in API)
- `SteamTurbine` tech from the REopt_API
### Changed
- Made some modifications to thermal tech results to be consistent with naming conventions of REopt.jl
### Fixed
- Bug for scalar `ElectricTariff.wholesale_rate`
- Bug in which CHP could not charge Hot TES

## v0.19.0
### Changed
The following name changes were made: 
- Change "pct" to "rate_fraction" for "discount", "escalation", names containing "tax_pct" (financial terms)
- Change "pct" to "fraction" for all other variable names (e.g., "min_soc", "min_turndown_")
- Change `prod_factor_series` to `production_factor_series` and rename some internal methods and variables to match
- Change four (4) CHP input field names to spell out `electric` (from `elec`) and `efficiency` (from `effic`) for electric and thermal efficiencies
### Added
- Add schedule-based `FlatLoad`s which take the annual or monthly energy input and create a load profile based on the specified type of schedule. The load is "flat" (the same) for all hours within the chosen schedule.
- Add `addressable_load_fraction` inputs for `SpaceHeatingLoad` and `DomesticHotWaterLoad` which effectively ignores a portion of the entered loads. These inputs can be scalars (applied to all time steps of the year), monthly (applied to the timesteps of each month), or of length 8760 * `time_steps_per_hour`.
- Add a validation error for cooling in the case that the cooling electric load is greater than the total electric load.
  
## v0.18.1
### Removed
- **include_climate_in_objective**, **pwf_emissions_cost_CO2_grid**, and **pwf_emissions_cost_CO2_onsite** unnecessarily included in Site results

## v0.18.0
### Added
- Add geothermal heat pump (`GHP`), also known as ground-source heat pump (GSHP), to the REopt model for serving heating and cooling loads (typically the benefits include electrifying the heating load and improving the efficiency of cooling).
    - The unregistered `GhpGhx` package (https://github.com/NREL/GhpGhx.jl) is a "conditional" dependency of REopt by using the Requires.jl package, and this package sizes the ground heat exchanger (GHE) and gets the hourly electric consumption of the `GHP` for the specified heating and cooling loads that it serves.
    - The `GhpGhx` module calls for sizing the GHE can only be done if you first "add https://github.com/NREL/GhpGhx.jl" to the environment and then load the package by "using GhpGhx" before running REopt with `GHP`.
    - The `GHP` size and dispatch of the different `GHP` options is pre-determined by the `GhpGhx` package, so the REopt model just chooses one or none of the `GHP` options with a binary decision variable.
### Changed
- Change default value for `wind.jl` **operating_reserve_required_pct** from 0.1 to 0.5 (only applicable when **off_grid_flag**=_True_.)
- allow user to specify emissions_region in ElectricUtility, which is used instead of lat/long to look up AVERT data if emissions factors aren't provided by the user
- Updated results keys in `results/absorption_chiller.jl`
### Fixed
- Add **wholesale_rate** and **emissions_factor_series_lb_\<pollutant\>_per_kwh** inputs to the list of inputs that `dictkeys_tosymbols()` tries to convert to type _Array{Real}_. Due to serialization, when list inputs come from the API, they are of type _Array{Any}_ so must be converted to match type required by the constructors they are passed to.
- Fixed bug in calcuation of power delivered to cold thermal storage by the electric chiller in `results/existing_chiller.jl`.

## v0.17.0
### Added
- Emissions
    - add emissions factors for CO2, NOx, SO2, and PM25 to inputs of all fuel burning technologies
    - add emissions factor series for CO2, NOx, SO2, and PM25 to `ElectricUtility` inputs and use [AVERT v3.2](https://www.epa.gov/avert/download-avert) (2021 data) if not provided
    - add `include_climate_in_objective` and `include_health_in_objective` to `Settings` inputs
    - constrain CO2 emissions based on `CO2_emissions_reduction_min_pct`, `CO2_emissions_reduction_max_pct`, and `include_exported_elec_emissions_in_total` added to `Site` inputs
    - add emissions costs to `Financial` inputs and use EASIUR data for NOx, SO2, and PM25 if not provided
    - report emissions and their cost in `Site` (on-site and total) and `ElectricUtility` (grid) results
    - calculate `breakeven_cost_of_emissions_reduction_per_tonnes_CO2` for `Financial` results
- Renewable energy percentage
    - calculate renewable energy percentage (electric only and total) and add to `Site` results
    - add `renewable_electricity_min_pct`, `renewable_electricity_max_pct`, and `include_exported_renewable_electricity_in_total` to `Site` inputs
    - add `fuel_renewable_energy_pct` input for all fuel burning technologies
    - constrain renewable electricity percentage based on user inputs
- Add "Emissions and Renewable Energy Percent" testset
### Changed
- Allow Wind tech to be included when `off_grid_flag` is true
- Add `operating_reserve_required_pct` to Wind struct and incorporate wind into operating reserve constraints
- Add hot, cold TES results for MPC model
- Update documentation and add `docs/devdeploy.jl` to locally host the REopt.jl documentation 
- Make `ExistingBoiler` `fuel_cost_per_mmbtu` a required input
- In `production_factor.jl`, include lat-long coordinates if-statement to determine whether the "nsrdb" dataset should be used in call to PVWatts. Accounts for recent updates to NSRDB data used by PVWatts (v6). If outside of NSRDB range, use "intl" (international) dataset.
- Don't trigger GitHub 'Run test' workflow on a push that only changes README.md and/or CHANGELOG.md
- Avoid triggering duplicate GitHub workflows. When pushing to a branch that's in a PR, only trigger tests on the push not on the PR sync also.
### Fixed
- Bug fix to constrain dvCurtail in `time_steps_without_grid`
- Bug fix to report accurate wind ["year_one_to_load_series_kw"] in results/wind.jl (was previously not accounting for curtailed wind)

## v0.16.2
### Changed
- Update PV defaults to tilt=10 for rooftop, tilt = abs(lat) for ground mount, azimuth = 180 for northern lats, azimuth = 0 for southern lats.
### Fixed
- bug fix for Generator inputs to allow for time_steps_per_hour > 1
- change various `Float64` types to `Real` to allow integers too

## v0.16.1
### Fixed
- bug fix for outage simulator when `microgrid_only=true`

## v0.16.0
### Added
Allows users to model "off-grid" systems as a year-long outage: 
- add flag to "turn on" off-grid modeling `Settings.off_grid_flag` 
- when `off_grid_flag` is "true", adjust default values in core/ `electric_storage`, `electric_load`, `financial`, `generator`, `pv` 
- add operating reserve requirement inputs, outputs, and constraints based on load and PV generation 
- add minimum load met percent input and constraint
- add generator replacement year and cost (for off-grid and on-grid) 
- add off-grid additional annual costs (tax deductible) and upfront capital costs (depreciable via straight line depreciation)
### Changed
Name changes: 
- consistently append `_before_tax` and `_after_tax` to results names 
- change all instances of `timestep` to `time_step` and `timesteps` to `time_steps`
Other changes:
- report previously missing lcc breakdown components, all reported in `results/financial.jl`  
- change variable types from Float to Real to allow users to enter Ints (where applicable)
- `year_one_coincident_peak_cost_after_tax` is now correctly multiplied by `(1 - p.s.financial.offtaker_tax_pct)`

## v0.15.2
### Fixed
- bug fix for 15 & 30 minute electric, heating, and cooling loads
- bug fix for URDB fixed charges
- bug fix for default `Wind` `installed_cost_per_kw` and `federal_itc_pct`

## v0.15.1
### Added
- add `AbsorptionChiller` technology
- add `ElectricStorage.minimum_avg_soc_fraction` input and constraint

## v0.15.0
### Fixed
- bug fix in outage_simulator
### Changed
- allow Real Generator inputs (not just Float64)
- add "_series" to "Outages" outputs that are arrays [breaking]

## v0.14.0
### Changed
- update default values from v2 of API [breaking]
### Added
- add ElectricStorage degradation accounting and maintenance strategies
- finish cooling loads

## v0.13.0
### Added
- add FlexibleHVAC model (still testing)
- start thermal energy storage modeling
- add `ExistingBoiler` and `ExistingChiller`
- add `MPCLimits` inputs:
    - `grid_draw_limit_kw_by_time_step`
    - `export_limit_kw_by_time_step`
### Changed
- refactor `Storage` as `ElectricStorage`
### Fixed
- fix bugs for time_steps_per_hour != 1


## v0.12.4
### Removed
- rm "Lite" from docs
### Changed
- prioritize `urdb_response` over `urdb_label` in `ElectricTariff`

## v0.12.3
### Added
- add utils for PVwatts: `get_ambient_temperature` and `get_pvwatts_prodfactor`

## v0.12.2
### Added
- add CHP technology, including supplementary firing
- add URDB "sell" value from `energyratestructure` to wholesale rate
- update docs
### Changed
- allow annual or monthly energy rate w/o demand rate
- allow integer latitude/longitude

## v0.12.1
### Added
- add ExistingBoiler and CRB heating loads

## v0.12.0
### Changed
- change all output keys starting with "total_" or "net_" to "lifecycle_" (except "net_present_cost")
- update pv results for single PV in an array
### Fixed
- bug fix in urdb.jl when rate_name not found

## v0.11.0
### Added
- add ElectricLoad.blended_doe_reference_names & blended_doe_reference_percents
- add ElectricLoad.monthly_totals_kwh builtin profile scaling
- add ElectricTariff inputs: `add_monthly_rates_to_urdb_rate`, `tou_energy_rates_per_kwh`, 
    `add_tou_energy_rates_to_urdb_rate`, `coincident_peak_load_charge_per_kw`, `coincident_peak_load_active_time_steps`
### Fixed
- handle multiple PV outputs

## v0.10.0
### Added
- add modeling capability for tiered rates (energy, TOU demand, and monthly demand charges)
    - all of these tiered rates require binaries, which are conditionally added to the model
- add modeling capability for lookback demand charges
- add more outputs from the API (eg. `initial_capital_costs`)
- add option to run Business As Usual scenario in parallel with optimal scenario (default is `true`)
- add incentives (and cost curves) to `Wind` and `Generator`
### Changed
- removed "_us_dollars" from all names and generally aligned names with API
- renamed `outage_start(end)_time_step` to `outage_start(end)_time_step`
### Fixed
- fixed bug in URDB fixed charges

## v0.9.0
### Changed
- `ElectricTariff.NEM` boolean is now determined by `ElectricUtility.net_metering_limit_kw` (true if limit > 0)
### Added
- add `ElectricUtility` inputs for `net_metering_limit_kw` and `interconnection_limit_kw`
- add binary choice for net metering vs. wholesale export
- add `ElectricTariff.export_rate_beyond_net_metering_limit` input (scalar or vector allowed)
- add `can_net_meter`, `can_wholesale`, `can_export_beyond_nem_limit` tech inputs (`PV`, `Wind`, `Generator`)

## v0.8.0
### Added
- add `Wind` module, relying on System Advisor Model Wind module for production factors and Wind Toolkit for resource data
- new `ElectricTariff` input options:
    - `urdb_utility_name` and `urdb_rate_name`
    - `blended_annual_energy_rate` and `blended_annual_demand_rate`
- add two capabilities that require binary variables:
    - tax, production, and capacity incentives for PV (compatible with any energy generation technology)
    - technology cost curve modeling capability
    - both of these capabilities are only used for the technologies that require them (based on input values), unlike the API which always models these capabilities (and therefore always includes the binary variables).
- Three new tests: Wind, Blended Tariff and Complex Incentives (which aligns with API results)
### Changed
- `cost_per_kw[h]` input fields are now `installed_cost_per_kw[h]` to distinguish it from other costs like `om_cost_per_kw[h]`
- Financial input field refactored: `two_party_ownership` -> `third_party_ownership`
- `total_itc_pct` -> `federal_itc_pct` on technology inputs

## v0.7.3
### Fixed
- outage results processing would fail sometimes when an integer variable was not exact (e.g. 1.000000001)
- fixed `simulate_outages` for revised results formats (key names changed to align with the REopt API)

## v0.7.2
### Added
- add PV.production_factor_series input (can skip PVWatts call)
- add `run_mpc` capability, which dispatches DER for minimum energy cost over an arbitrary time horizon

## v0.7.1
### Fixed
- ElectricLoad.city default is empty string, must be filled in before annual_kwh look up

## v0.7.0
### Removed
- removed Storage.can_grid_export
### Added
- add optional integer constraint to prevent simultaneous export and import of power
- add warnings when adding integer variables
- add ability to add LinDistFlow constraints to multinode models
### Changed
- no longer require `ElectricLoad.city` input (look up ASHRAE climate zone from lat/lon)
- compatible with Julia 1.6

## v0.6.0
### Added
- add multi-node (site) capability for PV and Storage
- started documentation process using Github Pages and Documenter.jl
### Changed
- restructured outputs to align with the input structure, for example top-level keys added for `ElectricTariff` and `PV` in the outputs

## v0.5.3
### Changed
- compatible with Julia 1.5

## v0.5.2
### Fixed
- outage_simulator.jl had bug with summing over empty `Any[]`
### Added
- add optional `microgrid_only` arg to simulate_outages

## v0.5.1
### Added
- added outage dispatch outputs and speed up their derivation
### Removed
- removed redundant generator minimum turn down constraint

## v0.5.0
### Fixed
- handle missing input key for `year_one_soc_series_pct` in `outage_simulator` 
- remove erroneous `total_unserved_load = 0` output
- `dvUnservedLoad` definition was allowing microgrid production to storage and curtailment to be double counted towards meeting critical load
#### Added
- add `unserved_load_per_outage` output

## v0.4.1
### Fixed
- removed `total_unserved_load` output because it can take hours to generate and can error out when outage indices are not consecutive
### Added
- add @info for time spent processing results

## v0.4.0
### Added
- add `simulate_outages` function (similar to REopt API outage simulator)
- removed MutableArithmetics package from Project.toml (since JuMP now has method for `value(::MutableArithmetics.Zero)`)
- add outage related outputs:
    - Generator_mg_kw
    - mg_Generator_upgrade_cost
    - mg_Generator_fuel_used
    - mg_PV_upgrade_cost
    - mg_storage_upgrade_cost
    - dvUnservedLoad array
    - max_outage_cost_per_outage_duration
### Changed
- allow value_of_lost_load_per_kwh values to be subtype of Real (rather than only Real)
- add `run_reopt` method for scenario Dict

## v0.3.0
### Added
- add separate decision variables and constraints for microgrid tech capacities
    - new Site input `mg_tech_sizes_equal_grid_sizes` (boolean), when `false` the microgrid tech capacities are constrained to be <= the grid connected tech capacities
### Fixed
- allow non-integer `outage_probabilities`
- correct `total_unserved_load` output
- don't `add_min_hours_crit_ld_met_constraint` unless `min_resil_time_steps <= length(elecutil.outage_time_steps)`

## v0.2.0
### Added
- add support for custom ElectricLoad `loads_kw` input
- include existing capacity in microgrid upgrade cost
    - previously only had to pay to upgrade new capacity
- implement ElectricLoad `loads_kw_is_net` and `critical_loads_kw_is_net`
    - add existing PV production to raw load profile if `true`
- add `min_resil_time_steps` input and optional constraint for minimum time_steps that critical load must be met in every outage
### Fixed
- enforce storage cannot grid charge

## v0.1.1 Fix build.jl
deps/build.jl had a relative path dependency, fixed with an absolute path.

## v0.1.0 Initial release
This package is currently under development and only has a subset of capabilities of the REopt model used in the REopt API. For example, the Wind model, tiered electric utility tariffs, and piecewise linear cost curves are not yet modeled in this code. However this code is easier to use than the API (only dependencies are Julia and a solver) and has a novel model for uncertain outages.
