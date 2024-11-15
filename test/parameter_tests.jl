using DataInterpolations

@testset "Linear Interpolation" begin
    u = [1.0, 5.0, 3.0, 4.0, 4.0]
    t = collect(1:5)
    A = LinearInterpolation(u, t; cache_parameters = true)
    @test A.p.slope ≈ [4.0, -2.0, 1.0, 0.0]
end

@testset "Quadratic Interpolation" begin
    u = [1.0, 5.0, 3.0, 4.0, 4.0]
    t = collect(1:5)
    A = QuadraticInterpolation(u, t; cache_parameters = true)
    @test A.p.l₀ ≈ [0.5, 2.5, 1.5]
    @test A.p.l₁ ≈ [-5.0, -3.0, -4.0]
    @test A.p.l₂ ≈ [1.5, 2.0, 2.0]
end

@testset "Quadratic Spline" begin
    u = [1.0, 5.0, 3.0, 4.0, 4.0]
    t = collect(1:5)
    A = QuadraticSpline(u, t; cache_parameters = true)
    @test A.p.α ≈ [-9.5, 3.5, -0.5, -0.5]
    @test A.p.β ≈ [13.5, -5.5, 1.5, 0.5]
end

@testset "Cubic Spline" begin
    u = [1, 5, 3, 4, 4]
    t = collect(1:5)
    A = CubicSpline(u, t; cache_parameters = true)
    @test A.p.c₁ ≈ [6.839285714285714, 1.642857142857143, 4.589285714285714, 4.0]
    @test A.p.c₂ ≈ [1.0, 6.839285714285714, 1.642857142857143, 4.589285714285714]
end

@testset "Cubic Hermite Spline" begin
    du = [5.0, 3.0, 6.0, 8.0, 1.0]
    u = [1.0, 5.0, 3.0, 4.0, 4.0]
    t = collect(1:5)
    A = CubicHermiteSpline(du, u, t; cache_parameters = true)
    @test A.p.c₁ ≈ [-1.0, -5.0, -5.0, -8.0]
    @test A.p.c₂ ≈ [0.0, 13.0, 12.0, 9.0]
end

@testset "Quintic Hermite Spline" begin
    ddu = [0.0, 3.0, 6.0, 4.0, 5.0]
    du = [5.0, 3.0, 6.0, 8.0, 1.0]
    u = [1.0, 5.0, 3.0, 4.0, 4.0]
    t = collect(1:5)
    A = QuinticHermiteSpline(ddu, du, u, t; cache_parameters = true)
    @test A.p.c₁ ≈ [-1.0, -6.5, -8.0, -10.0]
    @test A.p.c₂ ≈ [1.0, 19.5, 20.0, 19.0]
    @test A.p.c₃ ≈ [1.5, -37.5, -37.0, -26.5]
end
