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

struct Boiler <: AbstractThermalTech
    min_kw::Real
    max_kw::Real
    efficiency::Real
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}}
    installed_cost_per_kw::Real
    om_cost_per_kw::Real
    om_cost_per_kwh::Real
    macrs_option_years::Int
    macrs_bonus_fraction::Real
    fuel_type::String
    can_supply_steam_turbine::Bool
end


"""
    Boiler

When modeling a heating load an `ExistingBoiler` model is created even if user does not provide the
`ExistingBoiler` key. The `Boiler` model is not created by default. If a user provides the `Boiler`
key then the optimal scenario has the option to purchase this new `Boiler` to meet the heating load
in addition to using the `ExistingBoiler` to meet the heating load. 

```julia
function Boiler(;
    min_mmbtu_per_hour::Real = 0.0, # Minimum thermal power size
    max_mmbtu_per_hour::Real = 0.0, # Maximum thermal power size
    efficiency::Real = 0.8, # boiler system efficiency - conversion of fuel to usable heating thermal energy
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = 0.0,
    macrs_option_years::Int = 0, # MACRS schedule for financial analysis. Set to zero to disable
    macrs_bonus_fraction::Real = 0.0, # Fraction of upfront project costs to depreciate under MACRS
    installed_cost_per_mmbtu_per_hour::Real = 293000.0, # Thermal power-based cost
    om_cost_per_mmbtu_per_hour::Real = 2930.0, # Thermal power-based fixed O&M cost
    om_cost_per_mmbtu::Real = 0.0, # Thermal energy-based variable O&M cost
    fuel_type::String = "natural_gas",  # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil", "uranium"]
    can_supply_steam_turbine::Bool = true # If the boiler can supply steam to the steam turbine for electric production
)
```
"""
function Boiler(;
        min_mmbtu_per_hour::Real = 0.0,
        max_mmbtu_per_hour::Real = 0.0,
        efficiency::Real = 0.8,
        fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = [], # REQUIRED. Can be a scalar, a list of 12 monthly values, or a time series of values for every time step
        time_steps_per_hour::Int = 1,  # passed from Settings
        macrs_option_years::Int = 0,
        macrs_bonus_fraction::Real = 0.0,
        installed_cost_per_mmbtu_per_hour::Real = 293000.0,
        om_cost_per_mmbtu_per_hour::Real = 2930.0,
        om_cost_per_mmbtu::Real = 0.0,
        fuel_type::String = "natural_gas",  # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil", "uranium"]
        can_supply_steam_turbine::Bool = true
        # emissions_factor_lb_CO2_per_mmbtu::Real,
    )

    if isempty(fuel_cost_per_mmbtu)
        throw(@error("The Boiler.fuel_cost_per_mmbtu is a required input when modeling a heating load which is served by the Boiler in the optimal case"))
    end

    min_kw = min_mmbtu_per_hour * KWH_PER_MMBTU
    max_kw = max_mmbtu_per_hour * KWH_PER_MMBTU

    # Convert cost basis of mmbtu/mmbtu_per_hour to kwh/kw
    installed_cost_per_kw = installed_cost_per_mmbtu_per_hour / KWH_PER_MMBTU
    om_cost_per_kw = om_cost_per_mmbtu_per_hour / KWH_PER_MMBTU
    om_cost_per_kwh = om_cost_per_mmbtu / KWH_PER_MMBTU

    Boiler(
        min_kw,
        max_kw,
        efficiency,
        fuel_cost_per_mmbtu,
        installed_cost_per_kw,
        om_cost_per_kw,
        om_cost_per_kwh,
        macrs_option_years,
        macrs_bonus_fraction,
        fuel_type,
        can_supply_steam_turbine
    )
end
