extends CanvasLayer
## Menus do jogo (fica dentro do Jogo, funciona mesmo com o jogo pausado):
##   pausa()            → Esc / Start: Continuar, Opções, Voltar ao título, Sair do jogo
##   opcoes()           → volume da música, volume dos efeitos, tela cheia
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


func _atualizar() -> void:
	for i in _linhas.size():
		var l: Label = _linhas[i]
		var texto := l.text.trim_prefix("▶ ").trim_prefix("   ")
		l.text = ("▶ " if i == _cursor else "   ") + texto
		var cor := COR_APAGADA if i in _desativadas else (COR_TITULO if i == _cursor else COR_TEXTO)
		l.add_theme_color_override("font_color", cor)


func _input(ev: InputEvent) -> void:
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
	elif ev.is_action_pressed("interagir") or ev.is_action_pressed("atirar"):
		if _cursor in _desativadas:
			Jogo.tocar_som("erro", -10.0)
		else:
			Jogo.tocar_som("buzio", -8.0)
			_resposta = {"i": _cursor, "acao": "ok"}
	elif ev.is_action_pressed("sair"):
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
	while true:
		var r := await escolher("Pausa", ["Continuar", "Opções", "Voltar ao título", "Sair do jogo"], escolha)
		escolha = maxi(r["i"], 0)
		if r["acao"] == "cancelar" or r["i"] == 0:
			break
		if r["i"] == 1:
			await opcoes()
		elif r["i"] == 2:
			if await confirmar("Voltar ao título?"):
				get_tree().paused = false
				Jogo.mudar_cena("res://cenas/titulo.tscn")
				return
		elif r["i"] == 3:
			if await confirmar("Sair do jogo?"):
				get_tree().quit()
				return
	get_tree().paused = false


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
			"Voltar",
		]
		var r := await escolher("Opções", itens, i, true, [], "← → para ajustar")
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
				if i == 3:
					break
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
			itens.append("Caminho %d  ·  %s  ·  ★ %d  ·  %s" % [i + 1, r["onde"], r["trofeus"], r["data"]])
	if not para_carregar:
		itens.append("Não guardar")
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
