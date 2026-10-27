extends Node
## Estado global do jogo (autoload "Jogo").
## Guarda o progresso, configura os controles, toca sons e faz as transições de cena.

## Tamanho da tela do jogo (como no Super Nintendo).
const TELA := Vector2i(256, 224)

## enquanto há um diálogo na tela, Adé não anda nem pula (ver jogador.gd)
var em_dialogo := false
var buzios := 0
var buzios_total := 0
## segundos de jogo (só conta com o jogo rodando, não em pausa)
var tempo_jogado := 0.0
## quantas vezes o axé de Adé acabou (o jogo volta ao último caminho guardado)
var mortes := 0
var falou_com_exu := false
## troféus que Adé ganhou dos orixás (id do orixá → nome do troféu), para levar ao terreiro da Vó
var trofeus := {}
## troféus que a Vó já colocou no assentamento do orixá, no quarto de santo
var assentados := {}
## O tempo no terreiro na última volta de Adé (manha, tarde, noite, nublado, chuva). Muda a cada volta.
var tempo_terreiro := ""

## Jogos salvos: três "caminhos", cada um num arquivo (user://caminho_1.json ...).
## Quem guarda é Exu, na quartinha com a vela vermelha e preta (ver scripts/terreiro.gd).
const ESPACOS := 3
## Para onde cada lugar de salvar leva quando o jogo continua.
const LOCAIS := {
	"terreiro": {"nome": "Terreiro da Vó", "cena": "res://cenas/terreiro.tscn"},
	"orita": {"nome": "Encruzilhada", "cena": "res://cenas/mapa_mundo.tscn"},
	"oxossi": {"nome": "Mata de Oxóssi", "cena": "res://cenas/mata_oxossi.tscn"},
	"nana": {"nome": "Terra de Nanã", "cena": "res://cenas/mata_nana.tscn"},
	"iemanja": {"nome": "Mar de Iemanjá", "cena": "res://cenas/mar_iemanja.tscn"},
}
const METAS_SALVAS := ["mapa_aberto", "volta_feita", "iemanja_remo", "iemanja_flores", "iemanja_alfazema", "bornal_dica"]
var espaco_atual := -1
var opcoes := {"musica": 8, "efeitos": 8}
var menu: CanvasLayer
var bornal: CanvasLayer          # o bornal de Adé (scripts/bornal.gd)

## Teclado ou controle: o último usado decide os nomes dos botões nos textos ({interagir}, {atirar}...).
signal dispositivo_mudou
var usando_controle := false
## Qual controle: "xbox", "playstation" ou "nintendo" (pelo nome que o sistema dá ao controle).
## Os botões funcionam pela posição; só os nomes nos textos mudam (A/✕/B, B/○/A...).
var tipo_controle := "xbox"
const NOMES_BOTOES := {
	# ação: [no teclado, no controle (nomes do padrão Xbox, pela posição do botão)]
	"interagir": ["E", "A"],
	"atirar": ["Espaço", "B"],
	"devagar": ["Shift", "L ou R"],
	"ver_mapa": ["M", "Y"],
	"bornal": ["Tab", "Select"],
	"pausa": ["Esc", "Start"],
	"andar": ["as setas", "o direcional"],
	"setas": ["← ↑ → ↓", "✚"],
	"confirmar": ["Enter", "A"],
}

var _musica: AudioStreamPlayer
var _fade: ColorRect


## O nome do lugar onde Adé está agora (para o diário saber o capítulo).
func nome_do_local_atual() -> String:
	var cena := get_tree().current_scene
	if cena:
		for k in LOCAIS:
			if cena.scene_file_path == LOCAIS[k]["cena"]:
				return LOCAIS[k]["nome"]
	return "Caminho de Adé"


func _process(delta: float) -> void:
	tempo_jogado += delta


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# fonte padrão de todos os textos: Noto Sans, que desenha certo os acentos do iorubá
	ThemeDB.fallback_font = preload("res://fontes/NotoSans-Regular.ttf")
	# tela no tamanho do Super Nintendo (256x224), ampliada 3x na janela
	get_window().content_scale_size = TELA
	_configurar_controles()
	Input.joy_connection_changed.connect(_controle_conectado)
	if not Input.get_connected_joypads().is_empty():
		tipo_controle = _tipo_do_controle(Input.get_connected_joypads()[0])

	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -8.0
	add_child(_musica)
	for bus in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	_musica.bus = "Musica"
	_ler_opcoes()

	menu = preload("res://scripts/menu.gd").new()
	add_child(menu)
	bornal = preload("res://scripts/bornal.gd").new()
	add_child(bornal)

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
	trofeus = {}
	assentados = {}
	tempo_terreiro = ""
	tempo_jogado = 0.0
	mortes = 0
	espaco_atual = -1
	if bornal:
		bornal.esvaziar()
	for m in ["mapa_aberto", "volta_feita", "no_mapa", "volta", "retorno", "na_quartinha", "iemanja_remo", "iemanja_flores", "iemanja_alfazema", "bornal_dica"]:
		if has_meta(m):
			remove_meta(m)


## Cada mundo tem a sua trilha (sons/<nome>.wav); o terreiro, a tela de título e as fases usam "musica".
## Trocando de trilha, a velha some e a nova entra devagar. As trilhas repetem sem emenda.
var _musica_atual := ""
var _tween_musica: Tween


func tocar_musica(nome := "musica") -> void:
	if nome == _musica_atual and _musica.playing:
		return
	var estava := _musica.playing
	_musica_atual = nome
	if _tween_musica:
		_tween_musica.kill()
	_tween_musica = create_tween()
	if estava:
		_tween_musica.tween_property(_musica, "volume_db", -40.0, 0.6)
	_tween_musica.tween_callback(func():
		var stream: AudioStream = load("res://sons/%s.wav" % nome)
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_musica.stream = stream
		_musica.volume_db = -40.0
		_musica.play())
	_tween_musica.tween_property(_musica, "volume_db", -8.0, 0.8 if estava else 0.4)


func tocar_som(nome: String, volume_db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load("res://sons/%s.wav" % nome)
	p.volume_db = volume_db
	p.bus = "Efeitos"
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


## Escurece a tela, troca de cena e clareia de novo.
func mudar_cena(caminho: String) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.35)
	await t.finished
	bornal.mostrar_hud(false)        # cada cena liga a barra do bornal se usar (terreiro e fases)
	get_tree().change_scene_to_file(caminho)
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.35)


## Nome do botão de uma ação, para mostrar na tela (muda se o jogador troca de teclado para controle).
func botao(acao: String) -> String:
	var mapa := {"interagir": "interagir", "confirmar": "interagir", "atirar": "atirar", "devagar": "devagar",
		"ver_mapa": "ver_mapa", "pausa": "sair", "bornal": "bornal"}
	if mapa.has(acao):          # lê do controle configurado (o jogador pode ter trocado os botões)
		var n := nome_controle(mapa[acao], usando_controle)
		if n != "":
			return n
	if usando_controle and tipo_controle != "xbox":
		var por_marca := {
			"playstation": {"devagar": "L1 ou R1", "pausa": "Options", "bornal": "Create", "confirmar": "✕", "interagir": "✕", "atirar": "○", "ver_mapa": "△"},
			"nintendo": {"devagar": "L ou R", "pausa": "+", "bornal": "−", "confirmar": "B", "interagir": "B", "atirar": "A", "ver_mapa": "X"},
		}
		if por_marca[tipo_controle].has(acao):
			return por_marca[tipo_controle][acao]
	return NOMES_BOTOES.get(acao, [acao, acao])[1 if usando_controle else 0]


## Troca {interagir}, {atirar}, {devagar}, {ver_mapa}, {pausa}, {andar}, {setas} e {confirmar} pelos botões certos.
func texto(t: String) -> String:
	if not "{" in t:
		return t
	for acao in NOMES_BOTOES:
		t = t.replace("{%s}" % acao, botao(acao))
	return t


func _input(evento: InputEvent) -> void:
	var controle := usando_controle
	var tipo := tipo_controle
	if evento is InputEventJoypadButton and evento.pressed:
		controle = true
		tipo = _tipo_do_controle(evento.device)
	elif evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.6:
		controle = true
		tipo = _tipo_do_controle(evento.device)
	elif evento is InputEventKey and evento.pressed:
		controle = false
	if controle != usando_controle or tipo != tipo_controle:
		usando_controle = controle
		tipo_controle = tipo
		dispositivo_mudou.emit()


## Descobre a marca do controle pelo nome que o sistema dá a ele.
func _tipo_do_controle(device: int) -> String:
	var nome := Input.get_joy_name(device).to_lower()
	for chave in ["playstation", "dualsense", "dualshock", "sony", "ps3", "ps4", "ps5", "wireless controller"]:
		if chave in nome:
			return "playstation"
	for chave in ["nintendo", "switch", "joy-con", "joycon", "pro controller"]:
		if chave in nome:
			return "nintendo"
	return "xbox"


func _controle_conectado(device: int, conectado: bool) -> void:
	if conectado:
		tipo_controle = _tipo_do_controle(device)
		var marca: String = {"xbox": "Xbox", "playstation": "PlayStation", "nintendo": "Nintendo"}[tipo_controle]
		var nome := Input.get_joy_name(device)
		_aviso_controle("Controle conectado: " + marca + ("" if nome == "" else "  (" + nome + ")"))
		usando_controle = true
	else:
		_aviso_controle("Controle desconectado")
		if Input.get_connected_joypads().is_empty():
			usando_controle = false
	dispositivo_mudou.emit()


var _rotulo_aviso: Label


func _aviso_controle(texto: String) -> void:
	if not _rotulo_aviso:
		var camada := CanvasLayer.new()
		camada.layer = 101
		camada.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(camada)
		_rotulo_aviso = Label.new()
		_rotulo_aviso.position = Vector2(0, TELA.y - 16)
		_rotulo_aviso.size = Vector2(TELA.x, 12)
		_rotulo_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rotulo_aviso.add_theme_font_size_override("font_size", 7)
		_rotulo_aviso.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
		_rotulo_aviso.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
		_rotulo_aviso.add_theme_constant_override("outline_size", 3)
		camada.add_child(_rotulo_aviso)
	_rotulo_aviso.text = texto
	_rotulo_aviso.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(2.5)
	t.tween_property(_rotulo_aviso, "modulate:a", 0.0, 0.6)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("sair") and not menu.aberto and _fade.color.a < 0.1:
		var cena := get_tree().current_scene
		if cena and not cena.scene_file_path.ends_with("titulo.tscn"):
			get_viewport().set_input_as_handled()
			menu.pausa()
			return
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
	# controle (pela posição do botão, igual em Xbox, PlayStation e Nintendo):
	#   baixo (A / ✕) falar e confirmar · direita (B / ◯) atirar e voltar no menu · cima (Y / △) ver a ilha
	#   L ou R andar devagar · Start pausa · Select/Back também mostra a ilha
	_acao("interagir", [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_X], [JOY_BUTTON_A])
	_acao("sair", [KEY_ESCAPE], [JOY_BUTTON_START])
	_acao("cancelar", [KEY_ESCAPE, KEY_BACKSPACE], [JOY_BUTTON_B])
	# no mapa dos caminhos: afastar a câmera para ver a ilha inteira (e apertar de novo para voltar)
	_acao("ver_mapa", [KEY_M, KEY_Q], [JOY_BUTTON_Y])
	# o bornal de Adé: abrir, escolher um item e usar, dar ou arriar
	_acao("bornal", [KEY_TAB, KEY_I], [JOY_BUTTON_BACK, JOY_BUTTON_X])
	# na mata de Oxóssi: atirar a flecha do ofá e andar devagar (sem espantar os bichos)
	_acao("atirar", [KEY_SPACE, KEY_Z, KEY_J], [JOY_BUTTON_B])
	_acao("devagar", [KEY_SHIFT, KEY_C], [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER])
	_acao("tela_cheia", [KEY_F11], [])
	_ler_controles()


func _acao(nome: String, teclas: Array, botoes: Array, eixo := -1, direcao := 0.0) -> void:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, 0.3)
	InputMap.action_erase_events(nome)
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


# ------------------------------------------------------------------ trocar os controles (Configurações → Controles)

## As ações que o jogador pode trocar, com o nome que aparece no menu.
const CONTROLAVEIS := [
	["interagir", "Falar / confirmar"], ["atirar", "Atirar"], ["devagar", "Andar devagar"],
	["ver_mapa", "Ver a ilha"], ["bornal", "Abrir o Àpò"], ["sair", "Pausa"],
	["cima", "Cima"], ["baixo", "Baixo"], ["esquerda", "Esquerda"], ["direita", "Direita"],
]
const NOMES_JOY := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "L", JOY_BUTTON_RIGHT_SHOULDER: "R", JOY_BUTTON_START: "Start",
	JOY_BUTTON_BACK: "Select", JOY_BUTTON_DPAD_UP: "↑", JOY_BUTTON_DPAD_DOWN: "↓",
	JOY_BUTTON_DPAD_LEFT: "←", JOY_BUTTON_DPAD_RIGHT: "→", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_GUIDE: "Guia",
}
const NOMES_TECLAS := {"Space": "Espaço", "Escape": "Esc", "Up": "↑", "Down": "↓", "Left": "←", "Right": "→",
	"Backspace": "Apagar", "Tab": "Tab", "Shift": "Shift", "Ctrl": "Ctrl", "Alt": "Alt"}


func _nome_do_evento(ev: InputEvent) -> String:
	if ev is InputEventKey:
		var n := OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)
		return NOMES_TECLAS.get(n, n)
	if ev is InputEventJoypadButton:
		return nome_do_botao(ev.button_index)
	return ""


## O nome de um botão do controle, do jeito que está escrito no controle que está sendo usado.
func nome_do_botao(i: int) -> String:
	match tipo_controle:
		"playstation":
			var ps := {JOY_BUTTON_A: "✕", JOY_BUTTON_B: "○", JOY_BUTTON_X: "□", JOY_BUTTON_Y: "△",
				JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_START: "Options",
				JOY_BUTTON_BACK: "Create", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_GUIDE: "PS"}
			if ps.has(i):
				return ps[i]
		"nintendo":
			# no controle da Nintendo, o botão de baixo se chama B e o da direita, A
			var nin := {JOY_BUTTON_A: "B", JOY_BUTTON_B: "A", JOY_BUTTON_X: "Y", JOY_BUTTON_Y: "X",
				JOY_BUTTON_LEFT_SHOULDER: "L", JOY_BUTTON_RIGHT_SHOULDER: "R", JOY_BUTTON_START: "+",
				JOY_BUTTON_BACK: "−", JOY_BUTTON_GUIDE: "Home"}
			if nin.has(i):
				return nin[i]
	return NOMES_JOY.get(i, "Botão %d" % i)


## Nome da tecla (ou dos botões do controle) de uma ação, como ela está configurada agora.
func nome_controle(acao: String, do_controle: bool) -> String:
	var nomes := []
	for ev in InputMap.action_get_events(acao):
		if do_controle and ev is InputEventJoypadButton:
			nomes.append(_nome_do_evento(ev))
		elif not do_controle and ev is InputEventKey:
			return _nome_do_evento(ev)          # no teclado, só a tecla principal
	return " ou ".join(nomes)


## Troca a tecla principal (ou o botão) de uma ação. Se outra ação usava essa tecla, as duas trocam.
func trocar_controle(acao: String, novo: InputEvent) -> void:
	var de_controle := novo is InputEventJoypadButton
	var antigo: InputEvent = null
	for ev in InputMap.action_get_events(acao):
		if (de_controle and ev is InputEventJoypadButton) or (not de_controle and ev is InputEventKey):
			antigo = ev
			break
	var limpo: InputEvent
	if de_controle:
		limpo = InputEventJoypadButton.new()
		limpo.button_index = novo.button_index
	else:
		limpo = InputEventKey.new()
		limpo.physical_keycode = novo.physical_keycode if novo.physical_keycode != KEY_NONE else novo.keycode
	for par in CONTROLAVEIS:
		var outra: String = par[0]
		if outra == acao:
			continue
		for ev in InputMap.action_get_events(outra):
			if _mesmo(ev, limpo):
				InputMap.action_erase_event(outra, ev)
				if antigo:
					InputMap.action_add_event(outra, antigo.duplicate())
	if de_controle:     # no controle, cada ação fica com um botão só
		for ev in InputMap.action_get_events(acao):
			if ev is InputEventJoypadButton:
				InputMap.action_erase_event(acao, ev)
	else:
		if antigo:
			InputMap.action_erase_event(acao, antigo)
		for ev in InputMap.action_get_events(acao):
			if _mesmo(ev, limpo):
				InputMap.action_erase_event(acao, ev)
	# a nova vira a principal (fica em primeiro)
	var resto := InputMap.action_get_events(acao)
	InputMap.action_erase_events(acao)
	InputMap.action_add_event(acao, limpo)
	for ev in resto:
		InputMap.action_add_event(acao, ev)
	_salvar_controles()
	dispositivo_mudou.emit()       # para os textos ("Aperte E") se atualizarem


func _mesmo(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	return false


func restaurar_controles() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://controles.cfg"))
	_configurar_controles()
	dispositivo_mudou.emit()


func _salvar_controles() -> void:
	var cfg := ConfigFile.new()
	for par in CONTROLAVEIS:
		var teclas := []
		var botoes := []
		for ev in InputMap.action_get_events(par[0]):
			if ev is InputEventKey:
				teclas.append(ev.physical_keycode)
			elif ev is InputEventJoypadButton:
				botoes.append(ev.button_index)
		cfg.set_value(par[0], "teclas", teclas)
		cfg.set_value(par[0], "botoes", botoes)
	cfg.save("user://controles.cfg")


func _ler_controles() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://controles.cfg") != OK:
		return
	for par in CONTROLAVEIS:
		var acao: String = par[0]
		if not cfg.has_section(acao):
			continue
		var eixos := []
		for ev in InputMap.action_get_events(acao):
			if ev is InputEventJoypadMotion:
				eixos.append(ev)
		InputMap.action_erase_events(acao)
		for k in cfg.get_value(acao, "teclas", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = int(k)
			InputMap.action_add_event(acao, ev)
		for b in cfg.get_value(acao, "botoes", []):
			var evb := InputEventJoypadButton.new()
			evb.button_index = int(b)
			InputMap.action_add_event(acao, evb)
		for e in eixos:
			InputMap.action_add_event(acao, e)


# ------------------------------------------------------------------ opções (volume e tela)

func _ler_opcoes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://opcoes.cfg") == OK:
		for k in opcoes:
			opcoes[k] = int(cfg.get_value("som", k, opcoes[k]))
	_aplicar_opcoes()


func mudar_opcao(nome: String, valor: int) -> void:
	opcoes[nome] = valor
	_aplicar_opcoes()
	var cfg := ConfigFile.new()
	for k in opcoes:
		cfg.set_value("som", k, opcoes[k])
	cfg.save("user://opcoes.cfg")


func _aplicar_opcoes() -> void:
	for par in [["Musica", "musica"], ["Efeitos", "efeitos"]]:
		var i := AudioServer.get_bus_index(par[0])
		var v: float = opcoes[par[1]] / 10.0
		AudioServer.set_bus_mute(i, v <= 0.0)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


# ------------------------------------------------------------------ os caminhos guardados (jogos salvos)

func _arquivo(espaco: int) -> String:
	return "user://caminho_%d.json" % (espaco + 1)


## Guarda o jogo no espaço escolhido. "local" é onde Adé está: terreiro, orita, oxossi ou nana.
func salvar(espaco: int, local: String) -> void:
	var metas := {}
	for m in METAS_SALVAS:
		metas[m] = has_meta(m)
	var dados := {
		"versao": 1,
		"local": local,
		"trofeus": trofeus,
		"assentados": assentados,
		"buzios": buzios,
		"metas": metas,
		"bornal": bornal.para_salvar(),
		"tempo": tempo_terreiro,
		"tempo_jogado": tempo_jogado,
		"mortes": mortes,
		"data": Time.get_datetime_string_from_system(false, true),
	}
	var f := FileAccess.open(_arquivo(espaco), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dados, "\t"))
		f.close()
		espaco_atual = espaco


func _ler(espaco: int) -> Dictionary:
	if not FileAccess.file_exists(_arquivo(espaco)):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(_arquivo(espaco)))
	return d if d is Dictionary else {}


## O último caminho guardado: o espaço em uso (se existir) ou o arquivo salvo mais recente. -1 se não houver.
func ultimo_salvo() -> int:
	if espaco_atual >= 0 and FileAccess.file_exists(_arquivo(espaco_atual)):
		return espaco_atual
	var melhor := -1
	var quando := 0
	for e in ESPACOS:
		if FileAccess.file_exists(_arquivo(e)):
			var t := FileAccess.get_modified_time(_arquivo(e))
			if t > quando:
				quando = t
				melhor = e
	return melhor


## Uma linha curta para mostrar no menu: onde, quantos troféus e quando.
func resumo(espaco: int) -> Dictionary:
	var d := _ler(espaco)
	if d.is_empty():
		return {}
	var data: String = d.get("data", "")
	var curta := data
	if data.length() >= 16:     # "2026-10-23 10:40:12" → "23/10 10:40"
		curta = "%s/%s %s" % [data.substr(8, 2), data.substr(5, 2), data.substr(11, 5)]
	return {"onde": LOCAIS.get(d.get("local", ""), {"nome": "?"})["nome"],
		"trofeus": d.get("trofeus", {}).size(), "data": curta,
		"tempo": formatar_tempo(float(d.get("tempo_jogado", 0.0))), "mortes": int(d.get("mortes", 0)),
		"buzios": int(d.get("buzios", 0))}


## Tempo de jogo em horas e minutos: "1h02m" ou "12m".
func formatar_tempo(seg: float) -> String:
	var minutos := int(seg) / 60
	if minutos >= 60:
		return "%dh%02dm" % [minutos / 60, minutos % 60]
	return "%dm" % minutos


## Apaga o caminho guardado no espaço escolhido.
func apagar(espaco: int) -> void:
	if FileAccess.file_exists(_arquivo(espaco)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_arquivo(espaco)))
	if espaco_atual == espaco:
		espaco_atual = -1


## Continua o jogo de onde Exu guardou.
func carregar(espaco: int) -> void:
	var d := _ler(espaco)
	if d.is_empty():
		return
	reiniciar()
	espaco_atual = espaco
	trofeus = d.get("trofeus", {})
	assentados = d.get("assentados", {})
	buzios = int(d.get("buzios", 0))
	tempo_terreiro = d.get("tempo", "")
	tempo_jogado = float(d.get("tempo_jogado", 0.0))
	mortes = int(d.get("mortes", 0))
	for m in d.get("metas", {}):
		if d["metas"][m]:
			set_meta(m, true)
	bornal.carregar(d.get("bornal", {}))
	var local: String = d.get("local", "orita")
	match local:
		"terreiro":
			set_meta("retorno", true)
			set_meta("na_quartinha", true)
		"orita":
			set_meta("no_mapa", "orita")
	mudar_cena(LOCAIS.get(local, LOCAIS["orita"])["cena"])
