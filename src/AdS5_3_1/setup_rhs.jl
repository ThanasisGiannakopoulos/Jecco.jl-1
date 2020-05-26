
function setup_rhs(bulkconstrains::BulkPartition{Nsys}, systems::SystemPartition) where {Nsys}
    # function to solve the nested system
    solve_nested! = nested_solver(systems)

    function (ff_t::EvolVars, ff::EvolVars, evoleq::EvolutionEquations, t)
        bulkevols_t = getbulkevolvedpartition(ff_t)
        boundary_t  = getboundary(ff_t)
        gauge_t     = getgauge(ff_t)

        bulkevols   = getbulkevolvedpartition(ff)
        boundary    = getboundary(ff)
        gauge       = getgauge(ff)

        # TODO
        # compute_boundary_t!(boundary_t, bulkevols[1], boundary, gauge, systems[1], evoleq)

        # solve nested system for the constrained variables
        solve_nested!(bulkconstrains, bulkevols, boundary, gauge, evoleq)

        # TODO
        # compute_xi_t!(gauge_t, bulkconstrains[end], bulkevols[end], boundary, gauge, systems[end], evoleq)

        @inbounds for aa in 1:Nsys
            sys           = systems[aa]
            bulkevol_t    = bulkevols_t[aa]
            bulkevol      = bulkevols[aa]
            bulkconstrain = bulkconstrains[aa]

            # TODO
            # compute_bulkevolved_t!(bulkevol_t, bulkconstrain, bulkevol, boundary, gauge, sys, evoleq)
        end

        # TODO: sync_bulkevolved

        # TODO: add filtering here?

        nothing
    end
end