extends CanvasLayer
## Mini-jogo do Ogã: ele toca uma sequência nos três atabaques e Adé repete.
## Esquerda (← ou A) = atabaque grande, cima (↑ ou W) = médio, direita (→ ou D) = pequeno.
## São três rodadas, com 3, 4 e 5 batidas. Se errar, o Ogã toca de novo.
## Apertando "interagir" (Enter / E / A) no meio do mini-jogo, tudo é zerado e começa da primeira rodada.

signal batida(indice: int)

const RODADAS := [3, 4, 5]
const TEX := preload("res://arte/tambores.png")
const TECLAS := ["← A", "↑ W", "→ D"]

var ouvindo := false
var sequencia_atual: Array = []

var _tambores: Array = []
var _status: Label
var _raiz: Control
var _vez := 0              # muda quando o jogador zera: tudo o que estava esperando para e recomeça
var jogando := false
var _dica: Label


func _ready() -> void:
	layer = 9
	_montar()
	_raiz.visible = false


## Joga as três rodadas. Só termina quando Adé acerta todas.
func jogar() -> void:
	_dica.text = Jogo.texto("{interagir}: zerar e começar de novo")
	_raiz.visible = true
	jogando = true
	var i := 0
	while i < RODADAS.size():
		var vez := _vez
		sequencia_atual = []
		for n in RODADAS[i]:
			sequencia_atual.append(randi() % 3)
		while true:
			_status.text = "Rodada %d de %d · Ouça o toque do Ogã" % [i + 1, RODADAS.size()]
			await get_tree().create_timer(0.9).timeout
			if vez != _vez:
				break
			for t in sequencia_atual:
				_acender(t)
				await get_tree().create_timer(0.55).timeout
				if vez != _vez:
					break
			if vez != _vez:
				break
			_status.text = "Sua vez!"
			var acertou := await _ouvir()
			if vez != _vez:
				break
			if acertou:
				Jogo.tocar_som("buzio", -6.0)
				_status.text = "Isso!"
				await get_tree().create_timer(0.7).timeout
				break
			Jogo.tocar_som("erro", -6.0)
			_status.text = "Calma, menino. Ouve de novo."
			await get_tree().create_timer(1.2).timeout
		if vez != _vez:
			# zerou: volta para a primeira rodada, com toques novos
			i = 0
			_status.text = "Tudo do começo! Ouça de novo."
			await get_tree().create_timer(1.0).timeout
			continue
		i += 1
	jogando = false
	_raiz.visible = false


## Zera o mini-jogo: para o toque que estava tocando (ou a escuta) e volta para a primeira rodada.
func zerar() -> void:
	_vez += 1
	Jogo.tocar_som("caminho", -10.0)
	if ouvindo:
		ouvindo = false
		batida.emit(-1)


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
	if jogando and ev.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()      # não deixa o Ogã começar a conversa de novo
		zerar()
		return
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
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.96)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(2)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(38, 50)
	painel.custom_minimum_size = Vector2(180, 96)
	_raiz.add_child(painel)

	_status = Label.new()
	_status.position = Vector2(38, 56)
	_status.size = Vector2(180, 12)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 8)
	_status.add_theme_color_override("font_color", Color(0.95, 0.74, 0.32))
	_raiz.add_child(_status)

	var dica := Label.new()
	dica.position = Vector2(38, 134)
	dica.size = Vector2(180, 10)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 7)
	dica.add_theme_color_override("font_color", Color(0.75, 0.78, 0.95))
	dica.set_meta("dica", true)
	_raiz.add_child(dica)
	_dica = dica

	for i in 3:
		var caixa := Control.new()
		caixa.position = Vector2(58 + i * 52, 74)
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
