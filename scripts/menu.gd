extends CanvasLayer
## Menus do jogo (fica dentro do Jogo, funciona mesmo com o jogo pausado):
##   pausa()            → Esc / Start: Continuar, (Voltar ao mapa), Configurações, Voltar ao título, Sair do jogo
##   fim_de_jogo()      → acabou o axé: voltar ao último caminho guardado ou ao título
##   opcoes()           → as configurações: volume da música, volume dos efeitos, tela cheia
## Na tela de título os menus aparecem sem caixa, direto por cima do fundo (estilo_titulo).
##   escolher_caminho() → os três espaços de jogo salvo (para guardar ou para continuar)
##   escolher()         → uma lista qualquer de opções, no estilo das caixas de diálogo

const COR_FUNDO := Color(0.06, 0.08, 0.3, 0.97)
const COR_TEXTO := Color(1.0, 0.97, 0.9)
const COR_TITULO := Color(1.0, 0.86, 0.45)
const COR_APAGADA := Color(0.55, 0.58, 0.72)

var aberto := false
var _raiz: Control
var _linhas: Array = []
var _cursor := 0
var _desativadas: Array = []
var _lateral := false
var _resposta = null
var _capturando := false       # esperando a nova tecla ou botão (Configurações → Controles)
var _capturado: InputEvent
var _transparente := false     # sem caixa: as opções aparecem direto por cima do fundo (tela de título)
var _topo := 100.0


## Liga (na tela de título) ou desliga o jeito "sem caixa" dos menus.
func estilo_titulo(ligado: bool, topo := 100.0) -> void:
	_transparente = ligado
	_topo = topo


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS


## Mostra uma lista e espera a escolha. Devolve {"i": índice, "acao": "ok" | "cancelar" | "esq" | "dir"}.
## Com lateral = true, ← e → também respondem (para ajustar volumes).
func escolher(titulo: String, opcoes: Array, inicial := 0, lateral := false, desativadas := [], rodape := "") -> Dictionary:
	_fechar_caixa()
	aberto = true
	_lateral = lateral
	_desativadas = desativadas
	_cursor = clampi(inicial, 0, opcoes.size() - 1)
	_montar(titulo, opcoes, rodape)
	_resposta = null
	while _resposta == null:
		await get_tree().process_frame
	var r: Dictionary = _resposta
	if r["acao"] != "esq" and r["acao"] != "dir":
		_fechar_caixa()
		aberto = false
	return r


func _montar(titulo: String, opcoes: Array, rodape: String) -> void:
	var tela := Vector2(Jogo.TELA)
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)
	if _transparente:
		_montar_sem_caixa(titulo, opcoes, rodape)
		return
	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.45)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escuro)
	var largura := tela.x - 24.0
	var altura := 30.0 + opcoes.size() * 15.0 + (12.0 if rodape != "" else 0.0)
	var painel := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	estilo.shadow_color = Color(0, 0, 0, 0.5)
	estilo.shadow_size = 2
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(12, (tela.y - altura) / 2.0)
	painel.size = Vector2(largura, altura)
	_raiz.add_child(painel)
	var t := _rotulo(titulo, 10, COR_TITULO)
	t.position = Vector2(0, 5)
	t.size = Vector2(largura, 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", preload("res://fontes/NotoSans-SemiBold.ttf"))
	painel.add_child(t)
	_linhas.clear()
	for i in opcoes.size():
		var l := _rotulo(str(opcoes[i]), 8, COR_TEXTO)
		l.position = Vector2(18, 24 + i * 15)
		l.size = Vector2(largura - 26, 14)
		l.clip_text = true
		painel.add_child(l)
		_linhas.append(l)
	if rodape != "":
		var r := _rotulo(rodape, 7, COR_APAGADA)
		r.position = Vector2(0, altura - 14)
		r.size = Vector2(largura, 12)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		painel.add_child(r)
	_atualizar()


## As opções direto por cima do fundo, centralizadas, com contorno escuro (como nos títulos dos 16 bits).
func _montar_sem_caixa(titulo: String, opcoes: Array, rodape: String) -> void:
	var y := _topo
	var altura_lista := (15.0 if titulo != "" else 0.0) + opcoes.size() * 13.0 + (14.0 if rodape != "" else 0.0)
	if y + altura_lista > Jogo.TELA.y - 6.0:
		# lista comprida (os controles): sobe e ganha uma faixa escura atrás, para dar para ler
		y = maxf(6.0, (Jogo.TELA.y - altura_lista) / 2.0)
		var faixa := ColorRect.new()
		faixa.color = Color(0.05, 0.03, 0.1, 0.86)
		faixa.set_anchors_preset(Control.PRESET_FULL_RECT)
		_raiz.add_child(faixa)
	if titulo != "":
		var t := _rotulo(titulo, 9, COR_TITULO)
		t.add_theme_font_override("font", preload("res://fontes/NotoSans-SemiBold.ttf"))
		_centralizar(t, y, 12)
		y += 15
	_linhas.clear()
	var longa := false
	for o in opcoes:
		longa = longa or str(o).length() > 26
	for i in opcoes.size():
		var l := _rotulo(str(opcoes[i]), 7 if longa else 9, COR_TEXTO)
		_centralizar(l, y + i * 13, 13)
		_linhas.append(l)
	if rodape != "":
		var r := _rotulo(rodape, 7, Color(0.9, 0.85, 0.95))
		_centralizar(r, y + opcoes.size() * 13 + 3, 10)
	_atualizar()


## Põe o texto na largura toda da tela, centralizado, com contorno escuro.
func _centralizar(l: Label, y: float, altura: float) -> void:
	_contorno(l)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raiz.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = y
	l.offset_bottom = y + altura


func _contorno(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.14))
	l.add_theme_constant_override("outline_size", 3)


func _atualizar() -> void:
	for i in _linhas.size():
		var l: Label = _linhas[i]
		var texto := l.text.trim_prefix("▶ ").trim_prefix("   ")
		l.text = ("▶ " if i == _cursor else "   ") + texto
		var cor := COR_APAGADA if i in _desativadas else (COR_TITULO if i == _cursor else COR_TEXTO)
		if _transparente and i in _desativadas:
			cor = Color(0.7, 0.62, 0.72)
		l.add_theme_color_override("font_color", cor)


func _input(ev: InputEvent) -> void:
	if _capturando:
		if ev.is_echo() or not ev.is_pressed():
			return
		if ev is InputEventKey or ev is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
			_capturado = ev
			_capturando = false
		return
	if not aberto or _resposta != null or _linhas.is_empty():
		return
	if ev.is_action_pressed("cima"):
		_cursor = (_cursor - 1 + _linhas.size()) % _linhas.size()
		Jogo.tocar_som("texto", -10.0)
		_atualizar()
	elif ev.is_action_pressed("baixo"):
		_cursor = (_cursor + 1) % _linhas.size()
		Jogo.tocar_som("texto", -10.0)
		_atualizar()
	elif _lateral and ev.is_action_pressed("esquerda"):
		_resposta = {"i": _cursor, "acao": "esq"}
	elif _lateral and ev.is_action_pressed("direita"):
		_resposta = {"i": _cursor, "acao": "dir"}
	elif ev.is_action_pressed("interagir") or (ev is InputEventKey and ev.pressed and not ev.echo \
			and ev.physical_keycode == KEY_SPACE):
		if _cursor in _desativadas:
			Jogo.tocar_som("erro", -10.0)
		else:
			Jogo.tocar_som("buzio", -8.0)
			_resposta = {"i": _cursor, "acao": "ok"}
	elif ev.is_action_pressed("sair") or ev.is_action_pressed("cancelar"):
		_resposta = {"i": -1, "acao": "cancelar"}
	else:
		return
	get_viewport().set_input_as_handled()


func _fechar_caixa() -> void:
	if _raiz:
		_raiz.queue_free()
		_raiz = null
	_linhas.clear()


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


# ------------------------------------------------------------------ pausa

func pausa() -> void:
	if aberto:
		return
	get_tree().paused = true
	var escolha := 0
	var cena := get_tree().current_scene
	var pode_mapa: bool = cena != null and cena.has_method("pode_voltar_ao_mapa") and cena.pode_voltar_ao_mapa()
	var itens := ["Continuar", "Configurações", "Voltar ao título", "Sair do jogo"]
	if pode_mapa:
		itens.insert(1, "Voltar ao Ọ̀run")
	while true:
		var r := await escolher("Pausa", itens, escolha)
		escolha = maxi(r["i"], 0)
		if r["acao"] == "cancelar" or r["i"] == 0:
			break
		var item: String = itens[r["i"]]
		if item == "Voltar ao Ọ̀run":
			get_tree().paused = false
			cena.voltar_ao_mapa()
			return
		if item == "Configurações":
			await opcoes()
		elif item == "Voltar ao título":
			if await confirmar("Voltar ao título?"):
				get_tree().paused = false
				Jogo.mudar_cena("res://cenas/titulo.tscn")
				return
		elif item == "Sair do jogo":
			if await confirmar("Sair do jogo?"):
				get_tree().quit()
				return
	get_tree().paused = false


## Fim de jogo (acabaram os búzios de axé): voltar ao último caminho guardado ou ao título.
func fim_de_jogo() -> void:
	get_tree().paused = true
	Jogo.tocar_som("game_over", -2.0)
	var ultimo := Jogo.ultimo_salvo()
	var rodape := "Nenhum caminho guardado ainda."
	if ultimo >= 0:
		var r := Jogo.resumo(ultimo)
		rodape = "%s · %s" % [r.get("onde", "?"), r.get("data", "")]
	var opcoes := ["Voltar ao último caminho guardado", "Voltar ao título"]
	var desativadas := [] if ultimo >= 0 else [0]
	while true:
		var r := await escolher("O axé acabou...", opcoes, 0 if ultimo >= 0 else 1, false, desativadas, rodape)
		if r["acao"] != "ok":
			continue                      # aqui não dá para fechar: tem que escolher
		get_tree().paused = false
		if r["i"] == 0 and ultimo >= 0:
			Jogo.carregar(ultimo)
		else:
			Jogo.mudar_cena("res://cenas/titulo.tscn")
		return


func confirmar(pergunta: String) -> bool:
	var r := await escolher(pergunta, ["Não", "Sim"], 0, false, [], "O que Exu não guardou se perde.")
	return r["acao"] == "ok" and r["i"] == 1


# ------------------------------------------------------------------ opções

func opcoes() -> void:
	var i := 0
	while true:
		var itens := [
			"Música:   " + _barra(Jogo.opcoes["musica"]),
			"Efeitos:  " + _barra(Jogo.opcoes["efeitos"]),
			"Tela cheia:  " + ("sim" if get_window().mode == Window.MODE_FULLSCREEN else "não"),
			"Controles",
			"Voltar",
		]
		var r := await escolher("Configurações", itens, i, true, [], "← → para ajustar   ·   %s voltar" % ("B" if Jogo.usando_controle else "Esc"))
		i = r["i"]
		var passo := 0
		match r["acao"]:
			"cancelar":
				break
			"esq":
				passo = -1
			"dir":
				passo = 1
			"ok":
				if i == 4:
					break
				if i == 3:
					await controles()
					continue
				passo = 1
		if i == 0:
			Jogo.mudar_opcao("musica", clampi(Jogo.opcoes["musica"] + passo, 0, 10))
		elif i == 1:
			Jogo.mudar_opcao("efeitos", clampi(Jogo.opcoes["efeitos"] + passo, 0, 10))
			Jogo.tocar_som("buzio", -6.0)
		elif i == 2 and passo != 0:
			var janela := get_window()
			janela.mode = Window.MODE_WINDOWED if janela.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	_fechar_caixa()
	aberto = false


## Configurações → Controles: cada ação com a tecla e o botão do controle. Escolhendo uma, aperta-se a nova.
func controles() -> void:
	var i := 0
	while true:
		var itens := []
		for par in Jogo.CONTROLAVEIS:
			itens.append("%s:  %s  ·  %s" % [par[1], Jogo.nome_controle(par[0], false),
				Jogo.nome_controle(par[0], true) if Jogo.nome_controle(par[0], true) != "" else "—"])
		itens.append("Restaurar o padrão")
		itens.append("Voltar")
		var r := await escolher("Controles  (teclado · controle)", itens, i, false, [],
			"Escolha uma ação e aperte a nova tecla ou botão")
		if r["acao"] == "cancelar":
			break
		i = r["i"]
		if i == itens.size() - 1:
			break
		if i == itens.size() - 2:
			Jogo.restaurar_controles()
			continue
		var par: Array = Jogo.CONTROLAVEIS[i]
		await get_tree().create_timer(0.15, true, false, true).timeout
		var ev := await _esperar_tecla("Aperte a nova tecla ou botão para:\n%s" % par[1])
		if ev is InputEventKey and ev.physical_keycode == KEY_ESCAPE and par[0] != "sair":
			continue          # Esc desiste da troca
		if ev:
			Jogo.trocar_controle(par[0], ev)
			Jogo.tocar_som("buzio", -6.0)
	_fechar_caixa()
	aberto = false


func _esperar_tecla(texto: String) -> InputEvent:
	_fechar_caixa()
	aberto = true
	_montar(texto.split("\n")[0], [texto.split("\n")[1] if texto.contains("\n") else ""], "Esc desiste")
	_linhas[0].text = _linhas[0].text.trim_prefix("▶ ")
	_capturado = null
	_capturando = true
	while _capturando:
		await get_tree().process_frame
	_fechar_caixa()
	return _capturado


func _barra(v: int) -> String:
	return "■".repeat(v) + "□".repeat(10 - v)


# ------------------------------------------------------------------ os três caminhos (jogos salvos)

## Devolve o espaço escolhido (0, 1 ou 2) ou -1. Para continuar, os espaços vazios ficam apagados.
func escolher_caminho(titulo: String, para_carregar: bool) -> int:
	var itens := []
	var vazios := []
	for i in Jogo.ESPACOS:
		var r: Dictionary = Jogo.resumo(i)
		if r.is_empty():
			itens.append("Caminho %d  ·  vazio" % (i + 1))
			vazios.append(i)
		else:
			itens.append("Caminho %d · %s · ★%d · %s" % [i + 1, r["onde"], r["trofeus"], r["data"]])
	itens.append("Voltar" if para_carregar else "Não guardar")
	var inicial := maxi(Jogo.espaco_atual, 0)
	var r2 := await escolher(titulo, itens, inicial, false, vazios if para_carregar else [])
	if r2["acao"] != "ok" or r2["i"] >= Jogo.ESPACOS:
		return -1
	if not para_carregar and not Jogo.resumo(r2["i"]).is_empty() and r2["i"] != Jogo.espaco_atual:
		if not await confirmar_sobrescrever(r2["i"]):
			return -1
	return r2["i"]


func confirmar_sobrescrever(i: int) -> bool:
	var r := await escolher("Guardar por cima do caminho %d?" % (i + 1), ["Não", "Sim"], 0)
	return r["acao"] == "ok" and r["i"] == 1
