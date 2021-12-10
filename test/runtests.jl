using TreatmentPanels
using Test
using DataFrames, Dates

@testset "Input tests" begin
    test_df = DataFrame(id = ["a", "a", "b", "b"], period = [1, 2, 1, 2], value = 1.0:4.0)
    
    # Column not present in data
    @test_throws ArgumentError BalancedPanel(test_df, "a" => 2; id_var = :wrong_var, t_var = :period, outcome_var = :value)
    @test_throws ArgumentError BalancedPanel(test_df, "a" => 2; id_var = :id, t_var = :wrong_var, outcome_var = :value)
    @test_throws "" BalancedPanel(test_df, "a" => 2; id_var = :id, t_var = :period, outcome_var = :wrong_var)
    
    # Treatment assignment has nonexistent units/time periods
    @test_throws "" BalancedPanel(test_df, "c" => 2; id_var = :id, t_var = :period, outcome_var = :value)
end


@testset "Single unit, continuous treatment" begin
    int_treatment = "Single Treated Unit" => 5
    date_treatment = "Single Treated Unit" => Date(2004)

    single_continuous_data = DataFrame(
        name = [fill("Single Treated Unit", 8); fill("Untreated Unit 1", 8); fill("Untreated Unit 2", 8)], 
        period = repeat(1:8, 3), 
        year_period = repeat(Date(2000):Year(1):Date(2007), 3),
        outcome = vec([parse(Int, "$(i)$(t)") for t ∈ 1:8, i ∈ 1:3]))

    # Treatment specified as a single pair
    sc_bp_int = BalancedPanel(single_continuous_data, int_treatment;
        id_var = :name, t_var = :period, outcome_var = :outcome)
    @test sc_bp_int isa BalancedPanel{SingleUnitTreatment{Continuous}}
    # Treatment specified as a length one vector of pairs
    
    sc_bp_int2 = BalancedPanel(single_continuous_data, [int_treatment];
        id_var = :name, t_var = :period, outcome_var = :outcome) 
    @test sc_bp_int2 isa BalancedPanel{SingleUnitTreatment{Continuous}}
    
    # Year treatment
    sc_bp_year = BalancedPanel(single_continuous_data, date_treatment;
        id_var = :name, t_var = :year_period, outcome_var = :outcome) 
    @test sc_bp_year isa BalancedPanel{SingleUnitTreatment{Continuous}}
        
    # Utility functions
    y₁₀, y₁₁, y₀₀, y₀₁ = decompose_y(sc_bp_year)
    @test y₁₀ == [11.0, 12.0, 13.0, 14.0]
    @test y₁₁ == [15.0, 16.0, 17.0, 18.0]
    @test y₀₀ == [21.0 22.0 23.0 24.0
                  31.0 32.0 33.0 34.0]
    @test y₀₁ == [25.0 26.0 27.0 28.0
                  35.0 36.0 37.0 38.0]
    
    @test length_T₀(sc_bp_year) == 4
    @test length_T₁(sc_bp_year) == 4
    @test treated_ids(sc_bp_year) == 1
    @test treated_labels(sc_bp_year) == "Single Treated Unit"
    @test first_treated_period_ids(sc_bp_year) == 5
    @test first_treated_period_ids(sc_bp_int) == 5
    @test first_treated_period_labels(sc_bp_year) == Date(2004) 
end

@testset "Single unit, single time-limited treatment" begin
    treatment = "A" => Date(2000) => Date(2002)

    test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
        period = repeat(Date(2000):Year(1):Date(2009), 3), 
        value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    bp = BalancedPanel(test_df, treatment;
        id_var = :id, t_var = :period, outcome_var = :value)

    @test bp isa BalancedPanel{SingleUnitTreatment{Discontinuous}}

    #!# TO DO - test utility functions for this case
end

@testset "Single unit, multiple time-limited treatments" begin
    #!# TO DO
    #treatment = "A" => [Date(2000) => Date(2002), Date(2005) => Date(2007)]

    #test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
    #    period = repeat(Date(2000):Year(1):Date(2009), 3), 
    #    value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    #bp = BalancedPanel(test_df, treatment;
    #    id_var = :id, t_var = :period, outcome_var = :value)

    #@test bp isa BalancedPanel{SingleUnitTreatment, StartEndTreatment}
    @test true
end

@testset "Multiple units, continuous simultaneous treatment" begin
    treatment = ["A" => Date(2000), "B" => Date(2000)]
    
    test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
        period = repeat(Date(2000):Year(1):Date(2009), 3), 
        value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    bp = BalancedPanel(test_df, treatment;
        id_var = :id, t_var = :period, outcome_var = :value)
    
    @test bp isa BalancedPanel{MultiUnitTreatment{Simultaneous{Continuous}}}

    #!# TO DO - test utility functions for this case
end

@testset "Multiple units, continuous staggered treatment" begin
    treatment = ["A" => Date(2000), "B" => Date(2001)]

    test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
        period = repeat(Date(2000):Year(1):Date(2009), 3), 
        value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    bp = BalancedPanel(test_df, treatment;
        id_var = :id, t_var = :period, outcome_var = :value)

    @test bp isa BalancedPanel{MultiUnitTreatment{Staggered{Continuous}}}

    #!# TO DO - test utility functions for this case
end

#!# TO ADD - tests of plotting functionality