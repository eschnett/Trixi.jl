# By default, Julia/LLVM does not use fused multiply-add operations (FMAs).
# Since these FMAs can increase the performance of many numerical algorithms,
# we need to opt-in explicitly.
# See https://ranocha.de/blog/Optimizing_EC_Trixi for further details.
@muladd begin


@doc raw"""
    InviscidBurgersEquation1D

The inviscid Burgers' equation
```math
\partial_t u + \frac{1}{2} \partial_1 u^2 = 0
```
in one space dimension.
"""
struct InviscidBurgersEquation1D <: AbstractInviscidBurgersEquation{1, 1} end


varnames(::typeof(cons2cons), ::InviscidBurgersEquation1D) = ("scalar", )
varnames(::typeof(cons2prim), ::InviscidBurgersEquation1D) = ("scalar", )


# Set initial conditions at physical location `x` for time `t`
"""
    initial_condition_constant(x, t, equations::InviscidBurgersEquation1D)

A constant initial condition to test free-stream preservation.
"""
function initial_condition_constant(x, t, equation::InviscidBurgersEquation1D)
  return SVector(2.0)
end


"""
    initial_condition_convergence_test(x, t, equations::InviscidBurgersEquation1D)

A smooth initial condition used for convergence tests.
"""
function initial_condition_convergence_test(x, t, equation::InviscidBurgersEquation1D)
  c = 2.0
  A = 1.0
  L = 1
  f = 1/L
  omega = 2 * pi * f
  scalar = c + A * sin(omega * (x[1] - t))

  return SVector(scalar)
end


"""
    source_terms_convergence_test(u, x, t, equations::InviscidBurgersEquation1D)

Source terms used for convergence tests in combination with
[`initial_condition_convergence_test`](@ref).
"""
@inline function source_terms_convergence_test(u, x, t, equations::InviscidBurgersEquation1D)
  # Same settings as in `initial_condition`
  c = 2.0
  A = 1.0
  L = 1
  f = 1/L
  omega = 2 * pi * f
  du = omega * cos(omega * (x[1] - t)) * (1 + sin(omega * (x[1] - t)))

  return SVector(du)
end


# Pre-defined source terms should be implemented as
# function source_terms_WHATEVER(u, x, t, equations::InviscidBurgersEquation1D)


# Calculate 1D flux in for a single point
@inline function flux(u, orientation::Integer, equation::InviscidBurgersEquation1D)
  return SVector(0.5 * u[1]^2)
end


# Calculate maximum wave speed for local Lax-Friedrichs-type dissipation
@inline function max_abs_speed_naive(u_ll, u_rr, orientation::Integer, equations::InviscidBurgersEquation1D)
  u_L = u_ll[1]
  u_R = u_rr[1]

  λ_max = max(abs(u_L), abs(u_R))
end

# Calculate minimum and maximum wave speeds for HLL-type fluxes
@inline function min_max_speed_naive(u_ll, u_rr, orientation::Integer, equations::InviscidBurgersEquation1D)
  u_L = u_ll[1]
  u_R = u_rr[1]
  
  λ_min = min(u_L, u_R)
  λ_max = max(u_L, u_R)

  return λ_min, λ_max
end

@inline function max_abs_speeds(u, equation::InviscidBurgersEquation1D)
  return (abs(u[1]),)
end


# (Symmetric) Entropy Conserving flux
function flux_ec(u_ll, u_rr, orientation, equation::InviscidBurgersEquation1D)
  u_L = u_ll[1]
  u_R = u_rr[1]

  return SVector((u_L^2 + u_L * u_R + u_R^2) / 6)
end


# See https://metaphor.ethz.ch/x/2019/hs/401-4671-00L/literature/mishra_hyperbolic_pdes.pdf ,
# section 4.1.5 and especially equation (4.16).
function flux_godunov(u_ll, u_rr, orientation, equation::InviscidBurgersEquation1D)
  u_L = u_ll[1]
  u_R = u_rr[1]

  return SVector(0.5 * max(max(u_L, zero(u_L))^2, min(u_R, zero(u_R))^2))
end


# See https://metaphor.ethz.ch/x/2019/hs/401-4671-00L/literature/mishra_hyperbolic_pdes.pdf ,
# section 4.2.5 and especially equation (4.34).
function flux_engquist_osher(u_ll, u_rr, orientation, equation::InviscidBurgersEquation1D)
  u_L = u_ll[1]
  u_R = u_rr[1]

  return SVector(0.5 * (max(u_L, zero(u_L))^2 + min(u_R, zero(u_R))^2))
end

# Convert conservative variables to primitive
@inline cons2prim(u, equation::InviscidBurgersEquation1D) = u

# Convert conservative variables to entropy variables
@inline cons2entropy(u, equation::InviscidBurgersEquation1D) = u


# Calculate entropy for a conservative state `cons`
@inline entropy(u::Real, ::InviscidBurgersEquation1D) = 0.5 * u^2
@inline entropy(u, equation::InviscidBurgersEquation1D) = entropy(u[1], equation)


# Calculate total energy for a conservative state `cons`
@inline energy_total(u::Real, ::InviscidBurgersEquation1D) = 0.5 * u^2
@inline energy_total(u, equation::InviscidBurgersEquation1D) = energy_total(u[1], equation)


end # @muladd
