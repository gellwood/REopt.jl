using Revise, Xpress, JuMP, REopt, CSV, PlotlyJS, DataFrames, Statistics, Dates, JSON3, JSON, Serialization

include("../reopt_getdata.jl")
include("../reopt_plotting.jl")
include("../reopt_runscenarios.jl")
include("../reopt_groupedbarplot.jl")

# Specify folder path to the scenarios
path =   @__DIR__

# =======================================================================================================   
# =========================== PRIMARY INPUTS ===========================
# =======================================================================================================   

rerun_scenarios                         =   false  # Set to false if you want to load saved results
site                                    =   "GTEC" # Site that you are analyzing
data                                    =   JSON.parsefile(joinpath(path, "all_runs.json")) #JSON path to scenario definitions

# =======================================================================================================   
# ===========================   Step 1: Define Site and Scenarios ===========================  
# =======================================================================================================   

site_data                               =   data[site]
all_scenarios                           =   Dict{String, Vector{Tuple{String, String}}}()

for (case, scenarios) in site_data
    converted_scenarios =   Vector{Tuple{String, String}}()
    for scenario in scenarios
        absolute_scenario_path = joinpath(path, scenario[1])
        push!(converted_scenarios, (absolute_scenario_path, scenario[2]))
    end
    all_scenarios[case] =   converted_scenarios
end

# =======================================================================================================   
# ===========================   Step 2: Run REopt ===========================   
# =======================================================================================================   

# Initialize variables to hold results
reoptsim_results =   []
results          =   []


# Results directory relative to base path   
results_dir      =   joinpath(path, "$site/results")

# Ensure the results directory exists
mkpath(results_dir)

if rerun_scenarios
    all_results =   Dict()
    for (case, scenarios) in all_scenarios
        println("===========================Running scenarios for $site - Case $case===========================")
        reoptsim_results, results =   run_and_get_results(scenarios, case, results_dir)
        all_results[case]         =   (reoptsim_results, results)
    end
else
    all_results =   Dict()
    for case in keys(all_scenarios)
        println("===========================Loading Results for $site - Case $case===========================")
        reoptsim_results  =   deserialize(open(joinpath(results_dir, "$case-reopt_results.bin"), "r"))
        results           =   deserialize(open(joinpath(results_dir, "$case-results.bin"), "r"))
        all_results[case] =   (reoptsim_results, results)
    end
end

# =======================================================================================================   
# ===========================   Step 3: Process Results ===========================   
# =======================================================================================================   

for (case, scenarios) in all_scenarios  # Changed from all_scenarios
    reoptsim_results, results =   all_results[case]

    # curr_gen_size = reoptsim_results[1]["Generator"]["size_kw"]
    curr_gen_size = get(reoptsim_results[1], "Generator", Dict("size_kw" => 0))["size_kw"]
    # println(curr_gen_size)
    println("===========================Processing results for $site - Case $case===========================")
    post_process_results(site, scenarios, reoptsim_results, results, case, results_dir,curr_gen_size)
end

# # =======================================================================================================   
# # ===========================   Step 4: Get Pretty Plots ===========================   
# # =======================================================================================================   

# Define the columns and scenarios you are interested in
columns = OrderedDict(
    "Battery(kW)"       =>   3,
    "Battery(kWh)"      =>   4,
    "PV(kW)"            =>   2,
    "Current Gen.(kW)"  =>   5,
    "Add-on Gen.(kW)"   =>   6,
    "Net Present Value"  =>   25,
    "Payback Period"     =>   27,
    "Emission Reduction" =>   12,
    "Capital Cost"       =>   7
)

selected_scenarios =   [2, 3, 4, 5]

# Now you can loop through all your cases and plot the charts
for (case, scenarios) in all_scenarios  # Changed from all_scenarios
    # Call the plot function for each case
    println("===========================Plotting charts for $site - Case $case===========================")

    plot_bar_charts(path, site, columns, selected_scenarios, case)
end




# """
# ### Port Arthur REopt Analysis
# * Case 0: BAU
# * Case 1: Cost-Optimal Standalone PV
# * Case 2: Cost-Optimal PV + Storage
# * Case 3: Resilience PV + Storage + Generator
# * Case 4: Resilience PV + Storage + Generator - VLL + Isolated Grid Cost

# GTEC 
# GTEC =   5966, 6302, 6446

# LSC
# PP  =   6300, 6182
# CC  =   6300, 6182
# MM  =   302,  1239
# CAP =   302,  7311


# PAISD
# TJ    =   6783, 7258
# WASH  =   5629, 5823
# Wheat =   6300, 6182


# PAT
# TERM  =   5196, 5628
# ADMIN =   4455, 4767
# MAINT =   4455, 4622
# HO    =   3927, 5583
# FUEL  =   3929, 4193

# #Site Name
# # s_name =   "PAT"
# # b_name =   ["TERM","ADMIN","MAINT","HO","FUEL"]
# # label  =   ["A","B","C","D","E"]

# # Inside the Building
# # The NFPA 30 often limits the storage of flammable or combustible liquids to 120 gallons inside a building.
# # Approximate Space Needed: It's hard to define an exact square footage, but for a 120-gallon tank and its associated safety features (like spill containment and fire suppression), you might need a dedicated space that is at least 8x8 feet (64 sq ft) as a very rough estimate. This doesn't include space for aisles, accessibility, and other equipment.

# # Outside the Building
# # For outside, above-ground storage, NFPA and EPA often limit the aggregate capacity to 1,320 gallons.
# # Approximate Space Needed: Above-ground tanks with a total capacity of 1,320 gallons might require a dedicated space of at least 20x20 feet (400 sq ft) as a rough estimate. This should include space for secondary containment, safety barriers, and access for maintenance and refueling.
# # The Spill Prevention, Control, and Countermeasure (SPCC) rule requires facility owners or operators with more than 1,320 gallons of above-ground oil storage capacity or 42,000 gallons of underground oil storage capacity to have a written plan that addresses how the facility will prevent oil spills to navigable waters and adjoining shorelines.
# # An owner/operator must prepare an SPCC Plan if the facility, due to its location could reasonable be expected to discharge oil into or upon a navigable water or adjoining shorelines, is a non-transportation related facility, and the facility exceeds a threshold capacity.  
# # For Spill Prevention, Control, and Countermeasure (SPCC) applicability, only containers of 55 gallons or greater need to be considered toward a facility's oil storage capacity (67 FR 47042, 47066; July 17, 2002).  The 55-gallon minimum capacity also applies to oil-filled operating, manufacturing, or electrical equipment, such as transformers.  
# # Therefore, when determining if a facility meets the oil storage capacity threshold, an owner or operator must only consider oil-filled operating equipment that can contain 55 gallons or more of oil (40 CFR §112.1(d)(2)(ii)).
# """ 