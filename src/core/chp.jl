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

prime_movers = ["recip_engine", "micro_turbine", "combustion_turbine", "fuel_cell"]

"""
`CHP` is an optional REopt input with the following keys and default values:
```julia
    prime_mover::Union{String, Nothing} = nothing # Suggested to inform applicable default cost and performance. "restrict_to": ["recip_engine", "micro_turbine", "combustion_turbine", "fuel_cell"]
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = [] # REQUIRED. Can be a scalar, a list of 12 monthly values, or a time series of values for every time step

    # Required "custom inputs" if not providing prime_mover:
    installed_cost_per_kw::Union{Float64, AbstractVector{Float64}} = NaN # Installed CHP system cost in \$/kW (based on rated electric power)
    tech_sizes_for_cost_curve::Union{Float64, AbstractVector{Float64}} = NaN # Size of CHP systems corresponding to installed cost input points"
    om_cost_per_kwh::Float64 = NaN # CHP non-fuel variable operations and maintenance costs in \$/kwh
    electric_efficiency_full_load::Float64 = NaN # Electric efficiency of CHP prime-mover at full-load, HHV-basis
    electric_efficiency_half_load::Float64 = NaN # Electric efficiency of CHP prime-mover at half-load, HHV-basis
    min_turn_down_fraction::Float64 = NaN # Minimum CHP electric loading in fraction of capacity (size_kw)
    thermal_efficiency_full_load::Float64 = NaN # CHP fraction of fuel energy converted to hot-thermal energy at full electric load
    thermal_efficiency_half_load::Float64 = NaN # CHP fraction of fuel energy converted to hot-thermal energy at half electric load
    min_allowable_kw::Float64 = NaN # Minimum CHP size (based on electric) that still allows the model to choose zero (e.g. no CHP system)
    max_kw::Float64 = NaN # Maximum CHP size (based on electric) constraint for optimization.
    cooling_thermal_factor::Float64 = NaN  # only needed with cooling load
    unavailability_periods::AbstractVector{Dict} = Dict[] # CHP unavailability periods for scheduled and unscheduled maintenance, list of dictionaries with keys of "['month', 'start_week_of_month', 'start_day_of_week', 'start_hour', 'duration_hours'] all values are one-indexed and start_day_of_week uses 1 for Monday, 7 for Sunday

    # Optional inputs:
    size_class::Union{Int, Nothing} = nothing # CHP size class for using appropriate default inputs 
    min_kw::Float64 = 0.0 # Minimum CHP size (based on electric) constraint for optimization 
    fuel_type::String = "natural_gas" # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil"]
    om_cost_per_kw::Float64 = 0.0 # Annual CHP fixed operations and maintenance costs in \$/kw-yr 
    om_cost_per_hr_per_kw_rated::Float64 = 0.0 # CHP non-fuel variable operations and maintenance costs in \$/hr/kw_rated
    supplementary_firing_capital_cost_per_kw::Float64 = 150.0 # Installed CHP supplementary firing system cost in \$/kW (based on rated electric power)
    supplementary_firing_max_steam_ratio::Float64 = 1.0 # Ratio of max fired steam to un-fired steam production. Relevant only for combustion_turbine prime_mover 
    supplementary_firing_efficiency::Float64 = 0.92 # Thermal efficiency of the incremental steam production from supplementary firing. Relevant only for combustion_turbine prime_mover 
    standby_rate_per_kw_per_month::Float64 = 0.0 # Standby rate charged to CHP based on CHP electric power size
    reduces_demand_charges::Bool = true # Boolean indicator if CHP does not reduce demand charges 
    can_supply_steam_turbine::Bool=false # If CHP can supply steam to the steam turbine for electric production 

    macrs_option_years::Int = 5
    macrs_bonus_fraction::Float64 = 0.8
    macrs_itc_reduction::Float64 = 0.5
    federal_itc_fraction::Float64 = 0.3
    federal_rebate_per_kw::Float64 = 0.0
    state_ibi_fraction::Float64 = 0.0
    state_ibi_max::Float64 = 1.0e10
    state_rebate_per_kw::Float64 = 0.0
    state_rebate_max::Float64 = 1.0e10
    utility_ibi_fraction::Float64 = 0.0
    utility_ibi_max::Float64 = 1.0e10
    utility_rebate_per_kw::Float64 = 0.0
    utility_rebate_max::Float64 = 1.0e10
    production_incentive_per_kwh::Float64 = 0.0
    production_incentive_max_benefit::Float64 = 1.0e9
    production_incentive_years::Int = 0
    production_incentive_max_kw::Float64 = 1.0e9
    can_net_meter::Bool = false
    can_wholesale::Bool = false
    can_export_beyond_nem_limit::Bool = false
    can_curtail::Bool = false
    fuel_renewable_energy_fraction::Float64 = FUEL_DEFAULTS["fuel_renewable_energy_fraction"][fuel_type]
    emissions_factor_lb_CO2_per_mmbtu::Float64 = FUEL_DEFAULTS["emissions_factor_lb_CO2_per_mmbtu"][fuel_type]
    emissions_factor_lb_NOx_per_mmbtu::Float64 = FUEL_DEFAULTS["emissions_factor_lb_NOx_per_mmbtu"][fuel_type]
    emissions_factor_lb_SO2_per_mmbtu::Float64 = FUEL_DEFAULTS["emissions_factor_lb_SO2_per_mmbtu"][fuel_type]
    emissions_factor_lb_PM25_per_mmbtu::Float64 = FUEL_DEFAULTS["emissions_factor_lb_PM25_per_mmbtu"][fuel_type]
```

!!! note "Defaults and required inputs"
    See the `get_chp_defaults_prime_mover_size_class()` function docstring for details on the logic of choosing the type of CHP that is modeled
    If no information is provided, the default `prime_mover` is `recip_engine` and the `size_class` is 1 which represents
    the widest range of sizes available.

    `fuel_cost_per_mmbtu` is always required and can be a scalar, a list of 12 monthly values, or a time series of values for every time step

"""
Base.@kwdef mutable struct CHP <: AbstractCHP
    # Required input
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = []    
    
    # Inputs which defaults vary depending on prime_mover and size_class
    installed_cost_per_kw::Union{Float64, AbstractVector{Float64}} = Float64[]
    tech_sizes_for_cost_curve::AbstractVector{Float64} = Float64[]
    om_cost_per_kwh::Float64 = NaN
    electric_efficiency_full_load::Float64 = NaN
    thermal_efficiency_full_load::Float64 = NaN
    min_allowable_kw::Float64 = NaN
    cooling_thermal_factor::Float64 = NaN  # only needed with cooling load
    min_turn_down_fraction::Float64 = NaN
    unavailability_periods::AbstractVector{Dict} = Dict[]

    # Optional inputs:
    prime_mover::Union{String, Nothing} = nothing
    size_class::Union{Int, Nothing} = nothing
    min_kw::Float64 = 0.0
    max_kw::Float64 = 1.0e9
    fuel_type::String = "natural_gas"
    om_cost_per_kw::Float64 = 0.0
    om_cost_per_hr_per_kw_rated::Float64 = 0.0
    electric_efficiency_half_load::Float64 = NaN  # Assigned to electric_efficiency_full_load if not input
    thermal_efficiency_half_load::Float64 = NaN  # Assigned to thermal_efficiency_full_load if not input
    supplementary_firing_capital_cost_per_kw::Float64 = 150.0
    supplementary_firing_max_steam_ratio::Float64 = 1.0
    supplementary_firing_efficiency::Float64 = 0.92
    standby_rate_per_kw_per_month::Float64 = 0.0
    reduces_demand_charges::Bool = true
    can_supply_steam_turbine::Bool = false

    macrs_option_years::Int = 5
    macrs_bonus_fraction::Float64 = 0.8
    macrs_itc_reduction::Float64 = 0.5
    federal_itc_fraction::Float64 = 0.3
    federal_rebate_per_kw::Float64 = 0.0
    state_ibi_fraction::Float64 = 0.0
    state_ibi_max::Float64 = 1.0e10
    state_rebate_per_kw::Float64 = 0.0
    state_rebate_max::Float64 = 1.0e10
    utility_ibi_fraction::Float64 = 0.0
    utility_ibi_max::Float64 = 1.0e10
    utility_rebate_per_kw::Float64 = 0.0
    utility_rebate_max::Float64 = 1.0e10
    production_incentive_per_kwh::Float64 = 0.0
    production_incentive_max_benefit::Float64 = 1.0e9
    production_incentive_years::Int = 0
    production_incentive_max_kw::Float64 = 1.0e9
    can_net_meter::Bool = false
    can_wholesale::Bool = false
    can_export_beyond_nem_limit::Bool = false
    can_curtail::Bool = false
    fuel_renewable_energy_fraction::Real = get(FUEL_DEFAULTS["fuel_renewable_energy_fraction"],fuel_type,0)
    emissions_factor_lb_CO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_CO2_per_mmbtu"],fuel_type,0)
    emissions_factor_lb_NOx_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_NOx_per_mmbtu"],fuel_type,0)
    emissions_factor_lb_SO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_SO2_per_mmbtu"],fuel_type,0)
    emissions_factor_lb_PM25_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_PM25_per_mmbtu"],fuel_type,0)
end


function CHP(d::Dict; 
            avg_boiler_fuel_load_mmbtu_per_hour::Union{Float64, Nothing}=nothing, 
            existing_boiler::Union{ExistingBoiler, Nothing}=nothing)
    # If array inputs are coming from Julia JSON.parsefile (reader), they have type Vector{Any}; convert to expected type here
    for (k,v) in d
        if typeof(v) <: AbstractVector{Any} && k != "unavailability_periods"
            d[k] = convert(Vector{Float64}, v)
        end
    end

    # Check for required fuel cost
    if !haskey(d, "fuel_cost_per_mmbtu")
        throw(@error("CHP must have the required fuel_cost_per_mmbtu input"))
    end
    # Create CHP struct from inputs, to be mutated as needed
    chp = CHP(; dictkeys_tosymbols(d)...)

    @assert chp.fuel_type in FUEL_TYPES

    # These inputs are set based on prime_mover and size_class
    custom_chp_inputs = Dict{Symbol, Any}(
        :installed_cost_per_kw => chp.installed_cost_per_kw, 
        :tech_sizes_for_cost_curve => chp.tech_sizes_for_cost_curve, 
        :om_cost_per_kwh => chp.om_cost_per_kwh, 
        :electric_efficiency_full_load => chp.electric_efficiency_full_load,
        :thermal_efficiency_full_load => chp.thermal_efficiency_full_load,
        :min_allowable_kw => chp.min_allowable_kw,
        :cooling_thermal_factor => chp.cooling_thermal_factor,
        :min_turn_down_fraction => chp.min_turn_down_fraction 
    )

    # Installed cost input validation
    update_installed_cost_params = false
    pass_all_params_error = false
    if !isempty(chp.installed_cost_per_kw) && typeof(chp.installed_cost_per_kw) == Float64
        if !isempty(chp.tech_sizes_for_cost_curve)
            chp.tech_sizes_for_cost_curve = []
            @warn "Ignoring `chp.tech_sizes_for_cost_curve` input because `chp.installed_cost_per_kw` is a scalar"
        end
    elseif length(chp.installed_cost_per_kw) > 1 && length(chp.installed_cost_per_kw) != length(chp.tech_sizes_for_cost_curve)
        throw(@error("To model CHP cost curve, you must provide `chp.tech_sizes_for_cost_curve` vector of equal length to `chp.installed_cost_per_kw`"))
    elseif isempty(chp.tech_sizes_for_cost_curve) && isempty(chp.installed_cost_per_kw)
        update_installed_cost_params = true
    elseif isempty(chp.prime_mover)
        pass_all_params_error = true
    end

    # Set all missing default values in custom_chp_inputs after checking for an existing boiler; this allows CHP wo/ existing boiler
    if !isnothing(existing_boiler)
        prod_type = existing_boiler.production_type
        eff = existing_boiler.efficiency
    else
        prod_type = "hot_water"
        eff = EXISTING_BOILER_EFFICIENCY
    end

    chp_defaults_response = get_chp_defaults_prime_mover_size_class(;hot_water_or_steam=prod_type,
                                                                avg_boiler_fuel_load_mmbtu_per_hour=avg_boiler_fuel_load_mmbtu_per_hour,
                                                                prime_mover=chp.prime_mover,
                                                                size_class=chp.size_class,
                                                                boiler_efficiency=eff)
    defaults = chp_defaults_response["default_inputs"]
    for (k, v) in custom_chp_inputs
        if k in [:installed_cost_per_kw, :tech_sizes_for_cost_curve]
            if update_installed_cost_params
                setproperty!(chp, k, defaults[string(k)])
            end
        elseif isnan(v)
            setproperty!(chp, k, defaults[string(k)])
        end
    end

    # Set electric and thermal half load efficiency to full load if not input
    if isnan(chp.electric_efficiency_half_load)
        chp.electric_efficiency_half_load = chp.electric_efficiency_full_load
    end
    if isnan(chp.thermal_efficiency_half_load)
        chp.thermal_efficiency_half_load = chp.electric_efficiency_full_load
    end

    if chp.min_allowable_kw > chp.max_kw
        @warn "CHP.min_allowable_kw is greater than CHP.max_kw, so setting min_allowable_kw equal to max_kw"
        setproperty!(chp, :min_allowable_kw, chp.max_kw)
    end
        
    if isempty(chp.unavailability_periods)
        chp.unavailability_periods = defaults["unavailability_periods"]
    end

    return chp
end


"""
    get_prime_mover_defaults(prime_mover::String, boiler_type::String, size_class::Int, prime_mover_defaults_all::Dict)

return a Dict{String, Union{Float64, AbstractVector{Float64}}} by selecting the appropriate values from 
data/chp/chp_default_data.json, which contains values based on prime_mover, boiler_type, and size_class for the 
custom_chp_inputs, i.e.
- "installed_cost_per_kw"
- "tech_sizes_for_cost_curve"
- "om_cost_per_kwh"
- "electric_efficiency_full_load"
- "thermal_efficiency_full_load"
- "min_allowable_kw"
- "cooling_thermal_factor"
- "min_turn_down_fraction" 
- "unavailability_periods"
"""
function get_prime_mover_defaults(prime_mover::String, boiler_type::String, size_class::Int, prime_mover_defaults_all::Dict)
    pmds = prime_mover_defaults_all
    prime_mover_defaults = Dict{String, Any}()

    for key in keys(pmds[prime_mover])
        if key in ["thermal_efficiency_full_load", "thermal_efficiency_half_load"]
            prime_mover_defaults[key] = pmds[prime_mover][key][boiler_type][size_class]
        elseif key == "unavailability_periods"
            prime_mover_defaults[key] = convert(Vector{Dict}, pmds[prime_mover][key])
        else
            prime_mover_defaults[key] = pmds[prime_mover][key][size_class]
        end
    end
    pmds = nothing

    for (k,v) in prime_mover_defaults
        if typeof(v) <: AbstractVector{Any} && k != "unavailability_periods"
            prime_mover_defaults[k] = convert(Vector{Float64}, v)  # JSON.parsefile makes things Vector{Any}
        end
    end
    return prime_mover_defaults
end


"""
    get_chp_defaults_prime_mover_size_class(;hot_water_or_steam::Union{String, Nothing}=nothing,
                                        avg_boiler_fuel_load_mmbtu_per_hour::Union{Float64, Vector{Float64}, Nothing}=nothing,
                                        prime_mover::Union{String, Nothing}=nothing,
                                        size_class::Union{Int64, Nothing}=nothing,
                                        boiler_efficiency::Union{Float64, Nothing}=nothing)

Depending on the set of inputs, different sets of outputs are determine in addition to all CHP cost and performance parameter defaults:
    1. Inputs: existing_boiler_production_type_steam_or_hw and avg_boiler_fuel_load_mmbtu_per_hour
       Outputs: prime_mover, size_class, chp_size_based_on_avg_heating_load_kw
    2. Inputs: prime_mover and avg_boiler_fuel_load_mmbtu_per_hour
       Outputs: size_class
    3. Inputs: prime_mover and size_class
       Outputs: (uses default hot_water_or_steam)
    4. Inputs: prime_mover
       Outputs: default average size_class = 1

The main purpose of this function is to communicate the following mapping of dependency of CHP defaults versus 
    existing_boiler_production_type_steam_or_hot_water and avg_boiler_fuel_load_mmbtu_per_hour:
If hot_water and <= 27 MMBtu/hr avg_boiler_fuel_load_mmbtu_per_hour --> prime_mover = recip_engine of size_class X
If hot_water and > 27 MMBtu/hr avg_boiler_fuel_load_mmbtu_per_hour --> prime_mover = combustion_turbine of size_class X
If steam and <= 7 MMBtu/hr avg_boiler_fuel_load_mmbtu_per_hour --> prime_mover = recip_engine of size_class X
If steam and > 7 MMBtu/hr avg_boiler_fuel_load_mmbtu_per_hour --> prime_mover = combustion_turbine of size_class X

The threshold avg_boiler_fuel_load_mmbtu_per_hour are based on industry expert judgements for applicable prime_movers where
reciprocating engine is more suitable for smaller sizes and hot water, and combustion turbine is more suitable
for larger sizes and steam.
"""
function get_chp_defaults_prime_mover_size_class(;hot_water_or_steam::Union{String, Nothing}=nothing,
                                                avg_boiler_fuel_load_mmbtu_per_hour::Union{Float64, Vector{Float64}, Nothing}=nothing,
                                                prime_mover::Union{String, Nothing}=nothing,
                                                size_class::Union{Int64, Nothing}=nothing,
                                                boiler_efficiency::Union{Float64, Nothing}=nothing)
    
    prime_mover_defaults_all = JSON.parsefile(joinpath(@__DIR__, "..", "..", "data", "chp", "chp_defaults.json"))
    avg_boiler_fuel_load_under_recip_over_ct = Dict([("hot_water", 27.0), ("steam", 7.0)])  # [MMBtu/hr] Based on external calcs for size versus production by prime_mover type

    # Inputs validation
    if !isnothing(prime_mover)
        if !(prime_mover in prime_movers)  # Validate user-entered hot_water_or_steam
            throw(@error("Invalid argument for `prime_mover`; must be in $prime_movers"))
        end
    end

    if !isnothing(hot_water_or_steam)  # Option 1 if prime_mover also not input
        if !(hot_water_or_steam in ["hot_water", "steam"])  # Validate user-entered hot_water_or_steam
            throw(@error("Invalid argument for `hot_water_or_steam``; must be `hot_water` or `steam`"))
        end
    else  # Options 2, 3, or 4
        hot_water_or_steam = "hot_water"
    end

    if !isnothing(avg_boiler_fuel_load_mmbtu_per_hour)  # Option 1
        if avg_boiler_fuel_load_mmbtu_per_hour <= 0
            throw(@error("avg_boiler_fuel_load_mmbtu_per_hour must be >= 0.0"))
        end
    end

    if !isnothing(size_class) && !isnothing(prime_mover) # Option 3
        n_classes = length(prime_mover_defaults_all[prime_mover]["installed_cost_per_kw"])
        if size_class < 1 || size_class > n_classes
            throw(@error("The size class $size_class input is outside the valid range of 1 to $n_classes for prime_mover $prime_mover"))
        end
    end

    # Calculate heuristic CHP size based on average thermal load, using the default size class efficiency data
    if !isnothing(avg_boiler_fuel_load_mmbtu_per_hour)
        if isnothing(prime_mover)
            if avg_boiler_fuel_load_mmbtu_per_hour <= avg_boiler_fuel_load_under_recip_over_ct[hot_water_or_steam]
                prime_mover = "recip_engine"  # Must make an initial guess at prime_mover to use those thermal and electric efficiency params to convert to size
            else
                prime_mover = "combustion_turbine"
            end
        end
        if isnothing(size_class)
            size_class_calc = 1
        else
            size_class_calc = size_class
        end
        if isnothing(boiler_efficiency)
            boiler_effic = existing_boiler_efficiency_defaults[hot_water_or_steam]
        else
            boiler_effic = boiler_efficiency
        end
        therm_effic = prime_mover_defaults_all[prime_mover]["thermal_efficiency_full_load"][hot_water_or_steam][size_class_calc]
        elec_effic = prime_mover_defaults_all[prime_mover]["electric_efficiency_full_load"][size_class_calc]
        avg_heating_thermal_load_mmbtu_per_hr = avg_boiler_fuel_load_mmbtu_per_hour * boiler_effic
        chp_fuel_rate_mmbtu_per_hr = avg_heating_thermal_load_mmbtu_per_hr / therm_effic
        chp_elec_size_heuristic_kw = chp_fuel_rate_mmbtu_per_hr * elec_effic * KWH_PER_MMBTU
    else
        chp_elec_size_heuristic_kw = nothing
    end

    # Assign recip_engine as the (default) prime mover if not input or assigned base on avg_boiler_fuel_load_mmbtu_per_hour
    if isnothing(prime_mover)
        prime_mover = "recip_engine"
    end

    # prime_mover now assigned even if it was not input, so now load in these size_class metrics
    n_classes = length(prime_mover_defaults_all[prime_mover]["installed_cost_per_kw"])
    class_bounds = prime_mover_defaults_all[prime_mover]["tech_sizes_for_cost_curve"]

    # If size class is specified use that and ignore heuristic CHP sizing for determining size class
    if !isnothing(size_class)
        if size_class < 1 || size_class > n_classes
            throw(@error("The size class $size_class input is outside the valid range of 1 to $n_classes for prime_mover $prime_mover"))
        end
    # If size class is not specified, heuristic sizing based on avg thermal load and size class 0 efficiencies
    elseif isnothing(size_class) && !isnothing(chp_elec_size_heuristic_kw)
        # With heuristic size, find the suggested size class
        if chp_elec_size_heuristic_kw < class_bounds[2][2]
            # If smaller than the upper bound of the smallest class, assign the smallest class
            size_class = 2
        elseif chp_elec_size_heuristic_kw >= class_bounds[n_classes][1]
            # If larger than or equal to the lower bound of the largest class, assign the largest class
            size_class = n_classes # Size classes are one-indexed
        else
            # For middle size classes
            for sc in 2:(n_classes-1)
                if chp_elec_size_heuristic_kw >= class_bounds[sc][1] && 
                    chp_elec_size_heuristic_kw < class_bounds[sc][2]
                    size_class = sc
                end
            end
        end
    else
        size_class = 1
    end

    prime_mover_defaults = get_prime_mover_defaults(prime_mover, hot_water_or_steam, size_class, prime_mover_defaults_all)

    response = Dict([
        ("prime_mover", prime_mover),
        ("size_class", size_class),
        ("hot_water_or_steam", hot_water_or_steam),
        ("default_inputs", prime_mover_defaults),
        ("chp_size_based_on_avg_heating_load_kw", chp_elec_size_heuristic_kw),
        ("size_class_bounds", class_bounds)
    ])
    return response

end
