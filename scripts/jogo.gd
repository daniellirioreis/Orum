extends Node
## Estado global do jogo (autoload "Jogo").
## Guarda o progresso, configura os controles, toca sons e faz as transições de cena.

## Tamanho da tela do jogo (como no Super Nintendo).
const TELA := Vector2i(256, 224)

var buzios := 0
var buzios_total := 0
var falou_com_exu := false

var _musica: AudioStreamPlayer
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# fonte padrão de todos os textos: Noto Sans, que desenha certo os acentos do iorubá
	ThemeDB.fallback_font = preload("res://fontes/NotoSans-Regular.ttf")
	# tela no tamanho do Super Nintendo (256x224), ampliada 3x na janela
	get_window().content_scale_size = TELA
	_configurar_controles()

	_musica = AudioStreamPlayer.new()
	_musica.stream = load("res://sons/musica.wav")
	_musica.volume_db = -8.0
	_musica.finished.connect(_musica.play)  # repete em loop
	add_child(_musica)

	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.02, 0.08, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_fade)


func reiniciar() -> void:
	buzios = 0
	buzios_total = 0
	falou_com_exu = false


func tocar_musica() -> void:
	if not _musica.playing:
		_musica.play()


func tocar_som(nome: String, volume_db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load("res://sons/%s.wav" % nome)
	p.volume_db = volume_db
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


## Escurece a tela, troca de cena e clareia de novo.
func mudar_cena(caminho: String) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.35)
	await t.finished
	get_tree().change_scene_to_file(caminho)
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.35)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("tela_cheia"):
		var janela := get_window()
		if janela.mode == Window.MODE_FULLSCREEN:
			janela.mode = Window.MODE_WINDOWED
		else:
			janela.mode = Window.MODE_FULLSCREEN


# ------------------------------------------------------------------ controles

func _configurar_controles() -> void:
	_acao("esquerda", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_acao("direita", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_acao("pular", [KEY_SPACE, KEY_W, KEY_UP, KEY_Z], [JOY_BUTTON_A])
	# cima/baixo: para andar nas cenas vistas de cima (terreiro)
	_acao("cima", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_acao("baixo", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_acao("interagir", [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_X], [JOY_BUTTON_X, JOY_BUTTON_B])
	_acao("sair", [KEY_ESCAPE], [JOY_BUTTON_START])
	# no mapa dos caminhos: afastar a câmera para ver a ilha inteira (e apertar de novo para voltar)
	_acao("ver_mapa", [KEY_M, KEY_TAB, KEY_Q], [JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER])
	_acao("tela_cheia", [KEY_F11], [])


func _acao(nome: String, teclas: Array, botoes: Array, eixo := -1, direcao := 0.0) -> void:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, 0.3)
	for tecla in teclas:
		var ev := InputEventKey.new()
		ev.physical_keycode = tecla
		InputMap.action_add_event(nome, ev)
	for botao in botoes:
		var evb := InputEventJoypadButton.new()
		evb.button_index = botao
		InputMap.action_add_event(nome, evb)
	if eixo >= 0:
		var eva := InputEventJoypadMotion.new()
		eva.axis = eixo
		eva.axis_value = direcao
		InputMap.action_add_event(nome, eva)
