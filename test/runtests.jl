using TreatmentPanels
using Test

@testset "Input tests" begin
    test_df = DataFrame(id = ['a', 'a', 'b', 'b'], period = [1, 2, 1, 2], value = 1.0:4.0)
    
    # Basic functionality
    @test BalancedPanel(test_df, :id, :period, :value, ['a' => 2]) isa BalancedPanel
    
    # Column not present in data
    @test_throws "" BalancedPanel(test_df, :wrong_var, :period, :value, ['a'=> 2])
    @test_throws "" BalancedPanel(test_df, :id, :wrong_var, :value, ['a' => 2])
    @test_throws "" BalancedPanel(test_df, :id, :period, :wrong_var, ['a' => 2])
    
    # Treatment assignment has nonexistent units/time periods
    @test_throws "" BalancedPanel(test_df, :id, :period, :value, ['c' => 2])
end
