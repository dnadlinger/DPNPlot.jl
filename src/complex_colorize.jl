export colorize_cam16, draw_cam16_ampl_bar, draw_cam16_phase_ring

using PyCall

# pyimport()-ing only in functions to avoid clash with precompilation (which
# varyingly led to installation problems or runtime crashes).

function make_cam16ucs()
    pyimport("colorio.cs").CAM16UCS(0.69, 20, 64 / π / 5)
end

function colorize_cam16(ampls, phases_turns)
    # Size of circle in CAM16UCS space. Constrained by size of SRGB gamut.
    r0 = 21.652

    camdata = Array{Float64}(undef, (3, size(ampls)...))
    # Linearly interpolate between white ([1, 0, 0]) and a color at the
    # L = 0.5 phase circle.
    for idx in eachindex(IndexCartesian(), ampls)
        camdata[1, idx] = 100 * (2 - ampls[idx]) / 2
        phase = 2π * phases_turns[idx] + 0.8π
        camdata[2, idx] = r0 * ampls[idx] * cos(phase)
        camdata[3, idx] = r0 * ampls[idx] * sin(phase)
    end
    cam = make_cam16ucs()
    clamp.(cam.to_rgb1(camdata), 0, 1)
end

function draw_cam16_ampl_bar(centre_x, centre_y, width, height, min, max, ax)
    mc = pyimport("matplotlib.collections")
    mp = pyimport("matplotlib.patches")

    patches = []
    steps = 256
    degree_each = 360 / steps
    ys = centre_y .+ range(-height / 2, height / 2, length=steps + 1)[1:end - 1]
    for y in ys
        push!(patches, mp.Rectangle((centre_x - width / 2, y), width, height / steps, linewidth=0, edgecolor="none"))
    end
    
    p = mc.PatchCollection(patches)
    camdata = zeros((3, steps))
    camdata[1, :] = range(100, 50, length=steps)
    cam = make_cam16ucs()
    colors = clamp.(cam.to_rgb1(camdata), 0, 1)
    p.set_facecolor(colors')
    ax.add_collection(p)
    
    rect = mp.Rectangle((centre_x - width / 2, centre_y - height / 2), width, height,
        facecolor="none", edgecolor="k", linewidth=0.4)
    ax.add_patch(rect)
    
    ax.text(centre_x, centre_y - height / 2 - 0.5, "$(min)", size=6, color=colors[:, end],
        horizontalalignment="center", verticalalignment="top")
    ax.text(centre_x, centre_y + height / 2, "$(max)", size=6, color=colors[:, end],
        horizontalalignment="center", verticalalignment="bottom")
end

function draw_cam16_phase_ring(x, y, radius, ax)
    mc = pyimport("matplotlib.collections")
    mp = pyimport("matplotlib.patches")

    patches = []
    steps = 256
    degree_each = 360 / steps
    for i in 1:steps
        push!(patches, mp.Wedge((x, y), radius,
            (i - 1) * degree_each, i * degree_each, width=radius / 2))
    end
    p = mc.PatchCollection(patches)
    colors = colorize_cam16(ones(steps), collect(range(0, 1, length=steps + 1))[1:end - 1])
    p.set_facecolor(colors')
    ax.add_collection(p)

    padded = 1.1 * radius
    cam = make_cam16ucs()
    color = cam.to_rgb1([cam.from_rgb1(colors[:, 1])[1], 0, 0])
    y_fudge = -0.4
    ax.text(x + padded, y + y_fudge, L"$+$", ha="left", va="center", size=6, color=color)
    ax.text(x - padded, y + y_fudge, L"$-$", ha="right", va="center", size=6, color=color)
    ax.text(x, y + padded + y_fudge, L"$\mathrm{i}$", ha="center", va="bottom", size=6, color=color)
    ax.text(x, y - padded + y_fudge, L"$-\mathrm{i}$", ha="center", va="top", size=6, color=color)
end
