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
`SteamTurbine` results keys:
- `size_kw` Power capacity size [kW]
- `annual_thermal_consumption_mmbtu` Thermal (steam) consumption [MMBtu]
- `annual_electric_production_kwh` Electric energy produced in a year [kWh]
- `annual_thermal_production_mmbtu` Thermal energy produced in a year [MMBtu]
- `thermal_consumption_series_mmbtu_per_hour` Thermal (steam) energy consumption series [MMBtu/hr]
- `electric_production_series_kw` Electric power production series [kW]
- `electric_to_grid_series_kw` Electric power exported to grid series [kW]
- `electric_to_storage_series_kw` Electric power to charge the battery series [kW]
- `electric_to_load_series_kw` Electric power to serve load series [kW]
- `thermal_to_storage_series_mmbtu_per_hour` Thermal production to charge the HotThermalStorage series [MMBtu/hr]
- `thermal_to_load_series_mmbtu_per_hour` Thermal production to serve the heating load SERVICES [MMBtu/hr]

!!! note "'Series' and 'Annual' energy outputs are average annual"
	REopt performs load balances using average annual production values for technologies that include degradation. 
	Therefore, all timeseries (`_series`) and `annual_` results should be interpretted as energy outputs averaged over the analysis period. 

"""
function add_steam_turbine_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
	# Adds the `SteamTurbine` results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
	# Note: the node number is an empty string if evaluating a single `Site`.	

    r = Dict{String, Any}()

	r["size_kw"] = round(value(sum(m[Symbol("dvSize"*_n)][t] for t in p.techs.steam_turbine)), digits=3)
    @expression(m, Year1SteamTurbineThermalConsumptionKWH,
		p.hours_per_time_step * sum(m[Symbol("dvThermalToSteamTurbine"*_n)][tst,ts] for tst in p.techs.can_supply_steam_turbine, ts in p.time_steps))
    r["annual_thermal_consumption_mmbtu"] = round(value(Year1SteamTurbineThermalConsumptionKWH) / KWH_PER_MMBTU, digits=5)
    @expression(m, Year1SteamTurbineElecProd,
		p.hours_per_time_step * sum(m[Symbol("dvRatedProduction"*_n)][t,ts] * p.production_factor[t, ts]
			for t in p.techs.steam_turbine, ts in p.time_steps))
	r["annual_electric_production_kwh"] = round(value(Year1SteamTurbineElecProd), digits=3)
	@expression(m, Year1SteamTurbineThermalProdKWH,
		p.hours_per_time_step * sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.techs.steam_turbine, ts in p.time_steps))
	r["annual_thermal_production_mmbtu"] = round(value(Year1SteamTurbineThermalProdKWH) / KWH_PER_MMBTU, digits=5)
    @expression(m, SteamTurbineThermalConsumptionKW[ts in p.time_steps],
		sum(m[Symbol("dvThermalToSteamTurbine"*_n)][tst,ts] for tst in p.techs.can_supply_steam_turbine))
    r["thermal_consumption_series_mmbtu_per_hour"] = round.(value.(SteamTurbineThermalConsumptionKW) ./ KWH_PER_MMBTU, digits=5)
	@expression(m, SteamTurbineElecProdTotal[ts in p.time_steps],
		sum(m[Symbol("dvRatedProduction"*_n)][t,ts] * p.production_factor[t, ts] for t in p.techs.steam_turbine))
	r["electric_production_series_kw"] = round.(value.(SteamTurbineElecProdTotal), digits=3)
    if !isempty(p.s.electric_tariff.export_bins)
        @expression(m, SteamTurbinetoGrid[ts in p.time_steps],
                sum(m[Symbol("dvProductionToGrid"*_n)][t, u, ts] for t in p.techs.steam_turbine, u in p.export_bins_by_tech[t]))	
    else
        SteamTurbinetoGrid = zeros(length(p.time_steps))
    end
	r["electric_to_grid_series_kw"] = round.(value.(SteamTurbinetoGrid), digits=3)
	if !isempty(p.s.storage.types.elec)
		@expression(m, SteamTurbinetoBatt[ts in p.time_steps],
			sum(m[Symbol("dvProductionToStorage"*_n)]["ElectricStorage",t,ts] for t in p.techs.steam_turbine))
	else
		SteamTurbinetoBatt = zeros(length(p.time_steps))
	end
	r["electric_to_storage_series_kw"] = round.(value.(SteamTurbinetoBatt), digits=3)
	@expression(m, SteamTurbinetoLoad[ts in p.time_steps],
		sum(m[Symbol("dvRatedProduction"*_n)][t, ts] * p.production_factor[t, ts]
			for t in p.techs.steam_turbine) - SteamTurbinetoBatt[ts] - SteamTurbinetoGrid[ts])
	r["electric_to_load_series_kw"] = round.(value.(SteamTurbinetoLoad), digits=3)
    if !isempty(p.s.storage.types.hot)
		@expression(m, SteamTurbinetoHotTESKW[ts in p.time_steps],
			sum(m[Symbol("dvProductionToStorage"*_n)]["HotThermalStorage",t,ts] for t in p.techs.steam_turbine))
	else
		SteamTurbinetoHotTESKW = zeros(length(p.time_steps))
	end
	r["thermal_to_storage_series_mmbtu_per_hour"] = round.(value.(SteamTurbinetoHotTESKW) ./ KWH_PER_MMBTU, digits=5)
	@expression(m, SteamTurbineThermalToLoadKW[ts in p.time_steps],
		sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.techs.steam_turbine) - SteamTurbinetoHotTESKW[ts])
	r["thermal_to_load_series_mmbtu_per_hour"] = round.(value.(SteamTurbineThermalToLoadKW) ./ KWH_PER_MMBTU, digits=5)
	d["SteamTurbine"] = r
	nothing
end