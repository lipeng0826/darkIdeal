extends Node
## 暗影深渊 - 音频管理器
## 使用 AudioStreamGenerator 程序化生成暗黑风音效

var _players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}  # 音效缓存，避免每次重新生PCM
const MAX_PLAYERS := 8

func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -6.0
		add_child(player)
		_players.append(player)

## 播放音效
func play_sfx(sfx_name: String) -> void:
	if not GameManager.is_loaded:
		return
	if not GameManager.game_data["settings"]["sound"]:
		return
	
	var stream := _generate_sfx(sfx_name)
	if stream == null:
		return
	
	# 找一个空闲的播放器
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# 都在用，抢第一个
	_players[0].stream = stream
	_players[0].play()

## 程序化生成音效(带缓存)
func _generate_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	var sample_rate := 22050
	var duration := 0.1
	var frequency := 440.0
	var volume := 0.3
	var wave_type := 0  # 0=sine, 1=square, 2=saw, 3=noise
	var freq_sweep := 0.0
	var decay := 4.0
	
	match sfx_name:
		"hit":
			frequency = 180.0; duration = 0.08; wave_type = 1; volume = 0.2
			freq_sweep = -80.0; decay = 8.0
		"crit":
			frequency = 350.0; duration = 0.15; wave_type = 2; volume = 0.35
			freq_sweep = -200.0; decay = 5.0
		"enemy_hit":
			frequency = 120.0; duration = 0.06; wave_type = 1; volume = 0.15
			freq_sweep = -40.0; decay = 10.0
		"levelup":
			frequency = 440.0; duration = 0.4; wave_type = 0; volume = 0.3
			freq_sweep = 300.0; decay = 2.0
		"pickup":
			frequency = 600.0; duration = 0.12; wave_type = 0; volume = 0.25
			freq_sweep = 300.0; decay = 6.0
		"craft":
			frequency = 300.0; duration = 0.25; wave_type = 0; volume = 0.3
			freq_sweep = 150.0; decay = 3.0
		"boss":
			frequency = 80.0; duration = 0.6; wave_type = 2; volume = 0.4
			freq_sweep = -40.0; decay = 1.5
		"button":
			frequency = 500.0; duration = 0.05; wave_type = 0; volume = 0.15
			freq_sweep = 0.0; decay = 12.0
		"error":
			frequency = 150.0; duration = 0.2; wave_type = 1; volume = 0.25
			freq_sweep = -60.0; decay = 4.0
		"reward":
			frequency = 523.0; duration = 0.3; wave_type = 0; volume = 0.3
			freq_sweep = 400.0; decay = 2.5
		"death":
			frequency = 200.0; duration = 0.5; wave_type = 2; volume = 0.35
			freq_sweep = -180.0; decay = 2.0
		"sell":
			frequency = 400.0; duration = 0.1; wave_type = 0; volume = 0.2
			freq_sweep = 100.0; decay = 8.0
		_:
			return null
	
	var samples := int(sample_rate * duration)
	var data := PackedVector2Array()
	data.resize(samples)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		var progress := float(i) / samples
		var current_freq := frequency + freq_sweep * progress
		var sample := 0.0
		
		match wave_type:
			0: # Sine
				sample = sin(2.0 * PI * current_freq * t)
			1: # Square
				sample = 1.0 if fmod(t * current_freq, 1.0) < 0.5 else -1.0
			2: # Sawtooth
				sample = 2.0 * fmod(t * current_freq, 1.0) - 1.0
			3: # Noise
				sample = randf_range(-1.0, 1.0)
		
		# 应用衰减包络
		var envelope := exp(-decay * t) * volume
		sample *= envelope
		
		data[i] = Vector2(sample, sample)
	
	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	
	# 转换为16bit PCM
	var byte_data := PackedByteArray()
	byte_data.resize(samples * 4)  # 2 bytes per sample * 2 channels
	for i in range(samples):
		var left := int(clampf(data[i].x, -1.0, 1.0) * 32767.0)
		var right := int(clampf(data[i].y, -1.0, 1.0) * 32767.0)
		byte_data[i * 4] = left & 0xFF
		byte_data[i * 4 + 1] = (left >> 8) & 0xFF
		byte_data[i * 4 + 2] = right & 0xFF
		byte_data[i * 4 + 3] = (right >> 8) & 0xFF
	
	stream.data = byte_data
	_sfx_cache[sfx_name] = stream  # 缓存生成结果
	return stream
