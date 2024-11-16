function integral(A::AbstractInterpolation, t::Number)
    integral(A, first(A.t), t)
end

function integral(A::AbstractInterpolation, t1::Number, t2::Number)
    !hasfield(typeof(A), :I) && throw(IntegralNotFoundError())

    if t1 == t2 
        # If the integration interval is trivial then the result is 0
        return zero(eltype(A.I))
    elseif t1 > t2
        # Make sure that t1 < t2
        return -integral(A, t2, t1)
    end

    # the index less than or equal to t1
    idx1 = get_idx(A, t1, 0)
    # the index less than t2
    idx2 = get_idx(A, t2, 0; idx_shift = -1, side = :first)

    total = zero(eltype(A.I))

    # Lower potentially incomplete interval
    if t1 < first(A.t)

        if t2 < first(A.t)
            # If interval is entirely below data
            return _extrapolate_integral_down(A, t2) - extrapolate_integral_down(A.t1)
        end

        idx1 -= 1 # Make sure lowest complete interval is included
        total += _extrapolate_integral_down(A, t1)
    else
        total += _integral(A, idx1, t1, A.t[idx1 + 1])
    end

    # Upper potentially incomplete interval
    if t2 > last(A.t)

        if t1 > last(A.t)
            # If interval is entirely above data
            return _extrapolate_integral_up(A, t2) - extrapolate_integral_up(A.t, t1)
        end

        idx2 += 1 # Make sure highest complete interval is included
        total += _extrapolate_integral_up(A, t2)
    else
        total += _integral(A, idx2, A.t[idx2], t2)
    end

    if idx1 == idx2
        return _integral(A, idx1, t1, t2)
    end

    # Complete intervals
    if A.cache_parameters
        total += A.I[idx2] - A.I[idx1 + 1]
    else
        for idx in (idx1 + 1):(idx2 - 1)
            total += _integral(A, idx, A.t[idx], A.t[idx + 1])
        end
    end

    return total
end

function _extrapolate_integral_down(A, t)
    (; extrapolation_down) = A
    if extrapolation_down == ExtrapolationType.none
        throw(DownExtrapolationError())
    elseif extrapolation_down == ExtrapolationType.constant
        first(A.u) * (first(A.t) - t)
    elseif extrapolation_down == ExtrapolationType.linear
        slope = derivative(A, first(A.t))
        Δt = first(A.t) - t
        (first(A.u) - slope * Δt / 2) * Δt
    elseif extrapolation_down == ExtrapolationType.extension
        _integral(A, 1, t, first(A.t))
    end
end

function _extrapolate_integral_up(A, t)
    (; extrapolation_up) = A
    if extrapolation_up == ExtrapolationType.none
        throw(UpExtrapolationError())
    elseif extrapolation_up == ExtrapolationType.constant
        last(A.u) * (t - last(A.t))
    elseif extrapolation_up == ExtrapolationType.linear
        slope = derivative(A, last(A.t))
        Δt = t - last(A.t)
        (last(A.u) + slope * Δt / 2) * Δt
    elseif extrapolation_up == ExtrapolationType.extension
        _integral(A, length(A.t) - 1, last(A.t), t)
    end
end

function _integral(A::LinearInterpolation{<:AbstractVector{<:Number}},
        idx::Number, t1::Number, t2::Number)
    slope = get_parameters(A, idx)
    u_mean = A.u[idx] + slope * ((t1 + t2)/2 - A.t[idx])
    u_mean * (t2 - t1)
end

function _integral(
        A::ConstantInterpolation{<:AbstractVector{<:Number}}, idx::Number, t1::Number, t2::Number)
    Δt = t2 - t1
    if A.dir === :left
        # :left means that value to the left is used for interpolation
        return A.u[idx] * Δt
    else
        # :right means that value to the right is used for interpolation
        return A.u[idx + 1] * Δt
    end
end

function _integral(A::QuadraticInterpolation{<:AbstractVector{<:Number}},
        idx::Number,
        t::Number)
    A.mode == :Backward && idx > 1 && (idx -= 1)
    idx = min(length(A.t) - 2, idx)
    t₀ = A.t[idx]
    t₁ = A.t[idx + 1]
    t₂ = A.t[idx + 2]

    t_sq = (t^2) / 3
    l₀, l₁, l₂ = get_parameters(A, idx)
    Iu₀ = l₀ * t * (t_sq - t * (t₁ + t₂) / 2 + t₁ * t₂)
    Iu₁ = l₁ * t * (t_sq - t * (t₀ + t₂) / 2 + t₀ * t₂)
    Iu₂ = l₂ * t * (t_sq - t * (t₀ + t₁) / 2 + t₀ * t₁)
    return Iu₀ + Iu₁ + Iu₂
end

function _integral(A::QuadraticSpline{<:AbstractVector{<:Number}}, idx::Number, t1::Number, t2::Number)
    α, β = get_parameters(A, idx)
    uᵢ = A.u[idx]
    tᵢ = A.t[idx]
    t1_rel = t1 - tᵢ
    t2_rel = t2 - tᵢ
    Δt = t2 - t1
    Δt * (α * (t2_rel^2 + t1_rel * t2_rel + t1_rel^2) / 3 + β * (t2_rel + t1_rel) / 2 + uᵢ)
end

function _integral(A::CubicSpline{<:AbstractVector{<:Number}}, idx::Number, t1::Number, t2::Number)
    tᵢ = A.t[idx]
    tᵢ₊₁ = A.t[idx + 1]
    c₁, c₂ = get_parameters(A, idx)
    integrate_cubic_polynomial(t1, t2, tᵢ, 0, c₁, 0, A.z[idx + 1] / (6A.h[idx + 1])) +
    integrate_cubic_polynomial(t1, t2, tᵢ₊₁, 0, -c₂, 0, -A.z[idx] / (6A.h[idx + 1]))
end

function _integral(A::AkimaInterpolation{<:AbstractVector{<:Number}},
        idx::Number, t1::Number, t2::Number)
    integrate_cubic_polynomial(t1, t2, A.t[idx], A.u[idx], A.b[idx], A.c[idx], A.d[idx])
end

_integral(A::LagrangeInterpolation, idx::Number, t::Number) = throw(IntegralNotFoundError())
_integral(A::BSplineInterpolation, idx::Number, t::Number) = throw(IntegralNotFoundError())
_integral(A::BSplineApprox, idx::Number, t::Number) = throw(IntegralNotFoundError())

# Cubic Hermite Spline
function _integral(
        A::CubicHermiteSpline{<:AbstractVector{<:Number}}, idx::Number, t1::Number, t2::Number)
    c₁, c₂ = get_parameters(A, idx)
    tᵢ = A.t[idx]
    tᵢ₊₁ = A.t[idx + 1]
    c = c₁ - c₂ * (tᵢ₊₁ - tᵢ)
    integrate_cubic_polynomial(t1, t2, tᵢ, A.u[idx], A.du[idx], c, c₂)
end

# Quintic Hermite Spline
function _integral(
        A::QuinticHermiteSpline{<:AbstractVector{<:Number}}, idx::Number, t::Number)
    Δt₀ = t - A.t[idx]
    Δt₁ = t - A.t[idx + 1]
    out = Δt₀ * (A.u[idx] + A.du[idx] * Δt₀ / 2 + A.ddu[idx] * Δt₀^2 / 6)
    c₁, c₂, c₃ = get_parameters(A, idx)
    p = c₁ + c₂ * Δt₁ + c₃ * Δt₁^2
    dp = c₂ + 2c₃ * Δt₁
    ddp = 2c₃
    out += Δt₀^4 / 4 * (p - Δt₀ / 5 * dp + Δt₀^2 / 30 * ddp)
    out
end
