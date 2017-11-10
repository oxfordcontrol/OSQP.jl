using OSQP, Base.Test


function setup()
        # Simple QP problem
	problem = Dict()
        problem[:P] = sparse([11. 0.; 0. 0.])
	problem[:q] = [3.; 4]
	problem[:A] = sparse([-1 0; 0 -1; -1 -3; 2 5; 3 4])
	problem[:u] = [0.; 0.; -15; 100; 80]
	problem[:l] = -Inf * ones(length(problem[:u]))
	problem[:n] = size(problem[:P], 1)
	problem[:m] = size(problem[:A], 1)
	options = Dict(:verbose => false,
		       :eps_abs => 1e-09,
		       :eps_rel => 1e-09,
		       :check_termination => 1,
		       :polish => false,
		       :max_iter => 4000,
		       :rho => 0.1,
		       :adaptive_rho => false,
		       :warm_start => true)
	return problem, options
end

tol = 1e-5


@testset "basic" begin

	@testset "basic_QP" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
			    A=problem[:A], l=problem[:l], u=problem[:u], options...)
		results = OSQP.solve!(model)

		@test isapprox(norm(results.x - [0.; 5.]), 0., atol=tol)
		@test isapprox(norm(results.y - [1.666666666666; 0.; 1.3333333; 0.; 0.]), 0., atol=tol)
		@test isapprox(results.info.obj_val, 20., atol=tol)

	end


	@testset "update_q" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], options...)

		OSQP.update!(model, q=[10.; 20.])
		results = OSQP.solve!(model)

		@test isapprox(norm(results.x - [0.; 5.]), 0., atol=tol)
		@test isapprox(norm(results.y - [3.33333333; 0.; 6.66666666; 0.; 0.]), 0., atol=tol)
		@test isapprox(results.info.obj_val, 100., atol=tol)

	end

	@testset "update_l" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], options...)

		OSQP.update!(model, l=-100 * ones(problem[:m]))
		results = OSQP.solve!(model)

		@test isapprox(norm(results.x - [0.; 5.]), 0., atol=tol)
		@test isapprox(norm(results.y - [1.6666666666; 0.; 1.333333333333; 0.; 0.]), 0., atol=tol)
		@test isapprox(results.info.obj_val, 20., atol=tol)

	end

	@testset "update_u" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], options...)

		OSQP.update!(model, u=1000 * ones(problem[:m]))
		results = OSQP.solve!(model)

		@test isapprox(norm(results.x - [-1.51515152e-01, -3.33282828e+02]), 0., atol=tol)
		@test isapprox(norm(results.y - [0.; 0.; 1.333333333333; 0.; 0.]), 0., atol=tol)
		@test isapprox(results.info.obj_val, -1333.459595961, atol=tol)

	end


	@testset "update_max_iter" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], options...)

		OSQP.update_settings!(model, max_iter=80)
		results = OSQP.solve!(model)

		@test results.info.status == :Max_iter_reached
	end

	@testset "update_check_termination" begin
		problem, options = setup()

		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], options...)

		OSQP.update_settings!(model, check_termination=false)
		results = OSQP.solve!(model)

		@test results.info.iter == options[:max_iter]
	end


	@testset "update_rho" begin
		problem, options = setup()

		# Setup default problem
		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
			    A=problem[:A], l=problem[:l], u=problem[:u], options...)

		results_default = OSQP.solve!(model)

		# Setup different rho and update to same rho
		new_opts = copy(options)
		new_opts[:rho] = 0.7
		model = OSQP.Model()
		OSQP.setup!(model; P=problem[:P], q=problem[:q],
		            A=problem[:A], l=problem[:l], u=problem[:u], new_opts...)
		OSQP.update_settings!(model, rho=options[:rho])
		results_new_rho = OSQP.solve!(model)

		@test results_default.info.iter == results_new_rho.info.iter
	end
end
