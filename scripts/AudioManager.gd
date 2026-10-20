class_name AudioManager
extends Node

static var instance: AudioManager

enum SoundPack { DEFAULT, MEME_2026 }
var current_pack: SoundPack = SoundPack.DEFAULT

var sfx_player: AudioStreamPlayer
var dice_player: AudioStreamPlayer
var step_player: AudioStreamPlayer

# Meme capture pool
var meme_capture_streams: Array[AudioStream] = []
var active_tweens: Dictionary = {}
var procedural_sfx: Dictionary = {}

var last_roll_time: float = -999.0
var preloaded_dice_stream: AudioStream = null

signal intro_finished

const DEFAULT_CAPTURE_SOUND: AudioStream = preload("res://audio/capture.mp3")

# Exact paths to default audio assets
const DEFAULT_FILES = {
	"dice_roll": "res://audio/default/dice roll/dice_rolled.mp3",
	"capture": "res://audio/default/capture/capture_sound.mp3",
	"bonus": "res://audio/default/bonus/bonus_sound.mp3",
	"finish_each": "res://audio/default/finsih token/finish_each_token.mp3",
	"finish_all": "res://audio/default/finish all the token by player/finish_all_the_token.mp3",
	"game_over": "res://audio/default/game over/game_over.mp3",
	"intro": "res://audio/default/intro sound/intro_sound_4.21_sec.mp3"
}
# Ensure the folder path matches your actual project structure exactly
var meme_capture_sounds: Array[AudioStream] = [
	preload("res://audio/meme/capture/capture_1.mp3"),
	preload("res://audio/meme/capture/capture_10.mp3"),
	preload("res://audio/meme/capture/capture_11.mp3"),
	preload("res://audio/meme/capture/capture_12.mp3"),
	preload("res://audio/meme/capture/capture_13.mp3")
]

func _ready() -> void:
	instance = self

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	sfx_player.volume_db = 0.0
	add_child(sfx_player)

	dice_player = AudioStreamPlayer.new()
	dice_player.name = "DicePlayer"
	dice_player.bus = "Master"
	dice_player.volume_db = 0.0
	add_child(dice_player)

	step_player = AudioStreamPlayer.new()
	step_player.name = "StepPlayer"
	step_player.bus = "Master"
	step_player.volume_db = 0.0
	add_child(step_player)

	# Preload dice sound into memory immediately
	var roll_path = DEFAULT_FILES["dice_roll"]
	if ResourceLoader.exists(roll_path):
		preloaded_dice_stream = load(roll_path)

	_generate_procedural_sfx()
	_preload_meme_capture_pool()

func set_sound_pack(pack: SoundPack) -> void:
	current_pack = pack

func toggle_sound_pack() -> SoundPack:
	current_pack = SoundPack.MEME_2026 if current_pack == SoundPack.DEFAULT else SoundPack.DEFAULT
	return current_pack

# Load all files from res://audio/meme/capture
func _preload_meme_capture_pool() -> void:
	meme_capture_streams.clear()
	var folder_path = "res://audio/meme/capture"
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				var ext = file_name.get_extension().to_lower()
				if ext in ["mp3", "wav", "ogg"]:
					var stream_path = folder_path.path_join(file_name)
					var stream = load(stream_path)
					if stream:
						meme_capture_streams.append(stream)
			file_name = dir.get_next()

# Direct playback for default sounds
func _play_default_track(key: String, on_dice: bool = false, max_duration: float = 5.0) -> void:
	if not DEFAULT_FILES.has(key):
		return
	var path = DEFAULT_FILES[key]
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			var target_player = dice_player if on_dice else sfx_player
			_play_with_duration_cap(target_player, stream, max_duration)

# Dynamic cut-off timer with a smooth 0.3s fade-out
func _play_with_duration_cap(player: AudioStreamPlayer, stream: AudioStream, max_duration: float) -> void:
	var player_key = player.name
	if active_tweens.has(player_key) and active_tweens[player_key] != null:
		var old_tween: Tween = active_tweens[player_key]
		if old_tween.is_valid():
			old_tween.kill()

	player.stop()
	player.stream = stream
	player.volume_db = 0.0
	player.play()

	var fade_time = 0.3
	var sustain_time = max(0.0, max_duration - fade_time)

	var tween = create_tween()
	active_tweens[player_key] = tween
	tween.tween_interval(sustain_time)
	tween.tween_property(player, "volume_db", -40.0, fade_time)
	tween.tween_callback(func():
		if player.playing:
			player.stop()
		player.volume_db = 0.0
	)

# ==================== PUBLIC EVENT METHODS ====================

func play_intro(on_finished_callback: Callable = Callable()) -> void:
	if not DEFAULT_FILES.has("intro"):
		if on_finished_callback.is_valid():
			on_finished_callback.call()
		return

	var path = DEFAULT_FILES["intro"]
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			sfx_player.stop()
			sfx_player.stream = stream
			sfx_player.volume_db = 0.0
			sfx_player.play()

			var connection: Callable
			connection = func():
				if sfx_player.finished.is_connected(connection):
					sfx_player.finished.disconnect(connection)
				intro_finished.emit()
				if on_finished_callback.is_valid():
					on_finished_callback.call()

			sfx_player.finished.connect(connection)
			return

	if on_finished_callback.is_valid():
		on_finished_callback.call()

# Single-shot dice roll with active playing check
func play_dice_roll() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if (now - last_roll_time < 0.35) or (dice_player and dice_player.playing):
		return
	last_roll_time = now

	if preloaded_dice_stream:
		_play_with_duration_cap(dice_player, preloaded_dice_stream, 2.5)
	else:
		_play_default_track("dice_roll", true, 2.5)

# 1. Rolling a 6 plays bonus sound
func play_dice_six() -> void:
	_play_default_track("bonus", false, 4.0)

# 2. Token leaving home has its own bright spawn sound
func play_token_spawn() -> void:
	if procedural_sfx.has("spawn"):
		_play_with_duration_cap(sfx_player, procedural_sfx["spawn"], 1.5)
	else:
		_play_default_track("bonus", false, 1.5)

# 3. Dedicated step channel so it never cuts off other effects
func play_token_step() -> void:
	if procedural_sfx.has("step"):
		step_player.stream = procedural_sfx["step"]
		step_player.volume_db = -6.0
		step_player.play()

# 4. Token safe zone landing sound
func play_safe_place() -> void:
	if procedural_sfx.has("safe"):
		_play_with_duration_cap(sfx_player, procedural_sfx["safe"], 2.0)

# 5. Capture sound strictly capped at 3.0 seconds
func play_token_capture() -> void:
	if current_pack == SoundPack.MEME_2026 and not meme_capture_streams.is_empty():
		var chosen_stream: AudioStream = meme_capture_streams.pick_random()
		_play_with_duration_cap(sfx_player, chosen_stream, 3.0)
	else:
		_play_default_track("capture", false, 3.0)

# 6. Reaching finish goal
func play_token_finished() -> void:
	_play_default_track("finish_each", false, 5.0)

func play_player_win_fanfare() -> void:
	_play_default_track("finish_all", false, 5.0)

func play_game_over() -> void:
	_play_default_track("game_over", false, 5.0)

# ==================== CLEAN PROCEDURAL 16-BIT SFX ====================

func _generate_procedural_sfx() -> void:
	procedural_sfx["step"] = _make_tone_16bit(0.04, 600.0, 300.0, 0.35)
	procedural_sfx["spawn"] = _make_tone_16bit(0.22, 440.0, 880.0, 0.5)
	procedural_sfx["safe"] = _make_tone_16bit(0.25, 700.0, 950.0, 0.5)

func _make_tone_16bit(duration: float, start_f: float, end_f: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(duration * rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	var phase = 0.0

	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(start_f, end_f, t)
		phase += (freq * TAU) / float(rate)
		var env = exp(-t * 10.0)
		var sample_val = int(sin(phase) * env * vol * 32767.0)
		sample_val = clampi(sample_val, -32768, 32767)

		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
	
func play_capture_sound(is_meme_mode: bool = true) -> void:
	if is_meme_mode and meme_capture_sounds.size() > 0:
		var sound: AudioStream = meme_capture_sounds.pick_random()
		$SFXPlayer.stream = sound
		$SFXPlayer.play()
	else:
		$SFXPlayer.stream = default_capture_sound
		$SFXPlayer.play()
