"""
An abstract mesh in one space dimension.
"""
abstract type AbstractFVMesh1D <: AbstractFVMesh end


@inline numedges(mesh::AbstractFVMesh1D) = numcells(mesh)+1
@inline edge_indices(mesh::AbstractFVMesh1D) = 1:numedges(mesh)

"""
A uniform mesh in one space dimension of `N` cells
"""
struct Uniform1DFVMesh{T} <: AbstractFVMesh1D
  N ::Int
  Δx :: T
  cell_centers :: Vector{T}
  cell_faces :: Vector{T}
  left_boundary::Symbol
  right_boundary::Symbol
end

# REMARK: Dirichlet condition values are given by initial conditions.
isleftperiodic(mesh::AbstractFVMesh1D) = (mesh.left_boundary == :PERIODIC)
isrightperiodic(mesh::AbstractFVMesh1D) = (mesh.right_boundary == :PERIODIC)
isleftzeroflux(mesh::AbstractFVMesh1D) = (mesh.left_boundary == :ZERO_FLUX)
isrightzeroflux(mesh::AbstractFVMesh1D) = (mesh.right_boundary == :ZERO_FLUX)
isleftdirichlet(mesh::AbstractFVMesh1D) = (mesh.left_boundary == :DIRICHLET)
isrightdirichlet(mesh::AbstractFVMesh1D) = (mesh.right_boundary == :DIRICHLET)

function Uniform1DFVMesh(N::Int,xinit::Real,xend::Real,leftbdtype=:ZERO_FLUX,rightbdtype=:ZERO_FLUX)
    L = xend - xinit
    dx = L/N
    xx = [i*dx+dx/2+xinit for i in 0:(N-1)]
    faces = [xinit + dx*i for i in 0:N]
    Uniform1DFVMesh(N,dx,xx,faces,leftbdtype,rightbdtype)
end

@inline numcells(mesh::Uniform1DFVMesh) = mesh.N
@inline cell_indices(mesh::Uniform1DFVMesh) = 1:numcells(mesh)
@inline cell_centers(mesh::Uniform1DFVMesh) = mesh.cell_centers
@inline cell_faces(mesh::Uniform1DFVMesh) = mesh.cell_faces
@inline volume(cell::Int, mesh::Uniform1DFVMesh) = mesh.Δx

function getPeriodicIndex(A::AbstractArray{T,2}, I...) where {T}
    checkbounds(Bool, A, I...) && return A[I...]
    if typeof(I[1]) <: Int
      return A[mod1(I[1], size(A,1)),I[2]]
    else
      return A[[mod1(i, size(A,1)) for i in I[1]],I[2]]
    end
end

# function getDirichletIndex(A::AbstractArray{T,2}, I...) where {T}
#     checkbounds(Bool, A, I...) && return A[I...]
#     I... < 1 ? A.oob_val[1] : A.oob_val[2]
# end

# Reflective boundaries
# function getZFindex(A::AbstractArray{T,2}, I...) where {T}
#     checkbounds(Bool, A, I...) && return A[I...]
#     k::Int64 = indices(A,1)[end]
#     if typeof(I[1]) <: Int
#       a = I[1] < 1 ? 1:-1
#       return A[k+1+a-mod1(I[1],k),I[2]]
#     else
#       return A[[checkindex(Bool, indices(A)[1], i) ? i : k + 1 + (i < 1 ? 1:-1) - mod1(i,k) for i in I[1]],I[2]]
#     end
# end

function getZFindex(A::AbstractArray{T,2}, I...) where {T}
    checkbounds(Bool, A, I...) && return A[I...]
    if typeof(I[1]) <: Int
      return A[min(size(A,1),max(1,I[1])),I[2]]
    else
      return A[[min(size(A,1),max(1,i)) for i in I[1]],I[2]]
    end
end

# function getZFrow(A, idx, idc)
#     if checkindex(Bool, indices(A)[1], idx)
#         return A[idx,idc]
#     else
#         a = interpolate!(A, BSpline(Linear()), OnGrid())
#         a = extrapolate(a, Linear())
#         return a[idx,idc]
#     end
# end

#Zero flux with recommendation from
#C.-W. Shu, Essentially non-oscillatory and weighted essentially non-oscillatory
#schemes for hyperbolic conservation laws.
#In: B. Cockburn, C. Johnson, C.-W. Shu and E. Tadmor
# function getZFrow(A, idx, idc)
#     if checkindex(Bool, indices(A)[1], idx)
#         return A[idx,idc]
#     else
#         k::typeof(idx) = min(abs(idx-indices(A)[1][1]), abs(idx - indices(A)[1][end]))
#         if typeof(idc) <: Int
#           return (10*k)^10*one(eltype(A))
#         else
#           return (10*k)^10*ones(A[indices(A)[1][1],idc])
#         end
#     end
# end
#
# function getZFindex(A::AbstractArray{T,2}, I...) where {T}
#     checkbounds(Bool, A, I...) && return A[I...]
#     if typeof(I[1]) <: Int
#       return getZFrow(A,I[1],I[2])
#     else
#         idend::Int64 = (I[2] == Colon() ? size(A,2) : size(I[2],1))
#         if idend > 1
#             B = zeros(eltype(A), size(I[1],1), idend)
#             for (k,j) in enumerate(I[1])
#                 B[k,:] = getZFrow(A,j,I[2])
#             end
#             return B
#         else
#             B = zeros(eltype(A), size(I[1],1))
#             for (k,j) in enumerate(I[1])
#                 B[k] = getZFrow(A,j,I[2])
#             end
#             return B
#         end
#     end
# end

# Reference for cell and edge numbers
#   1   2   3          N-1  N
# |---|---|---|......|---|---|
# 1   2   3   4 ... N-1  N  N+1
"""
    get_cellvals(A::AbstractArray{T,2}, idx..., mesh::AbstractFVMesh1D) where {T}
   cell values of variable `A` on cells `idx` of `mesh`.
"""
@inline function get_cellvals(A::AbstractArray{T,2}, mesh::AbstractFVMesh1D, idx...) where {T}
    checkbounds(Bool, A, idx...) && return A[idx...]
    if (minimum(idx[1]) < 1) && isleftperiodic(mesh)
        getPeriodicIndex(A, idx...)
    elseif (minimum(idx[1]) < 1) && (isleftzeroflux(mesh) || isleftdirichlet(mesh))
        getZFindex(A,idx...)
    elseif (maximum(idx[1]) > numcells(mesh)) && isrightperiodic(mesh)
        getPeriodicIndex(A, idx...)
    elseif (maximum(idx[1]) > numcells(mesh)) && (isrightzeroflux(mesh) || isrightdirichlet(mesh))
        getZFindex(A,idx...)
    else
        error("To be implemented.")
    end
end

"""
    cellval_at_left(edge::Int, A::AbstractArray{T,2}, mesh::AbstractFVMesh1D) where {T}

   cell values of variable `A` to the left of `edge` in `mesh`.
"""
@inline function cellval_at_left(edge::Int, A::AbstractArray{T,2}, mesh::AbstractFVMesh1D) where {T}
    idx = (edge-1,:)
    checkbounds(Bool, A, idx...) && return A[idx...]
    if isleftperiodic(mesh)
        getPeriodicIndex(A, idx...)
    elseif isleftzeroflux(mesh) || isleftdirichlet(mesh)
        getZFindex(A,idx...)
    else
        error("To be implemented.")
    end
end

"""
    cellval_at_right(edge::Int, A::AbstractArray{T,2}, mesh::AbstractFVMesh1D) where {T}

cell values of variable `A` to the right of `edge` in `mesh`.
"""
@inline function cellval_at_right(edge::Int, A::AbstractArray{T,2}, mesh::AbstractFVMesh1D) where {T}
    idx = (edge,:)
    checkbounds(Bool, A, idx...) && return A[idx...]
    if isrightperiodic(mesh)
        getPeriodicIndex(A, idx...)
    elseif isrightzeroflux(mesh) || isrightdirichlet(mesh)
        getZFindex(A,idx...)
    else
        error("To be implemented.")
    end
end

"""
    left_edge(cell::Int, mesh::AbstractFVMesh1D)

The index of the edge to the left of `cell` in `mesh`.
"""
@inline function left_edge(cell::Int, mesh::AbstractFVMesh1D)
    @boundscheck begin
        assert(1 <= cell <= numcells(mesh))
    end
    cell
end

"""
    right_edge(cell::Int, mesh::AbstractFVMesh1D)

The index of the edge to the right of `cell` in `mesh`.
"""
@inline function right_edge(cell::Int, mesh::AbstractFVMesh1D)
    @boundscheck begin
        assert(1 <= cell <= numcells(mesh))
    end
    cell+1
end
