extends CanvasLayer
## O bornal de Adé: a sacola com as coisas que ele carrega para USAR, DAR ou ARRIAR.
## Fica dentro do Jogo (vai junto de uma cena para outra e é guardado no jogo salvo).
##
## Três bolsos:
##   ferramenta → Adé usa no lugar certo (o remo na jangada, a lâmina de bambu na taboa...).
##                Uma ferramenta pode ficar "na mão" (equipada): o botão de atirar usa ela (o ofá).
##   entrega    → Adé dá para alguém (o coco para a Tia Dora, o manjar para a Vó...).
##   oferenda   → Adé arria no lugar sagrado, uma coisa de cada vez (gààrí, epó, oti e luma na tronqueira...).
##
## Tab / I (ou Select no controle) abre o bornal. A cena diz o que dá para fazer com cada item ali onde
## Adé está (veja terreiro.gd: _acoes_do_bornal e _fazer_no_bornal).

signal mudou

const TEX_SLOT := preload("res://arte/hud_slot.png")
const COR_TITULO := Color(1.0, 0.86, 0.45)
const COR_TEXTO := Color(1.0, 0.97, 0.9)
const COR_APAGADA := Color(0.62, 0.66, 0.82)
const BOLSOS := [["ferramenta", "Ferramentas"], ["entrega", "Entregas"], ["oferenda", "Oferenda"]]

## id → nome, bolso, frase, ícone [folha, quadro de 12x12], fase (de onde o item é)
const ITENS := {
	# a oferenda a Exu, no terreiro da Vó
	"efum": {"nome": "Gààrí", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 0],
		"desc": "Farinha de mandioca, que a Tia Dora preparou para a oferenda de Exu."},
	"epo": {"nome": "Epó", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 1],
		"desc": "Azeite de dendê, vermelho e cheiroso. Exu gosta."},
	"oti": {"nome": "Oti", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 2],
		"desc": "A bebida que o Ogã Bené guardava para Exu."},
	"luna": {"nome": "Luma", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 3],
		"desc": "Uma vela para iluminar o caminho de Exu."},
	"lenha": {"nome": "Lenha", "tipo": "entrega", "fase": "exu", "icone": ["res://arte/itens.png", 4],
		"desc": "Um feixe de lenha seca para o fogão da Tia Dora."},
	# a mata de Oxóssi
	"ofa": {"curta": "Já está na mão de Adé. Atire com {atirar}.", "nome": "Ofá", "tipo": "ferramenta", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 3],
		"desc": "O arco do caçador, com uma flecha só. Na mão, atira com {atirar}.", "equipa": true},
	"milho": {"nome": "Milho", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 0],
		"desc": "Uma espiga do milharal. Vai na oferenda para Exu, como a mãe do caçador fez."},
	"coco_mata": {"nome": "Coco", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 1],
		"desc": "Um coco que caiu debaixo do coqueiro da mata."},
	"mel": {"nome": "Mel", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 2],
		"desc": "Um favo de mel da colmeia. Docinho."},
	# a terra de Nanã
	"faca": {"curta": "Uma faca de ferro velha. Será que corta a taboa?", "nome": "Faca de ferro", "tipo": "ferramenta", "fase": "nana", "icone": ["res://arte/bornal_itens.png", 4],
		"desc": "Uma faca de ferro velha, achada num toco."},
	"lamina": {"curta": "Bambu afiado: na terra de Nanã, corta melhor que o ferro.", "nome": "Lâmina de bambu", "tipo": "ferramenta", "fase": "nana", "icone": ["res://arte/nana_itens.png", 1],
		"desc": "Uma lasca afiada de bambu rachado. Na terra de Nanã, corta melhor que o ferro."},
	"pote_rachado": {"nome": "Pote rachado", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote de barro da velhinha. Está rachado: assim não segura água."},
	"pote": {"nome": "Pote de barro", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote da velhinha, consertado com o barro da lagoa. Está vazio."},
	"pote_cheio": {"nome": "Pote com água da chuva", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote cheio de água da chuva, para a oferenda de Nanã."},
	"flores_nana": {"nome": "Flores lilás", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 2],
		"desc": "Flores lilás da ilhota do mangue, para Nanã."},
	# o mar de Iemanjá (e o manjar no terreiro)
	"remo": {"curta": "Agora a jangada pode ir para o mar.", "nome": "Remo", "tipo": "ferramenta", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 0],
		"desc": "O remo da jangada, que o mar tinha deixado na gruta do costão."},
	"coco": {"nome": "Coco", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/ox_itens.png", 1],
		"desc": "Um coco maduro do coqueiro do quintal, para o manjar da Tia Dora."},
	"leite": {"nome": "Leite", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 1],
		"desc": "Uma garrafa de leite fresquinho, para o manjar."},
	"acucar": {"nome": "Açúcar", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 2],
		"desc": "Uma tigelinha de açúcar, para o manjar."},
	"manjar": {"nome": "Manjar branco", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 3],
		"desc": "O manjar que Adé e a Tia Dora fizeram. A comida que Iemanjá mais gosta."},
	"alfazema": {"nome": "Perfume de alfazema", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 1],
		"desc": "O vidrinho roxo da Vó. Ela usa no banho e para lavar as guias. Iemanjá gosta de se sentir cheirosa."},
	"flores_iemanja": {"nome": "Flores brancas", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 0],
		"desc": "As flores brancas da pedra no meio do mar, acesas pela lua."},
	"perola": {"nome": "Pérola", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 2],
		"desc": "Uma pérola do fundo do mar."},
	"espelho": {"nome": "Espelho", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 3],
		"desc": "Iemanjá gosta de se ver bonita."},
}

var itens: Array = []          # ids, na ordem em que Adé pegou
var equipado := ""             # a ferramenta "na mão"
var aberto := false

# --- tela do bornal
var _raiz: Control
var _lista: Array = []         # os ids, na ordem da lista
var _linha := 0                # o item escolhido
var _topo := 0                 # o primeiro item que aparece (a lista rola quando tem muita coisa)
var _linhas_ui: Array = []     # [fundo, ícone, nome] de cada linha visível
var _cursor: ColorRect
const LINHAS_VISIVEIS := 6
const ALTURA_LINHA := 15.0
const TOPO_LISTA := 38.0
var _nome: Label
var _desc: Label
var _escolha = null

# --- a barra pequena do bornal no canto da tela (o item na mão e quantos itens tem)
var _hud: CanvasLayer
var _hud_slot: TextureRect
var _hud_mao: TextureRect
var _hud_bolsa: TextureRect
var _hud_conta: Label
var _hud_tecla: Label


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_hud()
	mostrar_hud(false)


# ------------------------------------------------------------------ os itens

func tem(id: String) -> bool:
	return id in itens


func icone(id: String) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(ITENS[id]["icone"][0])
	a.region = Rect2(ITENS[id]["icone"][1] * 12, 0, 12, 12)
	return a


## Põe um item no bornal (se veio de um lugar da tela, o ícone voa de lá até o bornal).
func pegar(id: String, de_onde := Vector2(-1, -1)) -> void:
	if not ITENS.has(id):
		push_warning("Àpò: item desconhecido " + id)
		return
	if not tem(id):
		itens.append(id)
	if ITENS[id]["tipo"] == "ferramenta" and ITENS[id].get("equipa", false) and equipado == "":
		equipado = id
	_atualizar_hud()
	if de_onde.x >= 0:
		_voar(icone(id), de_onde, _hud_bolsa.position + Vector2(6, 6))
	_pular(_hud_bolsa)
	mudou.emit()


## Tira um item do bornal (dado, arriado ou usado). Se for para um lugar da tela, o ícone voa até lá.
func tirar(id: String, para_onde := Vector2(-1, -1)) -> void:
	itens.erase(id)
	if equipado == id:
		equipado = ""
	_atualizar_hud()
	if para_onde.x >= 0:
		_voar(icone(id), _hud_bolsa.position + Vector2(6, 6), para_onde)
	mudou.emit()


## Troca um item por outro no mesmo lugar (o pote rachado vira o pote consertado...).
func trocar(id_velho: String, id_novo: String) -> void:
	var i := itens.find(id_velho)
	if i < 0:
		pegar(id_novo)
		return
	itens[i] = id_novo
	if equipado == id_velho:
		equipado = id_novo
	_atualizar_hud()
	_pular(_hud_bolsa)
	mudou.emit()


func equipar(id: String) -> void:
	equipado = id if equipado != id else ""
	_atualizar_hud()
	mudou.emit()


## Começando uma fase do zero: tira do bornal o que era dessa fase (menos o que a fase guarda entre visitas).
func comecar_fase(fase: String, menos: Array = []) -> void:
	for id in itens.duplicate():
		if ITENS[id]["fase"] == fase and not id in menos:
			itens.erase(id)
	if equipado != "" and not equipado in itens:
		equipado = ""
	_atualizar_hud()
	mudou.emit()


func esvaziar() -> void:
	itens.clear()
	equipado = ""
	_atualizar_hud()


func para_salvar() -> Dictionary:
	return {"itens": itens.duplicate(), "equipado": equipado}


func carregar(d: Dictionary) -> void:
	itens = []
	for id in d.get("itens", []):
		if ITENS.has(id):
			itens.append(id)
	equipado = d.get("equipado", "")
	if not equipado in itens:
		equipado = ""
	_atualizar_hud()


# ------------------------------------------------------------------ a barra pequena (HUD)

func mostrar_hud(sim: bool) -> void:
	_hud.visible = sim
	_atualizar_hud()


func _montar_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	var tela := Vector2(Jogo.TELA)
	_hud_slot = TextureRect.new()
	_hud_slot.texture = TEX_SLOT
	_hud_slot.position = Vector2(tela.x - 124, 4)       # na mão: ao lado do bornal, na frente do axé
	_hud.add_child(_hud_slot)
	_hud_mao = TextureRect.new()
	_hud_mao.position = _hud_slot.position + Vector2(3, 3)
	_hud_mao.pivot_offset = Vector2(6, 6)
	_hud.add_child(_hud_mao)
	_hud_bolsa = TextureRect.new()
	var a := AtlasTexture.new()
	a.atlas = load("res://arte/bornal_itens.png")
	a.region = Rect2(5 * 12, 0, 12, 12)
	_hud_bolsa.texture = a
	_hud_bolsa.position = Vector2(tela.x - 102, 5)
	_hud_bolsa.pivot_offset = Vector2(6, 6)
	_hud.add_child(_hud_bolsa)
	_hud_conta = _rotulo("", 7, COR_TEXTO)
	_hud_conta.position = Vector2(tela.x - 91, 9)
	_hud.add_child(_hud_conta)
	_hud_tecla = _rotulo("", 6, COR_APAGADA)
	_hud_tecla.position = Vector2(tela.x - 109, 17)
	_hud_tecla.size = Vector2(26, 8)
	_hud_tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_hud_tecla)


func _atualizar_hud() -> void:
	if not _hud:
		return
	var vazio := itens.is_empty()
	_hud_bolsa.visible = true            # o Àpò fica sempre na tela, mesmo vazio
	_hud_bolsa.modulate = Color(1, 1, 1, 0.6 if vazio else 1.0)
	_hud_conta.visible = not vazio
	_hud_tecla.visible = true
	_hud_conta.text = str(itens.size())
	_hud_tecla.text = Jogo.botao("bornal")
	_hud_slot.visible = equipado != ""
	_hud_mao.visible = equipado != ""
	if equipado != "":
		_hud_mao.texture = icone(equipado)


## A ferramenta na mão fica meio apagada enquanto não dá para usar (a flecha do ofá voando...).
func mao_apagada(sim: bool) -> void:
	_hud_mao.modulate = Color(1, 1, 1, 0.45 if sim else 1.0)


func _pular(n: Control) -> void:
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(1.5, 1.5), 0.1)
	t.tween_property(n, "scale", Vector2.ONE, 0.16)


func _voar(tex: Texture2D, de: Vector2, para: Vector2) -> void:
	var r := TextureRect.new()
	r.texture = tex
	r.position = de - Vector2(6, 6)
	r.pivot_offset = Vector2(6, 6)
	_hud.add_child(r)
	var meio := (de + para) / 2.0 + Vector2(0, -24)
	var t := create_tween()
	t.tween_method(_voar_passo.bind(r, de, meio, para), 0.0, 1.0, 0.45)
	t.parallel().tween_property(r, "scale", Vector2(1.4, 1.4), 0.2)
	t.tween_property(r, "scale", Vector2(0.6, 0.6), 0.1)
	t.tween_callback(r.queue_free)


func _voar_passo(u: float, r: TextureRect, de: Vector2, meio: Vector2, para: Vector2) -> void:
	r.position = de.lerp(meio, u).lerp(meio.lerp(para, u), u) - Vector2(6, 6)


# ------------------------------------------------------------------ a tela do bornal

## Abre o bornal. "acoes" é uma função da cena: recebe o id e devolve [[rótulo, ação], ...] — o que dá
## para fazer com o item ali (Dar, Arriar, Usar, Equipar...). Devolve {"id", "acao"}, ou {} se Adé fechou.
func abrir(acoes: Callable) -> Dictionary:
	aberto = true
	get_tree().paused = true
	Jogo.tocar_som("pegar_item", -12.0)
	_montar_tela()
	var resposta := {}
	while true:
		_escolha = null
		while _escolha == null:
			await get_tree().process_frame
		if _escolha is String and _escolha == "fechar":
			break
		var id: String = _escolha
		var opcoes: Array = acoes.call(id)
		var rotulos := []
		for o in opcoes:
			rotulos.append(o[0])
		rotulos.append("Voltar")
		_raiz.visible = false
		var r: Dictionary = await Jogo.menu.escolher(ITENS[id]["nome"], rotulos)
		_raiz.visible = true
		if r["acao"] == "ok" and r["i"] < opcoes.size():
			resposta = {"id": id, "acao": opcoes[r["i"]][1]}
			break
	_raiz.queue_free()
	_raiz = null
	get_tree().paused = false
	await get_tree().process_frame
	aberto = false
	return resposta


func _montar_tela() -> void:
	var tela := Vector2(Jogo.TELA)
	_raiz = Control.new()
	_raiz.size = tela
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.45)
	fundo.size = tela
	_raiz.add_child(fundo)
	var painel := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.97)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(16, 14)
	painel.size = Vector2(tela.x - 32, tela.y - 28)
	_raiz.add_child(painel)
	var bolsa := TextureRect.new()
	var a := AtlasTexture.new()
	a.atlas = load("res://arte/bornal_itens.png")
	a.region = Rect2(5 * 12, 0, 12, 12)
	bolsa.texture = a
	bolsa.position = Vector2(94, 20)
	_raiz.add_child(bolsa)
	var titulo := _rotulo("Àpò de Adé", 9, COR_TITULO)
	titulo.position = Vector2(110, 19)
	_raiz.add_child(titulo)

	# a lista: ícone pequeno na frente do nome (as ferramentas primeiro, depois o resto, na ordem em que Adé pegou)
	_lista.clear()
	for b in BOLSOS:
		for id in itens:
			if ITENS[id]["tipo"] == b[0]:
				_lista.append(id)
	_cursor = ColorRect.new()
	_cursor.color = Color(1.0, 0.85, 0.3, 0.22)
	_cursor.size = Vector2(tela.x - 56, ALTURA_LINHA)
	_raiz.add_child(_cursor)
	_linhas_ui.clear()
	for i in LINHAS_VISIVEIS:
		var y := TOPO_LISTA + i * ALTURA_LINHA
		var ic := TextureRect.new()
		ic.position = Vector2(32, y + 1.5)
		_raiz.add_child(ic)
		var nome := _rotulo("", 8, COR_TEXTO)
		nome.position = Vector2(48, y + 1)
		_raiz.add_child(nome)
		_linhas_ui.append([ic, nome])
	var seta_cima := _rotulo("▲", 6, COR_APAGADA)
	seta_cima.name = "SetaCima"
	seta_cima.position = Vector2(tela.x - 34, TOPO_LISTA - 2)
	_raiz.add_child(seta_cima)
	var seta_baixo := _rotulo("▼", 6, COR_APAGADA)
	seta_baixo.name = "SetaBaixo"
	seta_baixo.position = Vector2(tela.x - 34, TOPO_LISTA + (LINHAS_VISIVEIS - 1) * ALTURA_LINHA + 4)
	_raiz.add_child(seta_baixo)

	var sep := ColorRect.new()
	sep.color = Color(0.95, 0.95, 1.0, 0.35)
	sep.position = Vector2(24, 132)
	sep.size = Vector2(tela.x - 48, 1)
	_raiz.add_child(sep)
	_nome = _rotulo("", 9, COR_TITULO)
	_nome.position = Vector2(26, 137)
	_raiz.add_child(_nome)
	_desc = _rotulo("", 8, COR_TEXTO)
	_desc.position = Vector2(26, 151)
	_desc.size = Vector2(tela.x - 52, 36)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_raiz.add_child(_desc)
	var dica := _rotulo("", 7, COR_APAGADA)
	dica.text = Jogo.texto("{interagir}: escolher   ·   %s: fechar" % Jogo.botao("bornal"))
	dica.position = Vector2(16, tela.y - 26)
	dica.size = Vector2(tela.x - 32, 10)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raiz.add_child(dica)
	_linha = 0
	_topo = 0
	_mostrar_cursor()


func _mostrar_cursor() -> void:
	if _lista.is_empty():
		_cursor.visible = false
		for l in _linhas_ui:
			l[0].texture = null
			l[1].text = ""
		_linhas_ui[0][1].text = "O Àpò está vazio."
		_linhas_ui[0][1].add_theme_color_override("font_color", COR_APAGADA)
		_nome.text = ""
		_desc.text = ""
		_raiz.get_node("SetaCima").visible = false
		_raiz.get_node("SetaBaixo").visible = false
		return
	_linha = clampi(_linha, 0, _lista.size() - 1)
	# rola a lista para o item escolhido aparecer
	if _linha < _topo:
		_topo = _linha
	elif _linha >= _topo + LINHAS_VISIVEIS:
		_topo = _linha - LINHAS_VISIVEIS + 1
	for i in LINHAS_VISIVEIS:
		var k := _topo + i
		var ic: TextureRect = _linhas_ui[i][0]
		var nome: Label = _linhas_ui[i][1]
		if k < _lista.size():
			var id: String = _lista[k]
			ic.texture = icone(id)
			nome.text = ITENS[id]["nome"] + ("   · na mão" if id == equipado else "")
			nome.add_theme_color_override("font_color", COR_TITULO if k == _linha else COR_TEXTO)
		else:
			ic.texture = null
			nome.text = ""
	_cursor.visible = true
	_cursor.position = Vector2(28, TOPO_LISTA + (_linha - _topo) * ALTURA_LINHA)
	_raiz.get_node("SetaCima").visible = _topo > 0
	_raiz.get_node("SetaBaixo").visible = _topo + LINHAS_VISIVEIS < _lista.size()
	var id_esc: String = _lista[_linha]
	_nome.text = ITENS[id_esc]["nome"] + ("  (na mão)" if id_esc == equipado else "")
	_desc.text = Jogo.texto(ITENS[id_esc]["desc"])


func _input(ev: InputEvent) -> void:
	if not aberto or not _raiz or not _raiz.visible or _escolha != null or Jogo.menu.aberto:
		return
	if ev.is_action_pressed("bornal") or ev.is_action_pressed("cancelar") or ev.is_action_pressed("sair"):
		_escolha = "fechar"
		Jogo.tocar_som("texto", -10.0)
	elif ev.is_action_pressed("cima") or ev.is_action_pressed("esquerda"):
		if not _lista.is_empty():
			_linha = (_linha - 1 + _lista.size()) % _lista.size()
			Jogo.tocar_som("texto", -12.0)
			_mostrar_cursor()
	elif ev.is_action_pressed("baixo") or ev.is_action_pressed("direita"):
		if not _lista.is_empty():
			_linha = (_linha + 1) % _lista.size()
			Jogo.tocar_som("texto", -12.0)
			_mostrar_cursor()
	elif ev.is_action_pressed("interagir"):
		if not _lista.is_empty():
			Jogo.tocar_som("buzio", -10.0)
			_escolha = _lista[_linha]
	else:
		return
	get_viewport().set_input_as_handled()


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 2)
	return l
