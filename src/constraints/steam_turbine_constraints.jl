# REopt®, Copyright (c) Alliance for Sustainable Energy, LLC. See also https://github.com/NREL/REopt.jl/blob/master/LICENSE.

function steam_turbine_thermal_input(m, p; _n="")

    # This constraint is already included in storage_constraints.jl if HotThermalStorage and SteamTurbine are considered that also includes dvProductionToStorage["HotThermalStorage"] in LHS
    if isempty(p.s.storage.types.hot)
        @constraint(m, SupplySteamTurbineProductionLimit[t in p.techs.can_supply_steam_turbine, ts in p.time_steps],
                    m[Symbol("dvThermalToSteamTurbine"*_n)][t,ts] <=
                    m[Symbol("dvThermalProduction"*_n)][t,ts]
        )
    end
end

function steam_turbine_production_constraints(m, p; _n="")
    # Constraint Steam Turbine Thermal Production
    @constraint(m, SteamTurbineThermalProductionCon[t in p.techs.steam_turbine, ts in p.time_steps],
                m[Symbol("dvThermalProduction"*_n)][t,ts] == p.s.steam_turbine.thermal_produced_to_thermal_consumed_ratio * sum(m[Symbol("dvThermalToSteamTurbine"*_n)][tst,ts] for tst in p.techs.can_supply_steam_turbine)
                )
    # Constraint Steam Turbine Electric Production
    @constraint(m, SteamTurbineElectricProductionCon[t in p.techs.steam_turbine, ts in p.time_steps],
                m[Symbol("dvRatedProduction"*_n)][t,ts] ==
                p.s.steam_turbine.electric_produced_to_thermal_consumed_ratio * sum(m[Symbol("dvThermalToSteamTurbine"*_n)][tst,ts] for tst in p.techs.can_supply_steam_turbine)
                )
end

function add_steam_turbine_constraints(m, p; _n="")
    steam_turbine_production_constraints(m, p; _n)
    steam_turbine_thermal_input(m, p; _n)

    m[:TotalSteamTurbinePerUnitProdOMCosts] = @expression(m, p.third_party_factor * p.pwf_om *
        sum(p.s.steam_turbine.om_cost_per_kwh * p.hours_per_time_step *
        m[:dvRatedProduction][t, ts] for t in p.techs.steam_turbine, ts in p.time_steps)
    )
end