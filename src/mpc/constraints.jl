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
function add_previous_monthly_peak_constraint(m::JuMP.AbstractModel, p::MPCInputs; _n="")
	## Constraint (11d): Monthly peak demand is >= demand at each time step in the month
	@constraint(m, [mth in p.months, ts in p.s.electric_tariff.time_steps_monthly[mth]],
    m[Symbol("dvPeakDemandMonth"*_n)][mth, 1] >= p.s.electric_tariff.monthly_previous_peak_demands[mth]
    )
end


function add_previous_tou_peak_constraint(m::JuMP.AbstractModel, p::MPCInputs; _n="")
    ## Constraint (12d): TOU peak demand is >= demand at each time step in the period` 
    @constraint(m, [r in p.ratchets],
        m[Symbol("dvPeakDemandTOU"*_n)][r, 1] >= p.s.electric_tariff.tou_previous_peak_demands[r]
    )
end


function add_grid_draw_limits(m::JuMP.AbstractModel, p::MPCInputs; _n="")
    @constraint(m, [ts in p.time_steps],
        sum(
            m[Symbol("dvGridPurchase"*_n)][ts, tier] 
            for tier in 1:p.s.electric_tariff.n_energy_tiers
        ) <= p.s.limits.grid_draw_limit_kw_by_time_step[ts]
    )
end


function add_export_limits(m::JuMP.AbstractModel, p::MPCInputs; _n="")
    @constraint(m, [ts in p.time_steps],
        sum(
            sum(m[Symbol("dvProductionToGrid"*_n)][t, u, ts] for u in p.export_bins_by_tech[t])
            for t in p.techs.elec
        ) <= p.s.limits.export_limit_kw_by_time_step[ts]
    )
end
