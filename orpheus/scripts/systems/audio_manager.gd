extends Node
## Procedural audio (autoload "AudioManager").
## Every sound effect and the background music are synthesized in code at
## startup, so there are no audio files to download, import, or break.
##
## Usage:  AudioManager.play("jump")   AudioManager.start_music()

const SFX_RATE := 22050
const MUSIC_RATE := 11025
const SFX_VOICES := 8
const SFX_VOLUME_DB := -6.0
const MUSIC_VOLUME_DB := -15.0
const BEAT_SECONDS := 0.62

# A minor pentatonic - it always sounds pleasant, whatever order it is played in
const SCALE := [220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 659.25]
# Indexes into SCALE. -1 is a rest.
const MELODY := [0, 2, 4, 5, 4, 2, 1, -1, 3, 5, 6, 5, 4, 2, 0, -1,
		0, 3, 4, 7, 5, 4, 2, -1, 1, 2, 4, 2, 1, 0, -1, -1]

var music_muted := false

var _sfx: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _plucks: Dictionary = {}
var _pluck_voices: Array[AudioStreamPlayer] = []
var _next_pluck_voice := 0
var _drone: AudioStreamPlayer
var _music_on := false
var _beat_timer := 0.0
var _step := 0
var _warmup: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep music running while paused
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	for i in 3:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = MUSIC_VOLUME_DB
		add_child(voice)
		_pluck_voices.append(voice)
	_drone = AudioStreamPlayer.new()
	_drone.volume_db = MUSIC_VOLUME_DB - 9.0
	add_child(_drone)
	_build_sfx()
	# Music notes are generated one per frame so the game never hitches.
	for i in SCALE.size():
		_warmup.append(i)


func _process(delta: float) -> void:
	if not _warmup.is_empty():
		var index: int = _warmup.pop_front()
		_get_pluck(index)
	if _music_on and not music_muted:
		_beat_timer -= delta
		if _beat_timer <= 0.0:
			_beat_timer += BEAT_SECONDS
			_play_melody_step()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		set_music_muted(not music_muted)


# ---------------------------------------------------------------- public API
func play(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _sfx[sfx_name]
	voice.pitch_scale = pitch
	voice.volume_db = SFX_VOLUME_DB + volume_db
	voice.play()


func start_music() -> void:
	if _music_on:
		return
	_music_on = true
	if _drone.stream == null:
		_drone.stream = _make_drone()
	if not music_muted:
		_drone.play()


func set_music_muted(muted: bool) -> void:
	music_muted = muted
	if muted:
		_drone.stop()
	elif _music_on:
		_drone.play()


# ---------------------------------------------------------------- music
func _play_melody_step() -> void:
	var note: int = MELODY[_step % MELODY.size()]
	_step += 1
	if note < 0 or randf() < 0.1:
		return
	var voice := _pluck_voices[_next_pluck_voice]
	_next_pluck_voice = (_next_pluck_voice + 1) % _pluck_voices.size()
	voice.stream = _get_pluck(note)
	voice.volume_db = MUSIC_VOLUME_DB + randf_range(-2.0, 1.0)
	voice.play()


func _get_pluck(index: int) -> AudioStreamWAV:
	if _plucks.has(index):
		return _plucks[index]
	var freq: float = SCALE[index]
	var count := int(1.3 * MUSIC_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MUSIC_RATE
		var tone := sin(TAU * freq * t) + 0.4 * sin(TAU * freq * 2.0 * t) * exp(-t * 6.0) \
				+ 0.15 * sin(TAU * freq * 3.0 * t) * exp(-t * 9.0)
		samples[i] = tone * exp(-t * 3.2) * 0.35
	# A soft echo, like a lyre in a stone hall
	samples = _with_echo(samples, 0.36, 0.38, 2, MUSIC_RATE)
	var stream := _to_stream(samples, MUSIC_RATE)
	_plucks[index] = stream
	return stream


func _make_drone() -> AudioStreamWAV:
	# Whole numbers of cycles per loop, so it repeats with no click.
	var count := MUSIC_RATE * 4
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MUSIC_RATE
		var tone := 0.5 * sin(TAU * 110.0 * t) + 0.3 * sin(TAU * 165.0 * t) + 0.4 * sin(TAU * 55.0 * t)
		var swell := 0.75 + 0.25 * sin(TAU * 0.5 * t)
		samples[i] = tone * swell * 0.3
	var stream := _to_stream(samples, MUSIC_RATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream


# ---------------------------------------------------------------- sound effects
func _build_sfx() -> void:
	_sfx["jump"] = _to_stream(_tone(300.0, 640.0, 0.16, 0, 0.45, 1.5))
	_sfx["land"] = _to_stream(_tone(160.0, 60.0, 0.09, 0, 0.55, 2.0))
	_sfx["collect"] = _to_stream(_with_echo(_sequence([1046.5, 1568.0, 2093.0], 0.055, 0, 0.4, 2.2), 0.09, 0.35, 2))
	_sfx["stomp"] = _to_stream(_tone(180.0, 420.0, 0.12, 1, 0.3, 1.5))
	_sfx["checkpoint"] = _to_stream(_with_echo(_sequence([523.25, 659.25, 783.99, 1046.5], 0.11, 0, 0.4, 1.6), 0.16, 0.35, 2))
	_sfx["respawn"] = _to_stream(_tone(200.0, 900.0, 0.3, 0, 0.3, 1.2))
	_sfx["locked"] = _to_stream(_sequence([180.0, 150.0], 0.12, 1, 0.3, 1.0))
	_sfx["click"] = _to_stream(_tone(700.0, 500.0, 0.05, 2, 0.35, 1.0))
	_sfx["portal"] = _to_stream(_with_echo(_tone(220.0, 880.0, 0.7, 0, 0.4, 0.8), 0.2, 0.3, 2))
	_sfx["win"] = _to_stream(_with_echo(
			_sequence([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.16, 0, 0.42, 1.4), 0.24, 0.4, 3))
	# Damage: noise burst plus a falling sawtooth
	var hurt := _tone(320.0, 70.0, 0.4, 3, 0.35, 1.3)
	_mix_into(hurt, _noise(0.25, 0.4, 2.5), 0, 1.0)
	_sfx["hurt"] = _to_stream(hurt)


## wave: 0 sine, 1 square, 2 triangle, 3 sawtooth
func _tone(freq_start: float, freq_end: float, duration: float, wave: int,
		volume: float, decay: float, rate: int = SFX_RATE) -> PackedFloat32Array:
	var count := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var progress := float(i) / float(count)
		phase += lerpf(freq_start, freq_end, progress) / float(rate)
		var cycle := phase - floorf(phase)
		var s := 0.0
		match wave:
			0:
				s = sin(TAU * cycle)
			1:
				s = 1.0 if cycle < 0.5 else -1.0
			2:
				s = 4.0 * absf(cycle - 0.5) - 1.0
			_:
				s = 2.0 * cycle - 1.0
		var attack := minf(1.0, float(i) / 60.0)
		out[i] = s * volume * attack * pow(1.0 - progress, decay)
	return out


func _noise(duration: float, volume: float, decay: float) -> PackedFloat32Array:
	var count := int(duration * SFX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var progress := float(i) / float(count)
		out[i] = randf_range(-1.0, 1.0) * volume * pow(1.0 - progress, decay)
	return out


## A run of notes, one after another.
func _sequence(freqs: Array, note_length: float, wave: int, volume: float, decay: float) -> PackedFloat32Array:
	var step := int(note_length * SFX_RATE)
	var tail := int(note_length * 3.0 * SFX_RATE)
	var out := PackedFloat32Array()
	out.resize(step * (freqs.size() - 1) + tail)
	for i in freqs.size():
		var freq: float = freqs[i]
		_mix_into(out, _tone(freq, freq, note_length * 3.0, wave, volume, decay), i * step, 1.0)
	return out


func _mix_into(dest: PackedFloat32Array, source: PackedFloat32Array, offset: int, gain: float) -> void:
	var limit := mini(source.size(), dest.size() - offset)
	for i in limit:
		dest[offset + i] += source[i] * gain


func _with_echo(source: PackedFloat32Array, delay: float, gain: float, repeats: int,
		rate: int = SFX_RATE) -> PackedFloat32Array:
	var delay_samples := int(delay * rate)
	var out := PackedFloat32Array()
	out.resize(source.size() + delay_samples * repeats)
	for r in range(repeats + 1):
		_mix_into(out, source, delay_samples * r, pow(gain, r))
	return out


func _to_stream(samples: PackedFloat32Array, rate: int = SFX_RATE) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
