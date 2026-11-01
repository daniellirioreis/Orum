extends CanvasLayer
## Mini-jogo da bacia: Adé macera a alfazema na água, com as duas mãos (← e → alternado, no verde).
## A água clara vai ficando roxa conforme a alfazema é macerada. Termina quando a barra enche.

signal acabou

const PONTO_MIN := 0.38
const PONTO_MAX := 0.72
const IMPULSO := 0.15          # cada mexida (alternando os lados) acelera a colher
const FREIO := 0.34            # e ela vai parando sozinha
const TEMPO_NO_PONTO := 8.0    # segundos mexendo no ponto até o manjar ficar pronto

var jogando := false

var _vel := 0.0                # 0..1: quão rápido Adé está mexendo
var _progresso := 0.0          # 0..1: o manjar engrossando
var _angulo := 0.0
var _ultimo_lado := 0
var _rapido := 0.0             # quanto tempo seguido rápido demais
var _devagar := 0.0            # quanto tempo seguido devagar demais
var _comecou := false
var _tempo := 0.0
var _folhas: Array = []        # folhas roxas de alfazema na mistura (somem mexendo no ponto; empelotar traz mais)
var _respingos: Array = []     # gotas que espirraram
var _aviso_t := 0.0
var _base := Color(0.45, 0.7, 0.98)   # água azul, antes da alfazema
const COR_FIM := Color(0.5, 0.2, 0.62)  # roxo: a água com alfazema pronta

var _raiz: Control
var _desenho: Control
var _status: Label
var _dica: Label


func _ready() -> void:
	layer = 9
	_montar()
	_raiz.visible = false
	set_process(false)


## Joga até a água ficar roxa.
func jogar() -> void:
	_vel = 0.0
	_progresso = 0.0
	_angulo = 0.0
	_ultimo_lado = 0
	_rapido = 0.0
	_devagar = 0.0
	_comecou = false
	_folhas.clear()
	for i in 6:
		_folhas.append(Vector2(randf_range(-20, 20), randf_range(-16, 16)))
	_respingos.clear()
	_base = Color(0.45, 0.7, 0.98)
	_raiz.visible = true
	_status.text = "Macere a alfazema na água!"
	_dica.text = "← → alternando · fique no verde"
	jogando = true
	set_process(true)
	await acabou
	set_process(false)
	jogando = false
	await get_tree().create_timer(1.1).timeout
	_raiz.visible = false


func _unhandled_input(ev: InputEvent) -> void:
	if not jogando:
		return
	var lado := 0
	if ev.is_action_pressed("esquerda"):
		lado = -1
	elif ev.is_action_pressed("direita"):
		lado = 1
	if ev.is_action_pressed("interagir") or ev.is_action_pressed("cima") or ev.is_action_pressed("baixo"):
		get_viewport().set_input_as_handled()     # não deixa a Tia começar a conversa de novo
	if lado == 0:
		return
	get_viewport().set_input_as_handled()
	if lado != _ultimo_lado:
		_vel = minf(1.0, _vel + IMPULSO)
		_comecou = true
	else:
		_vel = minf(1.0, _vel + IMPULSO * 0.25)   # o mesmo lado de novo quase não mexe
	_ultimo_lado = lado


func _process(delta: float) -> void:
	_tempo += delta
	_vel = maxf(0.0, _vel - FREIO * delta)
	_angulo += (1.0 + _vel * 12.0) * delta * (0.2 if _vel < 0.05 else 1.0)
	_aviso_t -= delta
	if _comecou and _progresso < 1.0:
		if _vel > PONTO_MAX:
			_rapido += delta
			_devagar = 0.0
			if _aviso_t <= 0.0:
				_status.text = "Devagar! Vai espirrar!"
			if _rapido > 0.7:
				_espirrar()
		elif _vel < PONTO_MIN:
			_devagar += delta
			_rapido = 0.0
			if _aviso_t <= 0.0:
				_status.text = "Macere mais, as folhas grudam!"
			if _devagar > 1.6:
				_empelotar()
		else:
			_rapido = 0.0
			_devagar = 0.0
			_progresso = minf(1.0, _progresso + delta / TEMPO_NO_PONTO)
			if _aviso_t <= 0.0:
				_status.text = "Isso, no ponto! Continua..."
			if not _folhas.is_empty() and randf() < delta * 2.0:
				_folhas.pop_back()            # mexendo no ponto, as folhas vão sumindo na mistura
			if _progresso >= 1.0:
				_status.text = "Pronto! Água roxinha!"
				Jogo.tocar_som("buzio", -4.0)
				acabou.emit()
	for r in _respingos:
		r["v"].y += 260.0 * delta
		r["p"] += r["v"] * delta
		r["t"] -= delta
	_respingos = _respingos.filter(func(r): return r["t"] > 0.0)
	_desenho.queue_redraw()


## Cor da água agora: fica roxa conforme a alfazema é macerada.
func _cor_mistura() -> Color:
	return _base.lerp(COR_FIM, _progresso)


func _espirrar() -> void:
	_rapido = 0.0
	_vel = 0.5
	_progresso = maxf(0.0, _progresso - 0.12)
	_status.text = "Ai! Espirrou água!"
	_aviso_t = 1.2
	Jogo.tocar_som("agua_cai", -8.0)
	for i in 14:
		var a := randf_range(-PI * 0.9, -PI * 0.1)
		_respingos.append({"p": Vector2(64, 60), "v": Vector2(cos(a), sin(a)) * randf_range(50.0, 95.0), "t": 0.7})


func _empelotar() -> void:
	_devagar = 0.0
	_progresso = maxf(0.0, _progresso - 0.08)
	_status.text = "Grudou! Macere mais rápido!"
	_aviso_t = 1.2
	Jogo.tocar_som("erro", -10.0)
	for i in 4:
		_folhas.append(Vector2(randf_range(-20, 20), randf_range(-10, 10)))   # as folhas se juntam em grumos


# ------------------------------------------------------------------ desenho

func _desenhar() -> void:
	var c := Vector2(64, 60)                     # o meio do alguidar
	_desenho.draw_circle(c + Vector2(0, 30), 36, Color(0, 0, 0, 0.25))     # sombra no chão
	_desenho.draw_circle(c, 37, Color(0.62, 0.62, 0.66))                   # borda de fora
	_desenho.draw_circle(c, 33, Color(0.93, 0.93, 0.95))                    # aro
	_desenho.draw_circle(c, 30, Color(0.82, 0.82, 0.86))                   # parede por dentro
	var dir := _cor_mistura()
	_desenho.draw_circle(c, 26, dir)
	_desenho.draw_arc(c, 33, PI * 1.1, PI * 1.5, 12, Color(1, 0.8, 0.6, 0.5), 1.0)   # brilho do barro
	for k in 3:
		var raio := 7.0 + k * 6.0
		var pontos := PackedVector2Array()
		for n in 13:
			var a := _angulo * (1.0 - k * 0.15) + n * 0.32 + k * 2.0
			pontos.append(c + Vector2(cos(a), sin(a)) * raio)
		_desenho.draw_polyline(pontos, dir.darkened(0.12), 1.0)
	for p in _folhas:
		# uma florzinha roxa de alfazema: cinco pétalas e um miolo
		for k in 5:
			var ang := TAU * float(k) / 5.0 + 0.3
			_desenho.draw_circle(c + p + Vector2(cos(ang), sin(ang)) * 2.4, 1.9, Color(0.5, 0.25, 0.7))
		_desenho.draw_circle(c + p, 1.4, Color(0.78, 0.6, 0.9))
	# as duas mãos de Adé esfregando a alfazema na água: uma vai e a outra vem
	var s := sin(_angulo)
	var m1 := c + Vector2(-4.0 + s * 12.0, -6.0 + absf(s) * 2.0)
	var m2 := c + Vector2(4.0 - s * 12.0, 6.0 - absf(s) * 2.0)
	_mao(m1, 0.0 + s * 0.3)      # a de cima, com os dedos para a direita
	_mao(m2, PI + s * 0.3)     # a de baixo, com os dedos para a esquerda
	for r in _respingos:
		_desenho.draw_rect(Rect2(r["p"], Vector2(2, 2)), dir)

	var mx := 122.0
	var my := 20.0
	var mh := 72.0
	_desenho.draw_rect(Rect2(mx - 1, my - 1, 12, mh + 2), Color(0.95, 0.95, 1.0))
	_desenho.draw_rect(Rect2(mx, my, 10, mh * (1.0 - PONTO_MAX)), Color(0.85, 0.3, 0.25))
	_desenho.draw_rect(Rect2(mx, my + mh * (1.0 - PONTO_MAX), 10, mh * (PONTO_MAX - PONTO_MIN)), Color(0.3, 0.75, 0.35))
	_desenho.draw_rect(Rect2(mx, my + mh * (1.0 - PONTO_MIN), 10, mh * PONTO_MIN), Color(0.3, 0.45, 0.85))
	var ny := my + mh * (1.0 - _vel)
	_desenho.draw_rect(Rect2(mx - 4, ny - 1, 18, 3), Color(1, 1, 1))
	_desenho.draw_rect(Rect2(mx - 4, ny, 18, 1), Color(0.1, 0.1, 0.1))
	_desenho.draw_rect(Rect2(10, 104, 124, 7), Color(0.95, 0.95, 1.0))
	_desenho.draw_rect(Rect2(11, 105, 122, 5), Color(0.1, 0.1, 0.25))
	_desenho.draw_rect(Rect2(11, 105, 122 * _progresso, 5), dir)


## Uma mão de Adé vista de cima: palma oval, quatro dedos e um polegar, apontando para `ang`.
func _mao(pos: Vector2, ang: float) -> void:
	var pele := Color(0.52, 0.32, 0.18)
	var contorno := Color(0.2, 0.12, 0.07)
	# palma oval
	var palma := PackedVector2Array()
	for n in 16:
		var a := TAU * float(n) / 16.0
		palma.append(pos + Vector2(cos(a) * 5.5, sin(a) * 4.5).rotated(ang))
	_desenho.draw_colored_polygon(palma, pele)
	palma.append(palma[0])
	_desenho.draw_polyline(palma, contorno, 1.0)
	# quatro dedos, saindo da palma
	for k in 4:
		var dedo := pos + Vector2(5.0, -2.4 + float(k) * 1.6).rotated(ang)
		_desenho.draw_circle(dedo, 1.5, pele)
		_desenho.draw_arc(dedo, 1.5, 0.0, TAU, 8, contorno, 0.6)
	# polegar, de lado
	var polegar := pos + Vector2(1.0, 4.0).rotated(ang)
	_desenho.draw_circle(polegar, 1.7, pele)
	_desenho.draw_arc(polegar, 1.7, 0.0, TAU, 8, contorno, 0.6)
	# brilho da palma
	_desenho.draw_circle(pos + Vector2(-1.5, -1.5).rotated(ang), 1.2, Color(0.7, 0.48, 0.3))

func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.96)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(2)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(56, 26)
	painel.custom_minimum_size = Vector2(144, 148)
	_raiz.add_child(painel)
	_desenho = Control.new()
	_desenho.position = Vector2(56, 40)
	_desenho.size = Vector2(144, 118)
	_desenho.draw.connect(_desenhar)
	_raiz.add_child(_desenho)
	_status = Label.new()
	_status.position = Vector2(56, 30)
	_status.size = Vector2(144, 12)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 8)
	_status.add_theme_color_override("font_color", Color(0.95, 0.74, 0.32))
	_raiz.add_child(_status)
	_dica = Label.new()
	_dica.position = Vector2(56, 158)
	_dica.size = Vector2(144, 10)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_font_size_override("font_size", 7)
	_dica.add_theme_color_override("font_color", Color(0.75, 0.78, 0.95))
	_raiz.add_child(_dica)
