using Aqua

@testset "Aqua.jl" begin
    Aqua.test_ambiguities(TreatmentPanels)
    Aqua.test_unbound_args(TreatmentPanels)
    Aqua.test_undefined_exports(TreatmentPanels)
    Aqua.test_project_extras(TreatmentPanels)
    Aqua.test_stale_deps(TreatmentPanels)
    Aqua.test_deps_compat(TreatmentPanels)
    Aqua.test_piracies(TreatmentPanels)
    Aqua.test_persistent_tasks(TreatmentPanels)
end