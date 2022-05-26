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
    reopt_results(m::JuMP.AbstractModel, p::REoptInputs; _n="")

Create a dictionary of results with string keys for each Scenario structure modeled.
"""
function reopt_results(m::JuMP.AbstractModel, p::REoptInputs; _n="")
	tstart = time()
    d = Dict{String, Any}()
    # TODO determine whether other results specific to electrical or thermal storage
    # systems warrant separate functions
    for b in p.s.storage.types.elec
        if p.s.storage.attr[b].max_kwh > 0
            add_electric_storage_results(m, p, d, b; _n)
        end
    end

    for b in p.s.storage.types.hot
        if p.s.storage.attr[b].max_kwh > 0
            add_hot_storage_results(m, p, d, b; _n)
        end
    end

    for b in p.s.storage.types.cold
        if p.s.storage.attr[b].max_kwh > 0
            add_cold_storage_results(m, p, d, b; _n)
        end
    end

    add_electric_tariff_results(m, p, d; _n)
    add_electric_utility_results(m, p, d; _n)
    add_financial_results(m, p, d; _n)
    add_electric_load_results(m, p, d; _n)

	if !isempty(p.techs.pv)
        add_pv_results(m, p, d; _n)
	end

    if "Wind" in p.techs.all
        add_wind_results(m, p, d; _n)
    end
    
    if "CHP" in p.techs.all
        add_chp_results(m, p, d; _n)
    end
	
	time_elapsed = time() - tstart
	@debug "Base results processing took $(round(time_elapsed, digits=3)) seconds."
	
	if !isempty(p.techs.gen) && isempty(_n)  # generators not included in multinode model
        tstart = time()
		add_generator_results(m, p, d)
        time_elapsed = time() - tstart
        @debug "Generator results processing took $(round(time_elapsed, digits=3)) seconds."
	end
	
	if !isempty(p.s.electric_utility.outage_durations) && isempty(_n)  # outages not included in multinode model
        tstart = time()
		add_outage_results(m, p, d)
        time_elapsed = time() - tstart
        @debug "Outage results processing took $(round(time_elapsed, digits=3)) seconds."
	end

    if !isempty(p.techs.boiler)
        add_existing_boiler_results(m, p, d)
    end

    if !isnothing(p.s.existing_chiller)
        add_existing_chiller_results(m, p, d)
    end

    if !isempty(p.techs.absorption_chiller)
        add_absorption_chiller_results(m, p, d)
    end

    if !isnothing(p.s.flexible_hvac)
        add_flexible_hvac_results(m, p, d)
    end
    
    if p.s.thermosyphon.active_cooling_rate_mmbtu_per_hour > 0
        add_thermosyphon_results(m, p, d)
    end

	return d
end


"""
    combine_results(bau::Dict, opt::Dict)
    
Combine two results dictionaries into one using BAU and optimal scenario results.
"""
function combine_results(p::REoptInputs, bau::Dict, opt::Dict, bau_scenario::BAUScenario)
    bau_outputs = (
        ("Financial", "lcc"),
        ("ElectricTariff", "year_one_energy_cost_before_tax"),
        ("ElectricTariff", "year_one_demand_cost_before_tax"),
        ("ElectricTariff", "year_one_fixed_cost_before_tax"),
        ("ElectricTariff", "year_one_min_charge_adder_before_tax"),
        ("ElectricTariff", "lifecycle_energy_cost_after_tax"),
        ("ElectricTariff", "lifecycle_demand_cost_after_tax"),
        ("ElectricTariff", "lifecycle_fixed_cost_after_tax"),
        ("ElectricTariff", "lifecycle_min_charge_adder_after_tax"),
        ("ElectricTariff", "lifecycle_export_benefit_after_tax"),
        ("ElectricTariff", "year_one_bill_before_tax"),
        ("ElectricTariff", "year_one_export_benefit_before_tax"),
        ("ElectricTariff", "year_one_coincident_peak_cost_before_tax"),
        ("ElectricTariff", "lifecycle_coincident_peak_cost_after_tax"),
        ("ElectricUtility", "year_one_to_load_series_kw"),  
        ("ElectricUtility", "year_one_energy_supplied_kwh"),
        ("PV", "average_annual_energy_produced_kwh"),
        ("PV", "year_one_energy_produced_kwh"),
        ("PV", "lifecycle_om_cost_after_tax"),
        ("Generator", "average_annual_fuel_used_gal"),
        ("Generator", "lifecycle_fixed_om_cost_after_tax"),
        ("Generator", "lifecycle_variable_om_cost_after_tax"),
        ("Generator", "lifecycle_fuel_cost_after_tax"),
        ("Generator", "year_one_fuel_cost_before_tax"),
        ("Generator", "year_one_variable_om_cost_before_tax"),
        ("Generator", "year_one_fixed_om_cost_before_tax"),
        ("FlexibleHVAC", "temperatures_degC_node_by_time"),
        ("ExistingBoiler", "lifecycle_fuel_cost_after_tax" )
    )

    for t in bau_outputs
        if t[1] in keys(opt) && t[1] in keys(bau)
            if t[2] in keys(bau[t[1]])
                opt[t[1]][t[2] * "_bau"] = bau[t[1]][t[2]]
            end
        elseif t[1] == "PV" && !isempty(p.techs.pv)
            for pvname in p.techs.pv
                if pvname in keys(opt) && pvname in keys(bau)
                    if t[2] in keys(bau[pvname])
                        opt[pvname][t[2] * "_bau"] = bau[pvname][t[2]]
                    end
                end
            end
        end
    end
    opt["Financial"]["lifecycle_om_costs_before_tax_bau"] = bau["Financial"]["lifecycle_om_costs_after_tax"]
    opt["Financial"]["npv"] = round(opt["Financial"]["lcc_bau"] - opt["Financial"]["lcc"], digits=2)

    opt["ElectricLoad"]["bau_critical_load_met"] = bau_scenario.outage_outputs.bau_critical_load_met
    opt["ElectricLoad"]["bau_critical_load_met_time_steps"] = bau_scenario.outage_outputs.bau_critical_load_met_time_steps

    # TODO add FlexibleHVAC opex savings

    return opt
end