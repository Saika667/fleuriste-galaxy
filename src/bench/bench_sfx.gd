class_name BenchSfx
extends Node
## Petits sons de l'etabli, synthetises par code (aucun fichier audio). Un lecteur par voix, flux mis en cache.

const RATE := 22050
static var _cache := {}

var enabled := true
var _players: Array = []
var _next := 0


func _init() -> void:
	for i in 6:
		var p = AudioStreamPlayer.new()
		p.volume_db = -9.0
		add_child(p)
		_players.append(p)


## kind : pop | pluck | swish | thunk | ding | cha | womp | chime. pitch : multiplicateur de hauteur.
func play(kind: String, pitch: float = 1.0, vol_db: float = -9.0) -> void:
	if not enabled:
		return
	var st = stream(kind)
	if st == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = st
	p.pitch_scale = clampf(pitch, 0.5, 2.5)
	p.volume_db = vol_db
	p.play()


## Hauteur pentatonique selon le nombre de tiges deja posees (chaque ajout monte d'une note).
static func pentatonic(i: int) -> float:
	var steps = [0, 2, 4, 7, 9]
	var semi = int(steps[i % 5]) + 12 * ((i / 5) % 2)
	return pow(2.0, float(semi) / 12.0)


static func stream(kind: String) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind]
	var s = PackedFloat32Array()
	match kind:
		"pop":
			s = _tone(520.0, 980.0, 0.11, 0, 5.0)
			_mix(s, _tone(1040.0, 1960.0, 0.07, 3, 7.0), 0.0, 0.25)
			_mix(s, _noise(0.012, 3.0, 0.5), 0.0, 0.18)
		"pluck":
			s = _tone(430.0, 170.0, 0.1, 3, 6.0)
			_mix(s, _noise(0.02, 4.0, 0.25), 0.0, 0.15)
		"swish":
			s = _noise(0.24, 0.0, 0.14)
			for i in s.size():
				s[i] *= sin(PI * float(i) / s.size()) * 0.9
		"thunk":
			s = _tone(150.0, 60.0, 0.2, 0, 5.0)
			_mix(s, _noise(0.05, 5.0, 0.06), 0.0, 0.7)
		"ding":
			s = _tone(1320.0, 1320.0, 0.4, 0, 5.0)
			_mix(s, _tone(1980.0, 1980.0, 0.3, 0, 6.0), 0.0, 0.3)
		"cha":
			var notes = [784.0, 988.0, 1175.0, 1568.0]
			for i in notes.size():
				_mix(s, _tone(notes[i], notes[i], 0.32, 0, 5.5), 0.075 * i, 0.55)
				_mix(s, _tone(notes[i] * 2.0, notes[i] * 2.0, 0.2, 3, 8.0), 0.075 * i, 0.15)
			_mix(s, _tone(2093.0, 2093.0, 0.5, 0, 4.0), 0.34, 0.45)
		"womp":
			s = _tone(330.0, 120.0, 0.5, 2, 2.2, 0.03)
			_mix(s, _tone(247.0, 82.0, 0.6, 2, 2.0, 0.03), 0.3, 1.0)
			for i in s.size():
				s[i] *= 0.45
		"chime":
			s = _tone(1760.0, 1760.0, 0.45, 0, 5.0)
			_mix(s, _tone(2349.0, 2349.0, 0.45, 0, 5.0), 0.09, 0.8)
			_mix(s, _tone(2794.0, 2794.0, 0.4, 0, 6.0), 0.18, 0.6)
		_:
			return null
	var w = _wav(s)
	_cache[kind] = w
	return w


## Tonalite a enveloppe exponentielle. wave : 0 sinus, 1 carre, 2 dent de scie, 3 triangle.
static func _tone(f0: float, f1: float, dur: float, wave: int, decay: float, vib: float = 0.0) -> PackedFloat32Array:
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var ph = 0.0
	for i in n:
		var k = float(i) / float(n)
		var f = lerpf(f0, f1, k) * (1.0 + vib * sin(float(i) / RATE * 40.0))
		ph += TAU * f / RATE
		var s = 0.0
		match wave:
			0:
				s = sin(ph)
			1:
				s = signf(sin(ph)) * 0.5
			2:
				s = 2.0 * (fposmod(ph / TAU, 1.0) - 0.5) * 0.7
			_:
				s = 4.0 * absf(fposmod(ph / TAU, 1.0) - 0.5) - 1.0
		out[i] = s * exp(-decay * k) * minf(1.0, float(i) / (RATE * 0.003))
	return out


static func _noise(dur: float, decay: float, lp: float) -> PackedFloat32Array:
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	var y = 0.0
	for i in n:
		y += (rng.randf_range(-1.0, 1.0) - y) * lp
		out[i] = y * exp(-decay * float(i) / float(n))
	return out


static func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, offset_s: float, gain: float) -> void:
	var o = int(offset_s * RATE)
	if dst.size() < o + src.size():
		dst.resize(o + src.size())
	for i in src.size():
		dst[o + i] += src[i] * gain


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i] * 0.6, -1.0, 1.0) * 32000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
