using DataFrames, Dates, Parameters

# Abstract type for dispatch
abstract type TreatmentPanel end

# Types for number of treatment units and periods
abstract type UnitTreatmentType end
abstract type TreatmentDurationType end
struct SingleUnitTreatment <: UnitTreatmentType end 
struct MultiUnitSimultaneousTreatment <: UnitTreatmentType end 
struct MultiUnitStaggeredTreatment <: UnitTreatmentType end 
struct ContinuousTreatment <: TreatmentDurationType end 
struct StartEndTreatment <: TreatmentDurationType end 

# BalancedPanel will have an N×T matrix of treatment assigment and outcomes
"""
    BalancedPanel{UnitTreatmentType, TreatmentDurationType}

A TreatmentPanel in which all N treatment units are observed for the same T periods.

The object is constructed from a `DataFrame` which contains all outcome and covariate data. The 
constructor requires passing information on which column in the `DataFrame` holds the subject and 
time period identifiers, as well as information on the timing of treatment. Treatments are specified
as a `Pair` of either a `String` or `Symbol` identifying the unit treated, and a `Date` or
`Int` value, identifying the treatment period. Where treatments have an end point, the
treatment period os specified as a `Tuple` of either `Date` or `Int`, indicating the first
and last period of treatment. Where individual units have multiple treatment periods,
these are specified as a `Pair{Union{String, Symbol}, Vector{Union{Int, Date}}}` of treatment
unit identifier and vector of timings. Finally, single continuous, single periodic, and
multiple period treatments can be generalized to multiple treated units.
The following table provides an overview of the types of treatment pattern supported:


|                     |  Only starting point        |   Start and end point                     |   Multiple start & end points                       |
|---------------------|-----------------------------|-------------------------------------------|-----------------------------------------------------|
| **one unit**        |  Pair{String, Date}         |   Pair{String, Tuple{Date, Date}}         |  Pair{String}, Vector{Tuple{Date, Date}}}           |
| **multiple units**  |  Vector{Pair{String, Date}} |   Vector{Pair{String, Tuple{Date, Date}}} |  Vector{Pair{String}, Vector{Tuple{Date, Date}}}}   |
"""
@with_kw struct BalancedPanel{UTType, TDType} <: TreatmentPanel where UTType <: UnitTreatmentType where TDType <: TreatmentDurationType
    N::Int64
    T::Int64
    W::Union{Matrix{Bool}, Matrix{Union{Missing, Bool}}}
    ts::Vector{T1} where T1 <: Union{Date, Int64}
    is::Vector{T2} where T2 <: Union{Symbol, String, Int64}
    Y::Matrix{Float64}
end

# Check that ID, time, and outcome variable are provided
function check_id_t_outcome(df, outcome_var, id_var, t_var)
    # Check relevant info has been provided
    !isnothing(outcome_var) || error(ArgumentError(
        "Please specify outcome_var, the name of the column in your dataset holding the "*
        "outcome variable of interest in your dataset."
        ))
    !isnothing(id_var) || error(ArgumentError(
            "Please specify id_var, the name of the column in your data set holding the "*
            "identifier of your units of observation (panel dimension)."
            ))
    !isnothing(t_var) || error(ArgumentError(
            "Please specify t_var, the name of the column in your dataset holding the "*
            "time dimension."
        ))

    # Ensure columns exist in data
    f = in(names(df))
    f(string(id_var)) || throw("Error: ID variable $id_var is not present in the data.")
    f(string(t_var)) || throw("Error: Time variable $t_var is not present in the data.")
    f(string(outcome_var)) || throw("Error: ID variable $outcome_var is not present in the data.")
end

# Functions to get all treatment periods
function treatment_periods(ta::Pair{T1, S1}) where T1 where S1
    [last(ta)]
end

function treatment_periods(ta::Pair{T1, S1}) where T1 where S1 <: Union{Pair{Int, Int}, Pair{Date, Date}}
    collect(last(ta))
end

function treatment_periods(ta::Vector{Pair{T1, S1}}) where T1 where S1
    last.(ta)
end

function treatment_periods(ta::Vector{Pair{T1, S1}}) where T1 where S1 <: Union{Pair{Int, Int}, Pair{Date, Date}}
    unique(reduce(vcat, collect.(last.(ta))))
end

# Functions to construct treatment assignment matrix
function construct_W(ta::Pair{T1, S1}, N, T, is, ts) where T1 where S1
    W = [false for i = 1:N, j = 1:T]
    W[findfirst(==(ta[1]), is), findfirst(==(ta[2]), ts):end] .= true

    return W
end

function construct_W(ta::Pair{T1, S1}, N, T, is, ts) where T1 where S1 <: Union{Pair{Int, Int}, Pair{Date, Date}}
    W = [false for i = 1:N, j = 1:T]
    W[findfirst(==(ta[1]), is), findfirst(==(ta[2][1]), ts):findfirst(==(ta[2][2]), ts)] .= true

    return W
end

function construct_W(tas::Vector{Pair{T1, S1}}, N, T, is, ts) where T1 where S1
    W = [false for i = 1:N, j = 1:T]
    for ta ∈ tas
        W[findfirst(==(ta[1]), is), findfirst(==(ta[2]), ts):end] .= true
    end

    return W
end

function construct_W(tas::Vector{Pair{T1, S1}}, N, T, is, ts) where T1 where S1 <: Union{Pair{Int, Int}, Pair{Date, Date}}
    W = [false for i = 1:N, j = 1:T]
    for ta ∈ tas
        W[findfirst(==(ta[1]), is), findfirst(==(ta[2][1]), ts):findfirst(==(ta[2][2]), ts)] .= true
    end

    return W
end

# Constructor based on DatFrame and treatment assignment in pairs
function BalancedPanel(df::DataFrame, treatment_assignment; 
    id_var = nothing, t_var = nothing, outcome_var = nothing,  
    sort_inplace = false) where NType where TType

    # Get all units and time periods
    is = sort(unique(df[!, id_var])); i_set = Set(is)
    ts = sort(unique(df[!, t_var])); t_set = Set(ts)

    # Get all treatment units and treatment periods
    treated_is = first.(treatment_assignment)
    treated_is = typeof(treated_is) <: AbstractArray ? treated_is : [treated_is]
    treated_ts = treatment_periods(treatment_assignment)

    # Dimensions
    N = length(is)
    T = length(ts)

    ### SANITY CHECKS ###
    check_id_t_outcome(df, outcome_var, id_var, t_var)
    for ti ∈ treated_is
        in(ti, i_set) || throw("Error: Treatment unit $ti is not in the list of unit identifiers $id_var")
    end

    for tt ∈ treated_ts
        in(tt, t_set) || throw("Error: Treatment period $tt is not in the list of time identifiers $t_var")
    end
    
    # Sort data if necessary, in place if required
    df = ifelse(issorted(df, [id_var, t_var]), df, 
                                               ifelse(sort_inplace, sort!(df, [id_var, t_var]), 
                                                                    sort(df, [id_var, t_var])))

    # Treatment matrix
    W = construct_W(treatment_assignment, N, T, is, ts)
    
    # Outcome matrix
    Y = zeros(size(W))
    for (row, i) ∈ enumerate(is), (col, t) ∈ enumerate(ts)
        try
            Y[row, col] = only(df[(df[!, id_var] .== i) .& (df[!, t_var] .== t), outcome_var])
        catch ArgumentError
            throw("$(nrow(df[(df[!, id_var] .== i) .& (df[!, t_var] .== t), :])) outcomes present in the data for unit $i in period $t")
        end
    end

    # Determine UnitTreatmentType and TreatmentDurationType
    uttype = if length(treated_is) == 1
        SingleUnitTreatment
    else
        if all(==(treatment_assignment[1][2]), last.(treatment_assignment))
            MultiUnitSimultaneousTreatment
        else
            MultiUnitStaggeredTreatment
        end
    end

    tdtype = if typeof(treatment_assignment) <: Pair
        if typeof(treatment_assignment[2]) <: Pair
            StartEndTreatment
        else
            ContinuousTreatment
        end
    else
        if typeof(treatment_assignment[1][2]) <: Pair
            StartEndTreatment
        else
            ContinuousTreatment
        end
    end

    BalancedPanel{uttype, tdtype}(N, T, W, ts, is, Y)    
end

## UnblancedPanel - N observations but not all of them for T periods

#!# Not yet implemented

## Utility functions
function treated_ids(x::BalancedPanel)
    any.(eachrow(x.W))
end

function treated_labels(x::BalancedPanel)
    x.is[treated_ids(x)]
end

function first_treated_period_ids(x::BalancedPanel)
    findfirst.(eachrow(x.W[treated_ids(x), :]))
end

function first_treated_period_labels(x::BalancedPanel)
    x.ts[first_treated_period_ids(x)]
end

function length_T₀(x::BalancedPanel)
    first_treated_period_ids(x) .- 1
end

function length_T₁(x::BalancedPanel)
    x.T .- first_treated_period_ids(x) .+ 1
end