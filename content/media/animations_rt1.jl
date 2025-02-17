using CSV
using DataFrames
using Distributions
using SequentialSamplingModels
using GLMakie
using Downloads
using Random

# Data ==========================================================================================
cd(@__DIR__)
df = CSV.read(Downloads.download("https://raw.githubusercontent.com/DominiqueMakowski/CognitiveModels/main/data/wagenmakers2008.csv"), DataFrame)


function rescale_param(p; original_range=(-1, 1), new_range=(-3, 3))
    p = (p - original_range[1]) / (original_range[2] - original_range[1])
    p = p * (new_range[2] - new_range[1]) + new_range[1]
    return p
end

function change_param(frame; frame_range=(0, 1), param_range=(0, 1))
    frame = rescale_param(frame; original_range=frame_range, new_range=(1π, 2π))
    p = rescale_param(cos(frame); original_range=(-1, 1), new_range=param_range)
    return p
end

# Normal =====================================================================================
# fit(Normal, df.RT)

# Parameters
μ = Observable(0.0)
σ = Observable(0.4)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(Normal($μ, $σ), x))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("Normal(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)

density!(ax, df.RT, npoints=1000, color=:grey)
lines!(x, pdf.(fit(Normal, df.RT), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
fig

function make_animation(frame)
    if frame < 0.2
        μ[] = change_param(frame; frame_range=(0, 0.2), param_range=(0, 1))
    end
    if frame >= 0.2 && frame < 0.4
        μ[] = change_param(frame; frame_range=(0.2, 0.4), param_range=(1, 0.58))
    end
    if frame >= 0.4 && frame < 0.6
        σ[] = change_param(frame; frame_range=(0.4, 0.6), param_range=(0.4, 0.18))
    end
    # Return to normal
    if frame >= 0.7
        μ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.58, 0))
        σ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.18, 0.4))
    end
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_normal.gif", frames; framerate=30)

# ExGaussian =====================================================================================

# Parameters
μ = Observable(0.0)
σ = Observable(0.4)
τ = Observable(0.1)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(ExGaussian($μ, $σ, $τ), x))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("ExGaussian(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)), τ = $(round($τ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
density!(ax, df.RT, npoints=1000, color=:grey)
lines!(x, pdf.(ExGaussian(0.4, 0.06, 0.2), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
fig

function make_animation(frame)
    if frame < 0.2
        μ[] = change_param(frame; frame_range=(0, 0.2), param_range=(0, 0.4))
    end
    if frame >= 0.2 && frame < 0.4
        σ[] = change_param(frame; frame_range=(0.2, 0.4), param_range=(0.4, 0.1))
    end
    if frame >= 0.4 && frame < 0.6
        τ[] = change_param(frame; frame_range=(0.4, 0.6), param_range=(0.1, 0.4))
    end
    # Return to normal
    if frame >= 0.7
        μ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.4, 0))
        σ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.1, 0.4))
        τ[] = change_param(frame; frame_range=(0.7, 1), param_range=(0.4, 0.1))
    end
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_exgaussian.gif", frames; framerate=30)


# ExGaussian 2 =====================================================================================
# Parameters
μ = Observable(0.3)
σ = Observable(0.2)
τ = Observable(0.001)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(ExGaussian($μ, $σ, $τ), x))

m = Observable(mean(rand(ExGaussian(0.3, 0.2, 0.001), 100_000)))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("ExGaussian(μ = $(round($μ, digits = 1)), σ =  $(round($σ, digits = 2)), τ = $(round($τ, digits = 3)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
lines!(x, y, linewidth=4, color=:orange)
vlines!(m, color=:green, label="Average RT")
leg = axislegend(position=:rt)
fig

function make_animation(frame)
    if frame < 0.5
        τ[] = change_param(frame; frame_range=(0, 0.5), param_range=(0.001, 0.4))
    end
    # Return to normal
    if frame >= 0.5
        τ[] = change_param(frame; frame_range=(0.5, 1), param_range=(0.4, 0.001))
    end
    m[] = mean(rand(ExGaussian(0.3, 0.2, τ[]), 100_000))
end

# animation settings
frames = range(0, 1, length=60)
record(make_animation, fig, "rt_exgaussian2.gif", frames; framerate=30)

# Wald =====================================================================================
# using Turing

# @model function wald_model(x)
#     ν ~ truncated(Normal(0, 1); lower=0)
#     α ~ truncated(Normal(0, 1); lower=0)
#     τ ~ truncated(Normal(0, 1); lower=0)
#     x ~ Wald(ν, α, τ)
# end
# sample(wald_model(df.RT), NUTS(), 400)

# Parameters
ν = Observable(2.0)
α = Observable(1.0)
τ = Observable(0.0)

x = range(-0.1, 2, length=1000)
y = @lift(pdf.(Wald($ν, $α, $τ), x))

m = Observable(mean(rand(Wald(2.0, 1.0, 0.0), 100_00)))

# Initialize the figure
fig = Figure()
ax = Axis(
    fig[1, 1],
    title=@lift("Wald(ν = $(round($ν, digits = 1)), α =  $(round($α, digits = 2)), τ = $(round($τ, digits = 2)))"),
    xlabel="RT (s)",
    ylabel="Distribution",
    yticksvisible=false,
    xticksvisible=false,
    yticklabelsvisible=false,
)
density!(ax, df.RT, npoints=1000, color=:grey)
# lines!(x, pdf.(Wald(4.03, 1.76, 0.143), x), linestyle=:dot, color=:red)  # Best fitting line
lines!(x, y, linewidth=4, color=:orange)
vlines!(m, color=:green, label="Average RT")
leg = axislegend(position=:rt)
fig

function make_animation(frame)
    if frame < 0.1
        τ[] = change_param(frame; frame_range=(0.0, 0.1), param_range=(0.0, 0.4))
    end
    if frame >= 0.1 && frame < 0.2
        τ[] = change_param(frame; frame_range=(0.1, 0.2), param_range=(0.4, 0.143))
    end
    if frame >= 0.25 && frame < 0.35
        α[] = change_param(frame; frame_range=(0.25, 0.35), param_range=(1.0, 2.5))
    end
    if frame >= 0.35 && frame < 0.45
        α[] = change_param(frame; frame_range=(0.35, 0.45), param_range=(2.5, 1.76))
    end
    if frame >= 0.55 && frame < 0.65
        ν[] = change_param(frame; frame_range=(0.55, 0.65), param_range=(2.0, 1.25))
    end
    if frame >= 0.65 && frame < 0.75
        ν[] = change_param(frame; frame_range=(0.65, 0.75), param_range=(1.25, 4.0))
    end
    # Return to normal
    if frame >= 0.8
        ν[] = change_param(frame; frame_range=(0.8, 1), param_range=(4.0, 2.0))
        α[] = change_param(frame; frame_range=(0.8, 1), param_range=(1.76, 1.0))
        τ[] = change_param(frame; frame_range=(0.8, 1), param_range=(0.143, 0.0))
    end
    m[] = mean(rand(Wald(ν[], α[], τ[]), 100_000))
end

# animation settings
frames = range(0, 1, length=120)
record(make_animation, fig, "rt_wald.gif", frames; framerate=30)

