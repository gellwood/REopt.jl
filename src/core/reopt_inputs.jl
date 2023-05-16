# *********************************************************************************
# REopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************
"""
    REoptInputs

The data structure for all the inputs necessary to construct the JuMP model.
```julia
struct REoptInputs <: AbstractInputs
    s::ScenarioType
    techs::Techs
    min_sizes::Dict{String, <:Real}  # (techs)
    max_sizes::Dict{String, <:Real}  # (techs)
    existing_sizes::Dict{String, <:Real}  # (techs)
    cap_cost_slope::Dict{String, Any}  # (techs)
    om_cost_per_kw::Dict{String, <:Real}  # (techs)
    cop::Dict{String, <:Real}  # (techs.cooling)
    thermal_cop::Dict{String, <:Real}  # (techs.absorption_chiller)
    time_steps::UnitRange
    time_steps_with_grid::Array{Int, 1}
    time_steps_without_grid::Array{Int, 1}
    hours_per_time_step::Real
    months::UnitRange
    production_factor::DenseAxisArray{<:Real, 2}  # (techs, time_steps)
    levelization_factor::Dict{String, <:Real,}  # (techs)
    value_of_lost_load_per_kwh::Array{<:Real, 1}
    pwf_e::Real
    pwf_om::Real
    pwf_fuel::Dict{String, <:Real}
    pwf_emissions_cost::Dict{String, Float64} # Cost of emissions present worth factors for grid and onsite fuelburn emissions [unitless]
    pwf_grid_emissions::Dict{String, Float64} # Emissions [lbs] present worth factors for grid emissions [unitless]
    pwf_offtaker::Real 
    pwf_owner::Real
    third_party_factor::Real
    pvlocations::Array{Symbol, 1}
    maxsize_pv_locations::DenseAxisArray{<:Real, 1}  # indexed on pvlocations
    pv_to_location::Dict{String, Dict{Symbol, Int64}}  # (techs.pv, pvlocations)
    ratchets::UnitRange
    techs_by_exportbin::Dict{Symbol, AbstractArray}  # keys can include [:NEM, :WHL, :CUR]
    export_bins_by_tech::Dict
    n_segs_by_tech::Dict{String, Int}
    seg_min_size::Dict{String, Dict{Int, <:Real}}
    seg_max_size::Dict{String, Dict{Int, <:Real}}
    seg_yint::Dict{String, Dict{Int, <:Real}}
    pbi_pwf::Dict{String, Any}  # (pbi_techs)
    pbi_max_benefit::Dict{String, Any}  # (pbi_techs)
    pbi_max_kw::Dict{String, Any}  # (pbi_techs)
    pbi_benefit_per_kwh::Dict{String, Any}  # (pbi_techs)
    timed_pbi_pwf::Dict{String, Any}  # (timed_pbi_techs)
    timed_pbi_max_benefit::Dict{String, Any}  # (timed_pbi_techs)
    timed_pbi_max_kw::Dict{String, Any}  # (timed_pbi_techs)
    timed_pbi_benefit_per_kwh::Dict{String, Any}  # (timed_pbi_techs)    
    boiler_efficiency::Dict{String, <:Real}
    fuel_cost_per_kwh::Dict{String, AbstractArray}  # Fuel cost array for all time_steps
    ghp_options::UnitRange{Int64}  # Range of the number of GHP options
    require_ghp_purchase::Int64  # 0/1 binary if GHP purchase is forced/required
    ghp_heating_thermal_load_served_kw::Array{Float64,2}  # Array of heating load (thermal!) profiles served by GHP
    ghp_cooling_thermal_load_served_kw::Array{Float64,2}  # Array of cooling load profiles served by GHP
    space_heating_thermal_load_reduction_with_ghp_kw::Array{Float64,2}  # Array of heating load reduction (thermal!) profile from GHP retrofit
    cooling_thermal_load_reduction_with_ghp_kw::Array{Float64,2}  # Array of cooling load reduction (thermal!) profile from GHP retrofit
    ghp_electric_consumption_kw::Array{Float64,2}  # Array of electric load profiles consumed by GHP
    ghp_installed_cost::Array{Float64,1}  # Array of installed cost for GHP options
    ghp_om_cost_year_one::Array{Float64,1}  # Array of O&M cost for GHP options    
    tech_renewable_energy_fraction::Dict{String, <:Real} # (techs)
    tech_emissions_factors_CO2::Dict{String, <:Real} # (techs)
    tech_emissions_factors_NOx::Dict{String, <:Real} # (techs)
    tech_emissions_factors_SO2::Dict{String, <:Real} # (techs)
    tech_emissions_factors_PM25::Dict{String, <:Real} # (techs)
    techs_operating_reserve_req_fraction::Dict{String, <:Real} # (techs.all)
end
```
"""
struct REoptInputs{ScenarioType <: AbstractScenario} <: AbstractInputs
    s::ScenarioType
    techs::Techs
    min_sizes::Dict{String, <:Real}  # (techs)
    max_sizes::Dict{String, <:Real}  # (techs)
    existing_sizes::Dict{String, <:Real}  # (techs)
    cap_cost_slope::Dict{String, Any}  # (techs)
    om_cost_per_kw::Dict{String, <:Real}  # (techs)
    cop::Dict{String, <:Real}  # (techs.cooling)
    thermal_cop::Dict{String, <:Real}  # (techs.absorption_chiller)
    time_steps::UnitRange
    time_steps_with_grid::Array{Int, 1}
    time_steps_without_grid::Array{Int, 1}
    hours_per_time_step::Real
    months::UnitRange
    production_factor::DenseAxisArray{<:Real, 2}  # (techs, time_steps)
    levelization_factor::Dict{String, <:Real}  # (techs)
    value_of_lost_load_per_kwh::Array{<:Real, 1}
    pwf_e::Real
    pwf_om::Real
    pwf_fuel::Dict{String, <:Real}
    pwf_emissions_cost::Dict{String, Float64} # Cost of emissions present worth factors for grid and onsite fuelburn emissions [unitless]
    pwf_grid_emissions::Dict{String, Float64} # Emissions [lbs] present worth factors for grid emissions [unitless]
    pwf_offtaker::Real 
    pwf_owner::Real
    third_party_factor::Real
    pvlocations::Array{Symbol, 1}
    maxsize_pv_locations::DenseAxisArray{<:Real, 1}  # indexed on pvlocations
    pv_to_location::Dict{String, Dict{Symbol, Int64}}  # (techs.pv, pvlocations)
    ratchets::UnitRange
    techs_by_exportbin::Dict{Symbol, AbstractArray}  # keys can include [:NEM, :WHL, :CUR]
    export_bins_by_tech::Dict
    n_segs_by_tech::Dict{String, Int}
    seg_min_size::Dict{String, Dict{Int, Real}}
    seg_max_size::Dict{String, Dict{Int, Real}}
    seg_yint::Dict{String, Dict{Int, Real}}
    pbi_pwf::Dict{String, Any}  # (pbi_techs)
    pbi_max_benefit::Dict{String, Any}  # (pbi_techs)
    pbi_max_kw::Dict{String, Any}  # (pbi_techs)
    pbi_benefit_per_kwh::Dict{String, Any}  # (pbi_techs)
    timed_pbi_pwf::Dict{String, Any}  # (timed_pbi_techs) # Added
    timed_pbi_max_benefit::Dict{String, Any}  # (timed_pbi_techs)
    timed_pbi_max_kw::Dict{String, Any}  # (timed_pbi_techs)
    timed_pbi_benefit_per_kwh::Dict{String, Any}  # (timed_pbi_techs) 
    boiler_efficiency::Dict{String, <:Real}
    fuel_cost_per_kwh::Dict{String, AbstractArray}  # Fuel cost array for all time_steps
    ghp_options::UnitRange{Int64}  # Range of the number of GHP options
    require_ghp_purchase::Int64  # 0/1 binary if GHP purchase is forced/required
    ghp_heating_thermal_load_served_kw::Array{Float64,2}  # Array of heating load (thermal!) profiles served by GHP
    ghp_cooling_thermal_load_served_kw::Array{Float64,2}  # Array of cooling load profiles served by GHP
    space_heating_thermal_load_reduction_with_ghp_kw::Array{Float64,2}  # Array of heating load reduction (thermal!) profile from GHP retrofit
    cooling_thermal_load_reduction_with_ghp_kw::Array{Float64,2}  # Array of cooling load reduction (thermal!) profile from GHP retrofit
    ghp_electric_consumption_kw::Array{Float64,2}  # Array of electric load profiles consumed by GHP
    ghp_installed_cost::Array{Float64,1}  # Array of installed cost for GHP options
    ghp_om_cost_year_one::Array{Float64,1}  # Array of O&M cost for GHP options
    tech_renewable_energy_fraction::Dict{String, <:Real} # (techs)
    tech_emissions_factors_CO2::Dict{String, <:Real} # (techs)
    tech_emissions_factors_NOx::Dict{String, <:Real} # (techs)
    tech_emissions_factors_SO2::Dict{String, <:Real} # (techs)
    tech_emissions_factors_PM25::Dict{String, <:Real} # (techs)
    techs_operating_reserve_req_fraction::Dict{String, <:Real} # (techs.all)
end


"""
    REoptInputs(fp::String)

Use `fp` to load in JSON scenario:
```
function REoptInputs(fp::String)
    s = Scenario(JSON.parsefile(fp))
    REoptInputs(s)
end
```
Useful if you want to manually modify REoptInputs before solving the model.
"""
function REoptInputs(fp::String)
    s = Scenario(JSON.parsefile(fp))
    REoptInputs(s)
end


"""
    REoptInputs(s::AbstractScenario)

Constructor for REoptInputs. Translates the `Scenario` into all the data necessary for building the JuMP model.
"""
function REoptInputs(s::AbstractScenario)

    time_steps = 1:length(s.electric_load.loads_kw)
    hours_per_time_step = 1 / s.settings.time_steps_per_hour
    techs, pv_to_location, maxsize_pv_locations, pvlocations, 
        production_factor, max_sizes, min_sizes, existing_sizes, cap_cost_slope, om_cost_per_kw, n_segs_by_tech, 
        seg_min_size, seg_max_size, seg_yint, techs_by_exportbin, export_bins_by_tech, boiler_efficiency,
        tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, 
        tech_emissions_factors_PM25, cop, techs_operating_reserve_req_fraction, thermal_cop, fuel_cost_per_kwh = setup_tech_inputs(s)

    pbi_pwf, pbi_max_benefit, pbi_max_kw, pbi_benefit_per_kwh = setup_pbi_inputs(s, techs)

    timed_pbi_pwf, timed_pbi_max_benefit, timed_pbi_max_kw, timed_pbi_benefit_per_kwh = setup_timed_pbi_inputs(s, techs)

    months = 1:12

    levelization_factor, pwf_e, pwf_om, pwf_fuel, pwf_emissions_cost, pwf_grid_emissions, third_party_factor, pwf_offtaker, pwf_owner = setup_present_worth_factors(s, techs)
    # the following hardcoded values for levelization_factor matches the public REopt API value
    # and makes the test values match.
    # the REopt code herein uses the Desktop method for levelization_factor, which is more accurate
    # (Desktop has non-linear degradation vs. linear degradation in API)
    # levelization_factor = Dict("PV" => 0.9539)
    # levelization_factor = Dict("ground" => 0.942238, "roof_east" => 0.942238, "roof_west" => 0.942238)
    # levelization_factor["PV"] = 0.9539
    # levelization_factor["Generator"] = 1.0
    time_steps_with_grid, time_steps_without_grid, = setup_electric_utility_inputs(s)
    
    ghp_options, require_ghp_purchase, ghp_heating_thermal_load_served_kw, 
        ghp_cooling_thermal_load_served_kw, space_heating_thermal_load_reduction_with_ghp_kw, 
        cooling_thermal_load_reduction_with_ghp_kw, ghp_electric_consumption_kw, 
        ghp_installed_cost, ghp_om_cost_year_one = setup_ghp_inputs(s, time_steps, time_steps_without_grid)

    if any(pv.existing_kw > 0 for pv in s.pvs)
        adjust_load_profile(s, production_factor)
    end

    REoptInputs(
        s,
        techs,
        min_sizes,
        max_sizes,
        existing_sizes,
        cap_cost_slope,
        om_cost_per_kw,
        cop,
        thermal_cop,
        time_steps,
        time_steps_with_grid,
        time_steps_without_grid,
        hours_per_time_step,
        months,
        production_factor,
        levelization_factor,
        typeof(s.financial.value_of_lost_load_per_kwh) <: Array{<:Real, 1} ? s.financial.value_of_lost_load_per_kwh : fill(s.financial.value_of_lost_load_per_kwh, length(time_steps)),
        pwf_e,
        pwf_om,
        pwf_fuel,
        pwf_emissions_cost,
        pwf_grid_emissions,
        pwf_offtaker, 
        pwf_owner,
        third_party_factor,
        pvlocations,
        maxsize_pv_locations,
        pv_to_location,
        1:length(s.electric_tariff.tou_demand_ratchet_time_steps),  # ratchets
        techs_by_exportbin,
        export_bins_by_tech,
        n_segs_by_tech,
        seg_min_size,
        seg_max_size,
        seg_yint,
        pbi_pwf, 
        pbi_max_benefit, 
        pbi_max_kw, 
        pbi_benefit_per_kwh,
        timed_pbi_pwf,  # Added
        timed_pbi_max_benefit, 
        timed_pbi_max_kw, 
        timed_pbi_benefit_per_kwh,
        boiler_efficiency,
        fuel_cost_per_kwh,
        ghp_options,
        require_ghp_purchase,
        ghp_heating_thermal_load_served_kw,
        ghp_cooling_thermal_load_served_kw,
        space_heating_thermal_load_reduction_with_ghp_kw,
        cooling_thermal_load_reduction_with_ghp_kw,
        ghp_electric_consumption_kw,
        ghp_installed_cost,
        ghp_om_cost_year_one,
        tech_renewable_energy_fraction, 
        tech_emissions_factors_CO2, 
        tech_emissions_factors_NOx, 
        tech_emissions_factors_SO2, 
        tech_emissions_factors_PM25,
        techs_operating_reserve_req_fraction 
    )
end


"""
    function setup_tech_inputs(s::AbstractScenario)

Create data arrays associated with techs necessary to build the JuMP model.
"""
function setup_tech_inputs(s::AbstractScenario)
    #TODO: create om_cost_per_kwh in here as well as om_cost_per_kw? (Generator, CHP, SteamTurbine, and Boiler have this)

    techs = Techs(s)

    boiler_efficiency = Dict{String, Float64}()
    fuel_cost_per_kwh = Dict{String, AbstractArray}()

    # REoptInputs indexed on techs:
    max_sizes = Dict(t => 0.0 for t in techs.all)
    min_sizes = Dict(t => 0.0 for t in techs.all)
    existing_sizes = Dict(t => 0.0 for t in techs.all)
    cap_cost_slope = Dict{String, Any}()
    om_cost_per_kw = Dict(t => 0.0 for t in techs.all)
    production_factor = DenseAxisArray{Float64}(undef, techs.all, 1:length(s.electric_load.loads_kw))
    tech_renewable_energy_fraction = Dict(t => 1.0 for t in techs.all)
    # !!! note: tech_emissions_factors are in lb / kWh of fuel burned (gets multiplied by kWh of fuel burned, not kWh electricity consumption, ergo the use of the HHV instead of fuel slope)
    tech_emissions_factors_CO2 = Dict(t => 0.0 for t in techs.all)
    tech_emissions_factors_NOx = Dict(t => 0.0 for t in techs.all)
    tech_emissions_factors_SO2 = Dict(t => 0.0 for t in techs.all)
    tech_emissions_factors_PM25 = Dict(t => 0.0 for t in techs.all)
    cop = Dict(t => 0.0 for t in techs.cooling)
    techs_operating_reserve_req_fraction = Dict(t => 0.0 for t in techs.all)
    thermal_cop = Dict(t => 0.0 for t in techs.absorption_chiller)

    # export related inputs
    techs_by_exportbin = Dict{Symbol, AbstractArray}(k => [] for k in s.electric_tariff.export_bins)
    export_bins_by_tech = Dict{String, Array{Symbol, 1}}()

    # REoptInputs indexed on techs.segmented
    n_segs_by_tech = Dict{String, Int}()
    seg_min_size = Dict{String, Dict{Int, Real}}()
    seg_max_size = Dict{String, Dict{Int, Real}}()
    seg_yint = Dict{String, Dict{Int, Real}}()

    pvlocations = [:roof, :ground, :both]
    d = Dict(loc => 0 for loc in pvlocations)
    pv_to_location = Dict(t => copy(d) for t in techs.pv)
    maxsize_pv_locations = DenseAxisArray([1.0e9, 1.0e9, 1.0e9], pvlocations)
    # default to large max size per location. Max size by roof, ground, both

    if !isempty(techs.pv)
        setup_pv_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, om_cost_per_kw, production_factor,
                        pvlocations, pv_to_location, maxsize_pv_locations, techs.segmented, n_segs_by_tech, 
                        seg_min_size, seg_max_size, seg_yint, techs_by_exportbin, techs)
    end

    if "Wind" in techs.all
        setup_wind_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, om_cost_per_kw, production_factor, 
            techs_by_exportbin, techs.segmented, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, techs)
    end

    if "Generator" in techs.all
        setup_gen_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, om_cost_per_kw, production_factor, 
            techs_by_exportbin, techs.segmented, n_segs_by_tech, seg_min_size, seg_max_size, 
            seg_yint, techs, tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, 
            fuel_cost_per_kwh)
    end

    if "ExistingBoiler" in techs.all
        setup_existing_boiler_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, boiler_efficiency,
            tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh)
    end

    if "Boiler" in techs.all
        setup_boiler_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, 
            boiler_efficiency, production_factor, fuel_cost_per_kwh)
    end

    if "CHP" in techs.all
        setup_chp_inputs(s, max_sizes, min_sizes, cap_cost_slope, om_cost_per_kw, 
            production_factor, techs_by_exportbin, techs.segmented, n_segs_by_tech, seg_min_size, seg_max_size, 
            seg_yint, techs,
            tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh)
    end

    if "ExistingChiller" in techs.all
        setup_existing_chiller_inputs(s, max_sizes, min_sizes, existing_sizes, cap_cost_slope, cop)
    else
        cop["ExistingChiller"] = 1.0
    end

    if "AbsorptionChiller" in techs.all
        setup_absorption_chiller_inputs(s, max_sizes, min_sizes, cap_cost_slope, cop, thermal_cop, om_cost_per_kw)
    else
        cop["AbsorptionChiller"] = 1.0
        thermal_cop["AbsorptionChiller"] = 1.0
    end

    if "SteamTurbine" in techs.all
        setup_steam_turbine_inputs(s, max_sizes, min_sizes, cap_cost_slope, om_cost_per_kw, production_factor, techs_by_exportbin, techs)
    end    

    # filling export_bins_by_tech MUST be done after techs_by_exportbin has been filled in
    for t in techs.elec
        export_bins_by_tech[t] = [bin for (bin, ts) in techs_by_exportbin if t in ts]
    end

    if s.settings.off_grid_flag
        setup_operating_reserve_fraction(s, techs_operating_reserve_req_fraction)
    end

    return techs, pv_to_location, maxsize_pv_locations, pvlocations, 
    production_factor, max_sizes, min_sizes, existing_sizes, cap_cost_slope, om_cost_per_kw, n_segs_by_tech, 
    seg_min_size, seg_max_size, seg_yint, techs_by_exportbin, export_bins_by_tech, boiler_efficiency,
    tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, 
    tech_emissions_factors_PM25, cop, techs_operating_reserve_req_fraction, thermal_cop, fuel_cost_per_kwh
end


"""
    setup_pbi_inputs(s::AbstractScenario, techs::Techs)

Create data arrays for production based incentives. 
All arrays can be empty if no techs have production_incentive_per_kwh > 0.
"""
function setup_pbi_inputs(s::AbstractScenario, techs::Techs)

    pbi_pwf = Dict{String, Any}()
    pbi_max_benefit = Dict{String, Any}()
    pbi_max_kw = Dict{String, Any}()
    pbi_benefit_per_kwh = Dict{String, Any}()

    for tech in techs.all
        if !(tech in techs.pv)
            T = typeof(eval(Meta.parse(tech)))
            if :production_incentive_per_kwh in fieldnames(T)
                if eval(Meta.parse("s.$(tech).production_incentive_per_kwh")) > 0
                    push!(techs.pbi, tech)
                    pbi_pwf[tech], pbi_max_benefit[tech], pbi_max_kw[tech], pbi_benefit_per_kwh[tech] = 
                        production_incentives(eval(Meta.parse("s.$(tech)")), s.financial)
                end
            end
        else
            pv = get_pv_by_name(tech, s.pvs)
            if pv.production_incentive_per_kwh > 0
                push!(techs.pbi, tech)
                pbi_pwf[tech], pbi_max_benefit[tech], pbi_max_kw[tech], pbi_benefit_per_kwh[tech] = 
                    production_incentives(pv, s.financial)
            end
        end
        
    end
    return pbi_pwf, pbi_max_benefit, pbi_max_kw, pbi_benefit_per_kwh
end


"""
    setup_timed_pbi_inputs(s::AbstractScenario, techs::Techs)

Create data arrays for production based incentives. 
All arrays can be empty if no techs have timed_production_incentive_per_kwh > 0.
Will only be called for PV techs
"""
function setup_timed_pbi_inputs(s::AbstractScenario, techs::Techs) # Added

    timed_pbi_pwf = Dict{String, Any}()
    timed_pbi_max_benefit = Dict{String, Any}()
    timed_pbi_max_kw = Dict{String, Any}()
    timed_pbi_benefit_per_kwh = Dict{String, Any}()

    for tech in techs.all
        if (tech in techs.pv)
            pv = get_pv_by_name(tech, s.pvs)
            if pv.timed_production_incentive_per_kwh > 0 
                push!(techs.timed_pbi, tech)
                timed_pbi_pwf[tech], timed_pbi_max_benefit[tech], timed_pbi_max_kw[tech], timed_pbi_benefit_per_kwh[tech] = 
                    timed_production_incentives(pv, s.financial)
            end
        end
        
    end
    return timed_pbi_pwf, timed_pbi_max_benefit, timed_pbi_max_kw, timed_pbi_benefit_per_kwh
end


"""
    update_cost_curve!(tech::AbstractTech, tech_name::String, financial::Financial,
        cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
    )

Modifies cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint based on tech attributes.
In the simplest case (zero incentives, no existing_kw) the cap_cost_slope is updated with:
```julia
    cap_cost_slope[tech_name] = tech.installed_cost_per_kw
```
However, if there are non-zero incentives or `existing_kw` then there will be more than one cost curve segment typically
and all of the other arguments will be updated as well.
"""
function update_cost_curve!(tech::AbstractTech, tech_name::String, financial::Financial,
    cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
    )
    cost_slope, cost_curve_bp_x, cost_yint, n_segments = cost_curve(tech, financial)
    cap_cost_slope[tech_name] = cost_slope[1]
    min_allowable_kw = 0.0
    if isdefined(tech, :min_allowable_kw)
        min_allowable_kw = tech.min_allowable_kw
    end
    if n_segments > 1 || (typeof(tech)==CHP && min_allowable_kw > 0.0)
        cap_cost_slope[tech_name] = cost_slope
        push!(segmented_techs, tech_name)
        seg_max_size[tech_name] = Dict{Int,Float64}()
        seg_min_size[tech_name] = Dict{Int,Float64}()
        n_segs_by_tech[tech_name] = n_segments
        seg_yint[tech_name] = Dict{Int,Float64}()
        for s in 1:n_segments
            seg_min_size[tech_name][s] = max(cost_curve_bp_x[s], min_allowable_kw)
            seg_max_size[tech_name][s] = cost_curve_bp_x[s+1]
            seg_yint[tech_name][s] = cost_yint[s]
        end
    end
    nothing
end


function setup_pv_inputs(s::AbstractScenario, max_sizes, min_sizes,
    existing_sizes, cap_cost_slope, om_cost_per_kw, production_factor,
    pvlocations, pv_to_location, maxsize_pv_locations, 
    segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, 
    techs_by_exportbin, techs)

    pv_roof_limited, pv_ground_limited, pv_space_limited = false, false, false
    roof_existing_pv_kw, ground_existing_pv_kw, both_existing_pv_kw = 0.0, 0.0, 0.0
    roof_max_kw, land_max_kw = 1.0e5, 1.0e5

    for pv in s.pvs        
        production_factor[pv.name, :] = get_production_factor(pv, s.site.latitude, s.site.longitude; 
            time_steps_per_hour=s.settings.time_steps_per_hour)
        for location in pvlocations
            if pv.location == String(location) # Must convert symbol to string
                pv_to_location[pv.name][location] = 1
            else
                pv_to_location[pv.name][location] = 0
            end
        end

        beyond_existing_kw = pv.max_kw
        if pv.location == "both"
            both_existing_pv_kw += pv.existing_kw
            if !(s.site.roof_squarefeet === nothing) && !(s.site.land_acres === nothing)
                # don"t restrict unless both land_area and roof_area specified,
                # otherwise one of them is "unlimited"
                roof_max_kw = s.site.roof_squarefeet * pv.kw_per_square_foot
                land_max_kw = s.site.land_acres / pv.acres_per_kw
                beyond_existing_kw = min(roof_max_kw + land_max_kw, beyond_existing_kw)
                pv_space_limited = true
            end
        elseif pv.location == "roof"
            roof_existing_pv_kw += pv.existing_kw
            if !(s.site.roof_squarefeet === nothing)
                roof_max_kw = s.site.roof_squarefeet * pv.kw_per_square_foot
                beyond_existing_kw = min(roof_max_kw, beyond_existing_kw)
                pv_roof_limited = true
            end

        elseif pv.location == "ground"
            ground_existing_pv_kw += pv.existing_kw
            if !(s.site.land_acres === nothing)
                land_max_kw = s.site.land_acres / pv.acres_per_kw
                beyond_existing_kw = min(land_max_kw, beyond_existing_kw)
                pv_ground_limited = true
            end
        end

        existing_sizes[pv.name] = pv.existing_kw
        min_sizes[pv.name] = pv.existing_kw + pv.min_kw
        max_sizes[pv.name] = pv.existing_kw + beyond_existing_kw

        update_cost_curve!(pv, pv.name, s.financial,
            cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
        )

        om_cost_per_kw[pv.name] = pv.om_cost_per_kw
        fillin_techs_by_exportbin(techs_by_exportbin, pv, pv.name)

        if !pv.can_curtail
            push!(techs.no_curtail, pv.name)
        end
    end

    if pv_roof_limited
        maxsize_pv_locations[:roof] = float(roof_existing_pv_kw + roof_max_kw)
    end
    if pv_ground_limited
        maxsize_pv_locations[:ground] = float(ground_existing_pv_kw + land_max_kw)
    end
    if pv_space_limited
        maxsize_pv_locations[:both] = float(both_existing_pv_kw + roof_max_kw + land_max_kw)
    end

    return nothing
end


function setup_wind_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes,
    cap_cost_slope, om_cost_per_kw, production_factor, techs_by_exportbin,
    segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, techs
    )
    max_sizes["Wind"] = s.wind.max_kw
    min_sizes["Wind"] = s.wind.min_kw
    existing_sizes["Wind"] = 0.0
    
    if !(s.site.land_acres === nothing) # Limit based on available land 
        land_max_kw = s.site.land_acres / s.wind.acres_per_kw
        if land_max_kw < 1500 # turbines less than 1.5 MW aren't subject to the acres/kW limit
            land_max_kw = 1500
        end
        if max_sizes["Wind"] > land_max_kw # if user-provided max is greater than land max, update max (otherwise use user-provided max)
            @warn "User-provided maximum wind kW is greater than the calculated land-constrained kW (site.land_acres/wind.acres_per_kw). Wind max kW has been updated to land-constrained max of $(land_max_kw) kW."
            max_sizes["Wind"] = land_max_kw
        end
        if min_sizes["Wind"] > max_sizes["Wind"] # If user-provided min is greater than max (updated to land max as above), send error
            throw(@error("User-provided minimum wind kW is greater than either wind.max_kw or calculated land-constrained kW (site.land_acres/wind.acres_per_kw). Update wind.min_kw or site.land_acres"))
        end 
    end
    
    update_cost_curve!(s.wind, "Wind", s.financial,
        cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
    )
    om_cost_per_kw["Wind"] = s.wind.om_cost_per_kw
    production_factor["Wind", :] = get_production_factor(s.wind, s.site.latitude, s.site.longitude, s.settings.time_steps_per_hour)
    fillin_techs_by_exportbin(techs_by_exportbin, s.wind, "Wind")
    if !s.wind.can_curtail
        push!(techs.no_curtail, "Wind")
    end
    return nothing
end


function setup_gen_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes,
    cap_cost_slope, om_cost_per_kw, production_factor, techs_by_exportbin,
    segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, techs,
    tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh
    )
    max_sizes["Generator"] = s.generator.existing_kw + s.generator.max_kw
    min_sizes["Generator"] = s.generator.existing_kw + s.generator.min_kw
    existing_sizes["Generator"] = s.generator.existing_kw
    update_cost_curve!(s.generator, "Generator", s.financial,
        cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
    )
    om_cost_per_kw["Generator"] = s.generator.om_cost_per_kw
    production_factor["Generator", :] = get_production_factor(s.generator; s.settings.time_steps_per_hour)
    fillin_techs_by_exportbin(techs_by_exportbin, s.generator, "Generator")
    if !s.generator.can_curtail
        push!(techs.no_curtail, "Generator")
    end
    tech_renewable_energy_fraction["Generator"] = s.generator.fuel_renewable_energy_fraction
    hhv_kwh_per_gal = s.generator.fuel_higher_heating_value_kwh_per_gal
    tech_emissions_factors_CO2["Generator"] = s.generator.emissions_factor_lb_CO2_per_gal / hhv_kwh_per_gal  # lb/gal * gal/kWh
    tech_emissions_factors_NOx["Generator"] = s.generator.emissions_factor_lb_NOx_per_gal / hhv_kwh_per_gal
    tech_emissions_factors_SO2["Generator"] = s.generator.emissions_factor_lb_SO2_per_gal / hhv_kwh_per_gal
    tech_emissions_factors_PM25["Generator"] = s.generator.emissions_factor_lb_PM25_per_gal / hhv_kwh_per_gal
    generator_fuel_cost_per_kwh = s.generator.fuel_cost_per_gallon / hhv_kwh_per_gal
    fuel_cost_per_kwh["Generator"] = per_hour_value_to_time_series(generator_fuel_cost_per_kwh, s.settings.time_steps_per_hour, "Generator")
    return nothing
end

"""
    function setup_existing_boiler_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes, cap_cost_slope, boiler_efficiency,
        tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh)

Update tech-indexed data arrays necessary to build the JuMP model with the values for existing boiler.
This version of this function, used in BAUInputs(), doesn't update renewable energy and emissions arrays.
"""

function setup_existing_boiler_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes, cap_cost_slope, boiler_efficiency,
    tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh)
    max_sizes["ExistingBoiler"] = s.existing_boiler.max_kw
    min_sizes["ExistingBoiler"] = 0.0
    existing_sizes["ExistingBoiler"] = 0.0
    cap_cost_slope["ExistingBoiler"] = 0.0
    boiler_efficiency["ExistingBoiler"] = s.existing_boiler.efficiency
    # om_cost_per_kw["ExistingBoiler"] = 0.0
    tech_renewable_energy_fraction["ExistingBoiler"] = s.existing_boiler.fuel_renewable_energy_fraction
    tech_emissions_factors_CO2["ExistingBoiler"] = s.existing_boiler.emissions_factor_lb_CO2_per_mmbtu / KWH_PER_MMBTU  # lb/mmtbu * mmtbu/kWh
    tech_emissions_factors_NOx["ExistingBoiler"] = s.existing_boiler.emissions_factor_lb_NOx_per_mmbtu / KWH_PER_MMBTU
    tech_emissions_factors_SO2["ExistingBoiler"] = s.existing_boiler.emissions_factor_lb_SO2_per_mmbtu / KWH_PER_MMBTU
    tech_emissions_factors_PM25["ExistingBoiler"] = s.existing_boiler.emissions_factor_lb_PM25_per_mmbtu / KWH_PER_MMBTU 
    existing_boiler_fuel_cost_per_kwh = s.existing_boiler.fuel_cost_per_mmbtu ./ KWH_PER_MMBTU
    fuel_cost_per_kwh["ExistingBoiler"] = per_hour_value_to_time_series(existing_boiler_fuel_cost_per_kwh, s.settings.time_steps_per_hour, "ExistingBoiler")      
    return nothing
end

"""
    function setup_boiler_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes, cap_cost_slope, boiler_efficiency,
        production_factor, fuel_cost_per_kwh)

Update tech-indexed data arrays necessary to build the JuMP model with the values for (new) boiler.
This version of this function, used in BAUInputs(), doesn't update renewable energy and emissions arrays.
"""
function setup_boiler_inputs(s::AbstractScenario, max_sizes, min_sizes, cap_cost_slope, om_cost_per_kw, boiler_efficiency, production_factor, fuel_cost_per_kwh)
    max_sizes["Boiler"] = s.boiler.max_kw
    min_sizes["Boiler"] = s.boiler.min_kw
    boiler_efficiency["Boiler"] = s.boiler.efficiency
    
    # The Boiler only has a MACRS benefit, no ITC etc.
    if s.boiler.macrs_option_years in [5, 7]

        cap_cost_slope["Boiler"] = effective_cost(;
            itc_basis = s.boiler.installed_cost_per_kw,
            replacement_cost = 0.0,
            replacement_year = s.financial.analysis_years,
            discount_rate = s.financial.owner_discount_rate_fraction,
            tax_rate = s.financial.owner_tax_rate_fraction,
            itc = 0.0,
            macrs_schedule = s.boiler.macrs_option_years == 5 ? s.financial.macrs_five_year : s.financial.macrs_seven_year,
            macrs_bonus_fraction = s.boiler.macrs_bonus_fraction,
            macrs_itc_reduction = 0.0,
            rebate_per_kw = 0.0
        )

    else
        cap_cost_slope["Boiler"] = s.boiler.installed_cost_per_kw
    end

    om_cost_per_kw["Boiler"] = s.boiler.om_cost_per_kw
    production_factor["Boiler", :] = get_production_factor(s.boiler)
    boiler_fuel_cost_per_kwh = s.boiler.fuel_cost_per_mmbtu ./ KWH_PER_MMBTU
    fuel_cost_per_kwh["Boiler"] = per_hour_value_to_time_series(boiler_fuel_cost_per_kwh, s.settings.time_steps_per_hour, "Boiler")
    return nothing
end


"""
    function setup_existing_chiller_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes, cap_cost_slope, cop)

Update tech-indexed data arrays necessary to build the JuMP model with the values for existing chiller.
"""
function setup_existing_chiller_inputs(s::AbstractScenario, max_sizes, min_sizes, existing_sizes, cap_cost_slope, cop)
    max_sizes["ExistingChiller"] = s.existing_chiller.max_kw
    min_sizes["ExistingChiller"] = 0.0
    existing_sizes["ExistingChiller"] = 0.0
    cap_cost_slope["ExistingChiller"] = 0.0
    cop["ExistingChiller"] = s.existing_chiller.cop
    # om_cost_per_kw["ExistingChiller"] = 0.0
    return nothing
end


function setup_absorption_chiller_inputs(s::AbstractScenario, max_sizes, min_sizes, cap_cost_slope, 
    cop, thermal_cop, om_cost_per_kw
    )
    max_sizes["AbsorptionChiller"] = s.absorption_chiller.max_kw
    min_sizes["AbsorptionChiller"] = s.absorption_chiller.min_kw
    
    # The AbsorptionChiller only has a MACRS benefit, no ITC etc.
    if s.absorption_chiller.macrs_option_years in [5, 7]

        cap_cost_slope["AbsorptionChiller"] = effective_cost(;
            itc_basis = s.absorption_chiller.installed_cost_per_kw,
            replacement_cost = 0.0,
            replacement_year = s.financial.analysis_years,
            discount_rate = s.financial.owner_discount_rate_fraction,
            tax_rate = s.financial.owner_tax_rate_fraction,
            itc = 0.0,
            macrs_schedule = s.absorption_chiller.macrs_option_years == 5 ? s.financial.macrs_five_year : s.financial.macrs_seven_year,
            macrs_bonus_fraction = s.absorption_chiller.macrs_bonus_fraction,
            macrs_itc_reduction = 0.0,
            rebate_per_kw = 0.0
        )

    else
        cap_cost_slope["AbsorptionChiller"] = s.absorption_chiller.installed_cost_per_kw
    end

    cop["AbsorptionChiller"] = s.absorption_chiller.cop_electric
    if isnothing(s.chp)
        thermal_factor = 1.0
    elseif s.chp.cooling_thermal_factor == 0.0
        throw(@error("The CHP cooling_thermal_factor is 0.0 which implies that CHP cannot serve AbsorptionChiller. If you
            want to model CHP and AbsorptionChiller, you must specify a cooling_thermal_factor greater than 0.0"))
    else
        thermal_factor = s.chp.cooling_thermal_factor
    end    
    thermal_cop["AbsorptionChiller"] = s.absorption_chiller.cop_thermal * thermal_factor
    om_cost_per_kw["AbsorptionChiller"] = s.absorption_chiller.om_cost_per_kw
    return nothing
end

"""
    function setup_chp_inputs(s::AbstractScenario, max_sizes, min_sizes, cap_cost_slope, om_cost_per_kw,  
        production_factor, techs_by_exportbin, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, techs,
        tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh
        )

Update tech-indexed data arrays necessary to build the JuMP model with the values for CHP.
"""
function setup_chp_inputs(s::AbstractScenario, max_sizes, min_sizes, cap_cost_slope, om_cost_per_kw,  
    production_factor, techs_by_exportbin, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint, techs,
    tech_renewable_energy_fraction, tech_emissions_factors_CO2, tech_emissions_factors_NOx, tech_emissions_factors_SO2, tech_emissions_factors_PM25, fuel_cost_per_kwh
    )
    max_sizes["CHP"] = s.chp.max_kw
    min_sizes["CHP"] = s.chp.min_kw
    update_cost_curve!(s.chp, "CHP", s.financial,
        cap_cost_slope, segmented_techs, n_segs_by_tech, seg_min_size, seg_max_size, seg_yint
    )
    om_cost_per_kw["CHP"] = s.chp.om_cost_per_kw
    production_factor["CHP", :] = get_production_factor(s.chp, s.electric_load.year, s.electric_utility.outage_start_time_step, 
        s.electric_utility.outage_end_time_step, s.settings.time_steps_per_hour)
    fillin_techs_by_exportbin(techs_by_exportbin, s.chp, "CHP")
    if !s.chp.can_curtail
        push!(techs.no_curtail, "CHP")
    end  
    tech_renewable_energy_fraction["CHP"] = s.chp.fuel_renewable_energy_fraction
    tech_emissions_factors_CO2["CHP"] = s.chp.emissions_factor_lb_CO2_per_mmbtu / KWH_PER_MMBTU  # lb/mmtbu * mmtbu/kWh
    tech_emissions_factors_NOx["CHP"] = s.chp.emissions_factor_lb_NOx_per_mmbtu / KWH_PER_MMBTU
    tech_emissions_factors_SO2["CHP"] = s.chp.emissions_factor_lb_SO2_per_mmbtu / KWH_PER_MMBTU
    tech_emissions_factors_PM25["CHP"] = s.chp.emissions_factor_lb_PM25_per_mmbtu / KWH_PER_MMBTU
    chp_fuel_cost_per_kwh = s.chp.fuel_cost_per_mmbtu ./ KWH_PER_MMBTU
    fuel_cost_per_kwh["CHP"] = per_hour_value_to_time_series(chp_fuel_cost_per_kwh, s.settings.time_steps_per_hour, "CHP")    
    return nothing
end

function setup_steam_turbine_inputs(s::AbstractScenario, max_sizes, min_sizes, cap_cost_slope, 
    om_cost_per_kw, production_factor, techs_by_exportbin, techs
    )

    max_sizes["SteamTurbine"] = s.steam_turbine.max_kw
    min_sizes["SteamTurbine"] = s.steam_turbine.min_kw
    
    # The AbsorptionChiller only has a MACRS benefit, no ITC etc.
    if s.steam_turbine.macrs_option_years in [5, 7]
        cap_cost_slope["SteamTurbine"] = effective_cost(;
            itc_basis = s.steam_turbine.installed_cost_per_kw,
            replacement_cost = 0.0,
            replacement_year = s.financial.analysis_years,
            discount_rate = s.financial.owner_discount_rate_fraction,
            tax_rate = s.financial.owner_tax_rate_fraction,
            itc = 0.0,
            macrs_schedule = s.steam_turbine.macrs_option_years == 5 ? s.financial.macrs_five_year : s.financial.macrs_seven_year,
            macrs_bonus_fraction = s.steam_turbine.macrs_bonus_fraction,
            macrs_itc_reduction = 0.0,
            rebate_per_kw = 0.0
        )
    else
        cap_cost_slope["SteamTurbine"] = s.steam_turbine.installed_cost_per_kw
    end

    om_cost_per_kw["SteamTurbine"] = s.steam_turbine.om_cost_per_kw
    
    production_factor["SteamTurbine", :] = get_production_factor(s.steam_turbine; s.settings.time_steps_per_hour)
    
    fillin_techs_by_exportbin(techs_by_exportbin, s.steam_turbine, "SteamTurbine")
    
    if !s.steam_turbine.can_curtail
        push!(techs.no_curtail, "SteamTurbine")
    end

    return nothing
end


function setup_present_worth_factors(s::AbstractScenario, techs::Techs)

    lvl_factor = Dict(t => 1.0 for t in techs.all)  # default levelization_factor of 1.0
    for (i, tech) in enumerate(techs.pv)  # replace 1.0 with actual PV levelization_factor (only tech with degradation)
        lvl_factor[tech] = levelization_factor(
            s.financial.analysis_years,
            s.financial.elec_cost_escalation_rate_fraction,
            s.financial.offtaker_discount_rate_fraction,
            s.pvs[i].degradation_fraction  # TODO generalize for any tech (not just pvs)
        )
    end

    pwf_e = annuity(
        s.financial.analysis_years,
        s.financial.elec_cost_escalation_rate_fraction,
        s.financial.offtaker_discount_rate_fraction
    )

    pwf_om = annuity(
        s.financial.analysis_years,
        s.financial.om_cost_escalation_rate_fraction,
        s.financial.owner_discount_rate_fraction
    )
    pwf_fuel = Dict{String, Float64}()
    for t in techs.fuel_burning
        if t == "ExistingBoiler"
            pwf_fuel["ExistingBoiler"] = annuity(
                s.financial.analysis_years,
                s.financial.existing_boiler_fuel_cost_escalation_rate_fraction,
                s.financial.offtaker_discount_rate_fraction
            )
        end
        if t == "Boiler"
            pwf_fuel["Boiler"] = annuity(
                s.financial.analysis_years,
                s.financial.boiler_fuel_cost_escalation_rate_fraction,
                s.financial.offtaker_discount_rate_fraction
            )
        end
        if t == "CHP"
            pwf_fuel["CHP"] = annuity(
                s.financial.analysis_years,
                s.financial.chp_fuel_cost_escalation_rate_fraction,
                s.financial.offtaker_discount_rate_fraction
            )
        end
        if t == "Generator" 
            pwf_fuel["Generator"] = annuity(
                s.financial.analysis_years,
                s.financial.generator_fuel_cost_escalation_rate_fraction,
                s.financial.offtaker_discount_rate_fraction
            )
        end     
    end

    # Emissions pwfs
    pwf_emissions_cost = Dict{String, Float64}()
    pwf_grid_emissions = Dict{String, Float64}() # used to calculate total grid CO2 lbs
    for emissions_type in ["CO2", "NOx", "SO2", "PM25"]
        merge!(pwf_emissions_cost, 
                Dict(emissions_type*"_grid"=>annuity_two_escalation_rates(
                            s.financial.analysis_years, 
                            getproperty(s.financial, Symbol("$(emissions_type)_cost_escalation_rate_fraction")),  
                            -1.0 * getproperty(s.electric_utility, Symbol("emissions_factor_$(emissions_type)_decrease_fraction")),
                            s.financial.offtaker_discount_rate_fraction)
                )
        )
        merge!(pwf_emissions_cost, 
                Dict(emissions_type*"_onsite"=>annuity(
                            s.financial.analysis_years, 
                            getproperty(s.financial, Symbol("$(emissions_type)_cost_escalation_rate_fraction")), 
                            s.financial.offtaker_discount_rate_fraction)
                )
        )
        merge!(pwf_grid_emissions, 
                Dict(emissions_type=>annuity(
                            s.financial.analysis_years, 
                            -1.0 * getproperty(s.electric_utility, Symbol("emissions_factor_$(emissions_type)_decrease_fraction")),
                            0.0)
                )
        )
    end

    pwf_offtaker = annuity(s.financial.analysis_years, 0.0, s.financial.offtaker_discount_rate_fraction)
    pwf_owner = annuity(s.financial.analysis_years, 0.0, s.financial.owner_discount_rate_fraction)
    if s.financial.third_party_ownership
        third_party_factor = (pwf_offtaker * (1 - s.financial.offtaker_tax_rate_fraction)) /
                           (pwf_owner * (1 - s.financial.owner_tax_rate_fraction))
    else
        third_party_factor = 1.0
    end

    return lvl_factor, pwf_e, pwf_om, pwf_fuel, pwf_emissions_cost, pwf_grid_emissions, third_party_factor, pwf_offtaker, pwf_owner
end


"""
    setup_electric_utility_inputs(s::AbstractScenario)

Define the `time_steps_with_grid` and `time_steps_without_grid` (detministic outage).

NOTE: v1 of the API spliced the critical_loads_kw into the loads_kw during outages but this splicing is no longer needed
now that the constraints are properly applied over `time_steps_with_grid` and `time_steps_without_grid` using loads_kw
and critical_loads_kw respectively.
"""
function setup_electric_utility_inputs(s::AbstractScenario)
    if s.electric_utility.outage_end_time_step > 0 &&
            s.electric_utility.outage_end_time_step >= s.electric_utility.outage_start_time_step
        time_steps_without_grid = Int[i for i in range(s.electric_utility.outage_start_time_step,
                                                    stop=s.electric_utility.outage_end_time_step)]
        if s.electric_utility.outage_start_time_step > 1
            time_steps_with_grid = append!(
                Int[i for i in range(1, stop=s.electric_utility.outage_start_time_step - 1)],
                Int[i for i in range(s.electric_utility.outage_end_time_step + 1,
                                     stop=length(s.electric_load.loads_kw))]
            )
        else
            time_steps_with_grid = Int[i for i in range(s.electric_utility.outage_end_time_step + 1,
                                       stop=length(s.electric_load.loads_kw))]
        end
    else
        time_steps_without_grid = Int[]
        time_steps_with_grid = Int[i for i in range(1, stop=length(s.electric_load.loads_kw))]
    end
    return time_steps_with_grid, time_steps_without_grid
end


"""
    adjust_load_profile(s::AbstractScenario, production_factor::DenseAxisArray)

Adjust the (critical_)loads_kw based off of (critical_)loads_kw_is_net
"""
function adjust_load_profile(s::AbstractScenario, production_factor::DenseAxisArray)
    if s.electric_load.loads_kw_is_net
        for pv in s.pvs if pv.existing_kw > 0
            s.electric_load.loads_kw .+= pv.existing_kw * production_factor[pv.name, :].data
        end end
    end
    
    if s.electric_load.critical_loads_kw_is_net
        for pv in s.pvs if pv.existing_kw > 0
            s.electric_load.critical_loads_kw .+= pv.existing_kw * production_factor[pv.name, :].data
        end end
    end
end


"""
    production_incentives(tech::AbstractTech, financial::Financial)

Intermediate function for building the PBI arrays in REoptInputs
"""
function production_incentives(tech::AbstractTech, financial::Financial)
    pwf_prod_incent = 0.0
    max_prod_incent = 0.0
    max_size_for_prod_incent = 0.0
    production_incentive_rate = 0.0
    T = typeof(tech)
    # TODO should Generator be excluded? (v1 has the PBI inputs for Generator)
    if !(nameof(T) in [:Generator, :Boiler, :Elecchl, :Absorpchl])
        if :degradation_fraction in fieldnames(T)  # PV has degradation
            pwf_prod_incent = annuity_escalation(tech.production_incentive_years, -1*tech.degradation_fraction,
                                                 financial.owner_discount_rate_fraction)
            # Added                                     
            if (nameof(T) in [:PV])
                timed_pwf_prod_incent = annuity_escalation(tech.timed_production_incentive_years, -1*tech.degradation_fraction,
                                                            financial.owner_discount_rate_fraction)
            end
        else
            # prod incentives have zero escalation rate
            pwf_prod_incent = annuity(tech.production_incentive_years, 0, financial.owner_discount_rate_fraction)
        end
        max_prod_incent = tech.production_incentive_max_benefit
        max_size_for_prod_incent = tech.production_incentive_max_kw
        production_incentive_rate = tech.production_incentive_per_kwh

        # Added
        timed_max_prod_incent = tech.production_incentive_max_benefit
        timed_max_size_for_prod_incent = tech.production_incentive_max_kw
        timed_production_incentive_rate = tech.production_incentive_per_kwh
    end

    return pwf_prod_incent, max_prod_incent, max_size_for_prod_incent, production_incentive_rate, timed_pwf_prod_incent, timed_max_prod_incent, timed_max_size_for_prod_incent, timed_production_incentive_rate
end

"""
    timed_production_incentives(tech::AbstractTech, financial::Financial)

Intermediate function for building the PBI arrays in REoptInputs
    Will be called for PV techs only
"""
function timed_production_incentives(tech::AbstractTech, financial::Financial) # Added
    timed_pwf_prod_incent = 0.0
    timed_max_prod_incent = 0.0
    timed_max_size_for_prod_incent = 0.0
    timed_production_incentive_rate = 0.0
    T = typeof(tech)

    if !(nameof(T) in [:Generator, :Boiler, :Elecchl, :Absorpchl])
        if :degradation_fraction in fieldnames(T)  # PV has degradation
            timed_pwf_prod_incent = annuity_escalation(tech.timed_production_incentive_years, -1*tech.degradation_fraction,
                                                 financial.owner_discount_rate_fraction)
        end
        timed_max_prod_incent = tech.timed_production_incentive_max_benefit
        timed_max_size_for_prod_incent = tech.timed_production_incentive_max_kw
        timed_production_incentive_rate = tech.timed_production_incentive_per_kwh
    end

    return timed_pwf_prod_incent, timed_max_prod_incent, timed_max_size_for_prod_incent, timed_production_incentive_rate
end


function fillin_techs_by_exportbin(techs_by_exportbin::Dict, tech::AbstractTech, tech_name::String)
    if tech.can_net_meter && :NEM in keys(techs_by_exportbin)
        push!(techs_by_exportbin[:NEM], tech_name)
        if tech.can_export_beyond_nem_limit && :EXC in keys(techs_by_exportbin)
            push!(techs_by_exportbin[:EXC], tech_name)
        end
    end
    
    if tech.can_wholesale && :WHL in keys(techs_by_exportbin)
        push!(techs_by_exportbin[:WHL], tech_name)
    end
    return nothing
end

function setup_ghp_inputs(s::AbstractScenario, time_steps, time_steps_without_grid)
    # GHP parameters for REopt model
    num = length(s.ghp_option_list)
    ghp_options = 1:num
    require_ghp_purchase = 0
    ghp_installed_cost = Vector{Float64}(undef, num)
    ghp_om_cost_year_one = Vector{Float64}(undef, num)
    ghp_heating_thermal_load_served_kw = zeros(num, length(time_steps))
    ghp_cooling_thermal_load_served_kw = zeros(num, length(time_steps))
    space_heating_thermal_load_reduction_with_ghp_kw = zeros(num, length(time_steps))
    cooling_thermal_load_reduction_with_ghp_kw = zeros(num, length(time_steps))
    ghp_cooling_thermal_load_served_kw = zeros(num, length(time_steps))        
    ghp_electric_consumption_kw = zeros(num, length(time_steps))
    if num > 0
        require_ghp_purchase = s.ghp_option_list[1].require_ghp_purchase  # This does not change with the number of options
        for (i, option) in enumerate(s.ghp_option_list)
            ghp_cap_cost_slope, ghp_cap_cost_x, ghp_cap_cost_yint, ghp_n_segments = cost_curve(option, s.financial)
            ghp_size_ton = option.heatpump_capacity_ton
            seg = 0
            if ghp_size_ton <= ghp_cap_cost_x[1]
                seg = 1
            elseif ghp_size_ton > ghp_cap_cost_x[end]
                seg = ghp_n_segments
            else
                for n in 2:(ghp_n_segments+1)
                    if (ghp_size_ton > ghp_cap_cost_x[n-1]) && (ghp_size_ton <= ghp_cap_cost_x[n])
                        seg = n
                        break
                    end
                end
            end
            ghp_installed_cost[i] = ghp_cap_cost_yint[seg-1] + ghp_size_ton * ghp_cap_cost_slope[seg-1]
            ghp_om_cost_year_one[i] = option.om_cost_year_one
            heating_thermal_load = s.space_heating_load.loads_kw + s.dhw_load.loads_kw
            # Using minimum of thermal load and ghp-serving load to avoid small negative net loads
            for j in time_steps
                space_heating_thermal_load_reduction_with_ghp_kw[i,j] = min(s.space_heating_thermal_load_reduction_with_ghp_kw[j], heating_thermal_load[j])
                cooling_thermal_load_reduction_with_ghp_kw[i,j] = min(s.cooling_thermal_load_reduction_with_ghp_kw[j], s.cooling_load.loads_kw_thermal[j])
                ghp_heating_thermal_load_served_kw[i,j] = min(option.heating_thermal_kw[j], heating_thermal_load[j] - space_heating_thermal_load_reduction_with_ghp_kw[i,j])
                ghp_cooling_thermal_load_served_kw[i,j] = min(option.cooling_thermal_kw[j], s.cooling_load.loads_kw_thermal[j] - cooling_thermal_load_reduction_with_ghp_kw[i,j])
                ghp_electric_consumption_kw[i,j] = option.yearly_electric_consumption_kw[j]
            end

            # GHP electric consumption is omitted from the electric load balance during an outage
            # So here we also have to zero out heating and cooling thermal production from GHP during an outage
            if !isempty(time_steps_without_grid)
                for outage_time_step in time_steps_without_grid
                    space_heating_thermal_load_reduction_with_ghp_kw[i,outage_time_step] = 0.0
                    cooling_thermal_load_reduction_with_ghp_kw[i,outage_time_step] = 0.0
                    ghp_heating_thermal_load_served_kw[i,outage_time_step] = 0.0
                    ghp_cooling_thermal_load_served_kw[i,outage_time_step] = 0.0
                    ghp_electric_consumption_kw[i,outage_time_step] = 0.0
                end
            end
        end
    end

    return ghp_options, require_ghp_purchase, ghp_heating_thermal_load_served_kw, 
    ghp_cooling_thermal_load_served_kw, space_heating_thermal_load_reduction_with_ghp_kw, 
    cooling_thermal_load_reduction_with_ghp_kw, ghp_electric_consumption_kw, 
    ghp_installed_cost, ghp_om_cost_year_one
end

function setup_operating_reserve_fraction(s::AbstractScenario, techs_operating_reserve_req_fraction)
    # currently only PV and Wind require operating reserves
    for pv in s.pvs 
        techs_operating_reserve_req_fraction[pv.name] = pv.operating_reserve_required_fraction
    end

    techs_operating_reserve_req_fraction["Wind"] = s.wind.operating_reserve_required_fraction

    return nothing
end