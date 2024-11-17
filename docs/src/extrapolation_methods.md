# Extrapolation methods

We will use the following interpolation to demonstrate the various extrapolation methods.

```@example tutorial
using DataInterpolations, Plots

u = [0.86, 0.65, 0.44, 0.76, 0.73]
t = [0.0022, 0.68, 1.41, 2.22, 2.46]
t_eval_down = range(-1, first(t), length = 25)
t_eval_up = range(last(t), 3.5, length = 25)
A = QuadraticSpline(u, t)
plot(A)
```

Extrapolation behavior can be set for `t` beyond the data in the negative and positive direction separately with the `extrapolation_down` and `extrapolation_up` keywords of the interpolation constructors respectively.

## `ExtrapolationType.none`

This extrapolation type will throw an error when the input `t` is beyond the data in the specified direction.

## `ExtrapolationType.constant`

This extrapolation type extends the interpolation with the boundary values of the data `u`.

```@example tutorial
A = QuadraticSpline(u, t; extrapolation_down = ExtrapolationType.constant,
    extrapolation_up = ExtrapolationType.constant)
plot(A)
plot!(t_eval_down, A.(t_eval_down); label = "extrapolation down")
plot!(t_eval_up, A.(t_eval_up); label = "extrapolation up")
```

## `ExtrapolationType.linear`

This extrapolation type extends the interpolation with a linear continuation of the interpolation, making it $C^1$ smooth at the data boundaries.

```@example tutorial
A = QuadraticSpline(u, t; extrapolation_down = ExtrapolationType.linear,
    extrapolation_up = ExtrapolationType.linear)
plot(A)
plot!(t_eval_down, A.(t_eval_down); label = "extrapolation down")
plot!(t_eval_up, A.(t_eval_up); label = "extrapolation up")
```

## `ExtrapolationType.extension`

This extrapolation type extends the interpolation with a continuation of the expression for the interpolation at the boundary intervals for maximum smoothness.

```@example tutorial
A = QuadraticSpline(u, t; extrapolation_down = ExtrapolationType.extension,
    extrapolation_up = ExtrapolationType.extension)
plot(A)
plot!(t_eval_down, A.(t_eval_down); label = "extrapolation down")
plot!(t_eval_up, A.(t_eval_up); label = "extrapolation up")
```