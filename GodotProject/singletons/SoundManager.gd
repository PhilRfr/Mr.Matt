extends Node

const SAMPLES = {
	"loss": preload("res://sounds/fx/loss.wav"),
	"no": preload("res://sounds/fx/no.wav"),
	"boulder": preload("res://sounds/fx/boulder.wav"),
	"pick": preload("res://sounds/fx/pick.wav"),
	"error": preload("res://sounds/fx/error.wav"),
	"win": preload("res://sounds/fx/win.wav"),
}

const POOL_SIZE = 8
var pool = []
# Index of the current audio player in the pool.
var next_player = 0

func _ready():
	_init_stream_players()

func _init_stream_players():
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		pool.append(player)

func _get_next_player_idx():
	var next = next_player
	next_player = (next_player + 1) % POOL_SIZE
	return next

func play(sample):
	assert(sample in SAMPLES)
	var stream = SAMPLES[sample]
	var idx = _get_next_player_idx()

	var player = pool[idx]
	player.stream = stream
	player.play()
