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
    ElectricVehicle

Inputs used when:
```julia 
haskey(d["ElectricVehicle"])
```
Defined by these parameters which are contained in the EV dictionary, unique to EV vs (stationary) ElectricStorage
```julia
Base.@kwdef mutable struct ElectricVehicle
    energy_capacity_kwh::Float64 = NaN
    max_c_rate::Float64 = 1.0
    ev_on_site_start_end::Array{Int64, 1} = [0,0]  # This should **maybe** be an array of arrays (meant to be array of tuples, could convert)
    ev_on_site_series::Array{Int64, 1} = []
    soc_used_off_site::Float64 = 0.0
    leaving_next_time_step_soc_min::Array{Float64, 1} = []
    back_on_site_time_step_soc_drained::Array{Float64, 1} = []
end
```

# TODO
- Align schedule parameters with year, and day of week = 1 is Sunday or Monday?
- Weeks or days where EV is never on-site
- Add soc_used_off_site options to be Scalar, 2x (weekday/weekend), or 7x (each day of week) Values of 0.0 to (1.0 - min_soc)


"""
Base.@kwdef mutable struct ElectricVehicle
    energy_capacity_kwh::Float64 = NaN
    max_c_rate::Float64 = 1.0
    ev_on_site_start_end::Array{Int64, 1} = [0,0]  # This should **maybe** be an array of arrays (meant to be array of tuples, could convert)
    ev_on_site_series::Array{Int64, 1} = Int64[]
    soc_used_off_site::Float64 = 0.0
    leaving_next_time_step_soc_min::Array{Float64, 1} = Float64[]
    back_on_site_time_step_soc_drained::Array{Float64, 1} = Float64[]
end

function get_availability_series(start_end::Array{Int64, 1}, year::Int64=2017)
    if start_end[1] < start_end[2]
        # EV is at the site during the day (commercial without their own EVs, just workers' EVs)
        profile = zeros(8760)
        for day in 1:365
            profile[24*(day-1)+start_end[1]:24*(day-1)+start_end[2]] .= 1
        end
    else
        # EV is at the site during the night (commercial with their own EVs, or residential)
        profile = ones(8760)
        for day in 1:365
            profile[24*(day-1)+start_end[2]-1:24*(day-1)+start_end[1]-1] .= 0
        end
    end

    return profile
    # TODO implement more options for profiles and use Dates.jl package to create profile, 
    #   something like generate_year_profile_hourly
    # # TODO get start day of the week (1-7) from the year to put in base
    # start_day_of_year = 7  # 2017 first day is Sunday (day=7)
    # entry_base = Dict([("month", 1),
    #                 ("start_week_of_month", 1),
    #                 ("start_day_of_week", start_day_of_year),
    #                 ("start_hour", start_end[1]),
    #                 ("duration_hours", start_end[2] - start_end[1])])
    # consecutive_periods = []
    # # TODO get weeks_per_month from the year (these can be partial weeks for weeks 1 or last/end)
    # weeks_per_month = [6,5,5,5,5,5,6,5,5,6,5,5]  # These are the total number of weeks where there's at least one day 1-7
    # for month in 1:12
    #     weeks = weeks_per_month[month]
    #     days = daysinmonth(Date(string(year) * "-" * string(month)))
    #     for week in 1:weeks
    #         day = 1
    #         if week == 1 && !(month == 1)
    #             start_day_of_week = 1
    #         elseif week == weeks_per_month[month]
                
    #         while start_day <= 7 do
    #             entry_base["month"] = month
    #             entry_base["start_week_of_month"] = week
    #             entry_base["start_day_of_week"] = start_day
    #             append!(consecutive_periods, entry)
    #             start_day += 1
    #             day += 1
    #         end

    # profile = generate_year_profile_hourly(year, consecutive_periods)
end

function get_returned_and_required_soc(soc_used_off_site, availability_series)
    back_on_site_time_step_soc_drained::Array{Float64, 1} = zeros(8760)
    leaving_next_time_step_soc_min::Array{Float64, 1} = zeros(8760)
    # TODO this is only populating the first event, then stuck in the same "switch" state
    for ts in firstindex(availability_series)+1:lastindex(availability_series)  # eachindex or axes(availability_series, 1) starting at ts=2?
        if !(availability_series[ts] == availability_series[ts-1])
            if availability_series[ts] == 1
                # Back on site
                back_on_site_time_step_soc_drained[ts] = soc_used_off_site
            elseif availability_series[ts] == 0
                # Leaving next time step
                # TODO add a "buffer"/extra charge as an input for soc above the min required soc_used_off_site (max(1,soc_used+buffer))
                leaving_next_time_step_soc_min[ts-1] = soc_used_off_site
            end
        end
    end

    return back_on_site_time_step_soc_drained, leaving_next_time_step_soc_min

end
                

function ElectricVehicle(d::Dict)
    ev = ElectricVehicle(;d...)
    ev.ev_on_site_series = get_availability_series(ev.ev_on_site_start_end)
    ev.back_on_site_time_step_soc_drained, 
        ev.leaving_next_time_step_soc_min = get_returned_and_required_soc(d[:soc_used_off_site], ev.ev_on_site_series)
    return ev
end

"""
`ElectricVehicle` is an optional optional REopt input with the following keys and default values:

```julia
    name::String = ""
    off_grid_flag::Bool = false  
    min_kw::Real = 0.0  Max charging power for EV is based on C-rate and/or charger rating  
    max_kw::Real = 0.0  "
    min_kwh::Real = 0.0  EV energy capacity (kwh) is an input value  
    max_kwh::Real = 0.0  "
    internal_efficiency_fraction::Float64 = 0.975
    inverter_efficiency_fraction::Float64 = 0.96
    rectifier_efficiency_fraction::Float64 = 0.96
    soc_min_fraction::Float64 = 0.0  Changed to zero for EV
    soc_init_fraction::Float64 = off_grid_flag ? 1.0 : 0.5  Not relevant for EV because specified in ElectricVehicle struct
    can_grid_charge::Bool = off_grid_flag ? false : true
    installed_cost_per_kw::Real = 0.0
    installed_cost_per_kwh::Real = 0.0
    replace_cost_per_kw::Real = 0.0
    replace_cost_per_kwh::Real = 0.0
    inverter_replacement_year::Int = 50
    battery_replacement_year::Int = 50
    macrs_option_years::Int = 0
    macrs_bonus_fraction::Float64 = 1.0
    macrs_itc_reduction::Float64 = 0.0
    total_itc_fraction::Float64 = 0.0
    total_rebate_per_kw::Real = 0.0
    total_rebate_per_kwh::Real = 0.0
    charge_efficiency::Float64 = rectifier_efficiency_fraction * internal_efficiency_fraction^0.5
    discharge_efficiency::Float64 = inverter_efficiency_fraction * internal_efficiency_fraction^0.5
    grid_charge_efficiency::Float64 = can_grid_charge ? charge_efficiency : 0.0
    model_degradation::Bool = false
    degradation::Dict = Dict()
    minimum_avg_soc_fraction::Float64 = 0.0
    electric_vehicle::Union{Dict, nothing} = Dict()
```
"""
Base.@kwdef mutable struct ElectricVehicleDefaults
    name::String = ""
    off_grid_flag::Bool = false  
    min_kw::Real = 0.0
    max_kw::Real = 0.0
    min_kwh::Real = 0.0
    max_kwh::Real = 0.0
    internal_efficiency_fraction::Float64 = 0.975
    inverter_efficiency_fraction::Float64 = 0.96
    rectifier_efficiency_fraction::Float64 = 0.96
    soc_min_fraction::Float64 = 0.0
    soc_init_fraction::Float64 = off_grid_flag ? 1.0 : 0.5
    can_grid_charge::Bool = off_grid_flag ? false : true
    installed_cost_per_kw::Real = 0.0
    installed_cost_per_kwh::Real = 0.0
    replace_cost_per_kw::Real = 0.0
    replace_cost_per_kwh::Real = 0.0
    inverter_replacement_year::Int = 50
    battery_replacement_year::Int = 50
    macrs_option_years::Int = 0
    macrs_bonus_fraction::Float64 = 1.0
    macrs_itc_reduction::Float64 = 0.0
    total_itc_fraction::Float64 = 0.0
    total_rebate_per_kw::Real = 0.0
    total_rebate_per_kwh::Real = 0.0
    charge_efficiency::Float64 = rectifier_efficiency_fraction * internal_efficiency_fraction^0.5
    discharge_efficiency::Float64 = inverter_efficiency_fraction * internal_efficiency_fraction^0.5
    grid_charge_efficiency::Float64 = can_grid_charge ? charge_efficiency : 0.0
    model_degradation::Bool = false
    degradation::Dict = Dict()
    minimum_avg_soc_fraction::Float64 = 0.0
    electric_vehicle::ElectricVehicle = ElectricVehicle()
end

function ElectricVehicleDefaults(d::Dict)
    inputs = ElectricVehicleDefaults(;d..., 
                    electric_vehicle=ElectricVehicle(dictkeys_tosymbols(d[:electric_vehicle])))
    # Set min/max kwh/kw based on specified energy capacity and max c-rate
    energy_capacity = inputs.electric_vehicle.energy_capacity_kwh
    inputs.min_kwh = energy_capacity
    inputs.max_kwh = energy_capacity
    inputs.min_kw = energy_capacity * inputs.electric_vehicle.max_c_rate
    inputs.max_kw = energy_capacity * inputs.electric_vehicle.max_c_rate

    return inputs
end

Base.@kwdef mutable struct EVSupplyEquipment
    # Do we want to allow a combination of level and/or bidirectional chargers?
    force_num_to_max::Bool = true
    max_num::Union{Int64, Array{Int64, 1}} = 1
    power_rating_kw::Union{Float64, Array{Float64, 1}} = [10.0, 80.0]
    installed_cost::Union{Float64, Array{Float64, 1}} = [1000.0, 18000.0]
    # TODO allow array for v2g (or "bidirectional") for each type
    v2g::Bool = false
end

function EVSupplyEquipment(d::Dict)
    if typeof(d[:power_rating_kw]) <: AbstractArray
        d[:power_rating_kw] = convert(Array{Float64, 1}, d[:power_rating_kw])
    end
    if typeof(d[:max_num]) <: AbstractArray
        if !(length(d[:max_num]) == length(d[:power_rating_kw]))
            throw(@error("The length of max_num must equal the length of power_rating_kw"))
        end   
        d[:max_num] = convert(Array{Int64, 1}, d[:max_num])
    end 
    if haskey(d, :installed_cost)
        if typeof(d[:installed_cost]) <: AbstractArray
            if !(length(d[:installed_cost]) == length(d[:power_rating_kw]))
                throw(@error("The length of installed_cost must equal the length of power_rating_kw"))
            end
            d[:installed_cost] = convert(Array{Float64, 1}, d[:installed_cost])
        end
    end
    evse = EVSupplyEquipment(;d...)
    # Convert scalars to arrays
    if !(typeof(evse.power_rating_kw) <: AbstractArray)
        evse.power_rating_kw = [deepcopy(evse.power_rating_kw)]
    end
    if !(typeof(evse.installed_cost) <: AbstractArray)
        evse.installed_cost = [deepcopy(evse.installed_cost)]
    end
    if !(typeof(evse.max_num) <: AbstractArray)
        evse.max_num = [deepcopy(evse.max_num)]
    end

    return evse
end