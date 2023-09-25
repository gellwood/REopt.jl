


function add_variables!(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario
	
	dvs_idx_on_techs = String[
		"dvSize",
		"dvPurchaseSize",
	]
	dvs_idx_on_techs_time_steps = String[
        "dvCurtail",
		"dvRatedProduction",
	]
	dvs_idx_on_storagetypes = String[
		"dvStoragePower",
		"dvStorageEnergy",
	]
	dvs_idx_on_storagetypes_time_steps = String[
		"dvDischargeFromStorage"
	]
	for p in ps
		_n = string("_", p.s.site.node)

		# Temporary fix:
		if "ElectricStorage" in keys(p.s.storage.attr)
			@info "** Temporary fix: Adding ElectricStorage to p.s.storage.types.all and p.s.storage.types.elec, for site node: " p.s.site.node
			p.s.storage.types.all = ["ElectricStorage"] #[keys(p.s.storage.attr)]
			p.s.storage.types.elec = ["ElectricStorage"]  #[keys(p.s.storage.attr)]
		end 
		# End of temporary fix

		for dv in dvs_idx_on_techs
			x = dv*_n
			m[Symbol(x)] = @variable(m, [p.techs.all], base_name=x, lower_bound=0)
		end

		for dv in dvs_idx_on_techs_time_steps
			x = dv*_n
			m[Symbol(x)] = @variable(m, [p.techs.all, p.time_steps], base_name=x, lower_bound=0)
		end

		for dv in dvs_idx_on_storagetypes
			x = dv*_n
			m[Symbol(x)] = @variable(m, [p.s.storage.types.elec], base_name=x, lower_bound=0)
		end

		for dv in dvs_idx_on_storagetypes_time_steps
			x = dv*_n
			m[Symbol(x)] = @variable(m, [p.s.storage.types.all, p.time_steps], base_name=x, lower_bound=0)
		end

		dv = "dvGridToStorage"*_n
		m[Symbol(dv)] = @variable(m, [p.s.storage.types.elec, p.time_steps], base_name=dv, lower_bound=0)

		dv = "dvGridPurchase"*_n
		m[Symbol(dv)] = @variable(m, [p.time_steps], base_name=dv, lower_bound=0)

		dv = "dvPeakDemandTOU"*_n
		m[Symbol(dv)] = @variable(m, [p.ratchets, 1], base_name=dv, lower_bound=0)

		dv = "dvPeakDemandMonth"*_n
		m[Symbol(dv)] = @variable(m, [p.months, 1], base_name=dv, lower_bound=0)

		dv = "dvProductionToStorage"*_n
		m[Symbol(dv)] = @variable(m, [p.s.storage.types.all, p.techs.all, p.time_steps], base_name=dv, lower_bound=0)

		dv = "dvStoredEnergy"*_n
		m[Symbol(dv)] = @variable(m, [p.s.storage.types.all, 0:p.time_steps[end]], base_name=dv, lower_bound=0)

		dv = "MinChargeAdder"*_n
		m[Symbol(dv)] = @variable(m, base_name=dv, lower_bound=0)

		# Add the new variables for the generator

		dv = "dvFuelUsage"*_n
		m[Symbol(dv)] = @variable(m, [p.techs.gen, 0:p.time_steps[end]], base_name=dv, lower_bound=0)
	
		dv = "binGenIsOnInTS"*_n
		m[Symbol(dv)] = @variable(m, [p.techs.gen, 0:p.time_steps[end]], base_name=dv, lower_bound=0)
	
		# Add the new variables to allow the battery to export to the grid
		dv = "dvStorageToGrid"*_n
		m[Symbol(dv)] = @variable(m, [p.time_steps], base_name=dv, lower_bound=0) # export of energy from storage to the grid
		
		dv = "dvBattCharge_binary"*_n
		m[Symbol(dv)] = @variable(m, [p.time_steps], base_name=dv, Bin) # Binary for battery charge
		
		dv = "dvBattDischarge_binary"*_n
		m[Symbol(dv)] = @variable(m, [p.time_steps], base_name=dv, Bin) # Binary for battery discharge
		
		if !isempty(p.s.electric_tariff.export_bins)
            dv = "dvProductionToGrid"*_n
            m[Symbol(dv)] = @variable(m, [p.techs.elec, p.s.electric_tariff.export_bins, p.time_steps], base_name=dv, lower_bound=0)
        end
		print("\n p.techs.elec are: ")	
		print(p.techs.elec)						
		print("\n p.techs.gen are: ")	
		print(p.techs.gen)	
		print("\n p.techs.all are: ")	
		print(p.techs.all)	

		ex_name = "TotalTechCapCosts"*_n
		m[Symbol(ex_name)] = @expression(m, p.third_party_factor *
			sum( p.cap_cost_slope[t] * m[Symbol("dvPurchaseSize"*_n)][t] for t in p.techs.all ) 
		)

		ex_name = "TotalStorageCapCosts"*_n
		m[Symbol(ex_name)] = @expression(m, p.third_party_factor * 
			sum(p.s.storage.attr[b].net_present_cost_per_kw * m[Symbol("dvStoragePower"*_n)][b] for b in p.s.storage.types.elec)
			+ sum(p.s.storage.attr[b].net_present_cost_per_kwh * m[Symbol("dvStorageEnergy"*_n)][b] for b in p.s.storage.types.all)
		)

		ex_name = "TotalPerUnitSizeOMCosts"*_n
		m[Symbol(ex_name)] = @expression(m, p.third_party_factor * p.pwf_om * 
			sum( p.om_cost_per_kw[t] * m[Symbol("dvSize"*_n)][t] for t in p.techs.all ) 
		)

        ex_name = "TotalPerUnitProdOMCosts"*_n
		m[Symbol(ex_name)] = 0

		ex_name = "TotalFuelCosts"*_n
		m[Symbol(ex_name)] = 0

		ex_name = "TotalFuelCosts"
		m[Symbol(ex_name)] = 0

		if !isempty(p.techs.gen)
            add_gen_constraints(m, p; _n = _n )
            m[Symbol("TotalPerUnitProdOMCosts"*_n)] += m[Symbol("TotalGenPerUnitProdOMCosts"*_n)]
            m[Symbol("TotalFuelCosts"*_n)] += m[Symbol("TotalGenFuelCosts"*_n)]
			#m[Symbol("TotalFuelCosts")] += m[Symbol("TotalGenFuelCosts"*_n)]
			
		
		end	

		if !isempty(p.s.electric_tariff.export_bins)  # added for testing
            add_export_constraints(m, p; _n=_n)  # added for testing 
        end

		add_elec_utility_expressions(m, p; _n=_n)
	
		#################################  Objective Function   ########################################
		m[Symbol("Costs"*_n)] = @expression(m,
			#TODO: update in line with non-multinode version
			# Capital Costs
			m[Symbol("TotalTechCapCosts"*_n)] + m[Symbol("TotalStorageCapCosts"*_n)] +  
			
			## Fixed O&M, tax deductible for owner
			m[Symbol("TotalPerUnitSizeOMCosts"*_n)] * (1 - p.s.financial.owner_tax_rate_fraction) +

			# Production O&M cost and fuel costs
			m[Symbol("TotalFuelCosts"*_n)] + 
			m[Symbol("TotalPerUnitProdOMCosts"*_n)] +

			# Utility Bill, tax deductible for offtaker, including export benefit
			m[Symbol("TotalElecBill"*_n)] * (1 - p.s.financial.offtaker_tax_rate_fraction)
			#+ (sum(m[Symbol("dvStorageToGrid"*_n)][ts]*9000 for ts in p.time_steps)) # added this line temporarily for debugging purposes
		);
    end
end


function build_reopt!(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario
    add_variables!(m, ps)
    @warn "Outages are not currently modeled in multinode mode. Use the multinode outage simulator instead or limit power from the substation using LinDistFlow."
    #@warn "Diesel generators are not currently modeled in multinode mode."
	@warn "Emissions and renewable energy fractions are not currently modeling in multinode mode."
    for p in ps
        _n = string("_", p.s.site.node)
		
		@info "** p.s.storage is: " p.s.storage
		@info "** p.s.storage.types is: " p.s.storage.types
		@info "** p.s.storage.types.all is: " p.s.storage.types.all
		@info "** p.s.storage.types.elec is: " p.s.storage.types.elec
		@info "** p.s.storage.attr is: " p.s.storage.attr
		@info "** keys(p.s.storage.attr) is: " keys(p.s.storage.attr)
		@info "** p.s.storage.attr[ElectricStorage(with quotes)] is: " p.s.storage.attr["ElectricStorage"]

        #for b in p.s.storage.types.all
		# Temporary fix:
		for b in keys(p.s.storage.attr)
			@info "** Applying constraints to storage type: " b
            if p.s.storage.attr[b].max_kw == 0 || p.s.storage.attr[b].max_kwh == 0
                @info "** The battery input size was 0 kW or 0 kWh, so the battery will not be used"
				@constraint(m, [ts in p.time_steps], m[Symbol("dvStoredEnergy"*_n)][b, ts] == 0)
                @constraint(m, m[Symbol("dvStorageEnergy"*_n)][b] == 0)
                @constraint(m, m[Symbol("dvStoragePower"*_n)][b] == 0)
                @constraint(m, [t in p.techs.elec, ts in p.time_steps_with_grid],
                            m[Symbol("dvProductionToStorage"*_n)][b, t, ts] == 0)
                @constraint(m, [ts in p.time_steps], m[Symbol("dvDischargeFromStorage"*_n)][b, ts] == 0)
                @constraint(m, [ts in p.time_steps], m[Symbol("dvGridToStorage"*_n)][b, ts] == 0)
				@constraint(m, [ts in p.time_steps], m[Symbol("dvStorageToGrid"*_n)][ts] == 0)
            else 
				@info "** The battery constraints are being applied"
                add_storage_size_constraints(m, p, b; _n=_n)
                add_general_storage_dispatch_constraints(m, p, b; _n=_n)
				#if b in p.s.storage.types.elec
				#Temporary fix:
				if b == "ElectricStorage" 
					@info "** adding electric storage dispatch constraints"
					add_elec_storage_dispatch_constraints(m, p, b; _n=_n)
				elseif b in p.s.storage.types.hot
					add_hot_thermal_storage_dispatch_constraints(m, p, b; _n=_n)
				elseif b in p.s.storage.types.cold
					add_cold_thermal_storage_dispatch_constraints(m, p, b; _n=_n)
				end
            end
        end

        if any(max_kw->max_kw > 0, (p.s.storage.attr[b].max_kw for b in p.s.storage.types.elec))
            add_storage_sum_constraints(m, p; _n=_n)
        end
    
        add_production_constraints(m, p; _n=_n)
    
        if !isempty(p.techs.all)
            add_tech_size_constraints(m, p; _n=_n)
            if !isempty(p.techs.no_curtail)
                add_no_curtail_constraints(m, p; _n=_n)
            end
        end
    
        add_elec_load_balance_constraints(m, p; _n=_n)
    
        if !isempty(p.s.electric_tariff.export_bins)
            add_export_constraints(m, p; _n=_n)
        end
    
        if !isempty(p.s.electric_tariff.monthly_demand_rates)
            add_monthly_peak_constraint(m, p; _n=_n)
        end
    
        if !isempty(p.s.electric_tariff.tou_demand_ratchet_time_steps)
            add_tou_peak_constraint(m, p; _n=_n)
        end

		if !(p.s.electric_utility.allow_simultaneous_export_import) & !isempty(p.s.electric_tariff.export_bins)
			add_simultaneous_export_import_constraint(m, p; _n=_n)
		end

        if p.s.electric_tariff.demand_lookback_percent > 0
            add_demand_lookback_constraints(m, p; _n=_n)
        end

        if !isempty(p.s.electric_tariff.coincpeak_periods)
            add_coincident_peak_charge_constraints(m, p; _n=_n)
        end
    
    end
end


function add_objective!(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario
	if !(any(p.s.settings.add_soc_incentive for p in ps))
		@objective(m, Min, sum(m[Symbol(string("Costs_", p.s.site.node))] for p in ps))
	else # Keep SOC high
		@objective(m, Min, sum(m[Symbol(string("Costs_", p.s.site.node))] for p in ps)
        - sum(sum(sum(m[Symbol(string("dvStoredEnergy_", p.s.site.node))][b, ts] 
            for ts in p.time_steps) for b in p.s.storage.types.elec) for p in ps) / (8760. / ps[1].hours_per_time_step))
	end  # TODO need to handle different hours_per_time_step?
	nothing
end
#=
function build_reopt_outagesimulator!(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario
	# note: this function is modelled after the build_reopt! function above
		# however, this function is for building a reopt model for testing if an outage can be survived
		# see the analysis code for how to implement this function

		# copied the contents of the add_variables! function:
			# but set the "costs" value to zero, because the objective function should not need to optimize for costs
		dvs_idx_on_techs = String[
			"dvSize",
			"dvPurchaseSize",
		]
		dvs_idx_on_techs_time_steps = String[
			"dvCurtail",
			"dvRatedProduction",
		]
		dvs_idx_on_storagetypes = String[
			"dvStoragePower",
			"dvStorageEnergy",
		]
		dvs_idx_on_storagetypes_time_steps = String[
			"dvDischargeFromStorage"
		]
		for p in ps
			_n = string("_", p.s.site.node)
			for dv in dvs_idx_on_techs
				x = dv*_n
				m[Symbol(x)] = @variable(m, [p.techs.all], base_name=x, lower_bound=0)
			end
	
			for dv in dvs_idx_on_techs_time_steps
				x = dv*_n
				m[Symbol(x)] = @variable(m, [p.techs.all, p.time_steps], base_name=x, lower_bound=0)
			end
	
			for dv in dvs_idx_on_storagetypes
				x = dv*_n
				m[Symbol(x)] = @variable(m, [p.s.storage.types.elec], base_name=x, lower_bound=0)
			end
	
			for dv in dvs_idx_on_storagetypes_time_steps
				x = dv*_n
				m[Symbol(x)] = @variable(m, [p.s.storage.types.all, p.time_steps], base_name=x, lower_bound=0)
			end
	
			dv = "dvGridToStorage"*_n
			m[Symbol(dv)] = @variable(m, [p.s.storage.types.elec, p.time_steps], base_name=dv, lower_bound=0)
	
			dv = "dvGridPurchase"*_n
			m[Symbol(dv)] = @variable(m, [p.time_steps], base_name=dv, lower_bound=0)
	
			dv = "dvPeakDemandTOU"*_n
			m[Symbol(dv)] = @variable(m, [p.ratchets, 1], base_name=dv, lower_bound=0)
	
			dv = "dvPeakDemandMonth"*_n
			m[Symbol(dv)] = @variable(m, [p.months, 1], base_name=dv, lower_bound=0)
	
			dv = "dvProductionToStorage"*_n
			m[Symbol(dv)] = @variable(m, [p.s.storage.types.all, p.techs.all, p.time_steps], base_name=dv, lower_bound=0)
	
			dv = "dvStoredEnergy"*_n
			m[Symbol(dv)] = @variable(m, [p.s.storage.types.all, 0:p.time_steps[end]], base_name=dv, lower_bound=0)
	
			dv = "MinChargeAdder"*_n
			m[Symbol(dv)] = @variable(m, base_name=dv, lower_bound=0)
	
			# Add the new variables for the generator
	
			dv = "dvFuelUsage"*_n
			m[Symbol(dv)] = @variable(m, [p.techs.gen, 0:p.time_steps[end]], base_name=dv, lower_bound=0)
		
			dv = "binGenIsOnInTS"*_n
			m[Symbol(dv)] = @variable(m, [p.techs.gen, 0:p.time_steps[end]], base_name=dv, lower_bound=0)
		
	
			if !isempty(p.s.electric_tariff.export_bins)
				dv = "dvProductionToGrid"*_n
				m[Symbol(dv)] = @variable(m, [p.techs.elec, p.s.electric_tariff.export_bins, p.time_steps], base_name=dv, lower_bound=0)
			end
			print("\n p.techs.elec are: ")	
			print(p.techs.elec)						
			print("\n p.techs.gen are: ")	
			print(p.techs.gen)	
			print("\n p.techs.all are: ")	
			print(p.techs.all)	
	
			ex_name = "TotalTechCapCosts"*_n
			m[Symbol(ex_name)] = @expression(m, p.third_party_factor *
				sum( p.cap_cost_slope[t] * m[Symbol("dvPurchaseSize"*_n)][t] for t in p.techs.all ) 
			)
	
			ex_name = "TotalStorageCapCosts"*_n
			m[Symbol(ex_name)] = @expression(m, p.third_party_factor * 
				sum(p.s.storage.attr[b].net_present_cost_per_kw * m[Symbol("dvStoragePower"*_n)][b] for b in p.s.storage.types.elec)
				+ sum(p.s.storage.attr[b].net_present_cost_per_kwh * m[Symbol("dvStorageEnergy"*_n)][b] for b in p.s.storage.types.all)
			)
	
			ex_name = "TotalPerUnitSizeOMCosts"*_n
			m[Symbol(ex_name)] = @expression(m, p.third_party_factor * p.pwf_om * 
				sum( p.om_cost_per_kw[t] * m[Symbol("dvSize"*_n)][t] for t in p.techs.all ) 
			)
	
			ex_name = "TotalPerUnitProdOMCosts"*_n
			m[Symbol(ex_name)] = 0
	
			ex_name = "TotalFuelCosts"*_n
			m[Symbol(ex_name)] = 0
	
			ex_name = "TotalFuelCosts"
			m[Symbol(ex_name)] = 0
	
			if !isempty(p.techs.gen)
				add_gen_constraints(m, p; _n = _n )
				m[Symbol("TotalPerUnitProdOMCosts"*_n)] += m[Symbol("TotalGenPerUnitProdOMCosts"*_n)]
				m[Symbol("TotalFuelCosts"*_n)] += m[Symbol("TotalGenFuelCosts"*_n)]
				#m[Symbol("TotalFuelCosts")] += m[Symbol("TotalGenFuelCosts"*_n)]
				
			
			end	
	
			if !isempty(p.s.electric_tariff.export_bins)  # added for testing
				add_export_constraints(m, p; _n=_n)  # added for testing 
			end
	
			add_elec_utility_expressions(m, p; _n=_n)
		
			# The costs are set to zero    
			m[Symbol("Costs"*_n)] = @expression(m, 0);
				#TODO: update in line with non-multinode version
				# Capital Costs
				#m[Symbol("TotalTechCapCosts"*_n)] + m[Symbol("TotalStorageCapCosts"*_n)] +  
				
				## Fixed O&M, tax deductible for owner
				#m[Symbol("TotalPerUnitSizeOMCosts"*_n)] * (1 - p.s.financial.owner_tax_rate_fraction) +
	
				# Production O&M cost and fuel costs
				#m[Symbol("TotalFuelCosts"*_n)] + 
				#m[Symbol("TotalPerUnitProdOMCosts"*_n)] +
	
				# Utility Bill, tax deductible for offtaker, including export benefit
				#m[Symbol("TotalElecBill"*_n)] * (1 - p.s.financial.offtaker_tax_rate_fraction)
			#);
		end
		for p in ps
			_n = string("_", p.s.site.node)
	
			
	
			for b in p.s.storage.types.all
				if p.s.storage.attr[b].max_kw == 0 || p.s.storage.attr[b].max_kwh == 0
					@constraint(m, [ts in p.time_steps], m[Symbol("dvStoredEnergy"*_n)][b, ts] == 0)
					@constraint(m, m[Symbol("dvStorageEnergy"*_n)][b] == 0)
					@constraint(m, m[Symbol("dvStoragePower"*_n)][b] == 0)
					@constraint(m, [t in p.techs.elec, ts in p.time_steps_with_grid],
								m[Symbol("dvProductionToStorage"*_n)][b, t, ts] == 0)
					@constraint(m, [ts in p.time_steps], m[Symbol("dvDischargeFromStorage"*_n)][b, ts] == 0)
					@constraint(m, [ts in p.time_steps], m[Symbol("dvGridToStorage"*_n)][b, ts] == 0)
				else
					add_storage_size_constraints(m, p, b; _n=_n)
					add_general_storage_dispatch_constraints(m, p, b; _n=_n)
					if b in p.s.storage.types.elec
						add_elec_storage_dispatch_constraints(m, p, b; _n=_n)
					elseif b in p.s.storage.types.hot
						add_hot_thermal_storage_dispatch_constraints(m, p, b; _n=_n)
					elseif b in p.s.storage.types.cold
						add_cold_thermal_storage_dispatch_constraints(m, p, b; _n=_n)
					end
				end
			end
	
			if any(max_kw->max_kw > 0, (p.s.storage.attr[b].max_kw for b in p.s.storage.types.elec))
				add_storage_sum_constraints(m, p; _n=_n)
			end
		
			add_production_constraints(m, p; _n=_n)
		
			if !isempty(p.techs.all)
				add_tech_size_constraints(m, p; _n=_n)
				if !isempty(p.techs.no_curtail)
					add_no_curtail_constraints(m, p; _n=_n)
				end
			end
		
			add_elec_load_balance_constraints(m, p; _n=_n)
		
			if !isempty(p.s.electric_tariff.export_bins)
				add_export_constraints(m, p; _n=_n)
			end
		
			if !isempty(p.s.electric_tariff.monthly_demand_rates)
				add_monthly_peak_constraint(m, p; _n=_n)
			end
		
			if !isempty(p.s.electric_tariff.tou_demand_ratchet_time_steps)
				add_tou_peak_constraint(m, p; _n=_n)
			end
	
			if !(p.s.electric_utility.allow_simultaneous_export_import) & !isempty(p.s.electric_tariff.export_bins)
				add_simultaneous_export_import_constraint(m, p; _n=_n)
			end
	
			if p.s.electric_tariff.demand_lookback_percent > 0
				add_demand_lookback_constraints(m, p; _n=_n)
			end
	
			if !isempty(p.s.electric_tariff.coincpeak_periods)
				add_coincident_peak_charge_constraints(m, p; _n=_n)
			end
		
		end
		

end 
=#

function run_reopt(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario

	build_reopt!(m, ps)

	add_objective!(m, ps)

	@info "Model built. Optimizing..."
	tstart = time()
	optimize!(m)
	opt_time = round(time() - tstart, digits=3)
	if termination_status(m) == MOI.TIME_LIMIT
		status = "timed-out"
    elseif termination_status(m) == MOI.OPTIMAL
        status = "optimal"
    else
        status = "not optimal"
        @warn "REopt solved with " termination_status(m), ", returning the model."
        return m
	end
	@info "REopt solved with " termination_status(m)
	@info "Solving took $(opt_time) seconds."
    
	tstart = time()
	results = reopt_results(m, ps)
	time_elapsed = time() - tstart
	@info "Results processing took $(round(time_elapsed, digits=3)) seconds."
	results["status"] = status
	results["solver_seconds"] = opt_time
	return results
end


function reopt_results(m::JuMP.AbstractModel, ps::AbstractVector{REoptInputs{T}}) where T <: AbstractScenario
	# TODO address Warning: The addition operator has been used on JuMP expressions a large number of times.
	results = Dict{Union{Int, String}, Any}()
	for p in ps
		results[p.s.site.node] = reopt_results(m, p; _n=string("_", p.s.site.node))
	end
	return results
end

