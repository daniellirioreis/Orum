extends CanvasLayer
## Mini-jogo do Ogã: ele toca uma sequência nos três atabaques e Adé repete.
## Esquerda (← ou A) = atabaque grande, cima (↑ ou W) = médio, direita (→ ou D) = pequeno.
## São três rodadas, com 3, 4 e 5 batidas. Se errar, o Ogã toca de novo.

signal batida(indice: int)

const RODADAS := [3, 4, 5]
const TEX := preload("res://arte/tambores.png")
const TECLAS := ["← A", "↑ W", "→ D"]

var ouvindo := false
var sequencia_atual: Array = []

var _tambores: Array = []
var _status: Label
var _raiz: Control


func _ready() -> void:
	layer = 9
	_montar()
	_raiz.visible = false


## Joga as três rodadas. Só termina quando Adé acerta todas.
func jogar() -> void:
	_raiz.visible = true
	for i in RODADAS.size():
		sequencia_atual = []
		for n in RODADAS[i]:
			sequencia_atual.append(randi() % 3)
		while true:
			_status.text = "Rodada %d de %d · Ouça o toque do Ogã" % [i + 1, RODADAS.size()]
			await get_tree().create_timer(0.9).timeout
			for t in sequencia_atual:
				_acender(t)
				await get_tree().create_timer(0.55).timeout
			_status.text = "Sua vez!"
			if await _ouvir():
				Jogo.tocar_som("buzio", -6.0)
				_status.text = "Isso!"
				await get_tree().create_timer(0.7).timeout
				break
			Jogo.tocar_som("erro", -6.0)
			_status.text = "Calma, menino. Ouve de novo."
			await get_tree().create_timer(1.2).timeout
	_raiz.visible = false


func _ouvir() -> bool:
	ouvindo = true
	for esperado in sequencia_atual:
		var tocado: int = await batida
		if tocado != esperado:
			ouvindo = false
			return false
	ouvindo = false
	return true


func _unhandled_input(ev: InputEvent) -> void:
	if not ouvindo:
		return
	var i := -1
	if ev.is_action_pressed("esquerda"):
		i = 0
	elif ev.is_action_pressed("cima"):
		i = 1
	elif ev.is_action_pressed("direita"):
		i = 2
	if i >= 0:
		get_viewport().set_input_as_handled()
		_acender(i)
		batida.emit(i)


func _acender(i: int) -> void:
	Jogo.tocar_som("atabaque_%d" % (i + 1), -2.0)
	var tambor: TextureRect = _tambores[i]
	(tambor.texture as AtlasTexture).region = Rect2((i + 3) * 28, 0, 28, 32)
	tambor.position.y = -3
	await get_tree().create_timer(0.25).timeout
	(tambor.texture as AtlasTexture).region = Rect2(i * 28, 0, 28, 32)
	tambor.position.y = 0


func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.04, 0.1, 0.93)
	estilo.border_color = Color(0.85, 0.62, 0.28)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(2)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(102, 40)
	painel.custom_minimum_size = Vector2(180, 96)
	_raiz.add_child(painel)

	_status = Label.new()
	_status.position = Vector2(102, 46)
	_status.size = Vector2(180, 12)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 8)
	_status.add_theme_color_override("font_color", Color(0.95, 0.74, 0.32))
	_raiz.add_child(_status)

	for i in 3:
		var caixa := Control.new()
		caixa.position = Vector2(122 + i * 52, 64)
		_raiz.add_child(caixa)
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX
		atlas.region = Rect2(i * 28, 0, 28, 32)
		var tambor := TextureRect.new()
		tambor.texture = atlas
		caixa.add_child(tambor)
		_tambores.append(tambor)
		var tecla := Label.new()
		tecla.text = TECLAS[i]
		tecla.position = Vector2(-6, 36)
		tecla.size = Vector2(40, 10)
		tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tecla.add_theme_font_size_override("font_size", 8)
		tecla.add_theme_color_override("font_color", Color(1, 0.95, 0.88))
		caixa.add_child(tecla)
