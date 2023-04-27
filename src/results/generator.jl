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
	add_generator_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")

Adds the Generator results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
Note: the node number is an empty string if evaluating a single `Site`.

Generator results:
- `size_kw` Optimal generator capacity
- `lifecycle_fixed_om_cost` Lifecycle fixed operations and maintenance cost in present value, after tax
- `year_one_fixed_om_cost` fixed operations and maintenance cost over the first year
- `lifecycle_variable_om_cost` Lifecycle variable operations and maintenance cost in present value, after tax
- `year_one_variable_om_cost` variable operations and maintenance cost over the first year
- `lifecycle_fuel_cost` Lifecycle fuel cost in present value, after tax
- `year_one_fuel_cost` Fuel cost over the first year
- `fuel_used_gal` Gallons of fuel used in each year
- `year_one_to_battery_series_kw` Vector of power sent to battery in year one
- `year_one_to_grid_series_kw` Vector of power sent to grid in year one
- `year_one_to_load_series_kw` Vector of power sent to load in year one
- `year_one_energy_produced_kwh` Total energy produced in year one
- `average_annual_energy_produced_kwh` Average annual energy produced over analysis period
"""
function add_generator_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
    r = Dict{String, Any}()

	GenPerUnitSizeOMCosts = @expression(m, p.third_party_factor * p.pwf_om * sum(m[:dvSize][t] * p.om_cost_per_kw[t] for t in p.techs.gen))

	GenPerUnitProdOMCosts = @expression(m, p.third_party_factor * p.pwf_om * p.hours_per_timestep *
		sum(m[:dvRatedProduction][t, ts] * p.production_factor[t, ts] * p.s.generator.om_cost_per_kwh
			for t in p.techs.gen, ts in p.time_steps)
	)
	r["size_kw"] = round(value(sum(m[:dvSize][t] for t in p.techs.gen)), digits=2)
	r["lifecycle_fixed_om_cost"] = round(value(GenPerUnitSizeOMCosts) * (1 - p.s.financial.owner_tax_pct), digits=0)
	r["lifecycle_variable_om_cost"] = round(value(m[:TotalPerUnitProdOMCosts]) * (1 - p.s.financial.owner_tax_pct), digits=0)
	r["lifecycle_fuel_cost"] = round(value(m[:TotalGenFuelCosts]) * (1 - p.s.financial.offtaker_tax_pct), digits=2)
	r["year_one_fuel_cost"] = round(value(m[:TotalGenFuelCosts]) / p.pwf_e, digits=2)
	r["year_one_variable_om_cost"] = round(value(GenPerUnitProdOMCosts) / (p.pwf_om * p.third_party_factor), digits=0)
	r["year_one_fixed_om_cost"] = round(value(GenPerUnitSizeOMCosts) / (p.pwf_om * p.third_party_factor), digits=0)

	generatorToBatt = @expression(m, [ts in p.time_steps],
		sum(m[:dvProductionToStorage][b, t, ts] for b in p.s.storage.types, t in p.techs.gen))
	r["year_one_to_battery_series_kw"] = round.(value.(generatorToBatt), digits=3)

	generatorToGrid = @expression(m, [ts in p.time_steps],
		sum(m[:dvProductionToGrid][t, u, ts] for t in p.techs.gen, u in p.export_bins_by_tech[t])
	)
	r["year_one_to_grid_series_kw"] = round.(value.(generatorToGrid), digits=3)

	generatorToLoad = @expression(m, [ts in p.time_steps],
		sum(m[:dvRatedProduction][t, ts] * p.production_factor[t, ts] * p.levelization_factor[t]
			for t in p.techs.gen) -
			generatorToBatt[ts] - generatorToGrid[ts]
	)
	r["year_one_to_load_series_kw"] = round.(value.(generatorToLoad), digits=3)

    GeneratorFuelUsed = @expression(m, sum(m[:dvFuelUsage][t, ts] for t in p.techs.gen, ts in p.time_steps))
	r["fuel_used_gal"] = round(value(GeneratorFuelUsed), digits=2)

	Year1GenProd = @expression(m,
		p.hours_per_timestep * sum(m[:dvRatedProduction][t,ts] * p.production_factor[t, ts]
			for t in p.techs.gen, ts in p.time_steps)
	)
	r["year_one_energy_produced_kwh"] = round(value(Year1GenProd), digits=0)
	AverageGenProd = @expression(m,
		p.hours_per_timestep * sum(m[:dvRatedProduction][t,ts] * p.production_factor[t, ts] *
		p.levelization_factor[t]
			for t in p.techs.gen, ts in p.time_steps)
	)
	r["average_annual_energy_produced_kwh"] = round(value(AverageGenProd), digits=0)
    
	d["Generator"] = r
    nothing
end


function add_generator_results(m::JuMP.AbstractModel, p::MPCInputs, d::Dict; _n="")
    r = Dict{String, Any}()

	r["variable_om_cost"] = round(value(m[:TotalPerUnitProdOMCosts]), digits=0)
	r["fuel_cost"] = round(value(m[:TotalGenFuelCosts]), digits=2)

    if p.s.storage.size_kw[:elec] > 0
        generatorToBatt = @expression(m, [ts in p.time_steps],
            sum(m[:dvProductionToStorage][b, t, ts] for b in p.s.storage.types, t in p.techs.gen))
        r["to_battery_series_kw"] = round.(value.(generatorToBatt), digits=3).data
    else
        generatorToBatt = zeros(length(p.time_steps))
    end

	generatorToGrid = @expression(m, [ts in p.time_steps],
		sum(m[:dvProductionToGrid][t, u, ts] for t in p.techs.gen, u in p.export_bins_by_tech[t])
	)
	r["to_grid_series_kw"] = round.(value.(generatorToGrid), digits=3).data

	generatorToLoad = @expression(m, [ts in p.time_steps],
		sum(m[:dvRatedProduction][t, ts] * p.production_factor[t, ts] * p.levelization_factor[t]
			for t in p.techs.gen) -
			generatorToBatt[ts] - generatorToGrid[ts]
	)
	r["to_load_series_kw"] = round.(value.(generatorToLoad), digits=3).data

    GeneratorFuelUsed = @expression(m, sum(m[:dvFuelUsage][t, ts] for t in p.techs.gen, ts in p.time_steps))
	r["fuel_used_gal"] = round(value(GeneratorFuelUsed), digits=2)

	Year1GenProd = @expression(m,
		p.hours_per_timestep * sum(m[:dvRatedProduction][t,ts] * p.production_factor[t, ts]
			for t in p.techs.gen, ts in p.time_steps)
	)
	r["energy_produced_kwh"] = round(value(Year1GenProd), digits=0)
    
	d["Generator"] = r
    nothing
end
