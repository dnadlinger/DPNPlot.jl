export colorize_cam16, draw_cam16_ampl_bar, draw_cam16_phase_ring

using PyCall

# pyimport()-ing only in functions to avoid clash with precompilation (which
# varyingly led to installation problems or runtime crashes).

function make_cam16ucs()
    pyimport("colorio.cs").CAM16UCS(0.69, 20, 64 / π / 5)
end

function make_srgb1()
    pyimport("colorio.cs").SRGB1()
end

function colorize_cam16(complex_values; max_magnitude=nothing)
    if max_magnitude === nothing
        max_magnitude = maximum(abs.(complex_values))
    end
    colorize_cam16(abs.(complex_values) / max_magnitude, angle.(complex_values) / 2π)
end

function colorize_cam16(ampls, phases_turns)
    # Size of circle in CAM16UCS space. Constrained by size of SRGB gamut.
    r0 = 21.652

    camdata = Array{Float64}(undef, (3, size(ampls)...))
    # Linearly interpolate between white ([1, 0, 0]) and a color at the
    # L = 0.5 phase circle.
    for idx in eachindex(IndexCartesian(), ampls)
        camdata[1, idx] = 100 * (2 - ampls[idx]) / 2
        phase = 2π * phases_turns[idx] - 0.75π
        camdata[2, idx] = r0 * ampls[idx] * cos(phase)
        camdata[3, idx] = r0 * ampls[idx] * sin(phase)
    end
    cam = make_cam16ucs()
    srgb = make_srgb1()
    clamp.(srgb.from_xyz100(cam.to_xyz100(camdata), mode="clip"), 0, 1)
end

function draw_cam16_ampl_bar(centre_x, centre_y, width, height, min, max, ax; direction=:vertical, fontsize=6)
    mc = pyimport("matplotlib.collections")
    mp = pyimport("matplotlib.patches")

    patches = []
    steps = 256
    if direction == :vertical
        ys = centre_y .+ range(-height / 2, height / 2, length=steps + 1)[1:end - 1]
        for y in ys
            push!(patches, mp.Rectangle((centre_x - width / 2, y), width, height / steps,
                linewidth=0, edgecolor="none"))
        end
    elseif direction == :horizontal
        xs = centre_x .+ range(-width / 2, width / 2, length=steps + 1)[1:end - 1]
        for x in xs
            push!(patches, mp.Rectangle((x, centre_y - height / 2), width / steps, height,
                linewidth=0, edgecolor="none"))
        end
    else
        throw(ArgumentError("Invalid direction: '$(direction)'"))
    end
    
    p = mc.PatchCollection(patches, linewidth=0, antialiased=false)
    camdata = zeros((3, steps))
    camdata[1, :] = range(100, 50, length=steps)
    cam = make_cam16ucs()
    srgb = make_srgb1()
    colors = srgb.from_xyz100(cam.to_xyz100(camdata), mode="clip")
    p.set_facecolor(colors')
    ax.add_collection(p)
    
    rect = mp.Rectangle((centre_x - width / 2, centre_y - height / 2), width, height,
        facecolor="none", edgecolor="k", linewidth=0.4)
    ax.add_patch(rect)
    
    if direction == :vertical
        ax.annotate("$(min)", (centre_x, centre_y - height / 2),
            (0, -1), textcoords="offset points",
            size=fontsize, color=colors[:, end],
            horizontalalignment="center", verticalalignment="top")
        ax.annotate("$(max)",  (centre_x, centre_y + height / 2),
            (0, 0), textcoords="offset points",
            size=fontsize, color=colors[:, end],
            horizontalalignment="center", verticalalignment="bottom")
    else
        ax.annotate("$(min)", (centre_x - width / 2, centre_y),
            (-2, 0), textcoords="offset points",
            size=fontsize, color=colors[:, end],
            horizontalalignment="right", verticalalignment="center")
        ax.annotate("$(max)", (centre_x + width / 2, centre_y),
            (3, 0), textcoords="offset points",
            size=fontsize, color=colors[:, end],
            horizontalalignment="left", verticalalignment="center")
    end
end

function draw_cam16_phase_ring(x, y, radius, ax; fontsize=6)
    mc = pyimport("matplotlib.collections")
    mp = pyimport("matplotlib.patches")

    patches = []
    steps = 256
    degree_each = 360 / steps
    for i in 1:steps
        push!(patches, mp.Wedge((x, y), radius,
            (i - 1) * degree_each, i * degree_each, width=radius / 2))
    end
    p = mc.PatchCollection(patches, linewidth=0, antialiased=false)
    colors = colorize_cam16(ones(steps), collect(range(0, 1, length=steps + 1))[1:end - 1])
    p.set_facecolor(colors')
    ax.add_collection(p)

    padded = 1.1 * radius
    cam = make_cam16ucs()
    srgb = make_srgb1()
    one_cam = cam.from_xyz100(srgb.to_xyz100(colors[:, 1]))
    color = srgb.from_xyz100(cam.to_xyz100([one_cam[1], 0, 0]))
    ax.annotate(L"$+$", (x + padded, y), ha="left", va="center", size=fontsize, color=color)
    ax.annotate(L"$-$", (x - padded, y), ha="right", va="center", size=fontsize, color=color)
    # Corrections for Minion Pro via LaTeX; should probably find a better way.
    ax.annotate(L"$\mathrm{i}$", (x, y + padded), (0, -fontsize / 8), textcoords="offset points", ha="center", va="bottom", size=fontsize, color=color)
    ax.annotate(L"$-\mathrm{i}$", (x, y - padded), (-fontsize / 4, 0), textcoords="offset points", ha="center", va="top", size=fontsize, color=color)
end
