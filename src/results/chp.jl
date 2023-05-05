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
`CHP` results keys:
- `size_kw` Power capacity size of the CHP system [kW]
- `size_supplemental_firing_kw` Power capacity of CHP supplementary firing system [kW]
- `annual_fuel_consumption_mmbtu` Fuel consumed in a year [MMBtu]
- `annual_electric_production_kwh` Electric energy produced in a year [kWh]
- `annual_thermal_production_mmbtu` Thermal energy produced in a year (not including curtailed thermal) [MMBtu]
- `electric_production_series_kw` Electric power production time-series array [kW]
- `electric_to_grid_series_kw` Electric power exported time-series array [kW]
- `electric_to_storage_series_kw` Electric power to charge the battery storage time-series array [kW]
- `electric_to_load_series_kw` Electric power to serve the electric load time-series array [kW]
- `thermal_to_storage_series_mmbtu_per_hour` Thermal power to TES (HotThermalStorage) time-series array [MMBtu/hr]
- `thermal_curtailed_series_mmbtu_per_hour` Thermal power wasted/unused/vented time-series array [MMBtu/hr]
- `thermal_to_load_series_mmbtu_per_hour` Thermal power to serve the heating load time-series array [MMBtu/hr]
- `thermal_to_steamturbine_series_mmbtu_per_hour` Thermal (steam) power to steam turbine time-series array [MMBtu/hr]
- `year_one_fuel_cost_before_tax` Cost of fuel consumed by the CHP system in year one [\$]
- `lifecycle_fuel_cost_after_tax` Present value of cost of fuel consumed by the CHP system, after tax [\$]
- `year_one_standby_cost_before_tax` CHP standby charges in year one [\$] 
- `lifecycle_standby_cost_after_tax` Present value of all CHP standby charges, after tax.
- `thermal_production_series_mmbtu_per_hour`  

!!! note "'Series' and 'Annual' energy outputs are average annual"
	REopt performs load balances using average annual production values for technologies that include degradation. 
	Therefore, all timeseries (`_series`) and `annual_` results should be interpretted as energy outputs averaged over the analysis period. 

"""
function add_chp_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
	# Adds the `CHP` results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
	# Note: the node number is an empty string if evaluating a single `Site`.
    r = Dict{String, Any}()
	r["size_kw"] = value(sum(m[Symbol("dvSize"*_n)][t] for t in p.techs.chp))
    r["size_supplemental_firing_kw"] = value(sum(m[Symbol("dvSupplementaryFiringSize"*_n)][t] for t in p.techs.chp))
	@expression(m, CHPFuelUsedKWH, sum(m[Symbol("dvFuelUsage"*_n)][t, ts] for t in p.techs.chp, ts in p.time_steps))
	r["annual_fuel_consumption_mmbtu"] = round(value(CHPFuelUsedKWH) / KWH_PER_MMBTU, digits=3)
	@expression(m, Year1CHPElecProd,
		p.hours_per_time_step * sum(m[Symbol("dvRatedProduction"*_n)][t,ts] * p.production_factor[t, ts]
			for t in p.techs.chp, ts in p.time_steps))
	r["annual_electric_production_kwh"] = round(value(Year1CHPElecProd), digits=3)
	
	@expression(m, CHPThermalProdKW[ts in p.time_steps],
		sum(m[Symbol("dvThermalProduction"*_n)][t,ts] + m[Symbol("dvSupplementaryThermalProduction"*_n)][t,ts] - 
			m[Symbol("dvProductionToWaste"*_n)][t,ts] for t in p.techs.chp))

	r["thermal_production_series_mmbtu_per_hour"] = round.(value.(CHPThermalProdKW) / KWH_PER_MMBTU, digits=5)
	
	r["annual_thermal_production_mmbtu"] = round(p.hours_per_time_step * sum(r["thermal_production_series_mmbtu_per_hour"]), digits=3)

	@expression(m, CHPElecProdTotal[ts in p.time_steps],
		sum(m[Symbol("dvRatedProduction"*_n)][t,ts] * p.production_factor[t, ts] for t in p.techs.chp))
	r["electric_production_series_kw"] = round.(value.(CHPElecProdTotal), digits=3)
	# Electric dispatch breakdown
    if !isempty(p.s.electric_tariff.export_bins)
        @expression(m, CHPtoGrid[ts in p.time_steps], sum(m[Symbol("dvProductionToGrid"*_n)][t,u,ts]
                for t in p.techs.chp, u in p.export_bins_by_tech[t]))
    else
        CHPtoGrid = zeros(length(p.time_steps))
    end
    r["electric_to_grid_series_kw"] = round.(value.(CHPtoGrid), digits=3)
	if !isempty(p.s.storage.types.elec)
		@expression(m, CHPtoBatt[ts in p.time_steps],
			sum(m[Symbol("dvProductionToStorage"*_n)]["ElectricStorage",t,ts] for t in p.techs.chp))
	else
		CHPtoBatt = zeros(length(p.time_steps))
	end
	r["electric_to_storage_series_kw"] = round.(value.(CHPtoBatt), digits=3)
	@expression(m, CHPtoLoad[ts in p.time_steps],
		sum(m[Symbol("dvRatedProduction"*_n)][t, ts] * p.production_factor[t, ts] * p.levelization_factor[t]
			for t in p.techs.chp) - CHPtoBatt[ts] - CHPtoGrid[ts])
	r["electric_to_load_series_kw"] = round.(value.(CHPtoLoad), digits=3)
	# Thermal dispatch breakdown
    if !isempty(p.s.storage.types.hot)
		@expression(m, CHPtoHotTES[ts in p.time_steps],
			sum(m[Symbol("dvProductionToStorage"*_n)]["HotThermalStorage",t,ts] for t in p.techs.chp))
	else 
		CHPtoHotTES = zeros(length(p.time_steps))
	end
	r["thermal_to_storage_series_mmbtu_per_hour"] = round.(value.(CHPtoHotTES / KWH_PER_MMBTU), digits=5)
	@expression(m, CHPThermalToWasteKW[ts in p.time_steps],
		sum(m[Symbol("dvProductionToWaste"*_n)][t,ts] for t in p.techs.chp))
	r["thermal_curtailed_series_mmbtu_per_hour"] = round.(value.(CHPThermalToWasteKW) / KWH_PER_MMBTU, digits=5)
    if !isempty(p.techs.steam_turbine) && p.s.chp.can_supply_steam_turbine
        @expression(m, CHPToSteamTurbineKW[ts in p.time_steps], sum(m[Symbol("dvThermalToSteamTurbine"*_n)][t,ts] for t in p.techs.chp))
    else
        CHPToSteamTurbineKW = zeros(length(p.time_steps))
    end	
    r["thermal_to_steamturbine_series_mmbtu_per_hour"] = round.(value.(CHPToSteamTurbineKW) / KWH_PER_MMBTU, digits=5)
    @expression(m, CHPThermalToLoadKW[ts in p.time_steps],
        sum(m[Symbol("dvThermalProduction"*_n)][t,ts] + m[Symbol("dvSupplementaryThermalProduction"*_n)][t,ts]
            for t in p.techs.chp) - CHPtoHotTES[ts] - CHPToSteamTurbineKW[ts] - CHPThermalToWasteKW[ts])
    r["thermal_to_load_series_mmbtu_per_hour"] = round.(value.(CHPThermalToLoadKW) / KWH_PER_MMBTU, digits=5)
	r["year_one_fuel_cost_before_tax"] = round(value(m[:TotalCHPFuelCosts] / p.pwf_fuel["CHP"]), digits=3)                
	r["lifecycle_fuel_cost_after_tax"] = round(value(m[:TotalCHPFuelCosts]) * p.s.financial.offtaker_tax_rate_fraction, digits=3)
	#Standby charges and hourly O&M
	r["year_one_standby_cost_before_tax"] = round(value(m[Symbol("TotalCHPStandbyCharges")]) / p.pwf_e, digits=0)
	r["lifecycle_standby_cost_after_tax"] = round(value(m[Symbol("TotalCHPStandbyCharges")]) * p.s.financial.offtaker_tax_rate_fraction, digits=0)


    d["CHP"] = r
    nothing
end
