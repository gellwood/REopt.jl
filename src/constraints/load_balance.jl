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

function add_elec_load_balance_constraints(m, p; _n="") 

	##Constraint (8a): Electrical Load Balancing with Grid
    if isempty(p.s.electric_tariff.export_bins)
        conrefs = @constraint(m, [ts in p.time_steps_with_grid],
            sum(p.production_factor[t, ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t,ts] for t in p.techs.elec) +  
            sum( m[Symbol("dvDischargeFromStorage"*_n)][b,ts] for b in p.s.storage.types ) + 
            sum(m[Symbol("dvGridPurchase"*_n)][ts, tier] for tier in 1:p.s.electric_tariff.n_energy_tiers) ==
            sum( sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types) 
                + m[Symbol("dvCurtail"*_n)][t, ts] for t in p.techs.elec)
            + sum(m[Symbol("dvGridToStorage"*_n)][b, ts] for b in p.s.storage.types)
            + p.s.electric_load.loads_kw[ts]
        )
    else
        conrefs = @constraint(m, [ts in p.time_steps_with_grid],
            sum(p.production_factor[t, ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t,ts] for t in p.techs.elec) +  
            sum( m[Symbol("dvDischargeFromStorage"*_n)][b,ts] for b in p.s.storage.types ) + 
            sum(m[Symbol("dvGridPurchase"*_n)][ts, tier] for tier in 1:p.s.electric_tariff.n_energy_tiers) ==
            sum(  sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types) 
                + sum(m[Symbol("dvProductionToGrid"*_n)][t, u, ts] for u in p.export_bins_by_tech[t]) 
                + m[Symbol("dvCurtail"*_n)][t, ts] 
            for t in p.techs.elec)
            + sum(m[Symbol("dvGridToStorage"*_n)][b, ts] for b in p.s.storage.types)
            + p.s.electric_load.loads_kw[ts]
        )
    end

	for (i, cr) in enumerate(conrefs)
		JuMP.set_name(cr, "con_load_balance"*_n*string("_t", i))
	end
	
	##Constraint (8b): Electrical Load Balancing without Grid
	@constraint(m, [ts in p.time_steps_without_grid],
		sum(p.production_factor[t,ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t,ts] for t in p.techs.elec) +  
		sum( m[Symbol("dvDischargeFromStorage"*_n)][b,ts] for b in p.s.storage.types )  ==
        sum( sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types) + 
        m[Symbol("dvCurtail"*_n)][t, ts] for t in p.techs.elec) +
        p.s.electric_load.critical_loads_kw[ts]
	)
end


function add_production_constraints(m, p; _n="")
	# Constraint (4d): Electrical production sent to storage or export must be less than technology's rated production
    if isempty(p.s.electric_tariff.export_bins)
        @constraint(m, [t in p.techs.elec, ts in p.time_steps_with_grid],
            sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types)  
          + m[Symbol("dvCurtail"*_n)][t, ts]
         <= p.production_factor[t, ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t, ts]
        )
    else
        @constraint(m, [t in p.techs.elec, ts in p.time_steps_with_grid],
            sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types)  
          + m[Symbol("dvCurtail"*_n)][t, ts]
          + sum(m[Symbol("dvProductionToGrid"*_n)][t, u, ts] for u in p.export_bins_by_tech[t])
         <= p.production_factor[t, ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t, ts]
        )
    end

	# Constraint (4e): Electrical production sent to storage or grid must be less than technology's rated production - no grid
	@constraint(m, [t in p.techs.elec, ts in p.time_steps_without_grid],
		sum(m[Symbol("dvProductionToStorage"*_n)][b, t, ts] for b in p.s.storage.types)  <= 
		p.production_factor[t, ts] * p.levelization_factor[t] * m[Symbol("dvRatedProduction"*_n)][t, ts]
	)

end


function add_thermal_load_constraints(m, p; _n="")
	### Constraint set (5) - hot and cold thermal loads

	##Constraint (5a): Cold thermal loads
	# if !isempty(p.CoolingTechs)
	# 	@constraint(m, ColdThermalLoadCon[ts in p.time_steps],
	# 			sum(p.production_factor[t,ts] * m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.CoolingTechs) +
	# 			sum(m[:dvDischargeFromStorage][b,ts] for b in p.ColdTES) ==
	# 			p.CoolingLoad[ts] -
	# 			sum(p.GHPCoolingThermalServed[g,ts] * m[:binGHP][g] for g in p.GHPOptions) +
	# 			sum(m[:dvProductionToStorage][b,t,ts] for b in p.ColdTES, t in p.CoolingTechs)
	# 	)
	# end

	##Constraint (5b): Hot thermal loads
	if !isempty(p.techs.heating)
        
        # if !isempty(p.SteamTurbineTechs)
        #     @constraint(m, HotThermalLoadCon[ts in p.time_steps],
        #             # sum(m[Symbol("dvThermalProduction"*_n)][t,ts] - m[:dvThermalToSteamTurbine][t,ts] for t in p.CHPTechs) +
        #             # sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.SteamTurbineTechs) +
        #             sum(p.production_factor[t,ts] * (m[Symbol("dvThermalProduction"*_n)][t,ts] - m[:dvThermalToSteamTurbine][t,ts]) for t in p.techs.boiler)
        #             # + sum(p.GHPHeatingThermalServed[g,ts] * m[:binGHP][g] for g in p.GHPOptions)
        #             # + sum(m[:dvDischargeFromStorage][b,ts] for b in p.HotTES) 
        #             ==
        #             p.HeatingLoad[ts] * p.s.existing_boiler.efficiency
        #             # + sum(m[:dvProductionToWaste][t,ts] for t in p.CHPTechs) +
        #             # sum(m[:dvProductionToStorage][b,t,ts] for b in p.HotTES, t in p.techs.heating) +
        #             # sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.AbsorptionChillers) / p.AbsorptionChillerCOP
        #     )
        # else
            @constraint(m, [ts in p.time_steps],
                    sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.techs.chp) +
                    sum(m[Symbol("dvThermalProduction"*_n)][t, ts] for t in p.techs.boiler)
                    # TODO do all thermal techs have production_factor = 1 ? get rid of it if so
                    # + sum(m[:dvDischargeFromStorage][b,ts] for b in p.HotTES)
                    # + sum(p.GHPHeatingThermalServed[g,ts] * m[:binGHP][g] for g in p.GHPOptions)
                    ==
                    (p.s.dhw_load.loads_kw[ts] + p.s.space_heating_load.loads_kw[ts])
                    + sum(m[Symbol("dvProductionToWaste"*_n)][t,ts] for t in p.techs.chp) #+
                    # sum(m[:dvProductionToStorage][b,t,ts] for b in p.HotTES, t in p.techs.heating)  +
                    # sum(m[Symbol("dvThermalProduction"*_n)][t,ts] for t in p.AbsorptionChillers) / p.AbsorptionChillerCOP
            )
        # end
	end
end