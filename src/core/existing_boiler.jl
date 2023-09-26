# REopt®, Copyright (c) Alliance for Sustainable Energy, LLC. See also https://github.com/NREL/REopt.jl/blob/master/LICENSE.
const existing_boiler_efficiency_defaults = Dict(
                                                "hot_water" => EXISTING_BOILER_EFFICIENCY,
                                                "steam" => 0.75
                                            )

struct ExistingBoiler <: AbstractThermalTech  # useful to create AbstractHeatingTech or AbstractThermalTech?
    max_kw::Real
    production_type::String
    efficiency::Real
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}}
    fuel_type::String
    can_supply_steam_turbine::Bool
    fuel_renewable_energy_fraction::Real
    emissions_factor_lb_CO2_per_mmbtu::Real
    emissions_factor_lb_NOx_per_mmbtu::Real
    emissions_factor_lb_SO2_per_mmbtu::Real
    emissions_factor_lb_PM25_per_mmbtu::Real
end


"""
`ExistingBoiler` is an optional REopt input with the following keys and default values:
```julia
    max_heat_demand_kw::Real=0, # Auto-populated based on SpaceHeatingLoad and DomesticHotWaterLoad inputs
    production_type::String = "hot_water", # Can be "steam" or "hot_water"
    max_thermal_factor_on_peak_load::Real = 1.25,
    efficiency::Real = NaN, # Existing boiler system efficiency - conversion of fuel to usable heating thermal energy. See note below.
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = [], # REQUIRED. Can be a scalar, a list of 12 monthly values, or a time series of values for every time step
    fuel_type::String = "natural_gas", # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil"]
    can_supply_steam_turbine::Bool = false,
    fuel_renewable_energy_fraction::Real = get(FUEL_DEFAULTS["fuel_renewable_energy_fraction"],fuel_type,0),
    emissions_factor_lb_CO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_CO2_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_NOx_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_NOx_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_SO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_SO2_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_PM25_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_PM25_per_mmbtu"],fuel_type,0)
```

!!! note "Max ExistingBoiler size" 
    The maximum size [kW] of the `ExistingBoiler` will be set based on the peak heat demand as follows:
    ```julia 
    max_kw = max_heat_demand_kw * max_thermal_factor_on_peak_load
    ```

!!! note "ExistingBoiler operating costs" 
    The `ExistingBoiler`'s `fuel_cost_per_mmbtu` field is a required input. The `fuel_cost_per_mmbtu` can be a scalar, a list of 12 monthly values, or a time series of values for every time step.

!!! note "Determining `efficiency`" 
    Must supply either: `efficiency` or `production_type`.
    
    If `efficiency` is not supplied, the `efficiency` will be determined based on the `production_type`. 
    If `production_type` is not supplied, it defaults to `hot_water`.
    The following defaults are used:
    ```julia
    existing_boiler_efficiency_defaults = Dict(
        "hot_water" => 0.8,
        "steam" => 0.75
    )
    ```

"""
function ExistingBoiler(;
    max_heat_demand_kw::Real=0,
    production_type::String = "hot_water",
    max_thermal_factor_on_peak_load::Real = 1.25,
    efficiency::Real = NaN,
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = [], # REQUIRED. Can be a scalar, a list of 12 monthly values, or a time series of values for every time step
    fuel_type::String = "natural_gas", # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil"]
    can_supply_steam_turbine::Bool = false,
    fuel_renewable_energy_fraction::Real = get(FUEL_DEFAULTS["fuel_renewable_energy_fraction"],fuel_type,0),
    emissions_factor_lb_CO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_CO2_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_NOx_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_NOx_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_SO2_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_SO2_per_mmbtu"],fuel_type,0),
    emissions_factor_lb_PM25_per_mmbtu::Real = get(FUEL_DEFAULTS["emissions_factor_lb_PM25_per_mmbtu"],fuel_type,0),
    time_steps_per_hour::Int = 1
)
    @assert fuel_type in FUEL_TYPES
    @assert production_type in ["steam", "hot_water"]

    if isempty(fuel_cost_per_mmbtu)
        throw(@error("The ExistingBoiler.fuel_cost_per_mmbtu is a required input when modeling a heating load which is served by the Existing Boiler in the BAU case"))
    end

    if isnan(efficiency)
        efficiency = existing_boiler_efficiency_defaults[production_type]
    end

    max_kw = max_heat_demand_kw * max_thermal_factor_on_peak_load

    ExistingBoiler(
        max_kw,
        production_type,
        efficiency,
        fuel_cost_per_mmbtu,
        fuel_type,
        can_supply_steam_turbine,
        fuel_renewable_energy_fraction,
        emissions_factor_lb_CO2_per_mmbtu,
        emissions_factor_lb_NOx_per_mmbtu,
        emissions_factor_lb_SO2_per_mmbtu,
        emissions_factor_lb_PM25_per_mmbtu
    )
end
