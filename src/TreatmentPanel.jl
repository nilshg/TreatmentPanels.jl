using DataFrames

# Abstract type for dispatch
abstract type TreatmentPanel end

# BalancedPanel will have an N×T matrix of treatment assigment and outcomes
struct BalancedPanel{NType, TType, YType} <: TreatmentPanel
    N::Int64
    T::Int64
    W::Union{Matrix{Bool}, Matrix{Union{Missing, Bool}}}
    ts::TType
    is::NType
    Y::Matrix{YType}
end

# Constructor based on DatFrame and treatment assignment in pairs
function BalancedPanel(df::DataFrame, id_var, t_var, outcome_var, 
    treatment_assignment::Vector{Pair{NType, TType}}; 
    sort_inplace = false) where NType where TType

    # Ensure columns exist in data
    f = in(names(df))
    f(string(id_var)) || throw("Error: ID variable $id_var is not present in the data.")
    f(string(t_var)) || throw("Error: Time variable $t_var is not present in the data.")
    f(string(outcome_var)) || throw("Error: ID variable $outcome_var is not present in the data.")

    # Get all units and time periods
    is = sort(unique(df[!, id_var])); i_set = Set(is)
    ts = sort(unique(df[!, t_var])); t_set = Set(ts)

    for tp ∈ treatment_assignment
    in(tp[1], i_set) || throw("Error: Treatment assignment $tp provided, but $(tp[1]) is not in the list of unit identifiers $id_var")
    in(tp[2], t_set) || throw("Error: Treatment assignment $tp provided, but $(tp[2]) is not in the list of time identifiers $t_var")
    end

    # Sort data if necessary, in place if required
    df = ifelse(issorted(df, [id_var, t_var]), df, 
            ifelse(sort_inplace, sort!(df, [id_var, t_var]), 
                                 sort(df, [id_var, t_var])))

    # Dimensions
    N = length(is)
    T = length(ts)

    # Treatment matrix
    W = [false for i ∈ 1:N, t ∈ 1:T]

    for tp ∈ treatment_assignment
        i_id = findfirst(==(tp[1]), is)
        t_id = findfirst(==(tp[2]), ts)
        W[i_id, t_id:end] .= true
    end

    # Outcome matrix
    Y = zeros(size(W))

    for (row, i) ∈ enumerate(is), (col, t) ∈ enumerate(ts)
        try
            Y[row, col] = only(df[(df[!, id_var] .== i) .& (df[!, t_var] .== t), outcome_var])
        catch ArgumentError
            throw("$(nrow(df[(df[!, id_var] .== i) .& (df[!, t_var] .== t), :])) outcomes present in the data for unit $i in period $t")
        end
    end

    BalancedPanel(N, T, W, ts, is, Y)    
end

# UnblaancedPanel - N observations but not all of them for T periods
struct UnbalancedPanel{NType, TType, YType} <: TreatmentPanel
    N::Int64
    T_max::Int64
    W::Union{Matrix{Bool}, Matrix{Union{Missing, Bool}}}
    ts::TType
    is::NType
    Y::Matrix{YType}
end