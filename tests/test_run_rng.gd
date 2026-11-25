extends "res://tests/test_case.gd"
## RunRng: seed con theo luồng, tất định và độc lập giữa các luồng.


func test_same_inputs_give_the_same_seed() -> void:
	assert_eq(RunRng.derive(12345, &"map", 1), RunRng.derive(12345, &"map", 1))
	assert_eq(RunRng.derive(-7, &"reward"), RunRng.derive(-7, &"reward", 0), "index mặc định là 0")


func test_the_seed_changes_with_each_input() -> void:
	var base := RunRng.derive(1, &"map", 1)
	assert_ne(RunRng.derive(2, &"map", 1), base, "seed run khác")
	assert_ne(RunRng.derive(1, &"shop", 1), base, "luồng khác")
	assert_ne(RunRng.derive(1, &"map", 2), base, "chỉ số khác")


func test_streams_are_independent_of_each_other_for_many_seeds() -> void:
	var seen := {}
	for run_seed in 200:
		for stream in [&"map", &"reward", &"shop", &"event", &"encounter"]:
			for index in 3:
				var derived := RunRng.derive(run_seed, stream, index)
				assert_false(seen.has(derived), "trùng seed con: %d %s %d" % [run_seed, stream, index])
				seen[derived] = true


func test_a_known_value_is_stable_across_runs_and_versions() -> void:
	# Chốt giá trị để phát hiện nếu cách tách seed đổi (sẽ làm đổi mọi bản đồ/phần thưởng đã lưu). SHA-256 ổn định.
	assert_eq(RunRng.derive(1, &"map", 1), -8915091053135001856, "SHA-256 của \"1|map|1\", 8 byte đầu, little-endian có dấu (tính độc lập bằng Python)")


func test_make_returns_an_rng_seeded_with_the_derived_seed() -> void:
	var rng := RunRng.make(99, &"map", 2)
	assert_eq(rng.seed, RunRng.derive(99, &"map", 2))
	var again := RunRng.make(99, &"map", 2)
	assert_eq(rng.randi(), again.randi(), "cùng seed cùng dãy số")
