using Revise, Xpress, JuMP, REopt, CSV, PlotlyJS, DataFrames, Statistics, Dates, JSON


path = "/Users/bpulluta/.julia/dev/REopt/BorgWarner"

if !isdir(path)
	println("##########################")
	println("MAKE SURE TO UPDATE PATH")
	println("##########################\n")

    error("$path does not exist.")
end

# continue with the code
println("##########################")
println("Directory exists at $path")
println("##########################\n")

cd(path)

function create_outage_plot(nested_dict::Dict{String, Any},filename::AbstractString)
	
    resilience_dict = nested_dict["resilience_by_time_step"]
    prob_dict = nested_dict["probs_of_surviving"]*100

	start_date = DateTime("2022-01-01T00:00:00")
    dates = [start_date + Hour(i-1) for i in 1:8760]
    
	avg_res = round(mean(resilience_dict))
	y_avg = fill(avg_res, length(dates))
	# Define trace1 with a title and x/y axis labels
    trace_a = scatter(x=dates, y=collect(values(resilience_dict)),
                  name="Resilience by Time Step")

	trace_b =  scatter(x = dates, y = y_avg, 
		name="Average Duration = $(avg_res) Hours",
        line=attr(color="black", width=2,
                                dash="dot"),
        mode="lines"
            )

	trace1 = plot([trace_a, trace_b],
			Layout(
			title="Resilience Duration by Hour of the Year",
			plot_bgcolor="white",
			paper_bgcolor="white",
			yaxis_title = "Outage Survival Duration (Hours)",
			xaxis=attr(showline=true, ticks="outside", showgrid=true,
			gridcolor="rgba(128, 128, 128, 0.2)",
			linewidth=1.5, zeroline=false),
			yaxis=attr(showline=true, ticks="outside", showgrid=true,
			gridcolor="rgba(128, 128, 128, 0.2)",
			linewidth=1.5, zeroline=false,range = [0, round(maximum(resilience_dict))*1.5])
			)
   		)

    x2 = 1:length(prob_dict)
    # Define a mask for the region above 90%
    mask = collect(values(prob_dict)) .>= 90
	mask2 = (collect(values(prob_dict)) .>= 50) .& (collect(values(prob_dict)) .< 90)
	mask3 = (collect(values(prob_dict)) .< 50)


    # Create a scatter trace for the data below 90% with a title and x/y axis labels
    trace_below = bar(x=x2[mask3], y=collect(values(prob_dict))[mask3],
                      name="Probability of Survival Below 50%", marker=attr(color="#fc8d59")
                     )			 

	trace_middle = bar(x=x2[mask2], y=collect(values(prob_dict))[mask2],
					name="Probability of Survival between 50% and 90%", marker=attr(color="#ffffbf")
					)		

    # Create a scatter trace for the data above 90% with a title and x/y axis labels
    trace_above = bar(x=x2[mask], y=collect(values(prob_dict))[mask],
						#  fill="tonexty", fillcolor="rgba(0, 255, 0, 0.2)",
                    name="Probability of Survival Above 90%", marker=attr(color="#91cf60")
                    )

    # Combine the two traces into a single plot with a legend title
    trace2 = plot([trace_below, trace_middle,  trace_above],
		Layout(
			title="Probability of Surving an Outage by Number of Hours",
			plot_bgcolor="white",
			paper_bgcolor="white",
			yaxis_title = "Probability (%)",
			xaxis_title = "Time Step (Hours)",
			xaxis=attr(showline=true, ticks="outside", showgrid=true,
            gridcolor="rgba(128, 128, 128, 0.2)",
            linewidth=1.5, zeroline=false),
        	yaxis=attr(showline=true, ticks="outside", showgrid=true,
            gridcolor="rgba(128, 128, 128, 0.2)",
            linewidth=1.5, zeroline=false,range = [0, 100]),
			)
	)


	p = [trace1 trace2]
	relayout!(p, title_text="Outage Results", width=1500, height=500)
	p

	savefig(p, filename)
end

function save_outage_dict_to_csv(dict::Dict{String, Any}, filename::AbstractString)
	# Convert the dictionary to a JSON string with pretty formatting
	json_str = JSON.json(dict, 4)

	# Save the JSON string to a file
	open(filename, "w") do file
		write(file, json_str)
	end
end

function get_data(data_f, scenario_name; shorthand = true)
	
	df_gen = rec_flatten_dict(data_f)
	var_name = scenario_name

	function format_shorthand(num; currency_symbol="\$")
		currency_symbol = currency_symbol
		if isa(num, String)
			return string(num)
		else
			if num >= 1e6 || num <= -1e6
				return string( num >= 0 ? "" : "-") * currency_symbol * string(round(abs(num) / 1e6, digits=1)) * "M"
			elseif num >= 1e3 || num <= -1e3
				return string( num >= 0 ? "" : "-") * currency_symbol * string(round(abs(num) / 1e3, digits=1)) * "k"
			else
				return string( num >= 0 ? "" : "-") * currency_symbol * string(round(abs(num), digits=1))
			end
		end
	end
	
	if shorthand
		if var_name == "BAU"
			var_1 	= get(df_gen,"PV.size_kw_bau","-")
			var_2 	= get(df_gen,"ElectricStorage.size_kw_bau","-")
			var_3 	= get(df_gen,"ElectricStorage.size_kwh_bau","-")
			var_4 	= get(df_gen,"Generator.size_kw_bau","-")
			var_5 	= get(df_gen,"Financial.lifecycle_capital_costs_bau","-")
			var_6 	= 100 *  get(df_gen,"Site.renewable_electricity_fraction_bau","-")
			var_7 	= get(df_gen,"ElectricUtility.annual_energy_supplied_kwh_bau","-")/1000
			var_8 	= get(df_gen,"Financial.lcc_bau","-")
			var_9 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax_bau","-")
			var_10 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax_bau","-")
			var_11 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-")
			var_12 	= get(df_gen,"PLACEHOLDER","-")
			var_13 	= get(df_gen,"PLACEHOLDER","-")
			var_14 	= get(df_gen,"PLACEHOLDER","-")
			var_15 	= get(df_gen,"PLACEHOLDER","-")
			var_16 	= get(df_gen,"PLACEHOLDER","-")
			var_17 	= get(df_gen,"ElectricTariff.lifecycle_fixed_cost_after_tax_bau","-") + get(df_gen,"ElectricTariff.lifecycle_demand_cost_after_tax_bau","-") + get(df_gen,"ElectricTariff.lifecycle_energy_cost_after_tax_bau","-")
			var_18 	= get(df_gen,"PLACEHOLDER","-")
			var_19 	= get(df_gen,"Financial.npv_bau","-")
			var_20 	= get(df_gen,"PV.lcoe_per_kwh_bau","-")
			var_21 	= get(df_gen,"Financial.simple_payback_years_bau","-")
			var_22 	= get(df_gen,"ElectricTariff.lifecycle_export_benefit_after_tax_bau","-")
			var_23 	= get(df_gen,"Financial.lifecycle_generation_tech_capital_costs_bau","-")
			var_24 	= get(df_gen,"Financial.lifecycle_storage_capital_costs_bau","-")
			var_25 	= get(df_gen,"Wind.size_kw_bau","-")
			var_26 	= get(df_gen,"Site.annual_emissions_tonnes_CO2_bau","-")
			var_27 	= get(df_gen,"Site.lifecycle_emissions_tonnes_CO2_bau","-")
			var_28  = get(df_gen,"PLACEHOLDER","-")

			df_res = DataFrame([
			[var_name],
			[var_1],[var_2],[var_3],[var_4],[format_shorthand(var_5)],
			[var_6],[var_7],[format_shorthand(var_8)],[format_shorthand(var_9)],[format_shorthand(var_10)],
			[format_shorthand(var_11)],[format_shorthand(var_12)],[format_shorthand(var_13)],[format_shorthand(var_14)],[var_15],
			[var_16],[format_shorthand(var_17)],[var_18],[format_shorthand(var_19)],[var_20],
			[var_21],[format_shorthand(var_22)],[format_shorthand(var_23)],[format_shorthand(var_24)],[var_25],
			[var_26],[var_27],[var_28]
			], 
			[
			"Scenario",
			"PV Size (KW-DC)", 							#1
			"Battery Size (kW)", 						#2
			"Storage Capacity (kWh)", 					#3
			"Generator Capacity (kW)", 					#4
			"Capital Cost (\$)",  						#5
			"RE Penetration (%)", 						#6
			"Year 1 Electric Grid Purchases (MWh)", 	#7
			"Total Lifecycle Cost (\$)", 				#8
			"Year 1 Energy Charges (\$)", 				#9
			"Year 1 Demand Charges (\$)", 				#10
			"Year 1 Total Electric Bill Costs (\$)",    #11
			"Year 1 Energy Charge Savings (\$)", 		#12
			"Year 1 Demand Charge Savings (\$)",		#13
			"Year 1 Total Electric Bill Savings (\$)",	#14
			"Year 1 Utility Savings (%)",  				#15
			"Average Outage Duration Survived (Hours)", #16
			"Total Utility Electricity Cost (\$)",  	#17
			"Lifecycle Savings (%)", 					#18
			"Net Present Value (\$)",  					#19
			"Levelized Cost of Energy (\$/kWh)", 		#20	
			"Payback Period (Years)", 					#21
			"Lifecycle Net Metering Benefit (\$)", 	 	#22
			"PV Installed Cost (\$)",					#23
			"Battery Installed Cost (\$)",				#24
			"Wind Size (kW)",							#25
			"Annual CO2 Emissions (Tons)",				#26
			"Lifecycle CO2 Emissions (Tons)",			#27
			"Lifecycle CO2 Reduction (%)"				#28
			])
			   return df_res
	
		else 
			var_1 	= get(df_gen, "PV.size_kw","-")
			var_1 	= isa(var_1, Number) ? round(var_1,digits=0) : var_1

			var_2 	= get(df_gen,"ElectricStorage.size_kw","-")
			var_2 	= isa(var_2, Number) ? round(var_2,digits=0) : var_2
			
			var_3 	= get(df_gen,"ElectricStorage.size_kwh","-")
			var_3 	= isa(var_3, Number) ? round(var_3,digits=0) : var_3
			
			var_4 	= get(df_gen,"Generator.size_kw","-")
			var_4 	= isa(var_4, Number) ? round(var_4,digits=0) : var_4
			
			var_5 	= get(df_gen,"Financial.lifecycle_capital_costs","-")
			
			var_6 	= 100*get(df_gen,"Site.renewable_electricity_fraction","-")
			var_6 	= isa(var_6, Number) ? round(var_6,digits=0) : var_6
			
			var_7 	= get(df_gen,"ElectricUtility.annual_energy_supplied_kwh","-")/1000
			var_8 	= get(df_gen,"Financial.lcc","-")
			var_9 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax","-")
			var_10 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax","-")
			var_11 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax","-")
			var_12 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax","-")
			var_13 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax","-")
			var_14 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_bill_before_tax","-")
			
			var_15 	= 100*(get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_bill_before_tax","-"))/get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-")
			var_15 	= isa(var_15, Number) ? round(var_15,digits=0) : var_15
			
			var_16 	= "-"
			var_17 	= get(df_gen,"ElectricTariff.lifecycle_fixed_cost_after_tax","-") + get(df_gen,"ElectricTariff.lifecycle_demand_cost_after_tax","-") + get(df_gen,"ElectricTariff.lifecycle_energy_cost_after_tax","-")
			
			var_18 	= 100 *  get(df_gen,"Financial.npv","-")/get(df_gen,"Financial.lcc_bau","-")
			var_18 	= isa(var_18, Number) ? round(var_18,digits=0) : var_18
			
			var_19 	= get(df_gen,"Financial.npv","-")
			var_20 	= get(df_gen,"PV.lcoe_per_kwh","-")
			var_21 	= get(df_gen, "Financial.simple_payback_years","-")
			var_22 	= get(df_gen, "ElectricTariff.lifecycle_export_benefit_after_tax","-")
			var_23 	= get(df_gen,"Financial.lifecycle_generation_tech_capital_costs","-")
			var_24 	= get(df_gen,"Financial.lifecycle_storage_capital_costs","-")

			var_25 	= get(df_gen,"Wind.size_kw","-")
			var_25 	= isa(var_25, Number) ? round(var_25,digits=0) : var_25
			
			var_26 	= get(df_gen,"Site.annual_emissions_tonnes_CO2","-")
			var_26 	= isa(var_26, Number) ? round(var_26,digits=0) : var_26
			
			var_27	= get(df_gen,"Site.lifecycle_emissions_tonnes_CO2","-")
			var_27 	= isa(var_27, Number) ? round(var_27,digits=0) : var_27

			var_28 	= 100*(get(df_gen,"Site.lifecycle_emissions_reduction_CO2_fraction","-"))
			var_28 	= isa(var_28, Number) ? round(var_28,digits=0) : var_28

			df_res = DataFrame([
			[var_name],
			[var_1],[var_2],[var_3],[var_4],[format_shorthand(var_5)],
			[var_6],[var_7],[format_shorthand(var_8)],[format_shorthand(var_9)],[format_shorthand(var_10)],
			[format_shorthand(var_11)],[format_shorthand(var_12)],[format_shorthand(var_13)],[format_shorthand(var_14)],[var_15],
			[var_16],[format_shorthand(var_17)],[var_18],[format_shorthand(var_19)],[var_20],
			[var_21],[format_shorthand(var_22)],[format_shorthand(var_23)],[format_shorthand(var_24)],[var_25],
			[var_26],[var_27],[var_28]
			], 
			[
			"Scenario",
			"PV Size (KW-DC)", 							#1
			"Battery Size (kW)", 						#2
			"Storage Capacity (kWh)", 					#3
			"Generator Capacity (kW)", 					#4
			"Capital Cost (\$)",  						#5
			"RE Penetration (%)", 						#6
			"Year 1 Electric Grid Purchases (MWh)", 	#7
			"Total Lifecycle Cost (\$)", 				#8
			"Year 1 Energy Charges (\$)", 				#9
			"Year 1 Demand Charges (\$)", 				#10
			"Year 1 Total Electric Bill Costs (\$)",    #11
			"Year 1 Energy Charge Savings (\$)", 		#12
			"Year 1 Demand Charge Savings (\$)",		#13
			"Year 1 Total Electric Bill Savings (\$)",	#14
			"Year 1 Utility Savings (%)",  				#15
			"Average Outage Duration Survived (Hours)", #16
			"Total Utility Electricity Cost (\$)",  	#17
			"Lifecycle Savings (%)", 					#18
			"Net Present Value (\$)",   				#19
			"Levelized Cost of Energy (\$/kWh)", 		#20	
			"Payback Period (Years)", 					#21
			"Lifecycle Net Metering Benefit (\$)",		#22
			"PV Installed Cost (\$)",					#23
			"Battery Installed Cost (\$)",				#24
			"Wind Size (kW)",							#25
			"Annual CO2 Emissions (Tons)",				#26
			"Lifecycle CO2 Emissions (Tons)",			#27,
			"Lifecycle CO2 Reduction (%)"				#28
			])
			return df_res
		end
	
	else
		if var_name == "BAU"
			var_1 	= get(df_gen,"PV.size_kw_bau","-")
			var_2 	= get(df_gen,"ElectricStorage.size_kw_bau","-")
			var_3 	= get(df_gen,"ElectricStorage.size_kwh_bau","-")
			var_4 	= get(df_gen,"Generator.size_kw_bau","-")
			var_5 	= get(df_gen,"Financial.lifecycle_capital_costs_bau","-")
			var_6 	= 100 *  get(df_gen,"Site.renewable_electricity_fraction_bau","-")
			var_7 	= get(df_gen,"ElectricUtility.annual_energy_supplied_kwh_bau","-")/1000
			var_8 	= get(df_gen,"Financial.lcc_bau","-")
			var_9 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax_bau","-")
			var_10 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax_bau","-")
			var_11 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-")
			var_12 	= get(df_gen,"PLACEHOLDER","-")
			var_13 	= get(df_gen,"PLACEHOLDER","-")
			var_14 	= get(df_gen,"PLACEHOLDER","-")
			var_15 	= get(df_gen,"PLACEHOLDER","-")
			var_16 	= get(df_gen,"PLACEHOLDER","-")
			var_17 	= get(df_gen,"ElectricTariff.lifecycle_fixed_cost_after_tax_bau","-") + get(df_gen,"ElectricTariff.lifecycle_demand_cost_after_tax_bau","-") + get(df_gen,"ElectricTariff.lifecycle_energy_cost_after_tax_bau","-")
			var_18 	= get(df_gen,"PLACEHOLDER","-")
			var_19 	= get(df_gen,"Financial.npv_bau","-")
			var_20 	= get(df_gen,"PV.lcoe_per_kwh_bau","-")
			var_21 	= get(df_gen,"Financial.simple_payback_years_bau","-")
			var_22 	= get(df_gen,"ElectricTariff.lifecycle_export_benefit_after_tax_bau","-")
			var_23 	= get(df_gen,"Financial.lifecycle_generation_tech_capital_costs_bau","-")
			var_24 	= get(df_gen,"Financial.lifecycle_storage_capital_costs_bau","-")
			var_25 	= get(df_gen,"Wind.size_kw_bau","-")
			var_26 	= get(df_gen,"Site.annual_emissions_tonnes_CO2_bau","-")
			var_27 	= get(df_gen,"Site.lifecycle_emissions_tonnes_CO2_bau","-")
			var_28  = get(df_gen,"PLACEHOLDER","-")

			df_res = DataFrame([
			[var_name],
			[var_1],[var_2],[var_3],[var_4],[var_5],
			[var_6],[var_7],[var_8],[var_9],[var_10],
			[var_11],[var_12],[var_13],[var_14],[var_15],
			[var_16],[var_17],[var_18],[var_19],[var_20],
			[var_21],[var_22],[var_23],[var_24],[var_25],
			[var_26],[var_27],[var_28]
			], 
			[
			"Scenario",
			"PV Size (KW-DC)", 							#1
			"Battery Size (kW)", 						#2
			"Storage Capacity (kWh)", 					#3
			"Generator Capacity (kW)", 					#4
			"Capital Cost (\$)",  						#5
			"RE Penetration (%)", 						#6
			"Year 1 Electric Grid Purchases (MWh)", 	#7
			"Total Lifecycle Cost (\$)", 				#8
			"Year 1 Energy Charges (\$)", 				#9
			"Year 1 Demand Charges (\$)", 				#10
			"Year 1 Total Electric Bill Costs (\$)",    #11
			"Year 1 Energy Charge Savings (\$)", 		#12
			"Year 1 Demand Charge Savings (\$)",		#13
			"Year 1 Total Electric Bill Savings (\$)",	#14
			"Year 1 Utility Savings (%)",  				#15
			"Average Outage Duration Survived (Hours)", #16
			"Total Utility Electricity Cost (\$)",  	#17
			"Lifecycle Savings (%)", 					#18
			"Net Present Value (\$)",  					#19
			"Levelized Cost of Energy (\$/kWh)", 		#20	
			"Payback Period (Years)", 					#21
			"Lifecycle Net Metering Benefit (\$)", 	 	#22
			"PV Installed Cost (\$)",					#23
			"Battery Installed Cost (\$)",				#24
			"Wind Size (kW)",							#25
			"Annual CO2 Emissions (Tons)",				#26
			"Lifecycle CO2 Emissions (Tons)",			#27
			"Lifecycle CO2 Reduction (%)"				#28
			])
			   return df_res
		

			else 
				var_1 	= get(df_gen, "PV.size_kw","-")
				var_1 	= isa(var_1, Number) ? round(var_1,digits=0) : var_1
	
				var_2 	= get(df_gen,"ElectricStorage.size_kw","-")
				var_2 	= isa(var_2, Number) ? round(var_2,digits=0) : var_2
				
				var_3 	= get(df_gen,"ElectricStorage.size_kwh","-")
				var_3 	= isa(var_3, Number) ? round(var_3,digits=0) : var_3
				
				var_4 	= get(df_gen,"Generator.size_kw","-")
				var_4 	= isa(var_4, Number) ? round(var_4,digits=0) : var_4
				
				var_5 	= get(df_gen,"Financial.lifecycle_capital_costs","-")
				
				var_6 	= 100*get(df_gen,"Site.renewable_electricity_fraction","-")
				var_6 	= isa(var_6, Number) ? round(var_6,digits=0) : var_6
				
				var_7 	= get(df_gen,"ElectricUtility.annual_energy_supplied_kwh","-")/1000
				var_8 	= get(df_gen,"Financial.lcc","-")
				var_9 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax","-")
				var_10 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax","-")
				var_11 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax","-")
				var_12 	= get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_energy_cost_before_tax","-")
				var_13 	= get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_demand_cost_before_tax","-")
				var_14 	= get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_bill_before_tax","-")
				
				var_15 	= 100*(get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-") - get(df_gen,"ElectricTariff.year_one_bill_before_tax","-"))/get(df_gen,"ElectricTariff.year_one_bill_before_tax_bau","-")
				var_15 	= isa(var_15, Number) ? round(var_15,digits=0) : var_15
				
				var_16 	= "-"
				var_17 	= get(df_gen,"ElectricTariff.lifecycle_fixed_cost_after_tax","-") + get(df_gen,"ElectricTariff.lifecycle_demand_cost_after_tax","-") + get(df_gen,"ElectricTariff.lifecycle_energy_cost_after_tax","-")
				
				var_18 	= 100 *  get(df_gen,"Financial.npv","-")/get(df_gen,"Financial.lcc_bau","-")
				var_18 	= isa(var_18, Number) ? round(var_18,digits=0) : var_18
				
				var_19 	= get(df_gen,"Financial.npv","-")
				var_20 	= get(df_gen,"PV.lcoe_per_kwh","-")
				var_21 	= get(df_gen, "Financial.simple_payback_years","-")
				var_22 	= get(df_gen, "ElectricTariff.lifecycle_export_benefit_after_tax","-")
				var_23 	= get(df_gen,"Financial.lifecycle_generation_tech_capital_costs","-")
				var_24 	= get(df_gen,"Financial.lifecycle_storage_capital_costs","-")
	
				var_25 	= get(df_gen,"Wind.size_kw","-")
				var_25 	= isa(var_25, Number) ? round(var_25,digits=0) : var_25
				
				var_26 	= get(df_gen,"Site.annual_emissions_tonnes_CO2","-")
				var_26 	= isa(var_26, Number) ? round(var_26,digits=0) : var_26
				
				var_27	= get(df_gen,"Site.lifecycle_emissions_tonnes_CO2","-")
				var_27 	= isa(var_27, Number) ? round(var_27,digits=0) : var_27
	
				var_28 	= 100*(get(df_gen,"Site.lifecycle_emissions_reduction_CO2_fraction","-"))
				var_28 	= isa(var_28, Number) ? round(var_28,digits=0) : var_28
	
				df_res = DataFrame([
				[var_name],
				[var_1],[var_2],[var_3],[var_4],[var_5],
				[var_6],[var_7],[var_8],[var_9],[var_10],
				[var_11],[var_12],[var_13],[var_14],[var_15],
				[var_16],[var_17],[var_18],[var_19],[var_20],
				[var_21],[var_22],[var_23],[var_24],[var_25],
				[var_26],[var_27],[var_28]
				], 
				[
				"Scenario",
				"PV Size (KW-DC)", 							#1
				"Battery Size (kW)", 						#2
				"Storage Capacity (kWh)", 					#3
				"Generator Capacity (kW)", 					#4
				"Capital Cost (\$)",  						#5
				"RE Penetration (%)", 						#6
				"Year 1 Electric Grid Purchases (MWh)", 	#7
				"Total Lifecycle Cost (\$)", 				#8
				"Year 1 Energy Charges (\$)", 				#9
				"Year 1 Demand Charges (\$)", 				#10
				"Year 1 Total Electric Bill Costs (\$)",    #11
				"Year 1 Energy Charge Savings (\$)", 		#12
				"Year 1 Demand Charge Savings (\$)",		#13
				"Year 1 Total Electric Bill Savings (\$)",	#14
				"Year 1 Utility Savings (%)",  				#15
				"Average Outage Duration Survived (Hours)", #16
				"Total Utility Electricity Cost (\$)",  	#17
				"Lifecycle Savings (%)", 					#18
				"Net Present Value (\$)",   				#19
				"Levelized Cost of Energy (\$/kWh)", 		#20	
				"Payback Period (Years)", 					#21
				"Lifecycle Net Metering Benefit (\$)",		#22
				"PV Installed Cost (\$)",					#23
				"Battery Installed Cost (\$)",				#24
				"Wind Size (kW)",							#25
				"Annual CO2 Emissions (Tons)",				#26
				"Lifecycle CO2 Emissions (Tons)",			#27,
				"Lifecycle CO2 Reduction (%)"				#28
				])
				return df_res
		end
	end

end

function rec_flatten_dict(d, prefix_delim = ".")
	new_d = empty(d)
	for (key, value) in pairs(d)
		if isa(value, Dict)
			 flattened_value = rec_flatten_dict(value, prefix_delim)
			 for (ikey, ivalue) in pairs(flattened_value)
				 new_d["$key.$ikey"] = ivalue
			 end
		else
			new_d[key] = value
		end
	end
	return new_d
end

###REoptPlots
function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=true, display_stats=false, year = 2022)
	
	function check_time_interval(arr::Array)
		if length(arr) == 8760
			interval = Dates.Hour(1)
		elseif length(arr) == 17520
			interval = Dates.Minute(30)
		elseif length(arr) == 35040
			interval = Dates.Minute(15)
		else
			error("Time interval length must be either 8760, 17520, or 35040")
		end
		return interval
	end

	df_stat = rec_flatten_dict(d)
	load  = get(df_stat,"ElectricLoad.load_series_kw","-")
	y_max = round(maximum(load))*1.4

    traces = GenericTrace[]
    layout = Layout(
        hovermode="closest",
        hoverlabel_align="left",
        plot_bgcolor="white",
        paper_bgcolor="white",
        font_size=18,
        xaxis=attr(showline=true, ticks="outside", showgrid=true,
            gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
            linewidth=1.5, zeroline=false),
        yaxis=attr(showline=true, ticks="outside", showgrid=true,
            gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
            linewidth=1.5, zeroline=false,range = [0, y_max]),
        # yaxis=attr(showline=true, ticks="outside", showgrid=true,linewidth=1.5, zeroline=false, color="black", range = [0, y_max]),
        title = title,
        xaxis_title = "",
        yaxis_title = "Power (kW)",
        xaxis_rangeslider_visible=true,
		legend=attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
		bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
				)
    
    eload       = d["ElectricLoad"]["load_series_kw"]

    #Define year
    year = year

    # Define the start and end time for the date and time array
    start_time  = DateTime(year, 1, 1, 0, 0, 0)
    end_time    = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr = start_time:check_time_interval(eload):end_time
    dr_v = collect(dr)

    #remove the last value of the array to match array sizes
    pop!(dr_v)

    ### REopt Data Plotting Begins
    ### Total Electric Load Line Plot
    push!(traces, scatter(;
        name = "Total Electric Load",
        x = dr_v,
        y = d["ElectricLoad"]["load_series_kw"],
        mode = "lines",
        fill = "none",
        line=attr(width=1, color="#003f5c")
    ))

    ### Grid to Load Plot
    push!(traces, scatter(;
        name = "Grid Serving Load",
        x = dr_v,
        y = d["ElectricUtility"]["electric_to_load_series_kw"],
        mode = "lines",
        fill = "tozeroy",
        line = attr(width=0, color="#0000ff")
    ))

	tech_color_dict = Dict("PV" => "#fea600", "ElectricStorage" => "#e604b3", "Generator" => "#ff552b", "Wind" => "#70ce57", "CHP" => "#33783f", "GHP" => "#52e9e6")
    tech_names  	= ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]

    #Plot every existing technology
    cumulative_data = zeros(length(dr_v))
    cumulative_data = cumulative_data .+ d["ElectricUtility"]["electric_to_load_series_kw"]
	
    for tech in tech_names
        if haskey(d, tech)
            sub_dict = d[tech]
            if tech == "ElectricStorage"
                new_data = sub_dict["storage_to_load_series_kw"]
				if isempty(new_data)
					continue
				end
                ### Battery SOC line plot
                push!(traces, scatter(
                    name = "Battery State of Charge",
                    x = dr_v,
                    y = d["ElectricStorage"]["soc_series_fraction"]*100,
                    yaxis="y2",
                    line = attr(
                    dash= "dashdot",
                    width = 1
                    ),
                    marker = attr(
                        color="rgb(100,100,100)"
                    ),
                ))

                layout = Layout(
					hovermode="closest",
					hoverlabel_align="left",
					plot_bgcolor="white",
					paper_bgcolor="white",
					font_size=18,
					xaxis=attr(showline=true, ticks="outside", showgrid=true,
						gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
						linewidth=1.5, zeroline=false),
					yaxis=attr(showline=true, ticks="outside", showgrid=true,
						gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
						linewidth=1.5, zeroline=false, range = [0, y_max]),
                    # yaxis=attr(showline=true, ticks="outside", showgrid=false,
                    #     linewidth=1.5, zeroline=false, range = [0, y_max]),
                    xaxis_title = "",
                    yaxis_title = "Power (kW)",
                    xaxis_rangeslider_visible=true,
					legend=attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
					bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
					    yaxis2 = attr(
                        title = "State of Charge (Percent)",
                        overlaying = "y",
                        side = "right",
						range = [0, 100]
                    ))
            else
                new_data = sub_dict["electric_to_load_series_kw"]
				
            end
            if any(x -> x > 0, new_data)
				#invisble line for plotting
				push!(traces, scatter(
					name = "invisible",			
					x = dr_v,
					y = cumulative_data,
					mode = "lines",
					fill = Nothing,
					line = attr(width = 0),
					showlegend = false,
					hoverinfo = "skip",
				))

				cumulative_data = cumulative_data .+ new_data
				
				#plot each technology
				push!(traces, scatter(;
					name = tech * " Serving Load",
					x = dr_v,
					y = cumulative_data,
					mode = "lines",
					fill = "tonexty",
					line = attr(width=0, color = tech_color_dict[tech])
				))        
			end
        end
	end

	net_tech_color_dict = Dict("PV" => "#326f9c", "Wind" => "#c2c5e2")

	#Net Metering Enabled
	for tech in tech_names
        if haskey(d, tech)
            sub_dict = d[tech]
            if tech == "PV" || tech == "Wind"
				new_data = sub_dict["electric_to_grid_series_kw"]
				if any(x -> x > 0, new_data)
					#invisble line for plotting
					push!(traces, scatter(
						name = "invisible",			
						x = dr_v,
						y = cumulative_data,
						mode = "lines",
						fill = Nothing,
						line = attr(width = 0),
						showlegend = false,
						hoverinfo = "skip",
					)) 

					cumulative_data = cumulative_data .+ new_data
				
					#plot each technology
					push!(traces, scatter(;
						name = tech * " Exporting to Grid",
						x = dr_v,
						y = cumulative_data,
						mode = "lines",
						fill = "tonexty",
						line = attr(width=0, color = net_tech_color_dict[tech])
					))        
					
				else
					#donothing
				end
			end 
		end
	end

	if display_stats
        ###Plot Stats
        avg_val = round(mean(load),digits=0)
        max_val = round(maximum(load),digits=0)
        min_val = round(minimum(load),digits=0)

        x_stat = [first(dr_v),dr_v[end-100]]
        y_stat1 = [min_val,min_val]
        y_stat2 = [max_val,max_val]
        y_stat3 = [avg_val,avg_val]
        
        push!(traces, scatter(
        x = x_stat,
        y = y_stat1,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Min = $(min_val) kW"),
        text=[String("Min = $(min_val) kW")],
        textposition="top right",
		textfont = attr(size = 18, color = "red", family = "Arial", weight = "bold")
            )
        )

        push!(traces, scatter(
        x = x_stat,
        y = y_stat2,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Max = $(max_val) kW"),
        text=[String("Max = $(max_val) kW")],
        textposition="top right",
		textfont = attr(size = 18, color = "red", family = "Arial", weight = "bold")
            )
        )

        push!(traces, scatter(
        x = x_stat,
        y = y_stat3,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Avg = $(avg_val) kW"),
        text=[String("Avg = $(avg_val) kW")],
        textposition="top right",
		textfont = attr(size = 18, color = "red", family = "Arial", weight = "bold")
            )
        )
    end

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

	# ###Save data
	# # Initialize an empty DataFrame to store the data
	# data = DataFrame(name=String[], y=Vector{Float64}[])

	# # Loop over each trace and extract the data
	# for trace in traces
	# 	y = trace[:y]
	# 	name = trace[:name]
	# 	if name == "invisible"
	# 		println("")
	# 	else
	# 		# Append the data to the DataFrame
	# 		push!(data, (name=name, y=y))
	# 	end
	# end
	
	# CSV.write("dispatch_data_$title.csv", data, delim = '\t')

    plot(traces, layout)  # will not produce plot in a loop
end

function hours_since_start_of_year(date_string::String)
    # Parse the input date string into a DateTime object
    date_format = Dates.DateFormat("mm-dd-yyyy HH:MM")
    dt = Dates.DateTime(date_string, date_format)
    
    # Calculate the number of hours between the input date and the start of the year
    year_start = Dates.DateTime("01-01-2022 00:00", date_format)
    diff = dt - year_start
    hours = Dates.Hour(diff)
    
    return hours
end

hours_since_start_of_year("06-24-2022 17:00")

# Define site name
site = "BorgWarner"

# Define scenarios
scenarios = [
	("./scenarios/Storage_200kw_2hour.json", "BAU"),
    ("./scenarios/Storage_200kw_2hour.json", "Storage - 200 kw - 2 hour"),
    ("./scenarios/Storage_200kw_3hour.json", "Storage - 200 kw - 3 hour"),
    ("./scenarios/Storage_200kw_4hour.json", "Storage - 200 kw - 4 hour"),
    ("./scenarios/Storage_400kw_2hour.json", "Storage - 400 kw - 2 hour"),
	("./scenarios/Storage_400kw_2_5hour.json", "Storage - 400 kw - 2.5 hour"),
	("./scenarios/Storage_400kw_3hour.json", "Storage - 400 kw - 3 hour")
]

# Create results directtory if it doesn't exist
mkpath.(["./results/"])

# Run optimization and get results for each scenario
df_list         = []
results         = []
peaks_demand    = []

for (i, (scenario_file, scenario_name)) in enumerate(scenarios)
    m1, m2 = Model(Xpress.Optimizer), Model(Xpress.Optimizer)
    results_i = run_reopt([m1, m2], scenario_file)

    push!(peaks_demand, [scenario_name,collect(value.(m2[:dvPeakDemandMonth]))])

    df_i = get_data(results_i, scenario_name)
    push!(results, (results_i, df_i))
    
    # Add df_i to df_list
    push!(df_list, df_i)
    
    # Plot Electric Dispatch
    plot_electric_dispatch(results_i, title=joinpath("./results/", "$site - Scenario $i - $scenario_name"))
    
    # Simulate Outages and create outage plot
    outage = simulate_outages(results_i, REoptInputs(scenario_file))
    create_outage_plot(outage, joinpath("./results/", "Scenario-$i-$site-outage.html"))
    save_outage_dict_to_csv(outage, joinpath("./results/", "Case_$i-$site-outage.csv"))
end

# Combine results into final dataframe and write to CSV
final_df = vcat(df_list...)
final_df = permutedims(final_df, 1, makeunique=true) #Transpose
CSV.write(joinpath("./results/", "Results-$site.csv"), final_df, transform=(col, val) -> something(val, "-"))

# Plot Electric Dispatch for Statistics
plot_electric_dispatch(results[1][1], title=joinpath("./results/", "$site - Statistics"), display_stats=true)

