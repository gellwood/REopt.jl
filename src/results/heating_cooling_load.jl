# REopt®, Copyright (c) Alliance for Sustainable Energy, LLC. See also https://github.com/NREL/REopt.jl/blob/master/LICENSE.
"""
`CoolingLoad` results keys:
- `load_series_ton` # vector of site cooling load in every time step
- `annual_calculated_tonhour` # sum of the `load_series_ton`. Annual site total cooling load [tonhr]
- `electric_chiller_base_load_series_kw` # Hourly total base load drawn from chiller [kW-electric]
- `annual_electric_chiller_base_load_kwh` # Annual total base load drawn from chiller [kWh-electric]

!!! note "'Series' and 'Annual' energy outputs are average annual"
	REopt performs load balances using average annual production values for technologies that include degradation. 
	Therefore, all timeseries (`_series`) and `annual_` results should be interpretted as energy outputs averaged over the analysis period. 

"""
function add_cooling_load_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
    # Adds the `ElectricLoad` results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
    # Note: the node number is an empty string if evaluating a single `Site`.

    r = Dict{String, Any}()

    load_series_kw = p.s.cooling_load.loads_kw_thermal
    r["load_series_ton"] = load_series_kw/ KWH_THERMAL_PER_TONHOUR

    r["electric_chiller_base_load_series_kw"] = load_series_kw ./ p.s.cooling_load.existing_chiller_cop

    r["annual_calculated_tonhour"] = round(
        sum(r["load_series_ton"]) / p.s.settings.time_steps_per_hour, digits=2
    )
    
    r["annual_electric_chiller_base_load_kwh"] = round(
        sum(r["electric_chiller_base_load_series_kw"]) / p.s.settings.time_steps_per_hour, digits=2
    )

    d["CoolingLoad"] = r
    nothing
end

"""
`HeatingLoad` results keys:
- `dhw_thermal_load_series_mmbtu_per_hour` vector of site domestic hot water load in every time step
- `space_heating_thermal_load_series_mmbtu_per_hour` vector of site space heating load in every time step
- `total_heating_thermal_load_series_mmbtu_per_hour` vector of sum heating load in every time step
- `annual_calculated_dhw_thermal_load_mmbtu` sum of the `dhw_load_series_mmbtu_per_hour`
- `annual_calculated_space_heating_thermal_load_mmbtu` sum of the `space_heating_thermal_load_series_mmbtu_per_hour`
- `annual_calculated_total_heating_thermal_load_mmbtu` sum of the `total_heating_thermal_load_series_mmbtu_per_hour`
- `annual_calculated_dhw_boiler_fuel_load_mmbtu`
- `annual_calculated_space_heating_boiler_fuel_load_mmbtu`
- `annual_calculated_total_heating_boiler_fuel_load_mmbtu`
"""
function add_heating_load_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
    # Adds the `ElectricLoad` results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
    # Note: the node number is an empty string if evaluating a single `Site`.

    r = Dict{String, Any}()

    dhw_load_series_kw = p.s.dhw_load.loads_kw
    space_heating_load_series_kw = p.s.space_heating_load.loads_kw

    existing_boiler_efficiency = nothing
    if isnothing(p.s.existing_boiler)
        existing_boiler_efficiency = EXISTING_BOILER_EFFICIENCY
    else
        existing_boiler_efficiency = p.s.existing_boiler.efficiency
    end
    
    r["dhw_thermal_load_series_mmbtu_per_hour"] = dhw_load_series_kw ./ KWH_PER_MMBTU
    r["space_heating_thermal_load_series_mmbtu_per_hour"] = space_heating_load_series_kw ./ KWH_PER_MMBTU
    r["total_heating_thermal_load_series_mmbtu_per_hour"] = r["dhw_thermal_load_series_mmbtu_per_hour"] .+ r["space_heating_thermal_load_series_mmbtu_per_hour"]

    r["dhw_boiler_fuel_load_series_mmbtu_per_hour"] = dhw_load_series_kw ./ KWH_PER_MMBTU ./ existing_boiler_efficiency
    r["space_heating_boiler_fuel_load_series_mmbtu_per_hour"] = space_heating_load_series_kw ./ KWH_PER_MMBTU ./ existing_boiler_efficiency
    r["total_heating_boiler_fuel_load_series_mmbtu_per_hour"] = r["dhw_boiler_fuel_load_series_mmbtu_per_hour"] .+ r["space_heating_boiler_fuel_load_series_mmbtu_per_hour"]

    r["annual_calculated_dhw_thermal_load_mmbtu"] = round(
        sum(r["dhw_thermal_load_series_mmbtu_per_hour"]) / p.s.settings.time_steps_per_hour, digits=2
    )
    r["annual_calculated_space_heating_thermal_load_mmbtu"] = round(
        sum(r["space_heating_thermal_load_series_mmbtu_per_hour"]) / p.s.settings.time_steps_per_hour, digits=2
    )
    r["annual_calculated_total_heating_thermal_load_mmbtu"] = r["annual_calculated_dhw_thermal_load_mmbtu"] + r["annual_calculated_space_heating_thermal_load_mmbtu"]
    
    r["annual_calculated_dhw_boiler_fuel_load_mmbtu"] = r["annual_calculated_dhw_thermal_load_mmbtu"] / existing_boiler_efficiency
    r["annual_calculated_space_heating_boiler_fuel_load_mmbtu"] = r["annual_calculated_space_heating_thermal_load_mmbtu"] / existing_boiler_efficiency
    r["annual_calculated_total_heating_boiler_fuel_load_mmbtu"] = r["annual_calculated_total_heating_thermal_load_mmbtu"] / existing_boiler_efficiency

    d["HeatingLoad"] = r
    nothing
end