# Julia translation of
# https://stackoverflow.com/questions/16992038/inline-labels-in-matplotlib

export label_line, label_lines

"""
Places a text label next to the end of a line in a line plot.
"""
function label_line(line, x, label=none, align=true; xshift=0, yshift=0, extra_args...)
    ax = line["axes"]
    xdata = line[:get_xdata]()
    ydata = line[:get_ydata]()

    @assert x >= xdata[1] && x <= xdata[end] "x label location is outside data range!"

    ip = 1
    for i in 1:length(xdata)
        if x < xdata[i]
            ip = i
            break
        end
    end

    y = (ydata[ip + 1] + ydata[ip]) / 2
    xdist = xdata[ip + 1] - xdata[ip]
    if xdist != 0
        y = ydata[ip] + (ydata[ip + 1] - ydata[ip]) * (x - xdata[ip]) / xdist
    end

    if length(label) == 0
        label = line[:get_label]()
    end

    trans_angl = 0
    if align
        # Compute the slope
        dx = xdata[ip + 1] - xdata[ip]
        dy = ydata[ip + 1] - ydata[ip]
        ang = atan2(dy, dx) |> rad2deg

        # Transform to screen coordinates
        pt = [x, y]'
        trans_angle = ax["transData"][:transform_angles]([ang], pt)[1]
    end

    # Set a bunch of keyword arguments
    kwargs = Dict{Symbol, Any}(extra_args)
    if !haskey(kwargs, :color)
        kwargs[:color] = line[:get_color]()
    end

    if !haskey(kwargs, :alpha)
        kwargs[:alpha] = line[:get_alpha]()
    end

    if !haskey(kwargs, :horizontalalignment) && !haskey(kwargs, :ha)
        kwargs[:ha] = "center"
    end

    if !haskey(kwargs, :verticalalignment) && !haskey(kwargs, :va)
        kwargs[:va] = "center"
    end

    if !haskey(kwargs, :backgroundcolor)
        kwargs[:backgroundcolor] = ax[:get_facecolor]()
    end

    if !haskey(kwargs, :clip_on)
        kwargs[:clip_on] = true
    end

    if !haskey(kwargs, :zorder)
        kwargs[:zorder] = 2.5
    end

    kwargs[:rotation] = trans_angle

    ax[:text](x + xshift, y + yshift, label; kwargs...)
end

"""
Annotates the given lines with a text label adjacent to their end points (none
if label property not set).
"""
function label_lines(lines::Vector, align=true, xvals=nothing; kwargs...)
    ax = lines[1]["axes"]
    lab_lines = []
    labels = []

    #Take only the lines which have labels other than the default ones
    for line in lines
        label = line[:get_label]()
        if !contains(label, "_line")
            push!(lab_lines, line)
            push!(labels, label)
        end
    end

    if xvals == nothing
        xmin, xmax = ax[:get_xlim]()
        xvals = linspace(xmin, xmax, length(lab_lines) + 2)[2:end-1]
    end

    for (line, x, label) in zip(lab_lines, xvals, labels)
        xrange = extrema(line[:get_xdata]())
        label_line(line, clamp(x, xrange...), label, align; kwargs...)
    end
end
