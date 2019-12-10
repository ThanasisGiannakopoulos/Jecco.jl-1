
using LinearAlgebra

function solve_lin_system!(sol, A_mat, b_vec)
    A_fact = lu!(A_mat)
    ldiv!(A_fact, b_vec)
    sol .= b_vec
    nothing
end

struct Nested{S,D,T<:Real}
    sys     :: S
    uu      :: Vector{T}
    xx      :: Vector{T}
    yy      :: Vector{T}
    Du_phi  :: D
    Dxx_phi :: D
    Dyy_phi :: D
    Du_phid :: D
    A_mat   :: Matrix{T}
    b_vec   :: Vector{T}
    vars    :: AllVars{T}
end
function Nested(sys::System)
    coords = sys.coords

    uu, xx, yy = Vivi.xx(coords)
    Nu = length(uu)
    Nx = length(xx)
    Ny = length(yy)

    Du_phi    = zeros(Nu, Nx, Ny)
    Dxx_phi   = zeros(Nu, Nx, Ny)
    Dyy_phi   = zeros(Nu, Nx, Ny)
    Du_phid   = zeros(Nu, Nx, Ny)

    A_mat = zeros(Nu, Nu)
    b_vec = zeros(Nu)
    vars  = AllVars{eltype(A_mat)}()

    Nested{typeof(sys), typeof(Du_phi),
           eltype(A_mat)}(sys, uu, xx, yy, Du_phi, Dxx_phi, Dyy_phi, Du_phid,
                          A_mat, b_vec, vars)
end

Nested(systems::Vector) = [Nested(sys) for sys in systems]


function solve_nested_g1!(bulk::BulkVars, BC::BulkVars, nested::Nested)
    sys  = nested.sys
    uu   = nested.uu
    xx   = nested.xx
    yy   = nested.yy

    Du_phi  = nested.Du_phi
    Dxx_phi = nested.Dxx_phi
    Dyy_phi = nested.Dyy_phi
    Du_phid = nested.Du_phid

    A_mat   = nested.A_mat
    b_vec   = nested.b_vec
    vars    = nested.vars

    uderiv = sys.uderiv
    xderiv = sys.xderiv
    yderiv = sys.yderiv

    Vivi.D!(Du_phi, bulk.phi, uderiv, 1)
    Vivi.D2!(Dxx_phi, bulk.phi, xderiv, 2)
    Vivi.D2!(Dyy_phi, bulk.phi, yderiv, 3)

    ABCS  = zeros(4)

    # set Sd
    @fastmath @inbounds for j in eachindex(yy)
        @fastmath @inbounds for i in eachindex(xx)
            @fastmath @inbounds @simd for a in eachindex(uu)
                bulk.Sd[a,i,j] = BC.Sd[i,j]
            end
        end
    end


    # solve for phidg1

    # TODO: parallelize here
    @fastmath @inbounds for j in eachindex(yy)
        @fastmath @inbounds for i in eachindex(xx)

            @fastmath @inbounds @simd for a in eachindex(uu)
                vars.u       = uu[a]
                vars.Sd_d0   = bulk.Sd[a,i,j]
                vars.phi_d0  = bulk.phi[a,i,j]
                vars.phi_du  = Du_phi[a,i,j]
                vars.phi_dxx = Dxx_phi[a,i,j]
                vars.phi_dyy = Dyy_phi[a,i,j]

                phig1_eq_coeff!(ABCS, vars)

                b_vec[a]     = -ABCS[4]

                @inbounds @simd for aa in eachindex(uu)
                    A_mat[a,aa] = ABCS[1] * uderiv.D2[a,aa] + ABCS[2] * uderiv.D[a,aa]
                end
                A_mat[a,a] += ABCS[3]
            end

            # boundary condition
            b_vec[1]    = BC.phid[i,j]
            A_mat[1,:] .= 0.0
            A_mat[1,1]  = 1.0

            sol = view(bulk.phid, :, i, j)
            solve_lin_system!(sol, A_mat, b_vec)
        end
    end


    # set Ag1
    @fastmath @inbounds for j in eachindex(yy)
        @fastmath @inbounds for i in eachindex(xx)
            @fastmath @inbounds @simd for a in eachindex(uu)
                bulk.A[a,i,j] = BC.A[i,j]
            end
        end
    end


    # finally compute dphidt_g1

    Vivi.D!(Du_phid, bulk.phid, uderiv, 1)

    # TODO: parallelize here
    @fastmath @inbounds for j in eachindex(yy)
        @inbounds for i in eachindex(xx)
            @inbounds @simd for a in eachindex(uu)
                vars.u       = uu[a]

                vars.phi_d0  = bulk.phi[a,i,j]
                vars.phid_d0 = bulk.phid[a,i,j]
                vars.A_d0    = bulk.A[a,i,j]

                vars.phi_du  = Du_phi[a,i,j]
                vars.phid_du = Du_phid[a,i,j]

                if vars.u > 1.e-9
                    bulk.dphidt[a,i,j]  = dphig1dt(vars)
                else
                    bulk.dphidt[a,i,j]  = dphig1dt_u0(vars)
                end
            end
        end
    end

    nothing
end


function solve_nested_g1!(bulk::BulkVars, BC::BulkVars, boundary::BoundaryVars,
                          nested::Nested)
    # u=0 boundary
    BC.Sd   .= 0.5 * boundary.a4
    BC.phid .= bulk.phi[1,:,:] # phi2
    BC.A    .= boundary.a4

    solve_nested_g1!(bulk, BC, nested)

    nothing
end

function solve_nested_g1!(bulks::Vector, BCs::Vector, boundary::BoundaryVars,
                          nesteds::Vector)
    Nsys = length(nesteds)

    # u=0 boundary
    BCs[1].Sd   .= 0.5 * boundary.a4
    BCs[1].phid .= bulks[1].phi[1,:,:] # phi2
    BCs[1].A    .= boundary.a4

    for i in 1:Nsys-1
        solve_nested_g1!(bulks[i], BCs[i], nesteds[i])
        BCs[i+1] = bulks[i][end,:,:]
    end
    solve_nested_g1!(bulks[Nsys], BCs[Nsys], nesteds[Nsys])

    # sync boundary points. note: in a more general situation we may need to
    # check the characteristic speeds (in this case we just know where the
    # horizon is)
    for i in 1:Nsys-1
        bulks[i].dphidt[end,:,:] .= bulks[i+1].dphidt[1,:,:]
    end

    nothing
end


function solve_nested_g1(phi::Array{<:Number,N}, sys::System) where {N}
    a4 = -ones2D(sys)
    boundary = BoundaryVars(a4)

    bulk = BulkVars(phi)
    BC = bulk[1,:,:]

    nested = Nested(sys)

    solve_nested_g1!(bulk, BC, boundary, nested)
    bulk
end

function solve_nested_g1(phis::Vector, systems::Vector)
    a4 = -ones2D(systems[1])
    boundary = BoundaryVars(a4)

    bulks = BulkVars(phis)
    phis_slice  = [phi[1,:,:] for phi in phis]
    BCs  = BulkVars(phis_slice)

    Nsys    = length(systems)
    nesteds = Nested(systems)

    solve_nested_g1!(bulks, BCs, boundary, nesteds)
    bulks
end
