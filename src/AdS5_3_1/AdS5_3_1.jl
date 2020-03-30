module AdS5_3_1

using Jecco
using Parameters

export ParamBase, ParamGrid, ParamID, ParamEvol, ParamIO
export Potential
export VV # this will contain the potential
export Inner, Outer, AbstractSystem, System
export BulkVars, BoundaryVars, GaugeVars

# Note: in the future we may promote this to something like BulkVars{Ng,T}, to
# dispatch on Ng (the type of equations to be solved on each grid)

# TODO: remove d*dt fields from this struct ?

struct BulkVars{T}
    B1     :: T
    B2     :: T
    G      :: T
    phi    :: T
    S      :: T
    Fx     :: T
    Fy     :: T
    B1d    :: T
    B2d    :: T
    Gd     :: T
    phid   :: T
    Sd     :: T
    A      :: T
    dB1dt  :: T
    dB2dt  :: T
    dGdt   :: T
    dphidt :: T
end

BulkVars(B1, B2, G, phi, S, Fx, Fy, B1d, B2d, Gd, phid, Sd, A, dB1dt, dB2dt,
         dGdt, dphidt) = BulkVars{typeof(B1)}(B1, B2, G, phi, S, Fx, Fy, B1d, B2d,
                                              Gd, phid, Sd, A, dB1dt, dB2dt, dGdt, dphidt)

function BulkVars(Nxx::Vararg)
    B1     = zeros(Nxx...)
    B2     = copy(B1)
    G      = copy(B1)
    phi    = copy(B1)
    S      = copy(B1)
    Fx     = copy(B1)
    Fy     = copy(B1)
    B1d    = copy(B1)
    B2d    = copy(B1)
    Gd     = copy(B1)
    phid   = copy(B1)
    Sd     = copy(B1)
    A      = copy(B1)
    dB1dt  = copy(B1)
    dB2dt  = copy(B1)
    dGdt   = copy(B1)
    dphidt = copy(B1)

    BulkVars{typeof(B1)}(B1, B2, G, phi, S, Fx, Fy, B1d, B2d, Gd, phid, Sd, A,
                         dB1dt, dB2dt,dGdt, dphidt)
end

function BulkVars(B1::Array{T,N}, B2::Array{T,N}, G::Array{T,N},
                  phi::Array{T,N}) where {T<:Number,N}
    S      = similar(B1)
    Fx     = similar(B1)
    Fy     = similar(B1)
    B1d    = similar(B1)
    B2d    = similar(B1)
    Gd     = similar(B1)
    phid   = similar(B1)
    Sd     = similar(B1)
    A      = similar(B1)
    dB1dt  = similar(B1)
    dB2dt  = similar(B1)
    dGdt   = similar(B1)
    dphidt = similar(B1)

    BulkVars{typeof(B1)}(B1, B2, G, phi, S, Fx, Fy, B1d, B2d, Gd, phid, Sd, A,
                         dB1dt, dB2dt,dGdt, dphidt)
end


struct GaugeVars{A,T}
    xi    :: A
    kappa :: T
end

function GaugeVars(xi::Array{T,N}, kappa::T) where {T<:Number,N}
    GaugeVars{typeof(xi), typeof(kappa)}(xi, kappa)
end


function setup(par_base)
    global VV = Potential(par_base)
end


struct BoundaryVars{T}
    a4   :: T
    fx2  :: T
    fy2  :: T
end


include("param.jl")
include("system.jl")
# include("initial_data.jl")
include("potential.jl")
# include("dphidt.jl")
include("equation_outer_coeff.jl")
include("solve_nested.jl")
# include("rhs.jl")
# include("run.jl")
# include("ibvp.jl")

end
