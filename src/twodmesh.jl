export plot_equidistant_2d_mesh

# Shifts a regularly spaced list of coordinates that give n pixel centres to the
# n + 1 corners of the respective pixels.
function center_to_corner_coords(xs)
    @assert length(xs) > 0 "Need at least one point to plot per axis"
    if length(xs) == 1
        # Plot a single value as taking up 1 unit of data coordinates.
        [-0.5, 0.5] .+ xs[1]
    else
        step = xs[2] - xs[1]
        [xs; [xs[end] + step]] .- step / 2
    end
end

"""
Generates a 2D plot where values are represented by uniformly sized coloured
rectangles.

The primary purpose of this function is to provide an interface that automatically leads
to the correct result for the usual case of grid-sampled data (whether from simulations
or an experiment), without having to worry about coordinate translation, etc.

Parameters
----------
xs
    A one-dimensional array of the data point x coordinates (centered). Assumed
    to be equally spaced.
ys
    A one-dimensional array of the data point y coordinates (centered). Assumed
    to be equally spaced.
zs
    A two-dimensional array of the data values at the corresponding coordinates.
    Outer dimension corresponds to the x axis.
ax
    The Axes object to use. Defaults to gca().

Returns
-------
A tuple with the Axes and plot objects.
"""
function plot_equidistant_2d_mesh(xs::AbstractVector, ys::AbstractVector, zs::AbstractMatrix, ax=nothing; output=:mesh, kwargs...)
    if ax === nothing
        ax = gca()
    end

    corner_xs = center_to_corner_coords(xs)
    corner_ys = center_to_corner_coords(ys)
    if output == :image
        extent = (corner_xs[1], corner_xs[end], corner_ys[1], corner_ys[end])
        # "auto" aspect for compatibility with pcolormesh defaults.
        img = ax.imshow(zs', origin="lower", extent=extent, aspect="auto"; kwargs...)
    elseif output == :mesh
        img = ax.pcolormesh(corner_xs, corner_ys, zs'; kwargs...)
    else
        throw(ArgumentError("Unexpected output type '$(output)'."))
    end
    ax.set_xlim(corner_xs[1], corner_xs[end])
    ax.set_ylim(corner_ys[1], corner_ys[end])

    ax, img
end
