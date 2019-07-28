export pi_axis_labels, set_pi_axis_labels

function pi_axis_labels(min, max, step = 1//2)
    first, last = round.([min, max] / (pi * step))
    locs = Float64[]
    labels = String[]
    for k in first:last
        factor = Integer(k) * step
        push!(locs, factor * π)

        sign = factor < 0 ? "-" : ""

        abs_num = abs(numerator(factor))
        num_string =
            if abs_num == 0
                "0"
            elseif abs_num == 1
                "\\pi"
            else
                "$abs_num \\pi"
            end

        if denominator(factor) == 1
            push!(labels, "\$ $sign $num_string \$")
        else
            push!(labels, "\$ $sign \\frac{$num_string}{$(denominator(factor))} \$")
        end
    end

    locs, labels
end

"""
Places ticks and labels on an axis in given multiples of π.
"""
function set_pi_axis_labels(axis, min, max, step = 1//2)
    locs, labels = pi_axis_labels(min, max, step)
    axis.set_ticks(locs)
    axis.set_ticklabels(labels)
end
