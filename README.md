# ConservationLawsDiffEq

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Build Status](https://travis-ci.org/Paulms/ConservationLawsDiffEq.jl.svg?branch=master)](https://travis-ci.org/Paulms/ConservationLawsDiffEq.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/3x0qjeud3viejfn0?svg=true)](https://ci.appveyor.com/project/Paulms/conservationlawsdiffeq-jl)
[![Coverage Status](https://coveralls.io/repos/Paulms/ConservationLawsDiffEq.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/Paulms/ConservationLawsDiffEq.jl?branch=master)
[![codecov.io](http://codecov.io/github/Paulms/ConservationLawsDiffEq.jl/coverage.svg?branch=master)](http://codecov.io/github/Paulms/ConservationLawsDiffEq.jl?branch=master)

Collection of numerical schemes for solving systems of Conservations Laws (finite volume methods/Discontinuous Galerkin + method of lines). Implementation is influenced by [DifferentialEquations API](http://docs.juliadiffeq.org/latest/).

Each scheme return a semidiscretization (discretization in space) that represents a ODE system. Time integration is performed then using [OrdinaryDiffEq](https://github.com/JuliaDiffEq/OrdinaryDiffEq.jl) algorithms.

The general conservation law problem is represented by the following PDE,

<a href="https://www.codecogs.com/eqnedit.php?latex=\frac{\partial}{\partial&space;t}u&space;&plus;&space;\nabla&space;\cdot&space;f(u)=&space;0,\quad&space;\forall&space;(x,t)\in&space;\mathbb{R}^{n}\times\mathbb{R}_{&plus;}&space;\\&space;u(x,0)&space;=&space;u_{0}(x)\quad&space;\forall&space;x&space;\in&space;\mathbb{R}^{n}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\frac{\partial}{\partial&space;t}u&space;&plus;&space;\nabla&space;\cdot&space;f(u)=&space;0,\quad&space;\forall&space;(x,t)\in&space;\mathbb{R}^{n}\times\mathbb{R}&space;\\&space;u(x,0)&space;=&space;u_{0}(x)\quad&space;\forall&space;x&space;\in&space;\mathbb{R}^{n}" title="\frac{\partial}{\partial t}u + \nabla \cdot f(u)= 0,\quad \forall (x,t)\in \mathbb{R}^{n}\times\mathbb{R} \\ u(x,0) = u_{0}(x)\quad \forall x \in \mathbb{R}^{n}" /></a>

We can also consider degenerate convection-diffusion systems (degenerate parabolic-hyperbolic equations) of the form:

<a href="https://www.codecogs.com/eqnedit.php?latex=\frac{\partial}{\partial&space;t}u&space;&plus;&space;\nabla&space;\cdot&space;f(u)=&space;\nabla&space;\cdot&space;(B(u)\nabla&space;u),\quad&space;\forall&space;(x,t)\in&space;\mathbb{R}^{n}\times\mathbb{R}_{&plus;}&space;\\&space;u(x,0)&space;=&space;u_{0}(x)\quad&space;\forall&space;x&space;\in&space;\mathbb{R}^{n}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\frac{\partial}{\partial&space;t}u&space;&plus;&space;\nabla&space;\cdot&space;f(u)=&space;\nabla&space;\cdot&space;(B(u)\nabla&space;u),\quad&space;\forall&space;(x,t)\in&space;\mathbb{R}^{n}\times\mathbb{R}_{&plus;}&space;\\&space;u(x,0)&space;=&space;u_{0}(x)\quad&space;\forall&space;x&space;\in&space;\mathbb{R}^{n}" title="\frac{\partial}{\partial t}u + \nabla \cdot f(u)= \nabla \cdot (B(u)\nabla u),\quad \forall (x,t)\in \mathbb{R}^{n}\times\mathbb{R}_{+} \\ u(x,0) = u_{0}(x)\quad \forall x \in \mathbb{R}^{n}" /></a>

Solutions follow a conservative finite difference (finite volume) pattern. This method updates cell averages of the solution **u**. For a particular cell *i* it has the general form

<a href="https://www.codecogs.com/eqnedit.php?latex=\frac{d}{d&space;t}u(x_i,t)&space;=&space;-&space;\frac{1}{\Delta&space;x_i}(F(x_{i&plus;1/2},t)&space;-&space;F(x_{i-1/2},t))" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\frac{d}{d&space;t}u(x_i,t)&space;=&space;-&space;\frac{1}{\Delta&space;x_i}(F(x_{i&plus;1/2},t)&space;-&space;F(x_{i-1/2},t))" title="\frac{d}{d t}u(x_i,t) = - \frac{1}{\Delta x_i}(F(x_{i+1/2},t) - F(x_{i-1/2},t))" /></a>

Where the numerical flux <a href="https://www.codecogs.com/eqnedit.php?latex=F_{i&plus;1/2}(t)&space;=&space;F(u_{i}(t),u_{i&plus;1}(t)))" target="_blank"><img src="https://latex.codecogs.com/gif.latex?F_{i&plus;1/2}(t)&space;=&space;F(u_{i}(t),u_{i&plus;1}(t)))" title="F_{i+1/2}(t) = F(u_{i}(t),u_{i+1}(t)))" /></a> is an approximate solution of the Riemann problem at the cell interface <a href="https://www.codecogs.com/eqnedit.php?latex=x_{i&plus;1/2}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?x_{i&plus;1/2}" title="x_{i+1/2}" /></a>.

An extra numerical function similar to **F** could be added to account for the Diffusion in the second case.

Discontinuous Galerking formulation is based on Hesthaven, Warburton, Nodal Discontinuous Galerkin Methods Algorithms, book.

## Features
### Mesh:
At the momento only Cartesian 1D uniform mesh available, using `Uniform1DFVMesh(N,a,b,left_boundary, right_boundary)` command. Where

`N` = Number of cells

`a,b` = start and end coordinates.

`left_boundary`,`right_boundary` = boundary type (`:ZERO_FLUX` (default), `:PERIODIC`, `:DIRICHLET` )

*Note:* Dirichlet boundary values are defined by initial condition.

* Problem types: System of Conservation Laws without (`ConservationLawsProblem`) and with degenerate diffusion term (`ConservationLawsWithDiffusionProblem`).

### Algorithms

The algorithms follow the method of lines, so first we compute a semidiscretization in space and time integration is performed using ODE solvers.

#### Lax-Friedrichs method

(`LaxFriedrichsAlgorithm()`), Global/Local L-F Scheme (`GlobalLaxFriedrichsAlgorithm()`, `LocalLaxFriedrichsAlgorithm()`), Second order Law-Wendroff Scheme (`LaxWendroffAlgorithm()`), Ritchmeyer Two-step Lax-Wendroff Method (`LaxWendroff2sAlgorithm()`)

* R. LeVeque. Finite Volume Methods for Hyperbolic Problems.Cambridge University Press. New York 2002

#### TECNO Schemes

(`FVTecnoAlgorithm(Nflux;ve, order)`)

* U. Fjordholm, S. Mishra, E. Tadmor, *Arbitrarly high-order accurate entropy stable essentially nonoscillatory schemes for systems of conservation laws*. 2012. SIAM. vol. 50. No 2. pp. 544-573

#### High-Resolution Central Schemes

(`FVSKTAlgorithm()`)

Kurganov, Tadmor, *New High-Resolution Central Schemes for Nonlinear Conservation Laws and Convection–Diffusion Equations*, Journal of Computational Physics, Vol 160, issue 1, 1 May 2000, Pages 241-282

#### Second-Order upwind central scheme

(`FVCUAlgorithm`)

* Kurganov A., Noelle S., Petrova G., Semidiscrete Central-Upwind schemes for hyperbolic Conservation Laws and Hamilton-Jacobi Equations. SIAM. Sci Comput, Vol 23, No 3m pp 707-740. 2001

#### Dissipation Reduced Central upwind Scheme:

Second-Order (`FVDRCUAlgorithm`), fifth-order (`FVDRCU5Algorithm`)

* Kurganov A., Lin C., On the reduction of Numerical Dissipation in Central-Upwind # Schemes, Commun. Comput. Phys. Vol 2. No. 1, pp 141-163, Feb 2007.

#### Component Wise Weighted Essentially Non-Oscilaroty (WENO-LF)

(`FVCompWENOAlgorithm(;order)`)

* C.-W. Shu, *High order weighted essentially non-oscillatory schemes for convection dominated problems*, SIAM Review, 51:82-126, (2009).

#### Component Wise Mapped WENO Scheme

(`FVCompMWENOAlgorithm(;order)`)

* A. Henrick, T. Aslam, J. Powers, *Mapped weighted essentially non-oscillatory schemes: Achiving optimal order near critical points*. Journal of Computational Physics. Vol 207. 2005. Pages 542-567

#### Component Wise Global Lax-Friedrichs Scheme

(`COMP_GLF_Diff_Algorithm()`)

#### Characteristic Wise WENO (Spectral) Scheme

(`FVSpecMWENOAlgorithm(;order)`)

* R. Bürger, R. Donat, P. Mulet, C. Vega, *On the implementation of WENO schemes for a class of polydisperse sedimentation models*. Journal of Computational Physics, Volume 230, Issue 6, 20 March 2011, Pages 2322-2344

#### Linearly implicit IMEX Runge-Kutta schemes

(`LI_IMEX_RK_Algorithm(;scheme, linsolve)`) (not working for zero_flux boundary conditions)

(See Time integration methods for RK options (`scheme`), Flux reconstruction uses Comp WENO5, to change linear solver see [DifferentialEquations.jl: Specifying (Non)Linear Solvers](http://docs.juliadiffeq.org/stable/features/linear_nonlinear.html))

* S. Boscarino, R. Bürger, P. Mulet, G. Russo, L. Villada, *Linearly implicit IMEX Runge Kutta methods for a class of degenerate convection diffusion problems*, SIAM J. Sci. Comput., 37(2), B305–B331

#### Discontinuos Galerkin Scheme

(`DiscontinuousGalerkinScheme(basis, num_flux; max_w_speed)`)

*Arguments:*

`basis` Polynomial basis for the discrete functional space, only `legendre_basis(k)` are available at the moment.

`num_flux` Function of the form `F(ul, ur, f, α)`, defines numerical flux for the cell interfaces. (α is the maximum wave speed, f: flux function)

`max_w_speed` Optional function used to compute maximum wave speed

*Note:* Limiters can be added through the stage_limiter! option of `SSPRKXX` ODE integration algorithms (Default limiters can be used with the following code: `limiter! = DGLimiter(prob.mesh, basis, Linear_MUSCL_Limiter())`) and then passing `limiter!` as argument to the time integrator, i.e. `SSPRK22(limiter!)`.
For examples see `0_Burgers1D.jl` and `5_Advection1D.jl`

* Bernard, Cockburn., and Shu,C.W. (1998). “The local discontinuous Galerkin method for convection diffusion problems”. SIAM Journal of numerical analysis, vol. 35, no. 6, pp. 2440-2463.
* Hesthaven, Warburton, Nodal Discontinuous Galerkin Methods Algorithms, Analysis and applications



### Time integration methods:

Time integration use OrdinaryDiffEq algorithms (default to `SSPRK22()`)

For IMEX Scheme RK methods: H-CN(2,2,2) `:H_CN_222`, H-DIRK2(2,2,2) `:H_DIRK2_222`, H-LDIRK2(2,2,2) `:H_LDIRK2_222`, H-LDIRK3(2,2,2) `:H_LDIRK3_222`, SSP-LDIRK(3,3,2) `:SSP_LDIRK_332`. For more information see:

* S. Boscarino, P.G. LeFloch and G. Russo. *High order asymptotic-preserving methods for fully nonlinear relaxation problems*. SIAM J. Sci. Comput., 36 (2014), A377–A395.

* S. Boscarino, F. Filbet and G. Russo. *High order semi-implicit schemes for time dependent partial differential equations*. SIAM J. Sci. Comput. September 2016, Volume 68, Issue 3, pp 975–1001

## Example
Hyperbolic Shallow Water system with flat bottom:

```julia

using ConservationLawsDiffEq

const CFL = 0.1
const Tend = 0.2
const gr = 9.8

#Define Optional Jacobian of Flux
function Jf(u::AbstractVector)
  h = u[1]
  q = u[2]
  F =[0.0 1.0;-q^2/h^2+gr*h 2*q/h]
  F
end

#Flux function:
f(u::AbstractVector) = [u[2];u[2]^2/u[1]+0.5*gr*u[1]^2]

#Initial Condition:
f0(x) = x < 0.0 ? [2.0,0.0] : [1.0,0.0]

# Setup Mesh
N = 100
mesh = Uniform1DFVMesh(N,-5.0,5.0,:PERIODIC,:PERIODIC)

#Setup problem:
prob = ConservationLawsProblem(f0,f,CFL,Tend,mesh;jac = Jf)

#Solve problem using Kurganov-Tadmor scheme and Strong Stability Preserving RK33
@time sol = solve(prob, FVSKTAlgorithm();progress=true, TimeIntegrator = SSPRK33())

#Plot
using Plots
plot(sol, tidx=1, vars=1, lab="ho",line=(:dot,2))
plot!(sol, vars=1,lab="KT h")
```

# Disclamer
** developed for personal use, some of the schemes have not been tested enough!!!**
