using RecipesBase


function Base.show(io::IO, mime::MIME"text/plain", x::BalancedPanel)
    println("Balanced Panel")
    println("    Number of units: $(x.N)")
    println("    Number of time periods: $(x.T)")
    println("    Number of treated units")
end

function 