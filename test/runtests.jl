using TreatmentPanels
using Test
using DataFrames

@testset "Input tests" begin
    test_df = DataFrame(id = ["a", "a", "b", "b"], period = [1, 2, 1, 2], value = 1.0:4.0)
    
    # Basic functionality
    @test BalancedPanel(test_df, ["a" => 2];
        id_var = :id, t_var = :period, outcome_var = :value) isa BalancedPanel{SingleUnitTreatment, ContinuousTreatment}
    @test BalancedPanel(test_df, "a" => 2;
        id_var = :id, t_var = :period, outcome_var = :value) isa BalancedPanel{SingleUnitTreatment, ContinuousTreatment}
    
    # Column not present in data
    @test_throws "" BalancedPanel(test_df, "a" => 2; id_var = :wrong_var, t_var = :period, outcome_var = :value)
    @test_throws "" BalancedPanel(test_df, "a" => 2; id_var = :id, t_var = :wrong_var, outcome_var = :value)
    @test_throws "" BalancedPanel(test_df, "a" => 2; id_var = :id, t_var = :period, outcome_var = :wrong_var)
    
    # Treatment assignment has nonexistent units/time periods
    @test_throws "" BalancedPanel(test_df, "c" => 2; id_var = :id, t_var = :period, outcome_var = :value)
end
