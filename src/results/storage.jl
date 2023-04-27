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
    add_storage_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")

Adds the Storage results to the dictionary passed back from `run_reopt` using the solved model `m` and the `REoptInputs` for node `_n`.
Note: the node number is an empty string if evaluating a single `Site`.

Storage results:
- `size_kw` Optimal inverter capacity
- `size_kwh` Optimal storage capacity
- `year_one_soc_series_pct` Vector of normalized (0-1) state of charge values over the first year
- `year_one_to_load_series_kw` Vector of power used to meet load over the first year
- `year_one_to_grid_series_kw` Vector of power exported to the grid over the first year
"""
function add_storage_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict, b::Symbol; _n="")
    r = Dict{String, Any}()
    r["size_kwh"] = round(value(m[Symbol("dvStorageEnergy"*_n)][b]), digits=2)
    r["size_kw"] = round(value(m[Symbol("dvStoragePower"*_n)][b]), digits=2)

    if r["size_kwh"] != 0
    	soc = (m[Symbol("dvStoredEnergy"*_n)][b, ts] for ts in p.time_steps)
        r["year_one_soc_series_pct"] = round.(value.(soc) ./ r["size_kwh"], digits=3)

        discharge = (m[Symbol("dvDischargeFromStorage"*_n)][b, ts] for ts in p.time_steps)
        r["year_one_to_load_series_kw"] = round.(value.(discharge), digits=3)
    else
        r["year_one_soc_series_pct"] = []
        r["year_one_to_load_series_kw"] = []
    end

    # TODO handle other storage type names
    d["Storage"] = r
    nothing
end


function add_storage_results(m::JuMP.AbstractModel, p::MPCInputs, d::Dict, b::Symbol; _n="")
    r = Dict{String, Any}()

    soc = (m[Symbol("dvStoredEnergy"*_n)][b, ts] for ts in p.time_steps)
    r["soc_series_pct"] = round.(value.(soc) ./ p.s.storage.size_kwh[b], digits=3)
    discharge = (m[Symbol("dvDischargeFromStorage"*_n)][b, ts] for ts in p.time_steps)
    r["to_load_series_kw"] = round.(value.(discharge), digits=3)
    # NOTE: we no longer allow Storage to export to the grid (to align with typical export rules for retail customers)

    # TODO handle other storage types
    d["Storage"] = r
    nothing
end