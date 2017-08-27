export plot_equidistant_2d_mesh

# Shifts a regularly spaced list of coordinates
function center_to_corner_coords(xs)
    @assert length(xs) > 0 "Need at least one point to plot per axis"
    if length(xs) == 1
        # Plot a single value as
        [-0.5, 0.5] .+ xs[1]
    else
        step = xs[2] - xs[1]
        [xs; [xs[end] + step]] - step / 2
    end
end

"""
Generates a 2D plot where values are represented by uniformly sized coloured
rectangles.

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
function plot_equidistant_2d_mesh(xs::Vector, ys::Vector, zs::Matrix, ax=nothing; kwargs...)
    if ax == nothing
        ax = gca()
    end

    corner_xs = center_to_corner_coords(xs)
    corner_ys = center_to_corner_coords(ys)
    img = ax[:pcolormesh](corner_xs, corner_ys, zs'; kwargs...)
    ax[:set_xlim](corner_xs[1], corner_xs[end])
    ax[:set_ylim](corner_ys[1], corner_ys[end])

    ax, img
end
