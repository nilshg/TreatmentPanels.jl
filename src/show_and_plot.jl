using RecipesBase

# Custom show methods
function Base.show(io::IO, mime::MIME"text/plain", x::BalancedPanel{SingleUnitTreatment, ContinuousTreatment})
    println("Balanced Panel - single unit, single continuous treatment")
    println("    Treated unit: $(treated_labels(x))")
    println("    Number of untreated units: $(x.N - 1)")
    println("    First treatment period: $(first_treated_period_labels(x))")
    println("    Number of pretreatment periods: $(length_T₀(x))")
    println("    Number of treatment periods: $(length_T₁(x))")
end


# Plotting recipe
@recipe function f(bp::BalancedPanel; kind = "treatment")

    xguide := "Period"
    xticks --> bp.ts

    if kind == "treatment"
        
        legend --> :none
        yguide := "Unit"
        yticks --> (1:bp.N, bp.is)

        @series begin
            seriestype := :heatmap
            x := bp.W
        end
        
        #!# TO FIX - the xticks aren't displayed
        xticks := (1:bp.T, bp.ts)

    elseif kind == "outcome"
        
        yguide := "Outcome value"

        for i ∈ 1:bp.N

            if in(treated_ids(bp))(i)
                @series begin 
                    label --> bp.is[i]
                    color --> i
                    bp.ts[1:findfirst(bp.W[i, :])], bp.Y[i, 1:findfirst(bp.W[i, :])]
                end

                @series begin
                    seriestype := :scatter
                    color --> i 
                    markersize --> 7
                    label --> ""
                    [bp.ts[findfirst(bp.W[i, :])]], [bp.Y[i, findfirst(bp.W[i, :])]]
                end

                @series begin
                    label --> ""
                    color --> i
                    alpha --> 0.5
                    #linestyle --> :dash
                    bp.ts[findfirst(bp.W[i, :]):end], bp.Y[i, findfirst(bp.W[i, :]):end]
                end
            else 
                @series begin
                    label --> bp.is[i]
                    color --> i
                    bp.ts, bp.Y[i, :]
                end 
            end
        end
    end
        
    nothing
end