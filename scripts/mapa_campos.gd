extends CanvasLayer
## Mapa dos campos de atuação dos orixás, que Exu abre na encruzilhada.
## A encruzilhada fica no meio; em volta, cada campo (o mar, a mata, a pedreira...).
## Com "revelar", os campos vão se acendendo um por um; depois dá para escolher cada um
## com as setas e ler o que ele é. "interagir" fecha o mapa.
##
## Arte: arte/mapa_campos_base.png (tudo escuro), arte/mapa_campos_0..8.png (cada campo aceso),
## arte/mapa_icones.png (as ferramentas) e arte/mapa_selo.png — feitos pelo gerar_mapa_campos.py.

signal fechou

const CENTRO := Vector2(128, 118)
const RAIO_SELO := 64.0

var _campos: Array = []
var _acesos: Array = []
var _selos: Array = []
var _escolhido := 0
var _navegando := false
var _rapido := false
var _tempo := 0.0

var _raiz: Control
var _nome: Label
var _yoruba: Label
var _saudacao: Label
var _campo: Label
var _icone: TextureRect
var _dica: Label


func _ready() -> void:
	layer = 40


func _process(delta: float) -> void:
	_tempo += delta
	if _navegando and _selos.size() > _escolhido:
		var s: Sprite2D = _selos[_escolhido]
		s.scale = Vector2.ONE * (1.15 + sin(_tempo * 6.0) * 0.08)
	if _dica:
		_dica.modulate.a = 0.6 + 0.4 * sin(_tempo * 3.0)


func abrir(campos: Array, revelar: bool) -> void:
	_campos = campos
	_montar()
	_raiz.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_raiz, "modulate:a", 1.0, 0.5)
	await t.finished
	if revelar:
		await _revelar()
	else:
		for i in _acesos.size():
			_acesos[i].modulate.a = 1.0
			_selos[i].visible = true
	_escolher(_campos.size() - 1)   # começa em Ogum, o primeiro caminho
	_navegando = true
	_dica.visible = true
	await fechou
	var t2 := create_tween()
	t2.tween_property(_raiz, "modulate:a", 0.0, 0.4)
	await t2.finished
	queue_free()


func _revelar() -> void:
	_mostrar_info(-1)
	await _esperar(0.6)
	for i in _campos.size():
		Jogo.tocar_som("buzio", -6.0)
		var t := create_tween()
		t.tween_property(_acesos[i], "modulate:a", 1.0, 0.25 if _rapido else 0.5)
		var s: Sprite2D = _selos[i]
		s.visible = true
		s.scale = Vector2.ZERO
		t.parallel().tween_property(s, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_mostrar_info(i)
		_marcar(i)
		await t.finished
		await _esperar(0.25 if _rapido else 1.5)
	_marcar(-1)
	Jogo.tocar_som("caminho", -4.0)


func _esperar(segundos: float) -> void:
	var fim := _tempo + segundos
	while _tempo < fim and not (_rapido and segundos > 0.3):
		await get_tree().process_frame


func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	var fundo := TextureRect.new()
	fundo.texture = preload("res://arte/mapa_campos_base.png")
	_raiz.add_child(fundo)
	for i in _campos.size():
		var a := TextureRect.new()
		a.texture = load("res://arte/mapa_campos_%d.png" % i)
		a.modulate.a = 0.0
		_raiz.add_child(a)
		_acesos.append(a)
	var icones := preload("res://arte/mapa_icones.png")
	for i in _campos.size():
		var selo := Sprite2D.new()
		selo.texture = preload("res://arte/mapa_selo.png")
		selo.hframes = 2
		selo.position = _posicao(i)
		selo.visible = false
		_raiz.add_child(selo)
		var ic := Sprite2D.new()
		ic.texture = icones
		ic.hframes = _campos.size()
		ic.frame = i
		selo.add_child(ic)
		_selos.append(selo)

	var fonte_forte := preload("res://fontes/NotoSans-SemiBold.ttf")
	var titulo := _rotulo("Os campos dos orixás", 9, Color(1.0, 0.9, 0.6))
	titulo.add_theme_font_override("font", fonte_forte)
	titulo.position = Vector2(6, 2)
	_raiz.add_child(titulo)
	_dica = _rotulo(Jogo.texto("← →  ver os campos   ·   {interagir}  fechar"), 7, Color(1, 1, 1))
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dica.size = Vector2(250, 10)
	_dica.position = Vector2(0, 4)
	_dica.visible = false
	_raiz.add_child(_dica)

	# painel de baixo: o campo escolhido
	var painel := ColorRect.new()
	painel.color = Color(0.06, 0.03, 0.09, 0.86)
	painel.position = Vector2(0, 182)
	painel.size = Vector2(256, 42)
	_raiz.add_child(painel)
	var borda := ColorRect.new()
	borda.color = Color(0.85, 0.62, 0.25)
	borda.position = Vector2(0, 182)
	borda.size = Vector2(256, 1)
	_raiz.add_child(borda)
	_icone = TextureRect.new()
	_icone.position = Vector2(6, 188)
	_raiz.add_child(_icone)
	_nome = _rotulo("", 11, Color(1.0, 0.86, 0.45))
	_nome.add_theme_font_override("font", fonte_forte)
	_nome.position = Vector2(26, 183)
	_raiz.add_child(_nome)
	_yoruba = _rotulo("", 8, Color(0.85, 0.8, 0.95))
	_yoruba.position = Vector2(26, 199)
	_raiz.add_child(_yoruba)
	_saudacao = _rotulo("", 10, Color(1.0, 0.55, 0.45))
	_saudacao.add_theme_font_override("font", fonte_forte)
	_saudacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_saudacao.size = Vector2(120, 14)
	_saudacao.position = Vector2(130, 184)
	_raiz.add_child(_saudacao)
	_campo = _rotulo("", 8, Color(1, 0.97, 0.9))
	_campo.position = Vector2(6, 210)
	_campo.size = Vector2(246, 12)
	_campo.clip_text = true
	_raiz.add_child(_campo)


func _posicao(i: int) -> Vector2:
	var a := deg_to_rad(-90.0 + i * 360.0 / _campos.size())
	return CENTRO + Vector2(cos(a) * RAIO_SELO * 1.15, sin(a) * RAIO_SELO / 1.1)


func _mostrar_info(i: int) -> void:
	if i < 0:
		_nome.text = "Oríta Mẹ́ta"
		_yoruba.text = "a encruzilhada de Exu"
		_saudacao.text = "Laroyê!"
		_campo.text = "Daqui saem os caminhos para todos os campos."
		_icone.texture = null
		return
	var c: Dictionary = _campos[i]
	_nome.text = c["nome"]
	_yoruba.text = c["yo"]
	_saudacao.text = c["saudacao"]
	_campo.text = c["campo"]
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://arte/mapa_icones.png")
	atlas.region = Rect2(i * 16, 0, 16, 16)
	_icone.texture = atlas


func _marcar(i: int) -> void:
	for k in _selos.size():
		_selos[k].frame = 1 if k == i else 0
		if k != i:
			_selos[k].scale = Vector2.ONE


func _escolher(i: int) -> void:
	_escolhido = posmod(i, _campos.size())
	_marcar(_escolhido)
	_mostrar_info(_escolhido)


func _unhandled_input(ev: InputEvent) -> void:
	if not ev.is_pressed() or ev.is_echo():
		return
	if ev.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if _navegando:
			_navegando = false
			fechou.emit()
		else:
			_rapido = true
		return
	if not _navegando:
		return
	if ev.is_action_pressed("direita") or ev.is_action_pressed("baixo"):
		get_viewport().set_input_as_handled()
		Jogo.tocar_som("texto", -8.0)
		_escolher(_escolhido + 1)
	elif ev.is_action_pressed("esquerda") or ev.is_action_pressed("cima"):
		get_viewport().set_input_as_handled()
		Jogo.tocar_som("texto", -8.0)
		_escolher(_escolhido - 1)


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	return l
