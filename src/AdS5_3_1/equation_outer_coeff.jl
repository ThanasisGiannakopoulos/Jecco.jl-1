
# Vf(phi)  = VV(phi)
# Vfp(phi) = ∂(VV)(phi)

# FIXME
V(phi) = -3.0
Vp(phi) = 0.0


#= Notation

for any function f we're using the following notation (let _x denote partial
derivative with respect to x)

fp  = f_r = -u^2 f_u
fd  = \dot f
ft  = \tilde f = f_x - Fx f_r
fh  = \hat f   = f_y - Fy f_r

=#

mutable struct AllVarsOuter{T}
    u        :: T

    B1       :: T
    B1p      :: T
    B1t      :: T
    B1h      :: T
    B1tt     :: T
    B1hh     :: T
    B1tp     :: T
    B1hp     :: T

    B2       :: T
    B2p      :: T
    B2t      :: T
    B2h      :: T
    B2tt     :: T
    B2hh     :: T
    B2tp     :: T
    B2hp     :: T

    G        :: T
    Gp       :: T
    Gt       :: T
    Gh       :: T
    Gtt      :: T
    Ghh      :: T
    Gtp      :: T
    Ghp      :: T

    phi      :: T
    phip     :: T
    phit     :: T
    phih     :: T
    phitt    :: T
    phihh    :: T
    phitp    :: T
    phihp    :: T

    S        :: T
    Sp       :: T
    St       :: T
    Sh       :: T
    Stt      :: T
    Shh      :: T
    Stp      :: T
    Shp      :: T

    Fx       :: T
    Fxp      :: T
    Fxt      :: T
    Fxh      :: T
    Fxtt     :: T
    Fxhh     :: T
    Fxtp     :: T
    Fxhp     :: T

    Fy       :: T
    Fyp      :: T
    Fyt      :: T
    Fyh      :: T
    Fytt     :: T
    Fyhh     :: T
    Fytp     :: T
    Fyhp     :: T

    Sd       :: T
    B1d      :: T
    B2d      :: T
    Gd       :: T
    phid     :: T

    B2th     :: T
    Gth      :: T
    Sth      :: T
    phith    :: T
end
function AllVarsOuter{T}() where {T<:AbstractFloat}
    N = 1 + 8*7 + 5 + 4
    array = zeros(N)
    AllVarsOuter{T}(array...)
end


#= Notation

for any function f we're using the following convention: _x denotes partial
derivative with respect to x and

fp  = f_r  = -u^2 f_u
fpp = f_rr = 2u^3 f_u + u^4 f_uu

=#

mutable struct FxyVars{T}
    u        :: T

    B1       :: T
    B1p      :: T
    B1_x     :: T
    B1_y     :: T
    B1pp     :: T
    B1p_x    :: T
    B1p_y    :: T

    B2       :: T
    B2p      :: T
    B2_x     :: T
    B2_y     :: T
    B2pp     :: T
    B2p_x    :: T
    B2p_y    :: T

    G        :: T
    Gp       :: T
    Gpp      :: T
    G_x      :: T
    G_y      :: T
    Gp_x     :: T
    Gp_y     :: T

    phi      :: T
    phip     :: T
    phi_x    :: T
    phi_y    :: T

    S        :: T
    Sp       :: T
    S_x      :: T
    S_y      :: T
    Spp      :: T
    Sp_x     :: T
    Sp_y     :: T
end
function FxyVars{T}() where {T<:AbstractFloat}
    N = 1 + 4*7 + 4
    array = zeros(N)
    FxyVars{T}(array...)
end


# assuming
# (A d_uu + B d_u + C Id) f = -S

function S_outer_eq_coeff!(ABCS::Vector, vars::AllVarsOuter)
    u   = vars.u

    B1p  = vars.B1p
    B2p  = vars.B2p

    G   = vars.G
    Gp  = vars.Gp

    phip = vars.phip

    ABCS[1] = *(6, u ^ 4)
    ABCS[2] = *(12, u ^ 3)
    ABCS[3] = Gp ^ 2 + *(3, B2p ^ 2) + *(4, phip ^ 2) + *(B1p ^ 2, cosh(G) ^ 2)
    ABCS[4] = 0

    nothing
end


# this is a coupled equation for Fx and Fy. the notation used is
#
# ( A11 d_uu Fx + A12 d_uu Fy + B11 d_u Fx + B12 d_u Fy + C11 Fx + C12 Fy ) = -S1
# ( A21 d_uu Fx + A22 d_uu Fy + B21 d_u Fx + B22 d_u Fy + C21 Fx + C22 Fy ) = -S2

function Fxy_outer_eq_coeff!(AA::Matrix, BB::Matrix, CC::Matrix, SS::Vector, vars::FxyVars)
    u    = vars.u

    B1    = vars.B1
    B1p   = vars.B1p
    B1_x  = vars.B1_x
    B1_y  = vars.B1_y
    B1pp  = vars.B1pp
    B1p_x = vars.B1p_x
    B1p_y = vars.B1p_y

    B2    = vars.B2
    B2p   = vars.B2p
    B2_x  = vars.B2_x
    B2_y  = vars.B2_y
    B2pp  = vars.B2pp
    B2p_x = vars.B2p_x
    B2p_y = vars.B2p_y

    G     = vars.G
    Gp    = vars.Gp
    G_x   = vars.G_x
    G_y   = vars.G_y
    Gpp   = vars.Gpp
    Gp_x  = vars.Gp_x
    Gp_y  = vars.Gp_y

    phi   = vars.phi
    phip  = vars.phip
    phi_x = vars.phi_x
    phi_y = vars.phi_y

    S     = vars.S
    Sp    = vars.Sp
    S_x   = vars.S_x
    S_y   = vars.S_y
    Spp   = vars.Spp
    Sp_x  = vars.Sp_x
    Sp_y  = vars.Sp_y


    expB1   = exp(B1)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2


    AA[1,1] = *(2, S ^ 2, u ^ 4, expB1)
    AA[1,2] = 0
    AA[2,1] = 0
    AA[2,2] = *(2, S ^ 2, u ^ 4)

    BB[1,1] = *(2, S, u ^ 2, *(-1, Sp) + *(-1, B2p, S) + *(2, S, u) + *(-1, B1p, S, coshGsq), expB1)
    BB[1,2] = *(2, S ^ 2, u ^ 2, Gp + *(1 / 2, B1p, sinh2G))
    BB[2,1] = *(2, S ^ 2, u ^ 2, Gp + *(-1/2, B1p, sinh2G), expB1)
    BB[2,2] = *(S, u ^ 2, *(-2, Sp) + *(S, B1p + *(-2, B2p) + *(4, u)) + *(B1p, S, cosh2G))


    CC[1,1] = *(-2, *(4, Sp ^ 2) + *(-1, B2pp, S ^ 2) + *(-1, Gp ^ 2, S ^ 2) + *(-4, S, Spp) + *(-4, phip ^ 2, S ^ 2) + *(-3, B2p ^ 2, S ^ 2) + *(-1, S, coshGsq, *(B1pp, S) + *(S, B1p ^ 2) + *(3, B1p, Sp)) + *(-3, B2p, S, Sp) + *(-1, B1p, Gp, S ^ 2, sinh2G), expB1)

    CC[1,2] = *(-1, S, *(*(B1pp, S) + *(-1, S, B1p ^ 2) + *(3, B1p, Sp), sinh2G) + *(2, Gpp, S) + *(6, Gp, Sp) + *(-2, B1p, Gp, S) + *(2, B1p, Gp, S, cosh2G))

    CC[2,1] = *(S, *(*(B1pp, S) + *(S, B1p ^ 2) + *(3, B1p, Sp), sinh2G) + *(-6, Gp, Sp) + *(-2, Gpp, S) + *(-2, B1p, Gp, S) + *(2, B1p, Gp, S, cosh2G), expB1)

    CC[2,2] = *(-8, Sp ^ 2) + *(2, B2pp, S ^ 2) + *(2, Gp ^ 2, S ^ 2) + *(6, B2p ^ 2, S ^ 2) + *(8, S, Spp) + *(8, phip ^ 2, S ^ 2) + *(2, S, coshGsq, *(S, B1p ^ 2) + *(-1, B1pp, S) + *(-3, B1p, Sp)) + *(6, B2p, S, Sp) + *(-2, B1p, Gp, S ^ 2, sinh2G)

    SS[1] = *(2, Gp_y, S ^ 2) + *(B1p_y, S ^ 2, sinh2G) + *(-8, S, Sp_x, expB1) + *(-2, B1_y, Gp, S ^ 2) + *(-2, B2p_x, S ^ 2, expB1) + *(6, Gp, S, S_y) + *(8, S_x, Sp, expB1) + *(-1, B1_y, B1p, S ^ 2, sinh2G) + *(-8, phi_x, phip, S ^ 2, expB1) + *(-6, B2_x, B2p, S ^ 2, expB1) + *(-6, B2p, S, S_x, expB1) + *(-2, G_x, Gp, S ^ 2, expB1) + *(-2, S, coshGsq, *(B1p_x, S) + *(3, B1p, S_x) + *(B1_x, B1p, S), expB1) + *(2, B1p, G_y, S ^ 2, cosh2G) + *(3, B1p, S, S_y, sinh2G) + *(-2, B1p, G_x, S ^ 2, expB1, sinh2G)

    SS[2] = *(-8, S, Sp_y) + *(-2, B2p_y, S ^ 2) + *(8, S_y, Sp) + *(-8, phi_y, phip, S ^ 2) + *(-6, B2_y, B2p, S ^ 2) + *(-6, B2p, S, S_y) + *(-2, G_y, Gp, S ^ 2) + *(2, Gp_x, S ^ 2, expB1) + *(2, S, coshGsq, *(B1p_y, S) + *(3, B1p, S_y) + *(-1, B1_y, B1p, S)) + *(-1, B1p_x, S ^ 2, expB1, sinh2G) + *(2, B1_x, Gp, S ^ 2, expB1) + *(2, B1p, G_y, S ^ 2, sinh2G) + *(6, Gp, S, S_x, expB1) + *(-1, B1_x, B1p, S ^ 2, expB1, sinh2G) + *(-3, B1p, S, S_x, expB1, sinh2G) + *(-2, B1p, G_x, S ^ 2, cosh2G, expB1)

    nothing
end


function Sd_outer_eq_coeff!(ABCS::Vector, vars::AllVarsOuter)
    u   = vars.u

    B1     = vars.B1
    B1p    = vars.B1p
    B1t    = vars.B1t
    B1h    = vars.B1h
    B1tt   = vars.B1tt
    B1hh   = vars.B1hh
    B1tp   = vars.B1tp
    B1hp   = vars.B1hp

    B2     = vars.B2
    B2p    = vars.B2p
    B2t    = vars.B2t
    B2h    = vars.B2h
    B2tt   = vars.B2tt
    B2hh   = vars.B2hh
    B2tp   = vars.B2tp
    B2hp   = vars.B2hp

    G      = vars.G
    Gp     = vars.Gp
    Gt     = vars.Gt
    Gh     = vars.Gh
    Gtt    = vars.Gtt
    Ghh    = vars.Ghh
    Gtp    = vars.Gtp
    Ghp    = vars.Ghp

    phi    = vars.phi
    phip   = vars.phip
    phit   = vars.phit
    phih   = vars.phih
    phitt  = vars.phitt
    phihh  = vars.phihh
    phitp  = vars.phitp
    phihp  = vars.phihp

    S      = vars.S
    Sp     = vars.Sp
    St     = vars.St
    Sh     = vars.Sh
    Stt    = vars.Stt
    Shh    = vars.Shh
    Stp    = vars.Stp
    Shp    = vars.Shp

    Fx     = vars.Fx
    Fxp    = vars.Fxp
    Fxt    = vars.Fxt
    Fxh    = vars.Fxh
    # Fxtt   = vars.Fxtt
    # Fxhh   = vars.Fxhh
    Fxtp   = vars.Fxtp
    Fxhp   = vars.Fxhp

    Fy     = vars.Fy
    Fyp    = vars.Fyp
    Fyt    = vars.Fyt
    Fyh    = vars.Fyh
    # Fytt   = vars.Fytt
    # Fyhh   = vars.Fyhh
    Fytp   = vars.Fytp
    Fyhp   = vars.Fyhp

    B2th   = vars.B2th
    Gth    = vars.Gth
    Sth    = vars.Sth

    expB1   = exp(B1)
    expB2   = exp(B2)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2
    coshG   = cosh(G)
    sinhG   = sinh(G)


    ABCS[1] = 0.0

    ABCS[2] = *(-12, S ^ 3, u ^ 2, expB1)

    ABCS[3] = *(24, Sp, S ^ 2, expB1)

    ABCS[4] = *(*(S, *(*(-8, Gh, St) + *(-8, Gt, Sh), coshG) + *(*(-16, Sth) + *(2, Sh, Fxp + *(-4, B2t)) + *(2, Sp, *(4, Fxh) + *(4, Fyt)) + *(2, St, Fyp + *(-4, B2h)), sinhG)) + *(S ^ 2, *(*(-4, Gth) + *(-2, Gh, B1t + B2t + *(-1, Fxp)) + *(2, Gp, Fxh + Fyt) + *(2, Gt, B1h + Fyp + *(-1, B2h)), coshG) + *(*(-4, B2th) + *(2, Fxhp) + *(2, Fytp) + *(-8, phih, phit) + *(-4, Gh, Gt) + *(2, B2h, Fxp + *(-4, B2t)) + *(2, B2p, Fxh + Fyt) + *(2, Fyp, B2t + *(-1, Fxp)), sinhG)) + *(8, Sh, St, sinhG), expB1 *  expB2) + *(*(S, *(*(8, Shh) + *(-8, Fyh, Sp) + *(-2, Sh, Fyp + *(-4, B2h) + *(4, B1h)), coshG) + *(8, Gh, Sh, sinhG)) + *(S ^ 2, *(*(2, Ghh) + *(-2, Fyh, Gp) + *(2, Gh, B2h + *(-1, Fyp) + *(-2, B1h)), sinhG) + *(Fyp ^ 2 + *(-2, B1hh) + *(-2, Fyhp) + *(2, B2hh) + *(2, B1h ^ 2) + *(2, Gh ^ 2) + *(4, B2h ^ 2) + *(4, phih ^ 2) + *(Fyp, *(-2, B2h) + *(2, B1h)) + *(-2, B1h, B2h) + *(-2, B2p, Fyh) + *(2, B1p, Fyh), coshG)) + *(-4, Sh ^ 2, coshG), expB2) + *(*(S, *(*(8, Stt) + *(-8, Fxt, Sp) + *(-2, Fxp, St) + *(8, B1t, St) + *(8, B2t, St), coshG) + *(8, Gt, St, sinhG)) + *(S ^ 2, *(*(2, Gtt) + *(-2, Fxt, Gp) + *(2, Gt, B2t + *(-1, Fxp) + *(2, B1t)), sinhG) + *(Fxp ^ 2 + *(-2, Fxtp) + *(2, B1tt) + *(2, B2tt) + *(2, B1t ^ 2) + *(2, Gt ^ 2) + *(4, B2t ^ 2) + *(4, phit ^ 2) + *(-1, Fxp, *(2, B1t) + *(2, B2t)) + *(-2, Fxt, B1p + B2p) + *(2, B1t, B2t), coshG)) + *(-4, St ^ 2, coshG), exp(B2 + *(2, B1))) + *(8, V(phi), S ^ 4, expB1)

    nothing
end


function B2d_outer_eq_coeff!(ABCS::Vector, vars::AllVarsOuter)
    u   = vars.u

    B1     = vars.B1
    B1p    = vars.B1p
    B1t    = vars.B1t
    B1h    = vars.B1h
    B1tt   = vars.B1tt
    B1hh   = vars.B1hh
    B1tp   = vars.B1tp
    B1hp   = vars.B1hp

    B2     = vars.B2
    B2p    = vars.B2p
    B2t    = vars.B2t
    B2h    = vars.B2h
    B2tt   = vars.B2tt
    B2hh   = vars.B2hh
    B2tp   = vars.B2tp
    B2hp   = vars.B2hp

    G      = vars.G
    Gp     = vars.Gp
    Gt     = vars.Gt
    Gh     = vars.Gh
    Gtt    = vars.Gtt
    Ghh    = vars.Ghh
    Gtp    = vars.Gtp
    Ghp    = vars.Ghp

    phi    = vars.phi
    phip   = vars.phip
    phit   = vars.phit
    phih   = vars.phih
    phitt  = vars.phitt
    phihh  = vars.phihh
    phitp  = vars.phitp
    phihp  = vars.phihp

    S      = vars.S
    Sp     = vars.Sp
    St     = vars.St
    Sh     = vars.Sh
    Stt    = vars.Stt
    Shh    = vars.Shh
    Stp    = vars.Stp
    Shp    = vars.Shp

    Fx     = vars.Fx
    Fxp    = vars.Fxp
    Fxt    = vars.Fxt
    Fxh    = vars.Fxh
    # Fxtt   = vars.Fxtt
    # Fxhh   = vars.Fxhh
    Fxtp   = vars.Fxtp
    Fxhp   = vars.Fxhp

    Fy     = vars.Fy
    Fyp    = vars.Fyp
    Fyt    = vars.Fyt
    Fyh    = vars.Fyh
    # Fytt   = vars.Fytt
    # Fyhh   = vars.Fyhh
    Fytp   = vars.Fytp
    Fyhp   = vars.Fyhp

    B2th   = vars.B2th
    Gth    = vars.Gth
    Sth    = vars.Sth

    Sd     = vars.Sd

    expB1   = exp(B1)
    expB2   = exp(B2)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2
    coshG   = cosh(G)
    sinhG   = sinh(G)


    ABCS[1] = 0.0

    ABCS[2] = *(-12, S ^ 4, u ^ 2, expB1)

    ABCS[3] = *(18, Sp, S ^ 3, expB1)

    ABCS[4] = *(*(S, *(*(2, Gh, St) + *(2, Gt, Sh), coshG) + *(-1, *(-4, Sth) + *(-4, Fxp, Sh) + *(-4, Fyp, St) + *(2, Fxh, Sp) + *(2, Fyt, Sp) + *(4, B2h, St) + *(4, B2t, Sh), sinhG)) + *(S ^ 2, *(*(4, Gth) + *(-2, Gp, Fxh + Fyt) + *(-2, Gt, B1h + Fyp + *(2, B2h)) + *(2, Gh, B1t + *(-1, Fxp) + *(-2, B2t)), coshG) + *(*(-8, B2th) + *(-2, Fxhp) + *(-2, Fytp) + *(2, Fyp, Fxp + *(2, B2t)) + *(4, B2h, Fxp + *(-1, B2t)) + *(4, B2p, Fxh + Fyt) + *(4, Gh, Gt) + *(8, phih, phit), sinhG)) + *(-8, Sh, St, sinhG), exp(B1 + B2)) + *(*(S, *(*(-2, Shh) + *(2, Fyh, Sp) + *(2, Sh, B1h + *(-2, Fyp) + *(2, B2h)), coshG) + *(-2, Gh, Sh, sinhG)) + *(S ^ 2, *(*(-2, Ghh) + *(2, Fyh, Gp) + *(2, Gh, Fyp + *(2, B1h) + *(2, B2h)), sinhG) + *(-1, Fyp ^ 2 + *(-4, B2hh) + *(-2, B1hh) + *(-2, Fyhp) + *(-2, B2h ^ 2) + *(2, B1h ^ 2) + *(2, Gh ^ 2) + *(4, phih ^ 2) + *(2, B1h, Fyp + *(2, B2h)) + *(2, B1p, Fyh) + *(4, B2h, Fyp) + *(4, B2p, Fyh), coshG)) + *(4, Sh ^ 2, coshG), expB2) + *(*(S, *(*(-2, Stt) + *(-2, St, B1t + *(-2, B2t) + *(2, Fxp)) + *(2, Fxt, Sp), coshG) + *(-2, Gt, St, sinhG)) + *(S ^ 2, *(*(-2, Gtt) + *(2, Fxt, Gp) + *(2, Gt, Fxp + *(-2, B1t) + *(2, B2t)), sinhG) + *(-1, Fxp ^ 2 + *(-4, B2tt) + *(-2, Fxtp) + *(-2, B2t ^ 2) + *(2, B1tt) + *(2, B1t ^ 2) + *(2, Gt ^ 2) + *(4, phit ^ 2) + *(-2, B1p, Fxt) + *(-2, B1t, Fxp + *(2, B2t)) + *(4, B2p, Fxt) + *(4, B2t, Fxp), coshG)) + *(4, St ^ 2, coshG), exp(B2 + *(2, B1))) + *(18, B2p, Sd, S ^ 3, expB1)

    nothing
end


# this is another coupled equation, for B1d and Gd. the notation used is
#
# ( A11 d_uu B1d + A12 d_uu Gd + B11 d_u B1d + B12 d_u Gd + C11 B1d + C12 Gd ) = -S1
# ( A21 d_uu B1d + A22 d_uu Gd + B21 d_u B1d + B22 d_u Gd + C21 B1d + C22 Gd ) = -S2

function B1dGd_outer_eq_coeff!(AA::Matrix, BB::Matrix, CC::Matrix, SS::Vector, vars::AllVarsOuter)
    u    = vars.u

    B1     = vars.B1
    B1p    = vars.B1p
    B1t    = vars.B1t
    B1h    = vars.B1h
    B1tt   = vars.B1tt
    B1hh   = vars.B1hh
    B1tp   = vars.B1tp
    B1hp   = vars.B1hp

    B2     = vars.B2
    B2p    = vars.B2p
    B2t    = vars.B2t
    B2h    = vars.B2h
    B2tt   = vars.B2tt
    B2hh   = vars.B2hh
    B2tp   = vars.B2tp
    B2hp   = vars.B2hp

    G      = vars.G
    Gp     = vars.Gp
    Gt     = vars.Gt
    Gh     = vars.Gh
    Gtt    = vars.Gtt
    Ghh    = vars.Ghh
    Gtp    = vars.Gtp
    Ghp    = vars.Ghp

    phi    = vars.phi
    phip   = vars.phip
    phit   = vars.phit
    phih   = vars.phih
    phitt  = vars.phitt
    phihh  = vars.phihh
    phitp  = vars.phitp
    phihp  = vars.phihp

    S      = vars.S
    Sp     = vars.Sp
    St     = vars.St
    Sh     = vars.Sh
    Stt    = vars.Stt
    Shh    = vars.Shh
    Stp    = vars.Stp
    Shp    = vars.Shp

    Fx     = vars.Fx
    Fxp    = vars.Fxp
    Fxt    = vars.Fxt
    Fxh    = vars.Fxh
    # Fxtt   = vars.Fxtt
    # Fxhh   = vars.Fxhh
    Fxtp   = vars.Fxtp
    Fxhp   = vars.Fxhp

    Fy     = vars.Fy
    Fyp    = vars.Fyp
    Fyt    = vars.Fyt
    Fyh    = vars.Fyh
    # Fytt   = vars.Fytt
    # Fyhh   = vars.Fyhh
    Fytp   = vars.Fytp
    Fyhp   = vars.Fyhp

    B2th   = vars.B2th
    Gth    = vars.Gth
    Sth    = vars.Sth

    Sd     = vars.Sd

    expB1   = exp(B1)
    expB2   = exp(B2)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2
    coshG   = cosh(G)
    tanhG   = tanh(G)
    sinhG   = sinh(G)
    sechG   = sech(G)

    AA[1,1] = 0
    AA[1,2] = 0
    AA[2,1] = 0
    AA[2,2] = 0


    BB[1,1] = *(-12, S ^ 4, u ^ 2, expB1)

    BB[1,2] = 0

    BB[2,1] = 0

    BB[2,2] = *(-12, S ^ 4, u ^ 2, expB1)


    CC[1,1] = *(6, S ^ 3, *(3, Sp) + *(2, Gp, S, tanhG), expB1)

    CC[1,2] = *(12, B1p, S ^ 4, expB1, tanhG)

    CC[2,1] = *(-6, B1p, S ^ 4, expB1, sinh2G)

    CC[2,2] = *(18, Sp, S ^ 3, expB1)


    SS[1] = *(3, *(-4, Sh ^ 2) + *(S, *(2, Shh) + *(-2, Fyh, Sp) + *(2, B2h, Sh) + *(4, Fyp, Sh)) + *(S ^ 2, Fyp ^ 2 + *(-2, Fyhp) + *(2, B2hh) + *(4, B2h ^ 2) + *(4, phih ^ 2) + *(-2, B2h, Fyp) + *(-2, B2p, Fyh)), expB2, sechG) + *(3, *(4, St ^ 2) + *(-1, S ^ 2, Fxp ^ 2 + *(-2, Fxtp) + *(2, B2tt) + *(4, B2t ^ 2) + *(4, phit ^ 2) + *(-2, B2p, Fxt) + *(-2, B2t, Fxp)) + *(-2, S, Stt + *(B2t, St) + *(-1, Fxt, Sp) + *(2, Fxp, St)), exp(B2 + *(2, B1)), sechG) + *(6, S, *(Gt, Sh + *(S, B2h + *(-1, Fyp))) + *(-1, Gh, St) + *(Fxp, Gh, S) + *(Fyt, Gp, S) + *(-1, B2t, Gh, S) + *(-1, Fxh, Gp, S), exp(B1 + B2), sechG) + *(18, B1p, Sd, S ^ 3, expB1)

    SS[2] = *(3, *(4, Sh ^ 2) + *(-1, S, *(2, Shh) + *(-2, Fyh, Sp) + *(2, B2h, Sh) + *(4, Fyp, Sh)) + *(-1, S ^ 2, Fyp ^ 2 + *(-2, Fyhp) + *(2, B2hh) + *(4, B2h ^ 2) + *(4, phih ^ 2) + *(-2, B2h, Fyp) + *(-2, B2p, Fyh)), expB2, sinhG) + *(3, *(4, St ^ 2) + *(-1, S ^ 2, Fxp ^ 2 + *(-2, Fxtp) + *(2, B2tt) + *(4, B2t ^ 2) + *(4, phit ^ 2) + *(-2, B2p, Fxt) + *(-2, B2t, Fxp)) + *(-2, S, Stt + *(B2t, St) + *(-1, Fxt, Sp) + *(2, Fxp, St)), exp(B2 + *(2, B1)), sinhG) + *(6, *(S, *(2, Sth) + *(Sh, B2t + *(-1, B1t) + *(2, Fxp)) + *(St, B1h + B2h + *(2, Fyp)) + *(-1, Sp, Fxh + Fyt)) + *(S ^ 2, *(-1, Fxhp) + *(-1, Fytp) + *(2, B2th) + *(B1p, Fxh + *(-1, Fyt)) + *(B1t, Fyp) + *(B1h + *(-1, Fyp), B2t + *(-1, Fxp)) + *(-1, B2h, B1t + Fxp + *(-4, B2t)) + *(-1, B2p, Fxh + Fyt) + *(4, phih, phit)) + *(-4, Sh, St), coshG, exp(B1 + B2)) + *(18, Gp, Sd, S ^ 3, expB1)

    nothing
end


function phid_outer_eq_coeff!(ABCS::Vector, vars::AllVarsOuter)
    u   = vars.u

    B1     = vars.B1
    B1p    = vars.B1p
    B1t    = vars.B1t
    B1h    = vars.B1h
    B1tt   = vars.B1tt
    B1hh   = vars.B1hh
    B1tp   = vars.B1tp
    B1hp   = vars.B1hp

    B2     = vars.B2
    B2p    = vars.B2p
    B2t    = vars.B2t
    B2h    = vars.B2h
    B2tt   = vars.B2tt
    B2hh   = vars.B2hh
    B2tp   = vars.B2tp
    B2hp   = vars.B2hp

    G      = vars.G
    Gp     = vars.Gp
    Gt     = vars.Gt
    Gh     = vars.Gh
    Gtt    = vars.Gtt
    Ghh    = vars.Ghh
    Gtp    = vars.Gtp
    Ghp    = vars.Ghp

    phi    = vars.phi
    phip   = vars.phip
    phit   = vars.phit
    phih   = vars.phih
    phitt  = vars.phitt
    phihh  = vars.phihh
    phitp  = vars.phitp
    phihp  = vars.phihp

    S      = vars.S
    Sp     = vars.Sp
    St     = vars.St
    Sh     = vars.Sh
    Stt    = vars.Stt
    Shh    = vars.Shh
    Stp    = vars.Stp
    Shp    = vars.Shp

    Fx     = vars.Fx
    Fxp    = vars.Fxp
    Fxt    = vars.Fxt
    Fxh    = vars.Fxh
    # Fxtt   = vars.Fxtt
    # Fxhh   = vars.Fxhh
    Fxtp   = vars.Fxtp
    Fxhp   = vars.Fxhp

    Fy     = vars.Fy
    Fyp    = vars.Fyp
    Fyt    = vars.Fyt
    Fyh    = vars.Fyh
    # Fytt   = vars.Fytt
    # Fyhh   = vars.Fyhh
    Fytp   = vars.Fytp
    Fyhp   = vars.Fyhp

    B2th   = vars.B2th
    Gth    = vars.Gth
    Sth    = vars.Sth
    phith  = vars.phith

    Sd     = vars.Sd

    expB1   = exp(B1)
    expB2   = exp(B2)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2
    coshG   = cosh(G)
    sinhG   = sinh(G)


    ABCS[1] = 0.0

    ABCS[2] = *(-8, S ^ 3, u ^ 2, expB1)

    ABCS[3] = *(12, Sp, S ^ 2, expB1)

    ABCS[4] = *(*(*(4, phih, Sh + *(-1, S, B1h + Fyp + *(-1, B2h))) + *(4, S, phihh + *(-1, Fyh, phip)), coshG) + *(4, Gh, phih, S, sinhG), expB2) + *(*(4, S, *(phitt + *(phit, B1t + B2t + *(-1, Fxp)) + *(-1, Fxt, phip), coshG) + *(Gt, phit, sinhG)) + *(4, phit, St, coshG), exp(B2 + *(2, B1))) + *(*(-1, *(4, phih, St) + *(4, phit, Sh), sinhG) + *(S, *(-4, Gh, phit) + *(-4, Gt, phih), coshG) + *(S, *(-8, phith) + *(4, phih, Fxp + *(-1, B2t)) + *(4, phip, Fxh + Fyt) + *(4, phit, Fyp + *(-1, B2h)), sinhG), exp(B1 + B2)) + *(-4, S ^ 2, *(S, Vp(phi)) + *(-3, phip, Sd), expB1)

    nothing
end


function A_outer_eq_coeff!(ABCS::Vector, vars::AllVarsOuter)
    u   = vars.u

    B1     = vars.B1
    B1p    = vars.B1p
    B1t    = vars.B1t
    B1h    = vars.B1h
    B1tt   = vars.B1tt
    B1hh   = vars.B1hh
    B1tp   = vars.B1tp
    B1hp   = vars.B1hp

    B2     = vars.B2
    B2p    = vars.B2p
    B2t    = vars.B2t
    B2h    = vars.B2h
    B2tt   = vars.B2tt
    B2hh   = vars.B2hh
    B2tp   = vars.B2tp
    B2hp   = vars.B2hp

    G      = vars.G
    Gp     = vars.Gp
    Gt     = vars.Gt
    Gh     = vars.Gh
    Gtt    = vars.Gtt
    Ghh    = vars.Ghh
    Gtp    = vars.Gtp
    Ghp    = vars.Ghp

    phi    = vars.phi
    phip   = vars.phip
    phit   = vars.phit
    phih   = vars.phih
    phitt  = vars.phitt
    phihh  = vars.phihh
    phitp  = vars.phitp
    phihp  = vars.phihp

    S      = vars.S
    Sp     = vars.Sp
    St     = vars.St
    Sh     = vars.Sh
    Stt    = vars.Stt
    Shh    = vars.Shh
    Stp    = vars.Stp
    Shp    = vars.Shp

    Fx     = vars.Fx
    Fxp    = vars.Fxp
    Fxt    = vars.Fxt
    Fxh    = vars.Fxh
    # Fxtt   = vars.Fxtt
    # Fxhh   = vars.Fxhh
    Fxtp   = vars.Fxtp
    Fxhp   = vars.Fxhp

    Fy     = vars.Fy
    Fyp    = vars.Fyp
    Fyt    = vars.Fyt
    Fyh    = vars.Fyh
    # Fytt   = vars.Fytt
    # Fyhh   = vars.Fyhh
    Fytp   = vars.Fytp
    Fyhp   = vars.Fyhp

    B2th   = vars.B2th
    Gth    = vars.Gth
    Sth    = vars.Sth
    phith  = vars.phith

    Sd     = vars.Sd
    B1d    = vars.B1d
    B2d    = vars.B2d
    Gd     = vars.Gd
    phid   = vars.phid

    expB1   = exp(B1)
    expB2   = exp(B2)
    sinh2G  = sinh(*(2, G))
    cosh2G  = cosh(*(2, G))
    coshGsq = cosh(G)^2
    coshG   = cosh(G)
    sinhG   = sinh(G)


    ABCS[1] = *(6, S ^ 4, u ^ 4, expB1)

    ABCS[2] = *(12, S ^ 4, u ^ 3, expB1)

    ABCS[3] = 0

    ABCS[4] = *(*(2, S ^ 4, *(-4, V(phi)) + *(3, Gd, Gp) + *(9, B2d, B2p) + *(12, phid, phip) + *(3, B1d, B1p, coshGsq)) + *(-72, Sd, Sp, S ^ 2), expB1) + *(*(S, *(*(-24, Stt) + *(-24, St, B1t + B2t) + *(24, Fxt, Sp), coshG) + *(-24, Gt, St, sinhG)) + *(S ^ 2, *(*(-12, B2t ^ 2) + *(-12, phit ^ 2) + *(-6, B1tt) + *(-6, B2tt) + *(-6, B1t ^ 2) + *(-6, Gt ^ 2) + *(3, Fxp ^ 2) + *(-6, B1t, B2t) + *(6, Fxt, B1p + B2p), coshG) + *(-1, *(6, Gtt) + *(-6, Fxt, Gp) + *(6, B2t, Gt) + *(12, B1t, Gt), sinhG)) + *(12, St ^ 2, coshG), exp(B2 + *(2, B1))) + *(*(S, *(*(-24, Shh) + *(-24, B2h, Sh) + *(24, B1h, Sh) + *(24, Fyh, Sp), coshG) + *(-24, Gh, Sh, sinhG)) + *(S ^ 2, *(*(-6, Ghh) + *(-6, B2h, Gh) + *(6, Fyh, Gp) + *(12, B1h, Gh), sinhG) + *(*(-12, B2h ^ 2) + *(-12, phih ^ 2) + *(-6, B2hh) + *(-6, B1h ^ 2) + *(-6, Gh ^ 2) + *(3, Fyp ^ 2) + *(6, B1hh) + *(-6, B1p, Fyh) + *(6, B1h, B2h) + *(6, B2p, Fyh), coshG)) + *(12, Sh ^ 2, coshG), expB2) + *(*(S ^ 2, *(*(12, Gth) + *(-6, Gp, Fxh + Fyt) + *(6, Gh, B1t + B2t) + *(6, Gt, B2h + *(-1, B1h)), coshG) + *(*(12, B2th) + *(-6, B2p, Fxh + Fyt) + *(-6, Fxp, Fyp) + *(12, Gh, Gt) + *(24, B2h, B2t) + *(24, phih, phit), sinhG)) + *(24, S, *(*(Gh, St) + *(Gt, Sh), coshG) + *(*(2, Sth) + *(B2h, St) + *(B2t, Sh) + *(-1, Sp, Fxh + Fyt), sinhG)) + *(-24, Sh, St, sinhG), exp(B1 + B2))

    nothing
end