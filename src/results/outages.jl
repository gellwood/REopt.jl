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
`Outages` results keys:
- `expected_outage_cost` The expected outage cost over the random outages modeled.
- `max_outage_cost_per_outage_duration` The maximum outage cost in every outage duration modeled.
- `unserved_load_series_kw` The amount of unserved load in each outage and each time step.
- `unserved_load_per_outage_kwh` The total unserved load in each outage.
- `storage_microgrid_upgrade_cost` The cost to include the storage system in the microgrid.
- `storage_discharge_series_kw` Array of storage power discharged in every outage modeled.
- `pv_microgrid_size_kw` Optimal microgrid PV capacity. Note that the name `PV` can change based on user provided `PV.name`.
- `pv_microgrid_upgrade_cost` The cost to include the PV system in the microgrid.
- `pv_to_storage_series_kw` Array of PV power sent to the battery in every outage modeled.
- `pv_curtailed_series_kw` Array of PV curtailed in every outage modeled.
- `pv_to_load_series_kw` Array of PV power used to meet load in every outage modeled.
- `generator_microgrid_size_kw` Optimal microgrid Generator capacity. Note that the name `Generator` can change based on user provided `Generator.name`.
- `generator_microgrid_upgrade_cost` The cost to include the Generator system in the microgrid.
- `generator_to_storage_series_kw` Array of Generator power sent to the battery in every outage modeled.
- `generator_curtailed_series_kw` Array of Generator curtailed in every outage modeled.
- `generator_to_load_series_kw` Array of Generator power used to meet load in every outage modeled.
- `generator_fuel_used_per_outage_gal` Array of fuel used in every outage modeled, summed over all Generators.
- `chp_microgrid_size_kw` Optimal microgrid CHP capacity.
- `chp_microgrid_upgrade_cost` The cost to include the CHP system in the microgrid.
- `chp_to_storage_series_kw` Array of CHP power sent to the battery in every outage modeled.
- `chp_curtailed_series_kw` Array of CHP curtailed in every outage modeled.
- `chp_to_load_series_kw` Array of CHP power used to meet load in every outage modeled.
- `chp_fuel_used_per_outage_mmbtu` Array of fuel used in every outage modeled, summed over all CHPs.
- `microgrid_upgrade_capital_cost` Total capital cost of including technologies in the microgrid

!!! warn
	The output keys for "Outages" are subject to change.

!!! note 
	`Outage` results only added to results when multiple outages are modeled via the `ElectricUtility.outage_durations` input.

!!! note
	When modeling PV the name of the PV system is used for the output keys to allow for modeling multiple PV systems. The default PV name is `PV`.
	
!!! warn
	The Outage results can be very large when many outages are modeled and can take a long time to generate.
"""
function add_outage_results(m, p, d::Dict)
	# Adds the `Outages` results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs`.
	# Only added to results when multiple outages are modeled via the `ElectricUtility.outage_durations` input.

	# TODO with many outages the dispatch arrays are so large that it can take hours to create them
	# (eg. 8760 * 12 hour outages with PV, storage and diesel makes 7*12*8760 = 735,840 values)
	# For now the outage dispatch outputs are not created (commented out below). Perhaps make a new
	# function to optionally get the outage dispatch values so that we don't slow down returning the
	# other results.
	r = Dict{String, Any}()
	r["expected_outage_cost"] = value(m[:ExpectedOutageCost])
	r["max_outage_cost_per_outage_duration"] = value.(m[:dvMaxOutageCost]).data
	r["unserved_load_series_kw"] = value.(m[:dvUnservedLoad]).data
	S = length(p.s.electric_utility.scenarios)
	T = length(p.s.electric_utility.outage_start_time_steps)
	TS = length(p.s.electric_utility.outage_time_steps)
	unserved_load_per_outage = Array{Float64}(undef, S, T)
	for s in 1:S, t in 1:T
		if p.s.electric_utility.outage_durations[s] < TS
			r["unserved_load_series_kw"][s,t,p.s.electric_utility.outage_durations[s]+1:end] .= 0
		end
		unserved_load_per_outage[s, t] = sum(r["unserved_load_series_kw"][s, t, ts] for 
											 ts in 1:p.s.electric_utility.outage_durations[s]) 
		# need to sum over ts in 1:p.s.electric_utility.outage_durations[s] 
		# instead of all ts b/c dvUnservedLoad has unused values in third dimension
	end
	r["unserved_load_per_outage_kwh"] = round.(unserved_load_per_outage, digits=2)
	r["storage_microgrid_upgrade_cost"] = value(m[:dvMGStorageUpgradeCost])
	r["microgrid_upgrade_capital_cost"] = r["storage_microgrid_upgrade_cost"]
	if !isempty(p.s.storage.types.elec) && Bool(round(value(m[:binMGStorageUsed]), digits=0))
		r["storage_discharge_series_kw"] = value.(m[:dvMGDischargeFromStorage]).data
	else
		r["storage_discharge_series_kw"] = []
	end

	for (tech_type_name, tech_set) in [("pv", p.techs.pv), ("generator", p.techs.gen), ("chp", p.techs.chp)]
		if !isempty(tech_set)
			r[tech_type_name * "_microgrid_size_kw"] = round(
				sum(
					# need to multiply by the binary b/c can have non-zero mg capacity when not using the capacity
					# due to the constraint for setting the mg capacities equal to the grid connected capacities
					value(m[:dvMGsize][t]) * round(value(m[:binMGTechUsed][t]), digits=0)
					for t in tech_set
				), 
				digits=4
			)
			r[tech_type_name * "_microgrid_upgrade_cost"] = round(
				sum(
					value(m[:dvMGTechUpgradeCost][t]) for t in tech_set
				), 
				digits=2
			)
			if isempty(p.s.storage.types.elec)
				r[tech_type_name * "_to_storage_series_kw"] = []
			else
				r[tech_type_name * "_to_storage_series_kw"] = round.(
					sum(
						(
							value.(
								m[:dvMGProductionToStorage][t, s, tz, ts] 
								for s in p.s.electric_utility.scenarios,
									tz in p.s.electric_utility.outage_start_time_steps,
									ts in p.s.electric_utility.outage_time_steps
							) 
							for t in tech_set
						)
					), 
					digits=3
				)
			end
			r[tech_type_name * "_curtailed_series_kw"] = round.(
				sum(
					(
						value.(
							m[:dvMGCurtail][t, s, tz, ts] 
							for s in p.s.electric_utility.scenarios,
								tz in p.s.electric_utility.outage_start_time_steps,
								ts in p.s.electric_utility.outage_time_steps
						) 
						for t in tech_set
					)
				), 
				digits=3
			)
			r[tech_type_name * "_to_load_series_kw"] = round.(
				sum(
					(
						value.(
							m[:dvMGRatedProduction][t, s, tz, ts] * p.production_factor[t, tz+ts-1] * p.levelization_factor[t]
							- m[:dvMGCurtail][t, s, tz, ts]
							- m[:dvMGProductionToStorage][t, s, tz, ts]
							for s in p.s.electric_utility.scenarios,
								tz in p.s.electric_utility.outage_start_time_steps,
								ts in p.s.electric_utility.outage_time_steps
						) 
						for t in tech_set
					)
				), 
				digits=3
			)
			r["microgrid_upgrade_capital_cost"] += r[tech_type_name * "_microgrid_upgrade_cost"]
		end
	end
	for (tech_type_name, tech_set) in [("generator", p.techs.gen), ("chp", p.techs.chp)]
		if !isempty(tech_set)
            if tech_type_name == "generator"
                fuel_unit = "gal"
                unit_conversion = 1.0
            else
                fuel_unit = "mmbtu"
                unit_conversion = KWH_PER_MMBTU
            end
            r[tech_type_name*"_fuel_used_per_outage_"*fuel_unit] = round.(
                sum(
                    [value.(m[:dvMGFuelUsed][t, :, :]).data ./ unit_conversion for t in tech_set]
                ), 
                digits=4
            )
        end
	end

	d["Outages"] = r
end