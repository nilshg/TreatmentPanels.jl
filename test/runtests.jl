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
    int_treatment = "a" => 2
    date_treatment = "a" => Date(2001)

    test_df = DataFrame(id = ["a", "a", "b", "b"], 
        int_period = [1, 2, 1, 2], date_period = [Date(2000), Date(2001), Date(2000), Date(2001)],
        value = 1.0:4.0)

    # Treatment specified as a single pair
    @test BalancedPanel(test_df, int_treatment;
        id_var = :id, t_var = :int_period, outcome_var = :value) isa BalancedPanel{SingleUnitTreatment, ContinuousTreatment}
    # Treatment specified as a length one vector of pairs
    @test BalancedPanel(test_df, [int_treatment];
        id_var = :id, t_var = :int_period, outcome_var = :value) isa BalancedPanel{SingleUnitTreatment, ContinuousTreatment}
        
    # Year treatment
    @test BalancedPanel(test_df, date_treatment;
        id_var = :id, t_var = :date_period, outcome_var = :value) isa BalancedPanel{SingleUnitTreatment, ContinuousTreatment}
end

@testset "Single unit, single time-limited treatment" begin
    treatment = "A" => Date(2000) => Date(2002)

    test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
        period = repeat(Date(2000):Year(1):Date(2009), 3), 
        value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    bp = BalancedPanel(test_df, treatment;
        id_var = :id, t_var = :period, outcome_var = :value)

    @test bp isa BalancedPanel{SingleUnitTreatment, StartEndTreatment}
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
    
    @test bp isa BalancedPanel{MultiUnitSimultaneousTreatment, ContinuousTreatment}
end

@testset "Multiple units, continuous staggered treatment" begin
    treatment = ["A" => Date(2000), "B" => Date(2001)]

    test_df = DataFrame(id = repeat(["A", "B", "C"], inner = 10), 
        period = repeat(Date(2000):Year(1):Date(2009), 3), 
        value = [collect(1:10); collect(2:11); collect(1.5:10.5)])

    bp = BalancedPanel(test_df, treatment;
        id_var = :id, t_var = :period, outcome_var = :value)

    @test bp isa BalancedPanel{MultiUnitStaggeredTreatment, ContinuousTreatment}
end

#!# TO ADD - tests of plotting functionality