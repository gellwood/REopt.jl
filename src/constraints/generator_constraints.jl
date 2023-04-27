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
function add_fuel_burn_constraints(m,p)
  	@constraint(m, [t in p.techs.gen, ts in p.time_steps],
		m[:dvFuelUsage][t, ts] == p.s.generator.fuel_slope_gal_per_kwh *
		p.production_factor[t, ts] * p.hours_per_timestep * m[:dvRatedProduction][t, ts] +
		p.s.generator.fuel_intercept_gal_per_hr * p.hours_per_timestep * m[:binGenIsOnInTS][t, ts]
	)
	@constraint(m,
		sum(m[:dvFuelUsage][t, ts] for t in p.techs.gen, ts in p.time_steps) <=
		p.s.generator.fuel_avail_gal
	)
end


function add_binGenIsOnInTS_constraints(m,p)
	@constraint(m, [t in p.techs.gen, ts in p.time_steps],
		m[:dvRatedProduction][t, ts] <= p.s.generator.max_kw * m[:binGenIsOnInTS][t, ts]
	)
	@constraint(m, [t in p.techs.gen, ts in p.time_steps],
		p.s.generator.min_turn_down_pct * m[:dvSize][t] - m[:dvRatedProduction][t, ts] <=
		p.s.generator.max_kw * (1 - m[:binGenIsOnInTS][t, ts])
	)
end


function add_gen_can_run_constraints(m,p)
	if p.s.generator.only_runs_during_grid_outage
		for ts in p.time_steps_with_grid, t in p.techs.gen
			fix(m[:dvRatedProduction][t, ts], 0.0, force=true)
		end
	end

	if !(p.s.generator.sells_energy_back_to_grid)
		for t in p.techs.gen, u in p.export_bins_by_tech[t], ts in p.time_steps
			fix(m[:dvProductionToGrid][t, u, ts], 0.0, force=true)
		end
	end
end


function add_gen_rated_prod_constraint(m, p)
	@constraint(m, [t in p.techs.gen, ts in p.time_steps],
		m[:dvSize][t] >= m[:dvRatedProduction][t, ts]
	)
end


"""
    add_gen_constraints(m, p)

Add Generator operational constraints and cost expressions.
"""
function add_gen_constraints(m, p)
    add_fuel_burn_constraints(m,p)
    add_binGenIsOnInTS_constraints(m,p)
    add_gen_can_run_constraints(m,p)
    add_gen_rated_prod_constraint(m,p)

    m[:TotalGenPerUnitProdOMCosts] = @expression(m, p.third_party_factor * p.pwf_om *
        sum(p.s.generator.om_cost_per_kwh * p.hours_per_timestep *
        m[:dvRatedProduction][t, ts] for t in p.techs.gen, ts in p.time_steps)
    )
    m[:TotalGenFuelCosts] = @expression(m, p.pwf_e *
        sum(m[:dvFuelUsage][t,ts] * p.s.generator.fuel_cost_per_gallon for t in p.techs.gen, ts in p.time_steps)
    )
end
