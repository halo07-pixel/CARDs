extends "res://tests/test_case.gd"
## Tách lượt quái thành từng bước (begin_enemy_turn / run_next_enemy) KHÔNG được đổi hành vi của end_player_turn().
## GOLDEN là "dấu vân tay" (xem tests/enemy_turn_fingerprint.gd) của 40 trận mô phỏng, ghi từ code TRƯỚC khi tách:
## mọi sự kiện, mọi thay đổi máu/giáp/status, kết quả từng hiệu ứng và trạng thái cuối phải trùng từng byte.
## Chú thích: kết cục, số lượt, số lần quái đi. Kịch bản phủ thắng, thua giữa lượt quái và chạm trần lượt.

const Fingerprint := preload("res://tests/enemy_turn_fingerprint.gd")

const GOLDEN := {
	1: "96510bc81210a3c335a8fa962f42b30ebe03bd55f48d314d7e206ba3a18fff81",  # victory lượt 4, 6 lần quái đi
	2: "587e48fd4447343f7b1f8a29af0b470fd3513b06058267d05591bf433f315b60",  # victory lượt 1, 0 lần quái đi
	3: "62f3ed4abcf9a8dfc3a63aac7c4b6348b8e5305c757788ff9d95898f79b251be",  # defeat lượt 3, 6 lần quái đi
	4: "d9e8873e425d73f1eb8281f639b69a58bd10a12a7e18a83cce95b9eccd4df660",  # victory lượt 4, 4 lần quái đi
	5: "07d2f27e2e2dc2437f7ccce89b2d51bafea76e14af43a3d6856c9f7f827df149",  # turn_cap lượt 3, 6 lần quái đi
	6: "2e4fa8d628ca35d2c7e90b6945de86730ad57e90693f1bce940b2c860dbd3b03",  # victory lượt 1, 0 lần quái đi
	7: "820eff69f12ad9fa37f7a426bb028a68cd64c9b6c4a1f6896d54e232fde1a6b1",  # victory lượt 4, 7 lần quái đi
	8: "38e1551c56996d64b6d6de650a2ea92db6d90a9160631a6a3807a0fb0a443c69",  # victory lượt 4, 4 lần quái đi
	9: "87c5b56ebe3734265a739e28baeca86ede7f8c6ff4aae636937199e70a52661c",  # defeat lượt 3, 5 lần quái đi
	10: "158938e1c0516eef7221fc60048f1a8b0001ad451b13853fd5dd9eb593f59437",  # victory lượt 1, 0 lần quái đi
	11: "b33541032904d3a768d2acef81ba14da18dbc72e02eafeca47e5ba7ef3670608",  # victory lượt 4, 5 lần quái đi
	12: "33388566647f53d929cafd256fb489f076b6e76fbd4421fafd1b493a876431a9",  # victory lượt 4, 4 lần quái đi
	13: "e3473e479987acaf664a0509e3cdc9a5860ff4d85b0e2aa6f55c72322ef931f1",  # victory lượt 2, 2 lần quái đi
	14: "6f1004c80eb485ffa697f0e9ef8ecba30b9622c8a97f64e25e108a86802b9f5f",  # victory lượt 1, 0 lần quái đi
	15: "e0c7ca7ff21b647bd1fa9c22764f38a5dccb8985e2401bc59eba07da0956166d",  # defeat lượt 2, 3 lần quái đi
	16: "b7999c3cef46c9ec09f40a1c890e8b36c2f6c7014d38300eeee48024dba2e4f0",  # victory lượt 4, 4 lần quái đi
	17: "09027fe0009a9d78385554f9c9d014fa7a9369e45069e13f7e705ff0af196477",  # victory lượt 5, 9 lần quái đi
	18: "b73cddeaf0e913a736de9ebdeb53c4f7685e55ff69cf6fc0eb7ba820c491052d",  # victory lượt 1, 0 lần quái đi
	19: "4d7875f3f2ce4fd2b69941c3af9107d383c173f4e1a82665c918d330783651fd",  # victory lượt 5, 10 lần quái đi
	20: "e80b43cf52a75be8f20608bcb3d3616d26e74ec6df035da30df7f8bc4430bc27",  # turn_cap lượt 3, 4 lần quái đi
	21: "cb9ddd309ffeecaebf3b5d929fe4ce46c9afa04af5596e166135c9da61245cf4",  # defeat lượt 3, 2 lần quái đi
	22: "f2bbf3e75adf42f8c30b40d93bb9f5d1b9075a753fc72089db00186b7a968f1f",  # victory lượt 1, 0 lần quái đi
	23: "d28911776982435ec110f0ecc9daf7ba325fe9b336d287e4136f41d682038bfb",  # victory lượt 5, 9 lần quái đi
	24: "625bfca925d0bc71bb7416576d993d24a36a86e3045eac71bb307570fc701559",  # victory lượt 5, 6 lần quái đi
	25: "8d226caeb4f72131e6e46afa706fa1916f10bfb1ce1e7597a59fa3c07fca9a9a",  # turn_cap lượt 3, 6 lần quái đi
	26: "14bf0d5d2beaec16774dd3abe64710b07683c753ad9730076de366e1e22c0b5b",  # victory lượt 1, 0 lần quái đi
	27: "7181de48cbf162b4539efbc87f4b2ec09e97c425ec8836b27250b24c502e63d8",  # defeat lượt 2, 3 lần quái đi
	28: "d338caa802549c2c0c09f54e8bc6a3a7c5e95a5d6c5860fb40deab4e58b7b1e7",  # victory lượt 4, 4 lần quái đi
	29: "e940194f34fe8e141f0a4751dc763aa1cdbcb55bc5fd57ec0341a81372fc8982",  # victory lượt 7, 8 lần quái đi
	30: "5656ebb253bc3c9fa52fe01e11e8ced808d49d423c4788882b7fd1fa51e7025a",  # victory lượt 1, 0 lần quái đi
	31: "734f55718f8fe2c39b55aae69ff57c50d68d1a5f7b16392545a44108aabf26c1",  # victory lượt 5, 12 lần quái đi
	32: "e7dec1878ba474111ec2cfd958130f39861102c0752b5c8f7a46ce11a71e08b3",  # victory lượt 4, 4 lần quái đi
	33: "951fedb07ce71da2e2084735f29495a2f2729aed6f39335cb6ddc770e8293b6c",  # defeat lượt 3, 4 lần quái đi
	34: "29976e25e073b7b1b827d1b88254893890b8c7ceed5e85300f0510d8642f8d6c",  # victory lượt 1, 0 lần quái đi
	35: "ca2943adfce9782da3b739867bc4200dd8b932bb208c4f36d8f70047aa8189f6",  # turn_cap lượt 3, 9 lần quái đi
	36: "e38c5d035b3ce7bf550c043960e30267b3c0593a7b1b69c622f93eebd8eb81a4",  # victory lượt 4, 4 lần quái đi
	37: "41efc57a567c034c29928c7c66f8c7b1a7a3572bb1f738ae6fb1ecb81c32e87f",  # victory lượt 5, 7 lần quái đi
	38: "d8af48729a6b7a7026dd869ff22066c81a6ea2dd0e24282400d64d8f4b89d32d",  # victory lượt 1, 0 lần quái đi
	39: "eb8015034f8f1e0b5c6afc54185a8052cb931550010a274784e8e4e3247d7704",  # defeat lượt 2, 3 lần quái đi
	40: "8ea3e0f2a9ea2b0ef1db2e401aa5ea0b3168d3e50ddc90363761e9c8ce2b1e6f",  # turn_cap lượt 3, 4 lần quái đi
}


func test_end_player_turn_behaves_exactly_like_before_the_split() -> void:
	var data := GameData.load_default()
	var scenarios := Fingerprint.scenarios()
	assert_eq(scenarios.size(), GOLDEN.size())
	for scenario in scenarios:
		assert_eq(Fingerprint.fingerprint(scenario, data), GOLDEN[scenario["seed"]],
				"seed %d (%s, %s) lệch dấu vân tay so với trước khi tách" % [scenario["seed"], scenario["enemies"], scenario["bot"]])


func test_the_scenarios_cover_win_defeat_turn_cap_and_enemy_actions() -> void:
	var data := GameData.load_default()
	var reasons := {}
	var acted_total := 0
	for scenario in Fingerprint.scenarios():
		var result: Dictionary = Fingerprint.run(scenario, data)
		reasons[result["reason"]] = true
		acted_total += result["acted"]
	assert_true(reasons.has(&"victory") and reasons.has(&"defeat") and reasons.has(&"turn_cap"), "kết cục: %s" % [reasons.keys()])
	assert_true(acted_total > 100, "quái phải đi nhiều lần: %d" % acted_total)
