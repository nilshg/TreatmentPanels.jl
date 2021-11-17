module TreatmentPanels

include("TreatmentPanel.jl")
include("show_and_plot.jl")

# Export main types
export TreatmentPanel
export BalancedPanel, UnbalancedPanel

# Export treatment description types
export UnitTreatmentType
export SingleUnitTreatment, MultiUnitSimultaneousTreatment, MultiUnitStaggeredTreatment
export TreatmentDurationType 
export ContinuousTreatment, StartEndTreatment

# Export utility functions
export treated_ids, treated_labels, first_treated_period_ids, first_treated_period_labels, length_T₀, length_T₁

end
