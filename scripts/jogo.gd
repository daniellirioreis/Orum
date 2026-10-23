extends Node
## Estado global do jogo (autoload "Jogo").
## Guarda o progresso, configura os controles, toca sons e faz as transições de cena.

## Tamanho da tela do jogo (como no Super Nintendo).
const TELA := Vector2i(256, 224)

var buzios := 0
var buzios_total := 0
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
}
const METAS_SALVAS := ["mapa_aberto", "volta_feita"]
var espaco_atual := -1
var opcoes := {"musica": 8, "efeitos": 8}
var menu: CanvasLayer

## Teclado ou controle: o último usado decide os nomes dos botões nos textos ({interagir}, {atirar}...).
signal dispositivo_mudou
var usando_controle := false
const NOMES_BOTOES := {
	# ação: [no teclado, no controle (nomes do padrão Xbox, pela posição do botão)]
	"interagir": ["E", "A"],
	"atirar": ["Espaço", "B"],
	"devagar": ["Shift", "L ou R"],
	"ver_mapa": ["M", "Y"],
	"pausa": ["Esc", "Start"],
	"andar": ["as setas", "o direcional"],
	"setas": ["← ↑ → ↓", "✚"],
	"confirmar": ["Enter", "A"],
}

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
	for bus in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	_musica.bus = "Musica"
	_ler_opcoes()

	menu = preload("res://scripts/menu.gd").new()
	add_child(menu)

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
	espaco_atual = -1
	for m in ["mapa_aberto", "volta_feita", "no_mapa", "volta", "retorno", "na_quartinha"]:
		if has_meta(m):
			remove_meta(m)


func tocar_musica() -> void:
	if not _musica.playing:
		_musica.play()


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
	get_tree().change_scene_to_file(caminho)
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.35)


## Nome do botão de uma ação, para mostrar na tela (muda se o jogador troca de teclado para controle).
func botao(acao: String) -> String:
	var mapa := {"interagir": "interagir", "confirmar": "interagir", "atirar": "atirar", "devagar": "devagar",
		"ver_mapa": "ver_mapa", "pausa": "sair"}
	if mapa.has(acao):          # lê do controle configurado (o jogador pode ter trocado os botões)
		var n := nome_controle(mapa[acao], usando_controle)
		if n != "":
			return n
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
	if evento is InputEventJoypadButton and evento.pressed:
		controle = true
	elif evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.6:
		controle = true
	elif evento is InputEventKey and evento.pressed:
		controle = false
	if controle != usando_controle:
		usando_controle = controle
		dispositivo_mudou.emit()


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
	_acao("ver_mapa", [KEY_M, KEY_TAB, KEY_Q], [JOY_BUTTON_Y, JOY_BUTTON_BACK])
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
	["ver_mapa", "Ver a ilha"], ["sair", "Pausa"],
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
		return NOMES_JOY.get(ev.button_index, "Botão %d" % ev.button_index)
	return ""


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
		"tempo": tempo_terreiro,
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
		"trofeus": d.get("trofeus", {}).size(), "data": curta}


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
	for m in d.get("metas", {}):
		if d["metas"][m]:
			set_meta(m, true)
	var local: String = d.get("local", "orita")
	match local:
		"terreiro":
			set_meta("retorno", true)
			set_meta("na_quartinha", true)
		"orita":
			set_meta("no_mapa", "orita")
	mudar_cena(LOCAIS.get(local, LOCAIS["orita"])["cena"])
