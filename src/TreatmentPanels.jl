module TreatmentPanels

include("TreatmentPanel.jl")
include("show_and_plot.jl")

# Export main types
export TreatmentPanel
export BalancedPanel 
# export UnbalancedPanel - Not yet implemented

# Export treatment description types
export TreatmentType
export SingleUnitTreatment, MultiUnitTreatment
export TreatmentTimingType
export Staggered, Simultaneous
export TreatmentDurationType 
export Continuous, Discontinuous

# Export utility functions
export treated_ids, treated_labels, first_treated_period_ids, first_treated_period_labels, length_T₀, length_T₁
export get_y₀₀, get_y₀₁, get_y₁₀, get_y₁₁, decompose_y

end
