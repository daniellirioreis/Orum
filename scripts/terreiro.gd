extends Node2D
## Prólogo, parte 1: o terreiro da Vó — estilo 16 bits (inspirado nos RPGs de ação do Super Nintendo).
##
## O terreiro tem quatro lugares, cada um com seu mapa:
##   quintal   → a casa vista de fora (telhado, fachada), horta, tronqueira e porteira
##   barracão  → congá, atabaques, assistência (sala)
##   cozinha   → Tia Dora (sala)
##   despensa  → onde o Epó está escondido (sala)
## As portas são números no arquivo de objetos: o mesmo número em dois lugares liga um ao outro.
##
## A história:
##   Efum  → Tia Dora, na cozinha (ela pede lenha do quintal antes)
##   Epó   → escondido na despensa
##   Oti   → Ogã Bené, nos atabaques (mini-jogo: repetir o toque)
##   Luma  → Lia, a cambone, no congá (só depois das outras três)
## Com tudo em mãos, a Vó vai para a tronqueira, faz-se o ritual, Exu chega e abre a porteira.

const TILE := 16
const ARQUIVO_DIALOGO := "res://dialogos/terreiro.json"
const ITENS := ["efum", "epo", "oti", "luna"]

## Onde cada lugar fica no "mundo" (bem separados uns dos outros) e se é sala ou área externa.
const LUGARES := {
	"quintal": {"origem": Vector2(0, 0), "dentro": false},
	"barracao": {"origem": Vector2(0, 1200), "dentro": true},
	"cozinha": {"origem": Vector2(700, 1200), "dentro": true},
	"despensa": {"origem": Vector2(1200, 1200), "dentro": true},
	"quarto": {"origem": Vector2(2200, 1200), "dentro": true},
}
const LUGAR_INICIAL := "barracao"

## Cor da luz em cada tipo de lugar (fim de tarde lá fora, sombra fresca dentro de casa).
const COR_FORA := Color(1.0, 0.96, 0.9)
const COR_DENTRO := Color(0.95, 0.88, 0.82)
## Força das luzes de lampião e fogo (de dia elas brilham pouco).
const FORCA_LUZES := 0.35

# índice de cada bloco na folha arte/tiles_snes.png (lista em fases/tiles_snes_indices.txt)
enum {
	GRAMA, GRAMA_TUFO, GRAMA_FLOR, CAMINHO, TERRA, MURO_TOPO, MURO_FRENTE,
	TELHADO, CUMEEIRA, BEIRAL, TELHADO_ESQ, TELHADO_DIR,
	FACHADA, FACHADA_ALTO, FACHADA_JANELA, FACHADA_PORTA,
	PISO, PISO2, LADRILHO, TABUA,
	PAREDE_ALTO, PAREDE_JANELA, PAREDE_BAIXO, PAREDE_ESQ, PAREDE_DIR, PAREDE_FUNDO, PAREDE_CANTO, VAZIO, SOLEIRA,
	INVISIVEL, CALCADA, ARBUSTO, ESTACA, BARRANCO_BORDA, BARRANCO_FACE, BARRANCO_PE,
	ESCADA, AGUA, MARGEM, DEGRAU, ESTRADA, PISO_BRANCO, PISO_BRANCO2, TOTAL_TILES
}
const CHAO := {
	",": GRAMA, ";": GRAMA_TUFO, "*": GRAMA_FLOR, "_": CAMINHO, "t": TERRA,
	".": PISO, ":": PISO2, "c": LADRILHO, "d": TABUA, "+": SOLEIRA, "P": FACHADA_PORTA,
	"=": CALCADA, "r": ESTRADA, "o": DEGRAU, "E": ESCADA, "a": ARBUSTO, "e": ESTACA,
	"^": BARRANCO_BORDA, "B": BARRANCO_FACE, "b": BARRANCO_PE, "~": AGUA, "|": MARGEM,
	"w": PISO_BRANCO, "x": PISO_BRANCO2,
}
const ANDAVEL := [",", ";", "*", "_", "t", ".", ":", "c", "d", "+", "P", "=", "r", "o", "E", "w", "x", "m", "l"]   # m, l: lama (terra de Nanã)
const PAREDES := ["#", "j"]
const SOLIDOS := [MURO_TOPO, MURO_FRENTE, TELHADO, CUMEEIRA, BEIRAL, TELHADO_ESQ, TELHADO_DIR,
	FACHADA, FACHADA_ALTO, FACHADA_JANELA, PAREDE_ALTO, PAREDE_JANELA, PAREDE_BAIXO, PAREDE_ESQ,
	PAREDE_DIR, PAREDE_FUNDO, PAREDE_CANTO, VAZIO, INVISIVEL, ARBUSTO, ESTACA,
	BARRANCO_BORDA, BARRANCO_FACE, BARRANCO_PE, AGUA, MARGEM]

## Objetos de cenário: imagem e tamanho do "pé" que bloqueia a passagem (zero = não bloqueia).
const CENARIO := {
	"C": ["res://arte/obj_conga.png", Vector2(52, 14)],
	"A": ["res://arte/obj_atabaques.png", Vector2(48, 10)],
	"F": ["res://arte/obj_fogao.png", Vector2(36, 14)],
	"m": ["res://arte/obj_mesa.png", Vector2(32, 10)],
	"O": ["res://arte/obj_pote.png", Vector2(12, 6)],
	"Q": ["res://arte/obj_prateleira.png", Vector2(46, 8)],
	"H": ["res://arte/obj_horta.png", Vector2(46, 22)],
	"R": ["res://arte/obj_arvore.png", Vector2(12, 8)],
	"M": ["res://arte/obj_mangueira.png", Vector2(12, 8)],
	"q": ["res://arte/obj_coqueiro.png", Vector2(8, 6)],
	"B": ["res://arte/obj_banco.png", Vector2(44, 8)],
	"Z": ["res://arte/obj_cerquinha.png", Vector2(16, 6)],
	"p": ["res://arte/obj_vaso.png", Vector2(10, 6)],
	"h": ["res://arte/obj_filtro.png", Vector2(12, 6)],
	"i": ["res://arte/obj_pilao.png", Vector2(10, 6)],
	"U": ["res://arte/obj_barril.png", Vector2(14, 8)],
	"J": ["res://arte/obj_bananeira.png", Vector2(8, 6)],
	"Y": ["res://arte/obj_dendezeiro.png", Vector2(8, 6)],
	"W": ["res://arte/obj_varal.png", Vector2.ZERO],
	"f": ["res://arte/obj_flores.png", Vector2.ZERO],
	"o": ["res://arte/obj_pedras.png", Vector2(12, 6)],
	"u": ["res://arte/obj_poste.png", Vector2(6, 6)],
	"n": ["res://arte/obj_panelas.png", Vector2.ZERO],
	"l": ["res://arte/obj_lampiao.png", Vector2.ZERO],
	"a": ["res://arte/arbusto.png", Vector2(14, 10)],
	"m2": ["res://arte/mato.png", Vector2.ZERO],
}
## Coisas que ficam no chão, por baixo das pessoas.
const NO_CHAO := {"E": "res://arte/obj_esteira.png", "r": "res://arte/obj_tapete.png"}

const CENA_JOGADOR := preload("res://cenas/jogador_rpg.tscn")
const CENA_INTERATIVO := preload("res://cenas/interativo.tscn")
const TEX_ITENS := preload("res://arte/itens.png")
const TEX_SOMBRA := preload("res://arte/sombra.png")

## O quarto de santo: um assentamento para cada orixá, na ordem em que ficam na parede
## (Exu já tem o dele: a tronqueira). Quando Adé traz o troféu de um orixá, a Vó coloca no assentamento
## e a vela se acende. Folha arte/assentamentos.png: uma linha por orixá, quadro 0 apagado e 1 aceso.
const ASSENTAMENTOS := ["ogum", "oxossi", "xango", "iansa", "oxala", "oxum", "iemanja", "nana", "omolu"]
const COR_ASSENTAMENTO := {
	"ogum": Color(0.4, 0.55, 1.0), "oxossi": Color(0.4, 1.0, 0.6), "xango": Color(1.0, 0.45, 0.35),
	"iansa": Color(1.0, 0.6, 0.3), "oxala": Color(1.0, 1.0, 1.0), "oxum": Color(1.0, 0.85, 0.3),
	"iemanja": Color(0.55, 0.8, 1.0), "nana": Color(0.8, 0.6, 1.0), "omolu": Color(0.9, 0.75, 0.5),
}
## Ícone de cada troféu: [folha, quadro de 12x12]
const ICONE_TROFEU := {"oxossi": ["res://arte/ox_itens.png", 3], "nana": ["res://arte/nana_itens.png", 3]}

## Etapas: sonho → acordou → buscando → pronto → na_tronqueira → ritual → aberto
var estado := "sonho"
var coletados := {}
var tia := "inicio"          # inicio → pediu_lenha → com_lenha → deu_efum
## A alfazema de Iemanjá (na volta da praia): a Vó pede ajuda para a Tia Dora, que faz o manjar.
## "" → vo_pediu → tia_pediu → pronto → alfazema → fim
var _manjar := ""
var _ingredientes := {}
const INGREDIENTES := ["coco", "leite", "acucar"]
var _coqueiros: Array = []
var _prateleiras: Array = []
var _brilho_alfazema: PointLight2D
var _panela: CanvasLayer          # o mini-jogo de mexer o manjar
var _manjar_na_mao: Sprite2D      # o manjar pronto, nas mãos de Adé até chegar na Vó
var lugar_atual := ""
## (variáveis para que outras cenas — como a encruzilhada — reaproveitem este script)
var lugares: Dictionary = LUGARES
var cor_fora := COR_FORA
var cor_dentro := COR_DENTRO

var mundo: Node2D             # tudo que precisa de profundidade (ordenado por y)
var jogador: CharacterBody2D
var vo: Area2D
var tronqueira: Area2D
var porteira: Node2D
var exu: Sprite2D
var marcas := {}              # posições especiais: "v" (Vó na tronqueira), "e" (Exu)
var portas := {}              # número da porta → lista de [lugar, posição do bloco]
var tamanhos := {}            # lugar → tamanho em pixels
var _chaos := {}              # lugar → camada do chão (com as colisões)

var _dados: Dictionary
var _tileset: TileSet
var _noite: CanvasModulate
var _toque: CanvasLayer
var _lista: Control
var _icone_buzio: TextureRect
var _slots := {}              # id da oferenda → ícone no inventário
const COR_ITEM_FALTA := Color(0.25, 0.22, 0.3, 0.6)
## Búzios de axé (a "vida" de Adé nas fases): acabou, é fim de jogo.
const AXE_MAX := 3
var _contador_buzios: Label
var _hud_oferendas: Array = []   # caixinhas do inventário das oferendas
var _axe_icones: Array = []      # os búzios do axé (AXE_MAX)
var _aviso: Label
var _clarao: ColorRect
var _cortina: ColorRect
var _pendente := ""
var _buscas := 0
var _porteira_corpo: CollisionShape2D
var _porteira_aberta := false
var _trocando := false
var _luz_tex: Texture2D = preload("res://arte/luz.png")
var _bichos: Array = []
var _gatos: Array = []
var _ciranda := {}            # crianças de mãos dadas girando
var _pega := {}               # duas crianças brincando de pega-pega
var _roda := {}               # roda de capoeira
var _chamas: Array = []
var _tempo := 0.0
var _cor_fundo_antiga: Color
var _retorno := false         # Adé voltou de um campo (pela encruzilhada ou pelo atalho do mapa)
var _assentamentos := {}      # id do orixá → interativo do assentamento
var _campos := {}             # id → nome, saudação (de dialogos/encruzilhada.json)
var _quartinha: Area2D        # onde Exu guarda o caminho (o jogo salvo)
var _falas_quartinha: Dictionary


func _ready() -> void:
	_retorno = Jogo.has_meta("retorno")
	if _retorno:
		Jogo.remove_meta("retorno")
	else:
		Jogo.reiniciar()
	Jogo.tocar_musica()
	for c in JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/encruzilhada.json"))["campos"]:
		_campos[c["id"]] = c
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)   # fora das salas é tudo escuro
	_dados = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_DIALOGO))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	$HUD.esconder_contador = true   # o terreiro tem a barra própria, lá em cima
	Jogo.bornal.mostrar_hud(true)

	_toque = preload("res://scripts/toque.gd").new()
	add_child(_toque)
	_panela = preload("res://scripts/panela.gd").new()
	add_child(_panela)
	_alguidar = preload("res://scripts/alguidar.gd").new()
	add_child(_alguidar)
	_criar_interface()
	$Dialogo.evento.connect(_ao_evento)
	_entrar_lugar(LUGAR_INICIAL)
	_mostrar_assentamentos()
	if _retorno:
		_preparar_retorno()
	else:
		_sonho()
	_montar_rotinas()


func _exit_tree() -> void:
	RenderingServer.set_default_clear_color(_cor_fundo_antiga)


func _process(delta: float) -> void:
	_tempo += delta
	_segurar_manjar()
	for chama in _chamas:
		var l: PointLight2D = chama[0]
		l.energy = chama[1] * (0.88 + 0.12 * sin(_tempo * chama[2]) + randf_range(-0.04, 0.04))
	for b in _bichos:
		_mover_galinha(b, delta)
	if _contador_buzios:
		_contador_buzios.text = "%03d" % Jogo.buzios
	for g in _gatos:
		g.frame = int(_tempo * 0.8) % 2
	_animar_brincadeiras()
	_mover_rotinas(delta)
	_animar_tempo(delta)
	for i in _velas_brancas.size():
		_velas_brancas[i].frame = int(_tempo * 5.0 + i * 1.3) % 2


func _unhandled_input(ev: InputEvent) -> void:
	# o Esc (ou Start) abre o menu de pausa, que fica no Jogo (scripts/menu.gd); Tab (ou Select), o bornal
	if ev.is_action_pressed("bornal") and _pode_abrir_bornal():
		get_viewport().set_input_as_handled()
		_abrir_bornal()


# ------------------------------------------------------------------ lugares e portas

## Ajusta a câmera e a luz para o lugar onde Adé está.
func _entrar_lugar(nome: String) -> void:
	lugar_atual = nome
	var origem: Vector2 = lugares[nome]["origem"]
	var tam: Vector2 = tamanhos[nome]
	var tela := Vector2(Jogo.TELA)
	var camera: Camera2D = jogador.get_node("Camera")
	# sala menor que a tela fica centralizada (com escuro em volta), como nos jogos antigos
	var esq := origem.x if tam.x >= tela.x else origem.x + (tam.x - tela.x) / 2.0
	var topo := origem.y if tam.y >= tela.y else origem.y + (tam.y - tela.y) / 2.0
	camera.limit_left = int(esq)
	camera.limit_top = int(topo)
	camera.limit_right = int(esq + maxf(tam.x, tela.x))
	camera.limit_bottom = int(topo + maxf(tam.y, tela.y))
	camera.reset_smoothing()
	_noite.color = cor_dentro if lugares[nome]["dentro"] else cor_fora
	if _camada_chuva:
		_camada_chuva.visible = not lugares[nome]["dentro"]      # a chuva só cai lá fora
		_volume_chuva(_volume_do_lugar(nome), 0.3)


## Leva Adé (com a tela escurecendo) para outro lugar.
func teleportar(nome: String, posicao: Vector2) -> void:
	jogador.global_position = posicao
	_entrar_lugar(nome)


func _ao_pisar_porta(corpo: Node2D, numero: String, lugar: String) -> void:
	if _trocando or not corpo.is_in_group("jogador") or not jogador.pode_mover:
		return
	if lugar == "cozinha" and numero == "4" and _quer_alfazema() and _manjar == "vo_pediu":
		await _tia_barra_a_despensa()
		return
	for destino in portas[numero]:
		if destino[0] != lugar:
			_trocando = true
			jogador.congelar(true)
			Jogo.tocar_som("pulo", -14.0)
			var t := create_tween()
			t.tween_property(_cortina, "color:a", 1.0, 0.18)
			await t.finished
			teleportar(destino[0], _chegada(destino[0], destino[1]))
			_mostrar_nome_do_lugar(destino[0])
			await get_tree().create_timer(0.08).timeout
			var t2 := create_tween()
			t2.tween_property(_cortina, "color:a", 0.0, 0.22)
			await t2.finished
			jogador.congelar(false)
			_trocando = false
			return


## Ao passar por uma porta, uma plaquinha no alto da tela diz em que cômodo Adé entrou.
const NOMES_DOS_LUGARES := {"barracao": "Barracão", "cozinha": "Cozinha", "despensa": "Despensa",
	"quarto": "Quarto de santo", "quintal": "Quintal"}
var _placa_lugar: PanelContainer
var _tween_placa: Tween


func _mostrar_nome_do_lugar(nome: String) -> void:
	if not NOMES_DOS_LUGARES.has(nome):
		return
	if not _placa_lugar:
		var camada := CanvasLayer.new()
		camada.layer = 6
		add_child(camada)
		_placa_lugar = PanelContainer.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.06, 0.08, 0.3, 0.92)
		estilo.border_color = Color(0.95, 0.95, 1.0)
		estilo.set_border_width_all(1)
		estilo.set_corner_radius_all(3)
		estilo.content_margin_left = 10
		estilo.content_margin_right = 10
		estilo.content_margin_top = 1
		estilo.content_margin_bottom = 2
		_placa_lugar.add_theme_stylebox_override("panel", estilo)
		var rotulo := Label.new()
		rotulo.add_theme_font_override("font", preload("res://fontes/NotoSans-SemiBold.ttf"))
		rotulo.add_theme_font_size_override("font_size", 10)
		rotulo.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_placa_lugar.add_child(rotulo)
		camada.add_child(_placa_lugar)
	var rotulo: Label = _placa_lugar.get_child(0)
	rotulo.text = NOMES_DOS_LUGARES[nome]
	_placa_lugar.reset_size()
	_placa_lugar.position = Vector2((Jogo.TELA.x - _placa_lugar.size.x) / 2.0, 26.0)
	if _tween_placa:
		_tween_placa.kill()
	_placa_lugar.modulate.a = 0.0
	_tween_placa = create_tween()
	_tween_placa.tween_interval(0.2)
	_tween_placa.tween_property(_placa_lugar, "modulate:a", 1.0, 0.25)
	_tween_placa.tween_interval(1.6)
	_tween_placa.tween_property(_placa_lugar, "modulate:a", 0.0, 0.5)


## Onde Adé aparece ao chegar por uma porta: no primeiro bloco livre ao lado dela.
func _chegada(lugar: String, celula: Vector2i) -> Vector2:
	var mapa: PackedStringArray = _mapas[lugar]
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var c: Vector2i = celula + dir
		var letra := _letra(mapa, c.x, c.y)
		if letra in ANDAVEL and letra != "+" and letra != "P" and not _e_porta(lugar, c):
			var origem: Vector2 = lugares[lugar]["origem"]
			return origem + Vector2(c.x * TILE + TILE / 2.0, (c.y + 1) * TILE - 2)
	return lugares[lugar]["origem"]


func _e_porta(lugar: String, celula: Vector2i) -> bool:
	for numero in portas:
		for p in portas[numero]:
			if p[0] == lugar and p[1] == celula:
				return true
	return false


# ------------------------------------------------------------------ história

func _sonho() -> void:
	Jogo.bornal.comecar_fase("exu")
	jogador.congelar(true)
	var tela := Vector2(Jogo.TELA)
	var camada := CanvasLayer.new()
	camada.layer = 8
	add_child(camada)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(raiz)
	var ceu := TextureRect.new()
	ceu.texture = preload("res://arte/sonho_fundo.png")
	ceu.position = Vector2(-64, 0)
	raiz.add_child(ceu)
	var figuras := []
	for i in 9:                     # os orixás que têm mundo, em sombra (Oxalá no meio)
		var s := Sprite2D.new()
		s.texture = preload("res://arte/sonho_orixas.png")
		s.hframes = 9
		s.frame = i
		s.position = Vector2(tela.x / 2.0 + (i - 4) * 27, 84 + (6 if i % 2 else 0))
		s.modulate.a = 0.0
		raiz.add_child(s)
		figuras.append(s)

	await get_tree().create_timer(0.8).timeout
	var t := create_tween()
	for s in figuras:
		t.tween_property(s, "modulate:a", 1.0, 0.45)
	await t.finished
	var flutuar := create_tween().set_loops()
	flutuar.tween_property(raiz, "position:y", -2.0, 1.2).set_trans(Tween.TRANS_SINE)
	flutuar.tween_property(raiz, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	await _falar("sonho")
	flutuar.kill()
	var some := create_tween()
	some.tween_property(raiz, "modulate:a", 0.0, 1.2)
	await some.finished
	camada.queue_free()

	$HUD.mostrar_titulo("Prólogo", "Ilé · O Terreiro da Vó")
	estado = "acordou"
	jogador.congelar(false)


func _falar_com_vo() -> void:
	if _retorno:
		await _vo_no_retorno()
		return
	match estado:
		"acordou":
			await _falar("conversa")
		"buscando":
			var faltam := []
			for id in ITENS:
				if not coletados.has(id):
					faltam.append(_dados["nomes_itens"][id])
			var linha: Dictionary = _dados["falta"][0].duplicate()
			linha["pt"] = linha["pt"].replace("{faltam}", _juntar(faltam))
			await _falar_linhas([linha])
		"pronto":
			await _falar("pronto")
			if _pendente == "ir_para_tronqueira":
				_pendente = ""
				await _vo_vai_para_tronqueira()
		"na_tronqueira":
			await _falar("esperando")
		"aberto":
			await _falar("depois")


func _falar_com_tia() -> void:
	if _quer_alfazema() and _manjar != "":
		await _tia_e_o_manjar()
		return
	if estado == "acordou" or estado == "sonho":
		await _falar("tia_antes")
	elif tia == "inicio":
		await _falar("tia_pedido")
	elif tia == "pediu_lenha":
		if Jogo.bornal.tem("lenha"):
			await _falar("tia_quer_lenha")
			_dica_bornal("Dar à Tia Dora")
		else:
			await _falar("tia_esperando")
	elif tia == "com_lenha":
		await _falar("tia_lenha")
	else:
		await _falar("tia_depois")


## Na gameleira: se a Vó já está lá fora (na tronqueira), é ela quem fala; antes, Adé lembra.
func _olhar_gameleira() -> void:
	if estado in ["na_tronqueira", "aberto"]:
		await _falar("gameleira_vo")
	else:
		await _falar("gameleira_ade")


func _pegar_lenha() -> void:
	if tia == "pediu_lenha" and not Jogo.bornal.tem("lenha"):
		await _falar("lenha_pegar")
	else:
		await _falar("lenha_nada")


func _procurar_na_despensa(tem_epo: bool, letra := "") -> void:
	if _quer_alfazema() and _manjar == "tia_pediu":
		if letra == "S" and not _tem_ingrediente("acucar"):
			await _falar("acucar_pegar")
		elif letra in ["K", "k"] and not _tem_ingrediente("leite"):
			await _falar("leite_pegar")
		else:
			await _falar("despensa_manjar_nada")
		return
	if estado != "buscando":
		await _falar("despensa_antes")
	elif tem_epo and not coletados.has("epo"):
		await _falar("despensa_epo")
	else:
		var opcoes: Array = _dados["despensa_nada"]
		await _falar_linhas([opcoes[_buscas % opcoes.size()]])
		_buscas += 1


func _falar_com_oga() -> void:
	if _toque and _toque.jogando:
		return
	if estado == "acordou" or estado == "sonho":
		await _falar("oga_antes")
	elif coletados.has("oti"):
		await _falar("oga_depois")
	else:
		await _falar("oga_pedido")
		if _pendente == "comecar_toque":
			_pendente = ""
			jogador.congelar(true)
			_oga.ativo = false          # durante o mini-jogo, apertar Enter não recomeça a conversa
			await _toque.jogar()
			_oga.ativo = true
			await _falar("oga_ganhou")


func _falar_com_cambone() -> void:
	if estado == "acordou" or estado == "sonho":
		await _falar("cambone_antes")
	elif coletados.has("luna"):
		await _falar("cambone_depois")
	elif coletados.has("efum") and coletados.has("epo") and coletados.has("oti"):
		await _falar("cambone_luma")
	else:
		await _falar("cambone_cedo")


func _ao_evento(nome: String) -> void:
	match nome:
		"comecar_busca":
			estado = "buscando"
			_lista.visible = true
		"pedir_lenha":
			tia = "pediu_lenha"
		"pegar_lenha":
			_pegar_item("lenha", _objeto_perto("res://arte/obj_lenha.png"))
		"ganhar_efum":
			tia = "deu_efum"
			_ganhar("efum")
		"ganhar_epo":
			_ganhar("epo")
		"ganhar_oti":
			_ganhar("oti")
		"ganhar_luma":
			_ganhar("luna")
		"comecar_toque", "ir_para_tronqueira":
			_pendente = nome
		"vo_saudacao":
			vo.animar = false
			vo.sprite.frame = 2
		"tremer":
			_tremer()
		"exu_chega":
			_exu_aparece()
		"abrir_porteira":
			_abrir_porteira()
		"manjar_vo_pediu":
			_manjar = "vo_pediu"
		"manjar_ingredientes":
			_manjar = "tia_pediu"
			_atualizar_manjar()
		"pegar_coco", "pegar_leite", "pegar_acucar":
			_pegar_ingrediente(nome.trim_prefix("pegar_"))
		"liberar_alfazema":
			_manjar = "alfazema"
			_atualizar_manjar()
		"pegar_alfazema":
			_manjar = "fim"
			Jogo.set_meta("iemanja_alfazema", true)
			_pegar_item("alfazema", _prateleiras[0].global_position + Vector2(0, -20) if not _prateleiras.is_empty() else Vector2(-1, -1))
			_atualizar_manjar()


func _ganhar(id: String) -> void:
	coletados[id] = true
	var icone: TextureRect = _slots[id]
	icone.modulate = Color.WHITE
	icone.pivot_offset = Vector2(6, 6)
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(1.6, 1.6), 0.12)
	t.tween_property(icone, "scale", Vector2.ONE, 0.18)
	_atualizar_hud()
	_pegar_item(id)
	if coletados.size() == ITENS.size():
		estado = "pronto"
		await get_tree().create_timer(2.6).timeout
		_mostrar_aviso("Leve tudo para a Vó, no barracão.")


func _vo_vai_para_tronqueira() -> void:
	estado = "na_tronqueira"
	vo.ativo = false
	jogador.congelar(true)
	await _vo_sai_do_barracao()
	jogador.congelar(false)
	vo.global_position = marcas["v"]
	var t2 := create_tween()
	t2.tween_property(vo, "modulate:a", 1.0, 0.6)
	tronqueira.ativo = true
	_mostrar_aviso("Vá até a tronqueira, perto da porteira.")


## A Vó atravessa o barracão andando até a porta do quintal e sai por ela.
func _vo_sai_do_barracao() -> void:
	var origem: Vector2 = lugares["barracao"]["origem"]
	var xs := []
	var linha := 0
	for p in portas["1"]:
		if p[0] == "barracao":
			xs.append(p[1].x)
			linha = p[1].y
	var porta_x: float = origem.x + (xs.min() + xs.max() + 1) / 2.0 * TILE
	var dentro_y: float = origem.y + linha * TILE           # logo antes da porta
	var fora_y: float = origem.y + (linha + 1) * TILE + 4   # já atravessando
	vo.animar = false
	vo.olhar_para_jogador = false
	vo.sprite.flip_h = false
	var forma: CollisionShape2D = vo.get_node("Corpo/Forma")
	forma.set_deferred("disabled", true)   # não esbarra em Adé no caminho
	var passos := create_tween().set_loops()
	passos.tween_callback(func(): vo.sprite.frame = 3).set_delay(0.18)
	passos.tween_callback(func(): vo.sprite.frame = 4).set_delay(0.18)
	const VEL := 38.0   # pixels por segundo
	var pontos := [Vector2(porta_x, vo.global_position.y), Vector2(porta_x, dentro_y), Vector2(porta_x, fora_y)]
	var de: Vector2 = vo.global_position
	for alvo in pontos:
		var dur := de.distance_to(alvo) / VEL
		if dur > 0.01:
			var t := create_tween()
			t.tween_property(vo, "global_position", alvo, dur)
			if alvo == pontos[2]:
				t.parallel().tween_property(vo, "modulate:a", 0.0, dur)
			await t.finished
		de = alvo
	passos.kill()
	forma.set_deferred("disabled", false)
	Jogo.tocar_som("pulo", -16.0)
	await get_tree().create_timer(0.2).timeout
	vo.olhar_para_jogador = true
	vo.animar = true


var _arriados := {}       # as oferendas que Adé já arriou na tronqueira
var _pade_pronto := false      # o padê: Gààrí, Epó e Oti misturados e mexidos até ficar amarelo escuro
var _alguidar: CanvasLayer     # o mini-jogo do padê (alguidar de barro)
var _pade_na_mao: Sprite2D     # o padê nas mãos de Adé até arriar


## Na tronqueira: Adé arria cada oferenda pelo bornal (Arriar na tronqueira).
func _fazer_ritual() -> void:
	if estado != "na_tronqueira":
		return
	if not _pade_pronto and ["efum", "epo", "oti"].all(func(i): return Jogo.bornal.tem(i)):
		await _misturar_pade()
		return
	await _falar("esperando")
	_dica_bornal("Arriar na tronqueira")


## Adé põe o Gààrí, o Epó e o Oti no alguidar e mexe até ficar amarelo escuro (mesma dinâmica do manjar).
func _misturar_pade() -> void:
	jogador.congelar(true)
	jogador.olhar_para(tronqueira.global_position)
	await _falar_linhas([{"quem": "Benedita", "yo": "", "pt": "Vamos fazer o padê, meu neto. Põe cada coisa no alguidar e mexe até ficar amarelo escuro."}])
	for id in ["efum", "epo", "oti"]:
		if _slots.has(id):
			create_tween().tween_property(_slots[id], "modulate:a", 0.0, 0.25)
		Jogo.bornal.tirar(id, _na_tela(tronqueira.global_position + Vector2(0, -6)))
	await get_tree().create_timer(0.5).timeout
	await _alguidar.jogar(["efum", "epo", "oti"])
	_pade_pronto = true
	Jogo.bornal.pegar("pade")
	await _mostrar_grande(preload("res://arte/pade_grande.png"), 2.0, "Padê pronto!", "Mexido até ficar amarelo escuro.")
	_pade_na_mao = Sprite2D.new()
	_pade_na_mao.texture = preload("res://arte/pade.png")
	_pade_na_mao.position = Vector2(0, -9)
	_pade_na_mao.z_index = 1
	jogador.add_child(_pade_na_mao)
	_mostrar_aviso("Você guardou no Àpò: Padê")
	_dica_bornal("Arriar na tronqueira")


func _arriar_na_tronqueira(id: String) -> void:
	_arriados[id] = true
	if _slots.has(id):
		create_tween().tween_property(_slots[id], "modulate:a", 0.0, 0.25)   # sai da barra de cima
	Jogo.tocar_som("buzio", -6.0)
	var oferenda := Sprite2D.new()
	oferenda.modulate.a = 0.0
	if id == "pade":
		if is_instance_valid(_pade_na_mao):
			_pade_na_mao.queue_free()
			_pade_na_mao = null
		oferenda.texture = preload("res://arte/pade.png")
		oferenda.position = Vector2(0, 4)
	else:
		var lugares := [-12.0, -4.0, 4.0, 12.0]
		var i := ITENS.find(id)
		oferenda.texture = TEX_ITENS
		oferenda.hframes = 5
		oferenda.frame = i
		oferenda.position = Vector2(lugares[i], 4)
	tronqueira.get_node("Oferendas").add_child(oferenda)
	create_tween().tween_property(oferenda, "modulate:a", 1.0, 0.25)
	# o Exu só chega com o padê e a vela na tronqueira
	if _arriados.has("pade") and _arriados.has("luna"):
		await get_tree().create_timer(0.6).timeout
		await _ritual_completo()


func _ritual_completo() -> void:
	estado = "ritual"
	tronqueira.ativo = false
	jogador.congelar(true)
	jogador.olhar_para(tronqueira.global_position)
	_lista.visible = false
	tronqueira.sprite.frame = 1
	_esconder_inventario()
	var brilho: Sprite2D = tronqueira.get_node("Brilho")
	brilho.visible = true
	_luz(tronqueira.global_position + Vector2(0, -6), Color(1.0, 0.7, 0.4), 1.3, 1.6, true)
	var pulsar := create_tween().set_loops()
	pulsar.tween_property(brilho, "modulate:a", 0.6, 0.5)
	pulsar.tween_property(brilho, "modulate:a", 1.0, 0.5)

	await _falar("ritual")
	jogador.congelar(true)
	await get_tree().create_timer(0.4).timeout
	await _falar("exu")

	vo.animar = true
	var t := create_tween()
	t.tween_property(exu, "global_position", porteira.global_position + Vector2(0, 6), 1.4)
	t.tween_property(exu, "modulate:a", 0.0, 0.6)
	await t.finished
	estado = "aberto"
	vo.ativo = true
	jogador.congelar(false)
	_mostrar_aviso("A porteira está aberta. Siga Exu.")


func _exu_aparece() -> void:
	exu = _exu_surge(marcas["e"])


## Exu surge numa fumaça vermelha e preta, com uma luz vermelha. Devolve o sprite.
func _exu_surge(pos: Vector2) -> Sprite2D:
	Jogo.tocar_som("caminho", -2.0)
	var e := Sprite2D.new()
	e.texture = preload("res://arte/exu_snes.png")
	e.hframes = 4                      # 0-1 parado · 2-3 gargalhando
	e.add_to_group("exu_sprite")
	e.offset = Vector2(0, -16)
	e.position = pos
	e.modulate = Color(1, 1, 1, 0)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	e.add_child(sombra)
	mundo.add_child(e)
	var luz_exu := PointLight2D.new()
	luz_exu.texture = _luz_tex
	luz_exu.color = Color(1.0, 0.3, 0.25)
	luz_exu.texture_scale = 1.2
	luz_exu.energy = 0.0
	luz_exu.position = Vector2(0, -16)
	e.add_child(luz_exu)
	create_tween().tween_property(luz_exu, "energy", 1.0, 1.0)
	_fumaca_vermelha(pos + Vector2(0, -12))
	create_tween().tween_property(e, "modulate:a", 1.0, 1.0)
	var piscar := e.create_tween().set_loops()
	piscar.tween_callback(func():
		if not e.get_meta("rindo", false):
			e.frame = (e.frame + 1) % 2).set_delay(0.6)
	# quando a fala dele tem risada, Exu gargalha
	if not $Dialogo.risada.is_connected(_exu_ri):
		$Dialogo.risada.connect(_exu_ri)
	# chega rindo
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(e):
			_gargalhar(e, 1.4))
	return e


## Todos os Exus em cena gargalham (a fala do diálogo tem "Há há há!" ou "Hi hi hi!").
func _exu_ri(forte: bool) -> void:
	for e in get_tree().get_nodes_in_group("exu_sprite"):
		if is_instance_valid(e) and e.visible and e.modulate.a > 0.5:
			_gargalhar(e, 1.4 if forte else 0.9)


## Exu gargalha: olhos fechados, boca aberta, o corpo sacudindo (quadros 2 e 3).
func _gargalhar(e: Sprite2D, segundos: float) -> void:
	if e.get_meta("rindo", false):
		return
	e.set_meta("rindo", true)
	var x0 := e.position.x
	var passos := int(segundos / 0.12)
	var t := e.create_tween()
	for i in passos:
		t.tween_callback(func():
			e.frame = 2 + i % 2
			e.position.x = x0 + (0.5 if i % 2 == 0 else -0.5))
		t.tween_interval(0.12)
	t.tween_callback(func():
		e.frame = 0
		e.position.x = x0
		e.set_meta("rindo", false))


func _fumaca_vermelha(pos: Vector2) -> void:
	var fumaca := CPUParticles2D.new()
	fumaca.position = pos
	fumaca.z_index = 2
	fumaca.amount = 40
	fumaca.lifetime = 1.4
	fumaca.one_shot = true
	fumaca.explosiveness = 0.8
	fumaca.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	fumaca.emission_sphere_radius = 10.0
	fumaca.direction = Vector2(0, -1)
	fumaca.spread = 60.0
	fumaca.gravity = Vector2(0, -20)
	fumaca.initial_velocity_min = 8.0
	fumaca.initial_velocity_max = 22.0
	fumaca.scale_amount_min = 2.0
	fumaca.scale_amount_max = 3.0
	var cores := Gradient.new()
	cores.set_color(0, Color(0.77, 0.16, 0.16, 0.9))
	cores.set_color(1, Color(0.1, 0.05, 0.1, 0.0))
	fumaca.color_ramp = cores
	add_child(fumaca)
	fumaca.emitting = true
	get_tree().create_timer(2.0).timeout.connect(fumaca.queue_free)


func _abrir_porteira() -> void:
	_porteira_aberta = true
	porteira.get_node("Sprite").frame = 1
	_porteira_corpo.set_deferred("disabled", true)
	Jogo.tocar_som("caminho", -2.0)


func _ao_passar_porteira(corpo: Node2D) -> void:
	if not _porteira_aberta or not corpo.is_in_group("jogador") or estado != "aberto":
		return
	estado = "saindo"
	jogador.congelar(true)
	if _retorno:
		# os caminhos já estão abertos: Exu leva Adé direto ao mapa, na encruzilhada
		Jogo.set_meta("no_mapa", "orita")
		Jogo.mudar_cena("res://cenas/mapa_mundo.tscn")
	else:
		Jogo.mudar_cena("res://cenas/encruzilhada.tscn")


func _tremer() -> void:
	Jogo.tocar_som("caminho", -8.0)
	var camera: Camera2D = jogador.get_node("Camera")
	var t := create_tween()
	for i in 10:
		t.tween_property(camera, "offset", Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.04)
	var c := create_tween()
	c.tween_property(_clarao, "color:a", 0.35, 0.15)
	c.tween_property(_clarao, "color:a", 0.0, 0.8)


# ------------------------------------------------------------------ diálogo

func _falar(chave: String) -> void:
	await _falar_linhas(_dados[chave].duplicate(true))


func _falar_linhas(linhas: Array) -> void:
	# se Adé está na metade de baixo da tela, a caixa vai para o alto (e vice-versa)
	var y_na_tela := jogador.get_global_transform_with_canvas().origin.y
	$Dialogo.posicionar(estado != "sonho" and y_na_tela > Jogo.TELA.y * 0.58)
	$Dialogo.iniciar(linhas)
	await $Dialogo.terminou


func _juntar(lista: Array) -> String:
	if lista.size() <= 1:
		return "".join(lista)
	return ", ".join(lista.slice(0, lista.size() - 1)) + " e " + lista[-1]


# ------------------------------------------------------------------ interface (barra de axé, oferendas, avisos)

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 6
	add_child(camada)
	var tela := Vector2(Jogo.TELA)
	var fonte_forte := preload("res://fontes/NotoSans-SemiBold.ttf")

	# inventário (à esquerda): uma caixinha para cada oferenda; as que faltam aparecem apagadas
	for i in ITENS.size():
		var caixa := TextureRect.new()
		caixa.texture = preload("res://arte/hud_slot.png")
		caixa.position = Vector2(6 + i * 19, 6)
		camada.add_child(caixa)
		_hud_oferendas.append(caixa)
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX_ITENS
		atlas.region = Rect2(i * 12, 0, 12, 12)
		var item := TextureRect.new()
		item.texture = atlas
		item.position = caixa.position + Vector2(3, 3)
		item.modulate = COR_ITEM_FALTA
		camada.add_child(item)
		_hud_oferendas.append(item)
		_slots[ITENS[i]] = item

	# búzios recolhidos
	_icone_buzio = TextureRect.new()
	_icone_buzio.texture = preload("res://arte/buzio_axe.png")
	_icone_buzio.position = Vector2(86, 9)
	camada.add_child(_icone_buzio)
	_contador_buzios = _rotulo_hud("000", 10, Color.WHITE)
	_contador_buzios.add_theme_font_override("font", fonte_forte)
	_contador_buzios.position = Vector2(99, 6)
	_esconder_inventario()      # o que Adé carrega fica no bornal (scripts/bornal.gd); a barra antiga não aparece
	camada.add_child(_contador_buzios)

	# AXÉ (à direita): búzios no lugar dos corações
	var axe := _rotulo_hud("— AXÉ —", 7, Color(1.0, 0.9, 0.6))
	axe.add_theme_font_override("font", fonte_forte)
	axe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	axe.size = Vector2(70, 10)
	axe.position = Vector2(tela.x - 78, 3)
	camada.add_child(axe)
	for i in AXE_MAX:
		var b := TextureRect.new()
		b.texture = preload("res://arte/buzio_axe.png")
		b.position = Vector2(tela.x - 76 + 13 + i * 13, 15)
		camada.add_child(b)
		_axe_icones.append(b)

	_lista = Control.new()   # (marcador de "busca começou"; a barra fica sempre à mostra)
	camada.add_child(_lista)

	_aviso = _rotulo_hud("", 8, Color(1, 0.95, 0.85))
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.size = Vector2(tela.x, 14)
	_aviso.position = Vector2(0, 36)
	_aviso.modulate.a = 0.0
	camada.add_child(_aviso)

	_clarao = ColorRect.new()
	_clarao.color = Color(0.8, 0.1, 0.1, 0.0)
	_clarao.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_clarao)

	var camada_cortina := CanvasLayer.new()
	camada_cortina.layer = 50
	add_child(camada_cortina)
	_cortina = ColorRect.new()
	_cortina.color = Color(0, 0, 0, 0)
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada_cortina.add_child(_cortina)


func _atualizar_hud() -> void:
	_contador_buzios.text = "%03d" % Jogo.buzios


func _rotulo_hud(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _mostrar_aviso(texto: String) -> void:
	_aviso.text = Jogo.texto(texto)
	var t := create_tween()
	t.tween_property(_aviso, "modulate:a", 1.0, 0.25)
	t.tween_interval(2.0)
	t.tween_property(_aviso, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ mapas

var _mapas := {}


func _ler(caminho: String) -> PackedStringArray:
	var linhas := PackedStringArray()
	for linha in FileAccess.get_file_as_string(caminho).split("\n"):
		linha = linha.strip_edges(false, true)
		if linha != "":
			linhas.append(linha)
	return linhas


func _letra(mapa: PackedStringArray, x: int, y: int) -> String:
	if y < 0 or y >= mapa.size() or x < 0 or x >= mapa[y].length():
		return " "
	return mapa[y][x]


func _construir(nome: String) -> void:
	var origem: Vector2 = lugares[nome]["origem"]
	var mapa := _ler("res://fases/%s.txt" % nome)
	_mapas[nome] = mapa
	var largura := 0
	for linha in mapa:
		largura = maxi(largura, linha.length())
	tamanhos[nome] = Vector2(largura * TILE, mapa.size() * TILE)

	var chao := TileMapLayer.new()
	chao.tile_set = _tileset
	chao.position = origem
	chao.z_index = -10      # o chão fica sempre por baixo
	add_child(chao)
	_chaos[nome] = chao
	if lugares[nome]["dentro"]:
		for y in mapa.size():
			for x in mapa[y].length():
				var t := _tile_para(mapa, x, y)
				if t >= 0:
					chao.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	else:
		chao.z_index = -6
		_construir_terreno(mapa, origem, chao)

	var objetos := _ler("res://fases/%s_objetos.txt" % nome)
	for y in objetos.size():
		for x in objetos[y].length():
			var c := objetos[y][x]
			if c == ".":
				continue
			var base := origem + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			_criar_objeto(nome, c, Vector2i(x, y), base, chao)


## Escolhe o bloco certo olhando os vizinhos (paredes, telhado, muro).
func _tile_para(mapa: PackedStringArray, x: int, y: int) -> int:
	var c := _letra(mapa, x, y)
	var acima := _letra(mapa, x, y - 1)
	var abaixo := _letra(mapa, x, y + 1)
	var abaixo2 := _letra(mapa, x, y + 2)
	var esq := _letra(mapa, x - 1, y)
	var dir := _letra(mapa, x + 1, y)
	if CHAO.has(c):
		return CHAO[c]
	match c:
		"M":
			return MURO_TOPO if abaixo == "M" else MURO_FRENTE
		"R":
			if acima != "R":
				return CUMEEIRA
			if abaixo != "R":
				return BEIRAL
			if esq != "R":
				return TELHADO_ESQ
			if dir != "R":
				return TELHADO_DIR
			return TELHADO
		"h":
			return FACHADA_ALTO
		"H":
			return FACHADA
		"J":
			return FACHADA_JANELA
		"#", "j":
			if abaixo in ANDAVEL:
				return PAREDE_BAIXO
			if abaixo in PAREDES and abaixo2 in ANDAVEL:
				return PAREDE_JANELA if c == "j" else PAREDE_ALTO
			if dir in ANDAVEL:
				return PAREDE_ESQ
			if esq in ANDAVEL:
				return PAREDE_DIR
			if acima in ANDAVEL:
				return PAREDE_FUNDO
			return PAREDE_CANTO
	return -1


func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	if c.is_valid_int():
		if not portas.has(c):
			portas[c] = []
		portas[c].append([lugar, celula])
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.position = base - Vector2(0, TILE / 2.0)
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = Vector2(12, 12)
		forma.shape = ret
		area.add_child(forma)
		area.body_entered.connect(_ao_pisar_porta.bind(c, lugar))
		add_child(area)
		return
	if lugar == "quarto" and _adereco_do_quarto(c, base):
		return
	if c == "q" and lugar == "quintal":
		# coqueiro do quintal: na volta da praia de Iemanjá, dá o coco do manjar
		var coq := _criar_interativo(CENARIO["q"][0], 1, base, CENARIO["q"][1], -34.0)
		coq.olhar_para_jogador = false
		coq.ativo = false
		coq.interagiu.connect(_sacudir_coqueiro.bind(coq))
		_coqueiros.append(coq)
		return
	if c == "Q" and lugar == "despensa":
		# prateleira da despensa: onde a Vó guarda o vidrinho de alfazema
		var prat := _criar_interativo(CENARIO["Q"][0], 1, base, CENARIO["Q"][1], -30.0)
		prat.olhar_para_jogador = false
		prat.ativo = false
		prat.interagiu.connect(_pegar_alfazema)
		_prateleiras.append(prat)
		return
	if c == "m" and lugar == "quintal":
		c = "m2"   # no quintal, "m" é mato alto (na cozinha é a mesa)
	if CENARIO.has(c):
		var s := _criar_cenario(CENARIO[c][0], CENARIO[c][1], base)
		_objetos[lugar + ":" + c] = s       # para as pessoas da casa interagirem com eles (fogão, atabaques...)
		if c == "a" and randf() < 0.3:
			s.hframes = 2
			s.frame = 1   # arbusto com frutinhas
		elif c == "a":
			s.hframes = 2
		match c:
			"l":
				_lampioes.append([_luz(base + Vector2(0, -8), Color(1.0, 0.78, 0.45), 0.6, 1.8, true), s])
			"u":
				_luz(base + Vector2(0, -38), Color(1.0, 0.8, 0.5), 0.75, 2.2, true)
			"F":
				_luz(base + Vector2(-8, -10), Color(1.0, 0.55, 0.25), 0.7, 1.2, true)
				_cano_da_chamine(lugar, base)
			"C":
				_luz(base + Vector2(0, -24), Color(1.0, 0.85, 0.6), 0.7, 1.6, true)
		return
	if NO_CHAO.has(c):
		var tapete := Sprite2D.new()
		tapete.texture = load(NO_CHAO[c])
		tapete.position = base + Vector2(0, -tapete.texture.get_height() / 2.0)
		tapete.z_index = -5
		add_child(tapete)
		return
	match c:
		"b":
			var varal := Sprite2D.new()
			varal.texture = preload("res://arte/obj_bandeirinhas.png")
			varal.centered = false
			varal.position = base - Vector2(TILE / 2.0, TILE)
			varal.z_index = 20
			add_child(varal)
		"+":
			_luzes_de_ambiente.append(_luz(base + Vector2(0, -8), Color(1.0, 0.8, 0.55), 0.45, 2.4, false))
		"g":
			_criar_galinha(base)
		"c":
			var buzio := preload("res://cenas/buzio.tscn").instantiate()
			buzio.position = base - Vector2(0, TILE / 2.0)
			mundo.add_child(buzio)
			Jogo.buzios_total += 1
		"z":
			var gato := Sprite2D.new()
			gato.texture = preload("res://arte/gato.png")
			gato.hframes = 2
			gato.offset = Vector2(0, -6)
			gato.position = base
			mundo.add_child(gato)
			_gatos.append(gato)
		"P":
			jogador = CENA_JOGADOR.instantiate()
			jogador.position = base
		"V":
			vo = _criar_pessoa("res://arte/vo_snes.png", 9, base)
			vo.interagiu.connect(_falar_com_vo)
			_registrar_alvo(vo, "vo", "pessoa", "Dar à Vó")
		"D":
			_tia = _criar_pessoa("res://arte/tia_snes.png", 13, base)
			_tia.interagiu.connect(_falar_com_tia)
			_registrar_alvo(_tia, "tia", "pessoa", "Dar à Tia Dora")
		"G":
			_oga = _criar_pessoa("res://arte/oga_snes.png", 13, base)
			_oga.interagiu.connect(_falar_com_oga)
			_registrar_alvo(_oga, "oga", "pessoa", "Dar ao Ogã Bené")
		"N":
			_lia = _criar_pessoa("res://arte/cambone_snes.png", 9, base)
			_lia.interagiu.connect(_falar_com_cambone)
			_registrar_alvo(_lia, "lia", "pessoa", "Dar à Lia")
		"K", "S", "k":
			var tex := "res://arte/obj_caixote.png" if c != "S" else "res://arte/obj_saco.png"
			var spot := _criar_interativo(tex, 1, base, Vector2(14, 8), -22.0)
			spot.interagiu.connect(_procurar_na_despensa.bind(c == "k", c))
		"I":
			# gameleira-branca de Iroko: dá para "conversar" com ela
			var gameleira := _criar_interativo("res://arte/obj_gameleira.png", 1, base, Vector2(24, 10), -90.0)
			(gameleira.get_node("Alcance").shape as CircleShape2D).radius = 26.0
			gameleira.interagiu.connect(_olhar_gameleira)
		"L":
			var lenha := _criar_interativo("res://arte/obj_lenha.png", 1, base, Vector2(26, 10), -22.0)
			lenha.interagiu.connect(_pegar_lenha)
		"T":
			tronqueira = _criar_interativo("res://arte/tronqueira.png", 2, base, Vector2(26, 8), -46.0)
			tronqueira.ativo = false
			_registrar_alvo(tronqueira, "tronqueira", "altar", "Arriar na tronqueira", 40.0)
			var brilho := Sprite2D.new()
			brilho.name = "Brilho"
			brilho.texture = preload("res://arte/brilho.png")
			brilho.scale = Vector2(3, 3)
			brilho.position = Vector2(0, -8)
			brilho.visible = false
			tronqueira.add_child(brilho)
			tronqueira.move_child(brilho, 0)
			var oferendas := Node2D.new()
			oferendas.name = "Oferendas"
			tronqueira.add_child(oferendas)
			tronqueira.interagiu.connect(_fazer_ritual)
		"X":
			_criar_porteira(base)
		"v", "e":
			marcas[c] = base
		"w":
			_criar_ciranda(base)
		"s":
			_criar_pega_pega(base)
		"x":
			_criar_roda_capoeira(base)
		"&":
			_criar_assentamentos(base)
		"*":
			_criar_quartinha(base)


func _criar_cenario(caminho: String, pe: Vector2, base: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(caminho)
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)
	s.position = base
	mundo.add_child(s)
	if pe.x > 0:
		var corpo := StaticBody2D.new()
		corpo.position = base
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = pe
		forma.shape = ret
		forma.position = Vector2(0, -pe.y / 2.0)
		corpo.add_child(forma)
		add_child(corpo)
	return s


func _criar_interativo(caminho: String, quadros: int, base: Vector2, pe: Vector2, balao: float) -> Area2D:
	var n: Area2D = CENA_INTERATIVO.instantiate()
	n.position = base
	n.animar = false
	n.altura_balao = balao
	mundo.add_child(n)
	var tex: Texture2D = load(caminho)
	n.sprite.texture = tex
	n.sprite.hframes = quadros
	n.sprite.offset = Vector2(0, -tex.get_height() / 2.0)
	var forma: CollisionShape2D = n.get_node("Corpo/Forma")
	(forma.shape as RectangleShape2D).size = pe
	forma.position = Vector2(0, -pe.y / 2.0)
	return n


func _criar_pessoa(caminho: String, quadros: int, base: Vector2) -> Area2D:
	var n := _criar_interativo(caminho, quadros, base, Vector2(12, 6), -40.0)
	n.animar = true
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	n.add_child(sombra)
	n.move_child(sombra, 0)
	return n


func _criar_porteira(base: Vector2) -> void:
	porteira = Node2D.new()
	porteira.position = base
	mundo.add_child(porteira)
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.texture = preload("res://arte/obj_porteira.png")
	s.hframes = 2
	s.offset = Vector2(0, -15)
	porteira.add_child(s)

	var corpo := StaticBody2D.new()
	_porteira_corpo = CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(48, 8)
	_porteira_corpo.shape = ret
	_porteira_corpo.position = Vector2(0, -4)
	corpo.add_child(_porteira_corpo)
	porteira.add_child(corpo)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var forma := CollisionShape2D.new()
	var ret2 := RectangleShape2D.new()
	ret2.size = Vector2(44, 10)
	forma.shape = ret2
	forma.position = Vector2(0, -6)
	area.add_child(forma)
	area.body_entered.connect(_ao_passar_porteira)
	porteira.add_child(area)


func _criar_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = preload("res://arte/tiles_snes.png")
	fonte.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(fonte, 0)
	var m := TILE / 2.0
	var quadrado := PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
	for i in TOTAL_TILES:
		var coord := Vector2i(i, 0)
		fonte.create_tile(coord)
		if i in SOLIDOS:
			var dados := fonte.get_tile_data(coord, 0)
			dados.add_collision_polygon(0)
			dados.set_collision_polygon_points(0, 0, quadrado)
	return ts


# ------------------------------------------------------------------ luz, bichos e partículas

func _luz(pos: Vector2, cor: Color, energia: float, escala: float, tremula: bool) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = _luz_tex
	l.position = pos
	l.color = cor
	energia *= FORCA_LUZES
	l.energy = energia
	l.texture_scale = escala
	add_child(l)
	if tremula:
		_chamas.append([l, energia, randf_range(5.0, 9.0)])
	return l


func _material_sem_sombra() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m


func _criar_vagalumes(lugar := "quintal") -> void:
	var tam: Vector2 = tamanhos[lugar]
	var v := CPUParticles2D.new()
	v.material = _material_sem_sombra()
	v.z_index = 15
	v.position = lugares[lugar]["origem"] + Vector2(tam.x / 2.0, tam.y * 0.62)
	v.amount = 30
	v.lifetime = 5.0
	v.preprocess = 5.0
	v.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	v.emission_rect_extents = Vector2(tam.x / 2.0 - 24, tam.y * 0.33)
	v.gravity = Vector2.ZERO
	v.direction = Vector2(0, -1)
	v.spread = 180.0
	v.initial_velocity_min = 2.0
	v.initial_velocity_max = 7.0
	v.scale_amount_min = 1.0
	v.scale_amount_max = 1.6
	var cores := Gradient.new()
	cores.set_color(0, Color(0.85, 1.0, 0.45, 0.0))
	cores.add_point(0.2, Color(0.85, 1.0, 0.45, 1.0))
	cores.add_point(0.45, Color(0.85, 1.0, 0.45, 0.15))
	cores.add_point(0.7, Color(0.85, 1.0, 0.45, 1.0))
	cores.set_color(cores.get_point_count() - 1, Color(0.85, 1.0, 0.45, 0.0))
	v.color_ramp = cores
	add_child(v)


## O cano da chaminé do fogão a lenha sobe pela parede até o teto (a fumaça sai lá fora, no telhado).
func _cano_da_chamine(lugar: String, base: Vector2) -> void:
	var topo: float = lugares[lugar]["origem"].y
	var x0 := base.x + 12.0                    # o cano do desenho do fogão fica entre x+12 e x+18
	var alto := int(base.y - 39.0 - topo)
	if alto <= 0:
		return
	var img := Image.create(7, alto, false, Image.FORMAT_RGBA8)
	var cores := [Color8(36, 30, 38), Color8(140, 132, 140), Color8(120, 112, 120), Color8(104, 96, 102),
		Color8(86, 80, 88), Color8(66, 60, 68), Color8(36, 30, 38)]
	for y in alto:
		for x in 7:
			var c: Color = cores[x]
			if y % 12 == 0 and x > 0 and x < 6:
				c = Color8(70, 64, 72)          # as emendas do cano
			img.set_pixel(x, y, c)
	var cano := Sprite2D.new()
	cano.texture = ImageTexture.create_from_image(img)
	cano.centered = false
	cano.position = Vector2(x0 - 0.5, topo)
	cano.z_index = -6                        # na parede, atrás do fogão e de quem passa
	add_child(cano)


func _fumaca(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 18
	f.amount = 14
	f.lifetime = 3.0
	f.preprocess = 3.0
	f.direction = Vector2(0.2, -1)
	f.spread = 12.0
	f.gravity = Vector2(4, -6)
	f.initial_velocity_min = 6.0
	f.initial_velocity_max = 10.0
	f.scale_amount_min = 2.0
	f.scale_amount_max = 4.0
	var cores := Gradient.new()
	cores.set_color(0, Color(0.7, 0.68, 0.72, 0.7))
	cores.set_color(1, Color(0.5, 0.48, 0.55, 0.0))
	f.color_ramp = cores
	add_child(f)


# ------------------------------------------------------------------ gente brincando no quintal

const TEX_CRIANCAS := preload("res://arte/criancas_snes.png")
const TEX_CAPOEIRA := preload("res://arte/capoeira_snes.png")
const TEX_RODA := preload("res://arte/roda_snes.png")


## Uma pessoa animada só com quadros (sem área de conversa). "variante" é a linha da folha.
func _figura(tex: Texture2D, quadros: int, linhas: int, variante: int, pos: Vector2, sombra := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = quadros
	s.vframes = linhas
	s.frame = variante * quadros
	s.offset = Vector2(0, -16)
	s.position = pos
	s.set_meta("variante", variante)
	var sb := Sprite2D.new()
	sb.texture = TEX_SOMBRA
	sb.scale = Vector2(sombra, sombra)
	sb.show_behind_parent = true
	s.add_child(sb)
	mundo.add_child(s)
	return s


func _quadro(s: Sprite2D, f: int) -> void:
	s.frame = int(s.get_meta("variante")) * s.hframes + f


## Um ponto de conversa invisível no meio de um grupo, que também impede Adé de atravessá-lo.
func _ponto_de_conversa(centro: Vector2, tamanho: Vector2, alcance: float, balao: float) -> Area2D:
	var n := _criar_interativo("res://arte/criancas_snes.png", 4, centro, tamanho, balao)
	n.sprite.visible = false
	n.animar = false
	n.olhar_para_jogador = false
	(n.get_node("Corpo/Forma") as CollisionShape2D).position = Vector2.ZERO
	(n.get_node("Alcance").shape as CircleShape2D).radius = alcance
	return n


func _criar_ciranda(base: Vector2) -> void:
	var centro := base + Vector2(0, -4)
	var criancas := []
	for i in 4:
		criancas.append(_figura(TEX_CRIANCAS, 4, 6, i, centro, 0.8))
	_ciranda = {"centro": centro, "criancas": criancas}
	_ciranda["ponto"] = _ponto_de_conversa(centro, Vector2(52, 22), 38.0, -36.0)
	_ciranda["ponto"].interagiu.connect(_falar_com_criancas)


func _criar_pega_pega(base: Vector2) -> void:
	var centro := base + Vector2(8, -4)
	_pega = {"centro": centro, "criancas": [_figura(TEX_CRIANCAS, 4, 6, 4, centro, 0.8), _figura(TEX_CRIANCAS, 4, 6, 5, centro, 0.8)]}


func _criar_roda_capoeira(base: Vector2) -> void:
	var centro := base + Vector2(0, -6)
	var jogadores := [_figura(TEX_CAPOEIRA, 4, 2, 0, centro), _figura(TEX_CAPOEIRA, 4, 2, 1, centro)]
	jogadores[1].flip_h = true   # um de frente para o outro
	var membros := []
	# [ângulo em graus, variante]: 0 berimbau (mestre), 1 pandeiro, 2-4 palmas
	for m in [[-90, 0], [-118, 1], [-62, 2], [-148, 3], [-32, 4], [180, 2], [0, 3], [148, 4], [32, 1]]:
		var a := deg_to_rad(m[0])
		var pos := centro + Vector2(cos(a) * 50.0, sin(a) * 26.0 + 2.0)
		membros.append(_figura(TEX_RODA, 2, 5, m[1], pos))
	_roda = {"centro": centro, "jogadores": jogadores, "membros": membros}
	_roda["ponto"] = _ponto_de_conversa(centro + Vector2(0, -2), Vector2(104, 52), 64.0, -66.0)
	_roda["ponto"].interagiu.connect(_falar_com_mestre)


func _animar_brincadeiras() -> void:
	var t := _tempo
	if _ciranda:
		var c: Vector2 = _ciranda["centro"]
		var lista: Array = _ciranda["criancas"]
		for i in lista.size():
			var a := t * 0.9 + i * TAU / lista.size()
			lista[i].position = c + Vector2(cos(a) * 22.0, sin(a) * 10.0)
			_quadro(lista[i], (int(t * 4.0) + i) % 2)
	if _pega:
		var c: Vector2 = _pega["centro"]
		var lista: Array = _pega["criancas"]
		for i in lista.size():
			var a := t * 1.7 - i * 0.75                 # a segunda corre atrás da primeira
			var r := 40.0 + sin(t * 0.7 + i) * 6.0
			lista[i].position = c + Vector2(cos(a) * r, sin(a) * 12.0)
			lista[i].flip_h = -sin(a) < 0.0
			_quadro(lista[i], 2 + int(t * 9.0 + i) % 2)
	if _roda:
		var c: Vector2 = _roda["centro"]
		var j: Array = _roda["jogadores"]
		var fase := fmod(t, 4.0)
		var ginga := int(t * 2.6) % 2
		var balanco := sin(t * PI * 1.3) * 2.0
		var quem_ataca := int(t / 4.0) % 2
		for i in 2:
			var lado := -1.0 if i == 0 else 1.0
			j[i].position = c + Vector2(lado * 13.0 + balanco * -lado, 0)
			if fase >= 2.4 and fase < 3.1:
				_quadro(j[i], 2 if i == quem_ataca else 3)   # meia-lua de um, esquiva do outro
			else:
				_quadro(j[i], ginga)
		for m in _roda["membros"]:
			var v := int(m.get_meta("variante"))
			if v == 0:
				_quadro(m, int(t * 5.2) % 2)          # berimbau
			elif v == 1:
				_quadro(m, int(t * 5.2 + 1.0) % 2)    # pandeiro
			else:
				_quadro(m, int(t * 2.6) % 2)          # palmas no tempo da ginga


func _falar_com_criancas() -> void:
	await _falar("criancas_depois" if estado == "aberto" else "criancas")


func _falar_com_mestre() -> void:
	await _falar("capoeira_depois" if estado == "aberto" else "capoeira")


func _criar_galinha(base: Vector2) -> void:
	var g := Sprite2D.new()
	g.texture = preload("res://arte/galinha.png")
	g.hframes = 4
	g.offset = Vector2(0, -6)
	g.position = base
	mundo.add_child(g)
	var cor := 0 if randf() < 0.5 else 2
	_bichos.append({"sprite": g, "origem": base, "alvo": base, "espera": randf_range(0.5, 2.0), "cor": cor})


func _mover_galinha(b: Dictionary, delta: float) -> void:
	var g: Sprite2D = b["sprite"]
	if b["espera"] > 0.0:
		b["espera"] -= delta
		g.frame = b["cor"] + (1 if fmod(_tempo, 0.6) < 0.3 else 0)
		if b["espera"] <= 0.0:
			b["alvo"] = b["origem"] + Vector2(randf_range(-40, 40), randf_range(-24, 24))
		return
	var para: Vector2 = b["alvo"] - g.position
	if para.length() < 1.0:
		b["espera"] = randf_range(1.0, 3.0)
		return
	g.position += para.normalized() * minf(14.0 * delta, para.length())
	g.flip_h = para.x < 0.0
	g.frame = b["cor"]


# ------------------------------------------------------------------ terreno de fora com bordas arredondadas
# Folha arte/terreno_snes.png: linha 0 = grama (4 variações); linhas 1-3 = terra, calçada e água,
# 16 peças cada (índice = cima-esq*1 + cima-dir*2 + baixo-esq*4 + baixo-dir*8); linha 4 = enfeites.
# As peças de borda ficam deslocadas meio bloco ("dual-grid"): cada uma cobre o encontro de 4 blocos,
# por isso os cantos saem arredondados.
const TERRENOS := [["r", "t", "_"], ["="], ["~", "|"]]
const AGUA_CHARS := ["~", "|"]
## (outras fases trocam estes: cada terreno é [letras, linha na folha arte/terreno_snes.png])
var terrenos: Array = [[TERRENOS[0], 1], [TERRENOS[1], 2], [TERRENOS[2], 3]]
var agua_chars: Array = AGUA_CHARS
var _ts_terreno: TileSet
var tex_moita := "res://arte/arbusto.png"   # a moita das bordas (a fase de Nanã usa a do brejo)
const SOBRE_TERRENO := ["M", "^", "B", "b", "E"]
const CASA_CHARS := ["R", "h", "H", "J", "P"]


func _criar_tileset_terreno() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = preload("res://arte/terreno_snes.png")
	fonte.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(fonte, 0)
	for y in fonte.texture.get_height() / TILE:
		for x in 16:
			fonte.create_tile(Vector2i(x, y))
	return ts


func _construir_terreno(mapa: PackedStringArray, origem: Vector2, topo: TileMapLayer) -> void:
	if _ts_terreno == null:
		_ts_terreno = _criar_tileset_terreno()
	var ts := _ts_terreno
	var largura := 0
	for linha in mapa:
		largura = maxi(largura, linha.length())
	var altura := mapa.size()

	# 1) grama em tudo
	var grama := TileMapLayer.new()
	grama.tile_set = ts
	grama.position = origem
	grama.z_index = -10
	add_child(grama)
	for y in altura:
		for x in largura:
			grama.set_cell(Vector2i(x, y), 0, Vector2i((x * 7 + y * 13 + (x * y) % 5) % 4, 0))

	# 2) terra, calçada e água, com bordas arredondadas
	for i in terrenos.size():
		var camada := TileMapLayer.new()
		camada.tile_set = ts
		camada.position = origem - Vector2(TILE / 2.0, TILE / 2.0)
		camada.z_index = -9 + i
		add_child(camada)
		var letras: Array = terrenos[i][0]
		var linha_folha: int = terrenos[i][1]
		for vy in altura + 1:
			for vx in largura + 1:
				var indice := 0
				if _letra(mapa, vx - 1, vy - 1) in letras: indice += 1
				if _letra(mapa, vx, vy - 1) in letras: indice += 2
				if _letra(mapa, vx - 1, vy) in letras: indice += 4
				if _letra(mapa, vx, vy) in letras: indice += 8
				if indice > 0:
					camada.set_cell(Vector2i(vx, vy), 0, Vector2i(indice, linha_folha))
		_camada_terreno(origem, i, camada)

	# 3) enfeites (tufos, flores, pedras de pisar)
	var enfeites := TileMapLayer.new()
	enfeites.tile_set = ts
	enfeites.position = origem
	enfeites.z_index = -5
	add_child(enfeites)
	for y in altura:
		for x in mapa[y].length():
			match mapa[y][x]:
				";":
					enfeites.set_cell(Vector2i(x, y), 0, Vector2i(0, 4))
				"*":
					enfeites.set_cell(Vector2i(x, y), 0, Vector2i(1 + (x + y) % 2, 4))
				"o":
					enfeites.set_cell(Vector2i(x, y), 0, Vector2i(3, 4))

	# 4) a casa é um desenho inteiro (arte/casa.png); no mapa ela só ocupa espaço (colisão)
	var casa_ini := Vector2i(9999, 9999)
	var casa_fim := Vector2i(-1, -1)
	for y in altura:
		for x in mapa[y].length():
			if mapa[y][x] in CASA_CHARS:
				casa_ini = Vector2i(mini(casa_ini.x, x), mini(casa_ini.y, y))
				casa_fim = Vector2i(maxi(casa_fim.x, x), maxi(casa_fim.y, y))
	if casa_fim.x >= 0:
		var casa := Sprite2D.new()
		casa.texture = preload("res://arte/casa.png")
		var base_casa := origem + Vector2((casa_ini.x + casa_fim.x + 1) * TILE / 2.0, (casa_fim.y + 1) * TILE)
		casa.offset = Vector2(0, -casa.texture.get_height() / 2.0)
		casa.position = base_casa
		mundo.add_child(casa)
		_fumaca(origem + Vector2(casa_ini.x * TILE + 211, casa_ini.y * TILE + 34))

	# 5) por cima: muro, barranco e escada (com colisão); água e casa bloqueiam passagem
	for y in altura:
		for x in mapa[y].length():
			var c := mapa[y][x]
			if c in CASA_CHARS:
				if c != "P":
					topo.set_cell(Vector2i(x, y), 0, Vector2i(INVISIVEL, 0))
			elif c in SOBRE_TERRENO:
				topo.set_cell(Vector2i(x, y), 0, Vector2i(_tile_para(mapa, x, y), 0))
			elif c in agua_chars:
				topo.set_cell(Vector2i(x, y), 0, Vector2i(INVISIVEL, 0))
			elif c == "a":
				_criar_cenario_quadros(tex_moita, 2, 1 if (x * 3 + y) % 4 == 0 else 0, Vector2(14, 8), origem + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE))
			elif c == "e":
				_criar_cenario("res://arte/estaca.png", Vector2(10, 6), origem + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE + 2))


## Cada camada de terreno pronta passa por aqui (a fase de Nanã guarda a da maré).
func _letra_em(pos: Vector2) -> String:
	var origem: Vector2 = lugares[lugar_atual]["origem"]
	var rel := pos - origem
	return _letra(_mapas[lugar_atual], floori(rel.x / TILE), floori(rel.y / TILE))


## Som que toca perto de Adé (mais baixo quanto mais longe; longe da tela, não toca).
func som_perto(nome: String, pos: Vector2, volume_db := 0.0) -> void:
	var d := pos.distance_to(jogador.global_position)
	if d < 160.0:
		Jogo.tocar_som(nome, volume_db - d / 20.0)


## O passo de Adé muda com o chão: [som, volume]. Vazio = sem som.
func som_do_chao(pos: Vector2) -> Array:
	if not lugares.has(lugar_atual) or not _mapas.has(lugar_atual):
		return []
	if lugares[lugar_atual]["dentro"]:
		return ["passo_madeira", -16.0]
	var l := _letra_em(pos)
	if l in agua_chars:
		return []
	if l in ["t", "r", "_", "="]:
		return ["passo_terra", -15.0]
	return ["passo_grama", -14.0]


func _camada_terreno(_origem: Vector2, _i: int, _camada: TileMapLayer) -> void:
	pass


func _criar_cenario_quadros(caminho: String, quadros: int, quadro: int, pe: Vector2, base: Vector2) -> void:
	var s := _criar_cenario(caminho, pe, base)
	s.hframes = quadros
	s.frame = quadro


# ------------------------------------------------------------------ o quarto de santo e a volta de Adé

func _criar_assentamentos(base: Vector2) -> void:
	for i in ASSENTAMENTOS.size():
		var id: String = ASSENTAMENTOS[i]
		var pos := base + Vector2(8 + (i - 4) * 24, 6)
		var a := _criar_interativo("res://arte/assentamentos.png", 2, pos, Vector2(20, 8), -36.0)
		a.sprite.vframes = ASSENTAMENTOS.size()
		a.sprite.frame = i * 2
		a.sprite.offset = Vector2(0, -15)
		a.interagiu.connect(_olhar_assentamento.bind(id))
		_assentamentos[id] = a


## Acende os assentamentos que já receberam troféu (ao abrir a cena).
func _mostrar_assentamentos() -> void:
	for id in Jogo.assentados:
		_acender_assentamento(id, false)


func _acender_assentamento(id: String, com_festa: bool) -> void:
	var a: Area2D = _assentamentos[id]
	a.sprite.frame = ASSENTAMENTOS.find(id) * 2 + 1
	var trofeu := Sprite2D.new()
	trofeu.name = "Trofeu"
	if ICONE_TROFEU.has(id):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(ICONE_TROFEU[id][0])
		atlas.region = Rect2(int(ICONE_TROFEU[id][1]) * 12, 0, 12, 12)
		trofeu.texture = atlas
	else:
		trofeu.texture = preload("res://arte/buzio_axe.png")
	trofeu.position = Vector2(2, -15)
	a.add_child(trofeu)
	var cor: Color = COR_ASSENTAMENTO[id]
	_luz(a.position + Vector2(6, -18), Color(1.0, 0.8, 0.5), 1.4, 0.9, true)
	var aura := _luz(a.position + Vector2(0, -10), cor, 0.0, 1.3, false)
	if com_festa:
		trofeu.position.y = -40
		trofeu.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(trofeu, "position:y", -15.0, 0.6).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(trofeu, "modulate:a", 1.0, 0.4)
		t.tween_property(aura, "energy", 1.6 * FORCA_LUZES, 0.8)
		Jogo.tocar_som("buzio", -2.0)
	else:
		aura.energy = 1.6 * FORCA_LUZES


func _olhar_assentamento(id: String) -> void:
	await _falar_linhas(_com_nomes(_dados["assentamento_cheio" if Jogo.assentados.has(id) else "assentamento_vazio"], id))


## Troca {nome}, {saudacao} e {trofeu} nas falas pelo orixá certo.
func _com_nomes(linhas: Array, id: String) -> Array:
	var c: Dictionary = _campos[id]
	var novas := linhas.duplicate(true)
	for l in novas:
		for campo in ["pt", "yo"]:
			l[campo] = l[campo].replace("{nome}", c["nome"]).replace("{saudacao}", c["saudacao"]) \
				.replace("{trofeu}", Jogo.trofeus.get(id, ""))
	return novas


## Adé volta de um campo: a porteira está aberta e a Vó o espera na tronqueira.
func _preparar_retorno() -> void:
	_escolher_tempo(Jogo.has_meta("na_quartinha"))
	estado = "aberto"
	for id in ITENS:
		coletados[id] = true
	_esconder_inventario()      # as oferendas já foram arriadas na tronqueira
	tia = "deu_efum"
	_abrir_porteira()
	if _tempo_de_ficar_dentro():
		# na chuva e à noite a Vó espera Adé dentro do barracão, perto do congá
		vo.global_position = _ponto_da_rota(["barracao", 11, 6])
	else:
		vo.global_position = marcas["v"]
	vo.modulate.a = 1.0
	tronqueira.ativo = false
	_lista.visible = true
	jogador.congelar(true)
	var continuando := Jogo.has_meta("na_quartinha")
	if continuando:
		# continuando um jogo guardado: Adé aparece ao lado da quartinha de Exu
		Jogo.remove_meta("na_quartinha")
		teleportar("quintal", _lugar_livre_perto("quintal", _quartinha.global_position))
		jogador.direcao_olhar = "frente"
	else:
		teleportar("quintal", porteira.global_position + Vector2(0, -22))
		jogador.direcao_olhar = "costas"
	await get_tree().create_timer(0.6).timeout
	$HUD.mostrar_titulo("Ilé", "O terreiro da Vó" if continuando else "De volta ao terreiro da Vó")
	await get_tree().create_timer(1.4).timeout
	if continuando:
		jogador.congelar(false)
	elif not _trofeus_novos().is_empty():
		# a fala da chegada depende do que Adé traz: troféu novo, nada ainda, ou só uma visita
		await _falar("retorno_chegada_dentro" if _tempo_de_ficar_dentro() else "retorno_chegada")
	elif _quer_alfazema():
		await _falar("retorno_alfazema")
	elif Jogo.assentados.is_empty():
		await _falar("retorno_sem_trofeu")
	else:
		await _falar("retorno_visita")


func _trofeus_novos() -> Array:
	var novos := []
	for id in ASSENTAMENTOS:
		if Jogo.trofeus.has(id) and not Jogo.assentados.has(id):
			novos.append(id)
	return novos


func _vo_no_retorno() -> void:
	var novos := _trofeus_novos()
	if novos.is_empty() and _quer_alfazema():
		await _vo_e_a_alfazema()
		return
	if novos.is_empty():
		await _falar("vo_quarto" if lugar_atual == "quarto" else "vo_sem_trofeu")
		return
	await _falar("retorno_vo")
	for id in novos:
		if _dados.has("conta_" + id):
			await _falar("conta_" + id)
	await _falar("vo_leva_ao_quarto")
	# a Vó leva Adé até o quarto de santo
	jogador.congelar(true)
	vo.ativo = false
	var t := create_tween()
	t.tween_property(_cortina, "color:a", 1.0, 0.5)
	await t.finished
	# os dois entram e ficam no meio do quarto, de frente para os assentamentos
	var meio: Vector2 = lugares["quarto"]["origem"] + Vector2(8 * TILE, 6 * TILE)
	teleportar("quarto", meio + Vector2(12, 0))
	jogador.direcao_olhar = "costas"
	vo.global_position = meio + Vector2(-14, 0)
	await get_tree().create_timer(0.3).timeout
	var t2 := create_tween()
	t2.tween_property(_cortina, "color:a", 0.0, 0.5)
	await t2.finished
	for id in novos:
		await _vo_assenta(id)
	await _falar("vo_bencao")
	vo.ativo = true
	vo.animar = true
	vo.olhar_para_jogador = true
	jogador.congelar(false)
	_mostrar_aviso("Quando quiser, saia pela porteira: Exu leva você ao Ọ̀run.")


func _celula_da_porta(numero: String, lugar: String) -> Vector2i:
	for p in portas[numero]:
		if p[0] == lugar:
			return p[1]
	return Vector2i.ZERO


## A Vó anda até o assentamento, coloca o troféu e saúda o orixá.
func _vo_assenta(id: String) -> void:
	var a: Area2D = _assentamentos[id]
	var alvo := a.global_position + Vector2(0, 20)
	vo.animar = false
	vo.olhar_para_jogador = false
	var passos := create_tween().set_loops()
	passos.tween_callback(func(): vo.sprite.frame = 3).set_delay(0.18)
	passos.tween_callback(func(): vo.sprite.frame = 4).set_delay(0.18)
	vo.sprite.flip_h = alvo.x < vo.global_position.x
	var forma: CollisionShape2D = vo.get_node("Corpo/Forma")
	forma.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(vo, "global_position", alvo, vo.global_position.distance_to(alvo) / 38.0)
	await t.finished
	passos.kill()
	forma.set_deferred("disabled", false)
	vo.sprite.frame = 0
	jogador.olhar_para(a.global_position)
	await get_tree().create_timer(0.3).timeout
	Jogo.assentados[id] = true
	_acender_assentamento(id, true)
	await get_tree().create_timer(0.9).timeout
	vo.sprite.frame = 2                      # a saudação
	await _falar_linhas(_com_nomes(_dados["vo_assenta"], id))
	if _dados.has("assenta_" + id):
		await _falar("assenta_" + id)
	jogador.congelar(true)
	# a Vó dá uns passos para trás, para Adé ver o assentamento aceso
	var volta := jogador.global_position + Vector2(-26, 0)
	vo.sprite.flip_h = volta.x < vo.global_position.x
	var anda := create_tween().set_loops()
	anda.tween_callback(func(): vo.sprite.frame = 3).set_delay(0.18)
	anda.tween_callback(func(): vo.sprite.frame = 4).set_delay(0.18)
	forma.set_deferred("disabled", true)
	var t2 := create_tween()
	t2.tween_property(vo, "global_position", volta, vo.global_position.distance_to(volta) / 38.0)
	await t2.finished
	anda.kill()
	forma.set_deferred("disabled", false)
	vo.sprite.frame = 0
	vo.sprite.flip_h = false



# ------------------------------------------------------------------ a quartinha de Exu: onde se guarda o caminho (salvar)
# Adé bate palmas três vezes, a vela vermelha e preta acende, Exu surge na fumaça e pergunta se Adé quer
# que ele guarde o seu caminho. As falas ficam em dialogos/quartinha.json; os jogos salvos, no Jogo.

func _criar_quartinha(base: Vector2) -> void:
	_quartinha = _criar_interativo("res://arte/quartinha_exu.png", 3, base, Vector2(14, 6), -32.0)
	_quartinha.olhar_para_jogador = false
	_quartinha.interagiu.connect(_na_quartinha)


## Onde o jogo continua se for guardado aqui (veja Jogo.LOCAIS). As outras cenas trocam isto.
func _local_do_caminho() -> String:
	return "terreiro"


## Exu só guarda o caminho depois que ele já chegou (no terreiro: depois da volta de Adé).
func _pode_guardar() -> bool:
	return _retorno


func _fala_quartinha(chave: String) -> void:
	if _falas_quartinha.is_empty():
		_falas_quartinha = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/quartinha.json"))
	await _falar_linhas(_falas_quartinha[chave].duplicate(true))


func _na_quartinha() -> void:
	if not _pode_guardar():
		await _fala_quartinha("cedo")
		return
	jogador.congelar(true)
	_quartinha.ativo = false
	await _bater_palmas()
	# a vela acende
	var vela := _quartinha.create_tween().set_loops()
	vela.tween_callback(func(): _quartinha.sprite.frame = 1).set_delay(0.15)
	vela.tween_callback(func(): _quartinha.sprite.frame = 2).set_delay(0.15)
	var luz := _luz(_quartinha.global_position + Vector2(5, -18), Color(1.0, 0.5, 0.35), 2.0, 1.0, true)
	Jogo.tocar_som("buzio", -4.0)
	await get_tree().create_timer(0.6).timeout
	# Exu surge na fumaça (se ele já estiver por perto, é ele mesmo quem vem)
	var e: Sprite2D = exu if exu and is_instance_valid(exu) and exu.visible \
		and exu.global_position.distance_to(_quartinha.global_position) < 160.0 else null
	var veio := false
	if e == null:
		var lado := 20.0 if jogador.global_position.x <= _quartinha.global_position.x else -20.0
		e = _exu_surge(_quartinha.global_position + Vector2(lado, 4))
		veio = true
		await get_tree().create_timer(1.1).timeout
	jogador.olhar_para(e.global_position)
	await _fala_quartinha("pergunta")
	jogador.congelar(true)
	var espaco: int = await Jogo.menu.escolher_caminho("Exu guarda o seu caminho", false)
	if espaco >= 0:
		Jogo.salvar(espaco, _local_do_caminho())
		_axe_cheio()
		Jogo.tocar_som("caminho", -6.0)
		var guardado := Jogo.resumo(espaco)
		await Jogo.menu.escolher("Caminho %d guardado" % (espaco + 1), ["Ok"], 0, false, [], "Tempo de jogo: %s  ·  Mortes: %d" % [guardado["tempo"], guardado["mortes"]])
		await _fala_quartinha("guardou")
	else:
		await _fala_quartinha("nao")
	jogador.congelar(true)
	if veio:
		_fumaca_vermelha(e.global_position + Vector2(0, -12))
		var t := create_tween()
		t.tween_property(e, "modulate:a", 0.0, 0.7)
		t.tween_callback(e.queue_free)
		await t.finished
	vela.kill()
	_quartinha.sprite.frame = 0
	_chamas = _chamas.filter(func(c): return c[0] != luz)
	luz.queue_free()
	_quartinha.ativo = true
	jogador.congelar(false)


## Enche o axé de novo (nas cenas que têm axé).
func _axe_cheio() -> void:
	if "axe" in self:
		set("axe", AXE_MAX)
		for b in _axe_icones:
			b.modulate = Color.WHITE


## Adé bate palmas três vezes, de frente (arte/ade_palmas.png: mãos abertas, mãos juntas).
func _bater_palmas() -> void:
	var sp: Sprite2D = jogador.sprite
	var tex := sp.texture
	var quadros := sp.hframes
	jogador.animacao_especial = true
	sp.flip_h = false
	sp.texture = preload("res://arte/ade_palmas.png")
	sp.hframes = 2
	for i in 3:
		sp.frame = 0
		await get_tree().create_timer(0.2).timeout
		sp.frame = 1
		Jogo.tocar_som("pulo", -6.0)
		_estrelinhas(jogador.global_position + Vector2(0, -16))
		await get_tree().create_timer(0.22).timeout
	sp.frame = 0
	await get_tree().create_timer(0.2).timeout
	sp.texture = tex
	sp.hframes = quadros
	sp.frame = 0
	jogador.direcao_olhar = "frente"
	jogador.animacao_especial = false


func _estrelinhas(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 12
	f.amount = 6
	f.lifetime = 0.35
	f.one_shot = true
	f.explosiveness = 1.0
	f.spread = 180.0
	f.gravity = Vector2.ZERO
	f.initial_velocity_min = 18.0
	f.initial_velocity_max = 30.0
	f.color = Color(1, 1, 0.85)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(0.8).timeout.connect(f.queue_free)


## Um ponto livre (chão andável, sem muro nem objeto) ao lado de "pos", para Adé aparecer sem ficar preso.
func _lugar_livre_perto(lugar: String, pos: Vector2) -> Vector2:
	var origem: Vector2 = lugares[lugar]["origem"]
	var espaco := get_world_2d().direct_space_state
	for d in [Vector2(0, -18), Vector2(18, 0), Vector2(-18, 0), Vector2(0, 18), Vector2(18, -18), Vector2(-18, -18),
			Vector2(0, -34), Vector2(34, 0), Vector2(-34, 0)]:
		var p: Vector2 = pos + d
		var rel := p - origem
		if not (_letra(_mapas[lugar], floori(rel.x / TILE), floori((rel.y - 1) / TILE)) in ANDAVEL):
			continue
		var livre := true
		for canto in [Vector2(-6, -1), Vector2(6, -1), Vector2(-6, -7), Vector2(6, -7)]:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = p + canto
			q.collision_mask = 1
			if not espaco.intersect_point(q, 1).is_empty():
				livre = false
				break
		if livre:
			return p
	return pos + Vector2(0, -18)


# ------------------------------------------------------------------ adereços do quarto de santo

var _velas_brancas: Array = []


## Letras próprias do quarto: u fotos da família na parede, j guias penduradas na parede, t trio de quartinhas, d defumador (com fumaça),
## y vaso de flores brancas, ! velas brancas acesas no chão.
func _adereco_do_quarto(c: String, base: Vector2) -> bool:
	match c:
		"j":
			var g := Sprite2D.new()
			g.texture = preload("res://arte/obj_guias.png")
			g.position = base + Vector2(0, -10)
			g.offset = Vector2(0, -g.texture.get_height() / 2.0)
			mundo.add_child(g)
		"t":
			_criar_cenario("res://arte/obj_quartinhas.png", Vector2(26, 6), base)
		"d":
			_criar_cenario("res://arte/obj_defumador.png", Vector2(10, 6), base)
			_fumaca_fina(base + Vector2(0, -12))
			_luz(base + Vector2(0, -8), Color(1.0, 0.55, 0.3), 0.6, 0.5, true)
		"y":
			_criar_cenario("res://arte/obj_flores_brancas.png", Vector2(10, 6), base)
		"u":
			# as fotos antigas da família na parede: o bisavô, a bisavó, a Vó (no meio), o avô e a Vó moça com a
			# mãe de Adé no colo. "u" marca só a parede; as posições ficam aqui (arte/obj_fotos.png).
			var origem: Vector2 = lugares["quarto"]["origem"]
			for f in [[56, 3, 0], [112, 2, 1], [128, 0, -1], [144, 1, 1], [202, 4, 0]]:
				var foto := Sprite2D.new()
				foto.texture = preload("res://arte/obj_fotos.png")
				foto.hframes = 5
				foto.frame = f[1]
				foto.position = origem + Vector2(f[0], 13 + f[2])
				foto.z_index = -2
				add_child(foto)
		"!":
			var v := _criar_cenario("res://arte/obj_velas_brancas.png", Vector2.ZERO, base)
			v.hframes = 2
			v.offset = Vector2(0, -7)
			_velas_brancas.append(v)
			_luz(base + Vector2(0, -10), Color(1.0, 0.85, 0.6), 1.2, 0.9, true)
		_:
			return false
	return true


func _fumaca_fina(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 18
	f.amount = 10
	f.lifetime = 2.4
	f.preprocess = 2.4
	f.direction = Vector2(0.1, -1)
	f.spread = 10.0
	f.gravity = Vector2(3, -5)
	f.initial_velocity_min = 4.0
	f.initial_velocity_max = 8.0
	f.scale_amount_min = 1.0
	f.scale_amount_max = 2.5
	var cores := Gradient.new()
	cores.set_color(0, Color(0.92, 0.9, 0.95, 0.55))
	cores.set_color(1, Color(0.8, 0.78, 0.85, 0.0))
	f.color_ramp = cores
	add_child(f)



## Depois do ritual o inventário das oferendas fica vazio: as caixinhas somem e os búzios vão para o canto.
func _esconder_inventario() -> void:
	for n in _hud_oferendas:
		n.visible = false
	_icone_buzio.position.x = 8
	_contador_buzios.position.x = 21



# ------------------------------------------------------------------ a vida no terreiro: rotinas da Vó, do Ogã Bené e da Lia
# Cada pessoa anda entre alguns pontos, para um pouco em cada um e às vezes faz alguma coisa:
#   "saudar" (braços erguidos, quadro 2), "varrer" (Vó e Lia, quadros 5-6), "tocar" (Ogã com o atabaque na
#   frente, quadros 5-6), "afinar" (Ogã batendo o malho nas cunhas do atabaque, quadros 7-8) ou
#   "cozinhar" / "colher" (Tia Dora com a colher de pau: no fogão, no pilão e, na volta de Adé, na horta).
# Os quadros 3 e 4 são os passos. Quando Adé chega perto, a pessoa para e olha para ele; quando o jogo
# está numa cena (diálogo, ritual, mini-jogo), todo mundo espera.
# Antes do ritual cada um fica perto do seu lugar no barracão (para Adé achar); na volta de Adé, eles saem:
# o Ogã vai para perto da roda de capoeira, a Lia varre o quintal e a Vó, depois de assentar os troféus,
# cuida do quarto de santo (ou, se não há troféu novo, fica pela tronqueira e pela gameleira).

const VEL_PESSOA := 22.0
var _oga: Area2D
var _lia: Area2D
var _tia: Area2D
var _objetos := {}            # "lugar:letra" → sprite do objeto (ex.: "cozinha:F" é o fogão)
var _vapor: CPUParticles2D
var _rotinas := {}            # pessoa → {rota: [[lugar, celula, espera, acao]], i, espera, andando, nome}

## [lugar, coluna, linha, segundos parado, o que faz]
const ROTAS := {
	"vo_barracao": [["barracao", 14, 5, 3.0, ""], ["barracao", 9.5, 4, 4.0, "saudar_costas"], ["barracao", 9, 7, 2.0, ""],
		["barracao", 15, 7, 2.5, "varrer"]],
	# o Ogã afina ao lado do atabaque grande e toca atrás do atabaque pequeno (só o tronco aparece)
	"oga_barracao": [["barracao", 17, 6, 3.0, ""], ["barracao", 16.875, 4, 4.0, "afinar_grande"],
		["barracao", 20.125, 3.75, 6.0, "tocar_grande"], ["barracao", 22, 6, 0.0, ""], ["barracao", 21, 7, 2.5, ""]],
	"tia_cozinha": [["cozinha", 10.2, 2.6, 6.0, "cozinhar"], ["cozinha", 3, 3, 3.0, ""], ["cozinha", 4, 6, 1.5, ""],
		["cozinha", 11, 6.4, 4.0, "pilao"], ["cozinha", 8, 6, 2.0, ""]],
	# na volta de Adé, a Tia colhe na horta, leva para a cozinha, cozinha no fogão e no pilão e volta para a horta
	# (os pontos com 0 segundos são só o caminho, para contornar a cerca e a casa)
	"tia_quintal": [["quintal", 34, 16, 4.0, "colher"], ["quintal", 36, 16, 4.0, "colher"],
		["quintal", 31, 17, 0.0, ""], ["quintal", 31, 11, 0.0, ""], ["quintal", 29, 11, 0.0, ""],
		["quintal", 29, 12, 0.0, ""], ["quintal", 25, 12, 0.0, ""],
		["cozinha", 10.2, 2.6, 6.0, "cozinhar"], ["cozinha", 3, 3, 2.5, ""], ["cozinha", 11, 6.4, 4.0, "pilao"],
		["cozinha", 10.2, 2.6, 5.0, "cozinhar"],
		["quintal", 25, 12, 0.0, ""], ["quintal", 29, 12, 0.0, ""], ["quintal", 29, 11, 0.0, ""],
		["quintal", 31, 11, 0.0, ""], ["quintal", 31, 17, 0.0, ""]],
	"lia_barracao": [["barracao", 6, 4, 3.0, "varrer"], ["barracao", 12.5, 4, 3.0, "acender"], ["barracao", 5, 7, 3.0, "varrer"]],
	"vo_quintal": [["quintal", 14, 31, 4.0, ""], ["quintal", 10, 30, 4.0, "varrer"], ["quintal", 12, 32, 3.0, ""]],
	"vo_quarto": [["quarto", 8, 6, 3.0, ""], ["quarto", 4, 3, 3.0, "saudar_costas"], ["quarto", 11, 3, 3.0, "saudar_costas"],
		["quarto", 8, 7, 3.0, "varrer"]],
	"oga_quintal": [["quintal", 29, 11, 3.0, ""], ["quintal", 37, 11, 3.0, "afinar"], ["quintal", 37, 11, 5.0, "tocar"],
		["quintal", 33, 11, 3.0, ""]],
	"lia_quintal": [["quintal", 3, 18, 4.0, "varrer"], ["quintal", 15, 18, 4.0, "varrer"], ["quintal", 8, 18, 2.5, ""]],
}


func _montar_rotinas() -> void:
	if _retorno and _tempo_de_ficar_dentro():
		# na chuva e à noite todo mundo fica dentro de casa
		_rotina(_oga, "oga_barracao", true)
		_rotina(_lia, "lia_barracao", true)
		_rotina(_tia, "tia_cozinha", true)
	elif _retorno:
		_rotina(_oga, "oga_quintal", true)
		_rotina(_lia, "lia_quintal", true)
		_rotina(_tia, "tia_quintal", true)
	else:
		_rotina(_tia, "tia_cozinha", false)
		_rotina(_oga, "oga_barracao", false)
		_rotina(_lia, "lia_barracao", false)
	_rotina(vo, "", false)          # a da Vó muda conforme a história (veja _rota_da_vo)


func _rotina(p: Area2D, nome: String, comecar_la: bool) -> void:
	if p == null:
		return
	# começa andando até o primeiro ponto (a não ser que já apareça lá)
	_rotinas[p] = {"nome": nome, "i": 0, "espera": randf_range(0.5, 2.0), "andando": not comecar_la}
	if comecar_la and nome != "":
		p.global_position = _ponto_da_rota(ROTAS[nome][0])


func _ponto_da_rota(ponto: Array) -> Vector2:
	return lugares[ponto[0]]["origem"] + Vector2(ponto[1] * TILE + TILE / 2.0, (ponto[2] + 1) * TILE - 2)


## Qual rotina a Vó segue agora (ou nenhuma, quando a história precisa dela num lugar).
func _rota_da_vo() -> String:
	if not vo or not vo.ativo:
		return ""
	if not _retorno:
		return "vo_barracao" if estado in ["acordou", "buscando"] else ""
	if not _trofeus_novos().is_empty():
		return ""                   # esperando Adé na tronqueira com o troféu
	var q: Vector2 = lugares["quarto"]["origem"]
	var no_quarto := vo.global_position.x >= q.x and vo.global_position.y >= q.y
	if no_quarto:
		return "vo_quarto"
	return "vo_barracao" if _tempo_de_ficar_dentro() else "vo_quintal"


func _mover_rotinas(delta: float) -> void:
	if _rotinas.is_empty() or not jogador:
		return
	var em_cena: bool = not jogador.pode_mover or $Dialogo.ativo
	_atualizar_vapor()
	for p in _rotinas:
		var r: Dictionary = _rotinas[p]
		if p == vo:
			var nome := _rota_da_vo()
			if nome != r["nome"]:
				r["nome"] = nome
				r["i"] = 0
				r["espera"] = 0.5
				r["andando"] = true
				if nome == "":
					continue
		if r["nome"] == "":
			continue
		var rota: Array = ROTAS[r["nome"]]
		var sp: Sprite2D = p.sprite
		var perto: bool = p.global_position.distance_to(jogador.global_position) < 30.0
		if em_cena or perto:
			# para, olha para Adé e respira
			p.animar = true
			p.olhar_para_jogador = true
			continue
		var ponto: Array = rota[r["i"]]
		var alvo := _ponto_da_rota(ponto)
		if r.get("trocando", false):
			continue
		if r["andando"] and _lugar_de(p.global_position) != ponto[0]:
			# o ponto fica em outro cômodo: anda até a porta, some por ela e aparece do outro lado
			var porta := _porta_entre(_lugar_de(p.global_position), ponto[0])
			if porta.is_empty():
				p.global_position = alvo
			else:
				alvo = lugares[porta[0]]["origem"] + Vector2(porta[1].x * TILE + TILE / 2.0, (porta[1].y + 1) * TILE - 2)
				if p.global_position.distance_to(alvo) < 1.0:
					_atravessar_porta(p, r, ponto[0], porta[2])
					continue
		if r["andando"]:
			var falta: Vector2 = alvo - p.global_position
			if falta.length() < 1.0:
				r["andando"] = false
				r["espera"] = float(ponto[3])
				continue
			p.animar = false
			p.olhar_para_jogador = false
			var passo: Vector2 = falta.limit_length(VEL_PESSOA * delta)
			p.global_position += passo
			if absf(passo.x) > 0.05:
				sp.flip_h = passo.x < 0.0
			sp.frame = 3 + int(_tempo * 6.0) % 2
		else:
			r["espera"] -= delta
			var antes := sp.frame
			var acao := str(ponto[4])
			match acao:
				"saudar":
					p.animar = false
					sp.frame = 2
				"saudar_costas":                                   # de costas, diante do congá ou do assentamento
					p.animar = false
					sp.flip_h = false
					sp.frame = 7 + int(_tempo * 1.5) % 2
				"acender":                                         # a Lia acende a vela do congá
					p.animar = false
					sp.flip_h = false
					sp.frame = 7 if r["espera"] > float(ponto[3]) - 1.0 else 8
				"cozinhar":                                        # de costas, mexendo a panela no fogão
					p.animar = false
					sp.flip_h = false
					sp.frame = (7 if _lugar_de(p.global_position) == "cozinha" else 5) + int(_tempo * 3.0) % 2
				"pilao":
					p.animar = false
					sp.flip_h = false
					sp.frame = 9 + int(_tempo * 2.5) % 2
				"colher":                                          # agachada na beira do canteiro
					p.animar = false
					sp.flip_h = false
					sp.frame = 11 + int(_tempo * 0.8) % 2
				"tocar_grande":
					p.animar = false
					sp.flip_h = false
					sp.frame = 9 + int(_tempo * 6.0) % 2
				"afinar_grande":
					p.animar = false
					sp.flip_h = false
					sp.frame = 11 + int(_tempo * 4.0) % 2
				"varrer":
					p.animar = false
					sp.frame = 5 + int(_tempo * 3.0) % 2
				"tocar":
					p.animar = false
					sp.frame = 5 + int(_tempo * 6.0) % 2      # as mãos batendo no couro, uma de cada vez
				"afinar":
					p.animar = false
					sp.frame = 7 + int(_tempo * 4.0) % 2      # o malho batendo nas cunhas do atabaque
				_:
					p.animar = true
			if sp.frame != antes:
				_efeito_no_objeto(p, acao, sp.frame)
			if r["espera"] <= 0.0:
				r["i"] = (r["i"] + 1) % rota.size()
				r["andando"] = true



## Em qual lugar (cômodo ou quintal) fica um ponto do mundo.
func _lugar_de(pos: Vector2) -> String:
	for nome in lugares:
		var o: Vector2 = lugares[nome]["origem"]
		if Rect2(o, tamanhos[nome]).has_point(pos):
			return nome
	return ""


## A porta que liga dois lugares: [lugar de saída, célula de saída, célula de chegada no outro lugar].
func _porta_entre(de: String, para: String) -> Array:
	for numero in portas:
		var lado_de = null
		var lado_para = null
		for pt in portas[numero]:
			if pt[0] == de and lado_de == null:
				lado_de = pt[1]
			elif pt[0] == para and lado_para == null:
				lado_para = pt[1]
		if lado_de != null and lado_para != null:
			return [de, lado_de, lado_para]
	return []


func _atravessar_porta(p: Area2D, r: Dictionary, destino: String, celula: Vector2i) -> void:
	r["trocando"] = true
	var t := create_tween()
	t.tween_property(p, "modulate:a", 0.0, 0.25)
	await t.finished
	p.global_position = _chegada(destino, celula)
	await get_tree().create_timer(0.4).timeout
	var t2 := create_tween()
	t2.tween_property(p, "modulate:a", 1.0, 0.25)
	await t2.finished
	r["trocando"] = false



# ------------------------------------------------------------------ os objetos respondem ao que as pessoas fazem

func _objeto(chave: String) -> Sprite2D:
	return _objetos.get(chave) as Sprite2D


func _efeito_no_objeto(p: Area2D, acao: String, quadro: int) -> void:
	var lugar := _lugar_de(p.global_position)
	match acao:
		"tocar_grande":
			var a := _objeto("barracao:A")
			if a:      # o couro do atabaque vibra a cada batida
				var t := create_tween()
				t.tween_property(a, "scale", Vector2(1.02, 0.97), 0.04)
				t.tween_property(a, "scale", Vector2.ONE, 0.08)
				_pufe(p.global_position + Vector2(0, -22), [Color(1, 1, 0.9, 0.9), Color(1, 0.9, 0.6, 0.0)], 3, 18.0, Vector2(0, -20))
		"afinar_grande":
			if quadro == 12:
				_pufe(p.global_position + Vector2(8, -10), [Color(0.95, 0.85, 0.6, 0.9), Color(0.8, 0.6, 0.3, 0.0)], 4, 22.0, Vector2(0, 30))
		"pilao":
			var pl := _objeto("cozinha:i")
			if quadro == 10 and pl:   # a mão de pilão bate no fundo: o pilão balança e sobe um pozinho
				var t := create_tween()
				t.tween_property(pl, "scale", Vector2(1.06, 0.94), 0.05)
				t.tween_property(pl, "scale", Vector2.ONE, 0.1)
				_pufe(pl.global_position + Vector2(0, -20), [Color(0.95, 0.9, 0.75, 0.9), Color(0.9, 0.85, 0.7, 0.0)], 5, 14.0, Vector2(0, 10))
		"colher":
			var h := _objeto("quintal:H")
			if h:      # as folhas balançam; quando ela levanta, sai uma verdura
				var t := create_tween()
				t.tween_property(h, "position:x", h.position.x + 1.0, 0.06)
				t.tween_property(h, "position:x", h.position.x, 0.06)
				_pufe(p.global_position + Vector2(4, -10), [Color(0.4, 0.8, 0.3, 1.0), Color(0.3, 0.6, 0.2, 0.0)], 4 if quadro == 12 else 2, 16.0, Vector2(0, 30))
		"saudar_costas":
			_pufe(p.global_position + Vector2(0, -34), [Color(1, 0.9, 0.5, 0.8), Color(1, 0.8, 0.4, 0.0)], 2, 8.0, Vector2(0, -12))
		"acender":
			if quadro == 8:   # a vela do congá acende na mão da Lia
				_pufe(p.global_position + Vector2(4, -34), [Color(1, 0.9, 0.5, 1.0), Color(1, 0.5, 0.2, 0.0)], 6, 14.0, Vector2(0, -10))
				var l := _luz(p.global_position + Vector2(4, -34), Color(1.0, 0.75, 0.4), 0.0, 0.8, false)
				var t := create_tween()
				t.tween_property(l, "energy", 1.4 * FORCA_LUZES, 0.3)
				t.tween_interval(1.2)
				t.tween_property(l, "energy", 0.0, 0.6)
				t.tween_callback(l.queue_free)
		"varrer":
			if quadro == 6:   # a poeira da vassoura
				var lado := -6.0 if p.sprite.flip_h else 6.0
				_pufe(p.global_position + Vector2(lado, -2), [Color(0.85, 0.78, 0.65, 0.7), Color(0.8, 0.75, 0.6, 0.0)], 4, 12.0, Vector2(0, -6))
	if lugar == "":
		return


## O vapor sobe da panela enquanto a Tia Dora cozinha no fogão.
func _atualizar_vapor() -> void:
	var f := _objeto("cozinha:F")
	if f == null or _tia == null or not _rotinas.has(_tia):
		return
	if _vapor == null:
		_vapor = CPUParticles2D.new()
		_vapor.position = f.position + Vector2(3, -36)
		_vapor.z_index = 18
		_vapor.amount = 12
		_vapor.lifetime = 1.6
		_vapor.direction = Vector2(0, -1)
		_vapor.spread = 20.0
		_vapor.gravity = Vector2(0, -12)
		_vapor.initial_velocity_min = 6.0
		_vapor.initial_velocity_max = 12.0
		_vapor.scale_amount_min = 1.5
		_vapor.scale_amount_max = 3.0
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.75))
		g.set_color(1, Color(0.9, 0.9, 0.95, 0.0))
		_vapor.color_ramp = g
		_vapor.emitting = false
		add_child(_vapor)
	var r: Dictionary = _rotinas[_tia]
	var cozinhando := false
	if r["nome"] != "" and not r["andando"]:
		var ponto: Array = ROTAS[r["nome"]][r["i"]]
		cozinhando = ponto[4] == "cozinhar" and ponto[0] == "cozinha"
	_vapor.emitting = cozinhando


func _pufe(pos: Vector2, cores: Array, n: int, vel: float, gravidade: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 16
	f.amount = n
	f.lifetime = 0.7
	f.one_shot = true
	f.explosiveness = 0.9
	f.spread = 180.0
	f.direction = Vector2(0, -1)
	f.gravity = gravidade
	f.initial_velocity_min = vel * 0.5
	f.initial_velocity_max = vel
	f.scale_amount_min = 1.0
	f.scale_amount_max = 1.6
	var g := Gradient.new()
	g.set_color(0, cores[0])
	g.set_color(1, cores[1])
	f.color_ramp = g
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.2).timeout.connect(f.queue_free)



# ------------------------------------------------------------------ o tempo no terreiro (muda a cada volta de Adé)
# manhã de sol, fim de tarde, noite, nublado ou chuva. Na primeira volta com troféu é sempre fim de tarde
# (para a cena com a Vó); depois é sorteado, sem repetir o da vez anterior. Fica guardado no jogo salvo.
const TEMPOS := {
	# tempo: [cor lá fora, cor dentro de casa, força das luzes (lampiões, fogão, velas)]
	"manha": [Color(1.0, 1.0, 0.95), Color(0.97, 0.94, 0.9), 0.5],
	"tarde": [Color(1.0, 0.86, 0.72), Color(0.95, 0.86, 0.8), 1.0],
	"noite": [Color(0.12, 0.13, 0.28), Color(0.2, 0.18, 0.3), 2.0],
	"nublado": [Color(0.72, 0.74, 0.8), Color(0.84, 0.82, 0.84), 1.3],
	"chuva": [Color(0.52, 0.56, 0.68), Color(0.75, 0.72, 0.76), 1.7],
}
const NOMES_TEMPOS := {"manha": "Manhã de sol", "tarde": "Fim de tarde", "noite": "Noite",
	"nublado": "Dia nublado", "chuva": "Chuva"}
var _tempo_atual := ""
var _lampioes: Array = []          # [luz, sprite] de cada lampião
var _luzes_de_ambiente: Array = []  # a claridade geral de cada cômodo
var _camada_chuva: CanvasLayer
var _som_chuva: AudioStreamPlayer   # barulho da chuva caindo (em laço)
var _tween_chuva: Tween
var _clarao_raio: ColorRect
var _sombras_nuvens: Array = []
var _proximo_raio := 6.0


func _escolher_tempo(continuando: bool) -> void:
	var t := Jogo.tempo_terreiro
	if not continuando or t == "":
		if Jogo.assentados.is_empty() and not _trofeus_novos().is_empty():
			t = "tarde"                       # a primeira volta com troféu
		else:
			var opcoes := TEMPOS.keys().filter(func(k): return k != Jogo.tempo_terreiro)
			t = opcoes[randi() % opcoes.size()]
	Jogo.tempo_terreiro = t
	_aplicar_tempo(t)


func _aplicar_tempo(t: String) -> void:
	_tempo_atual = t
	var dados: Array = TEMPOS[t]
	cor_fora = dados[0]
	cor_dentro = dados[1]
	var forca: float = dados[2]
	# lá fora as luzes crescem bastante; dentro de casa só um pouco (senão a sala fica clara como de dia)
	var fatores := {}
	for filho in get_children():
		if filho is PointLight2D:
			var lugar := _lugar_de(filho.position)
			var f := forca
			if lugar != "" and lugares[lugar]["dentro"]:
				f = 1.0 + (forca - 1.0) * 0.15
			fatores[filho] = f
			filho.energy *= f
	for chama in _chamas:
		chama[1] *= fatores.get(chama[0], forca)
	if t == "noite" or t == "chuva":
		# as crianças e a roda de capoeira foram para casa
		for grupo in [_ciranda, _pega, _roda]:
			if grupo.is_empty():
				continue
			for chave in ["criancas", "jogadores", "membros"]:
				for f in grupo.get(chave, []):
					f.visible = false
			if grupo.has("ponto"):
				grupo["ponto"].ativo = false
				grupo["ponto"].get_node("Corpo/Forma").set_deferred("disabled", true)
		_ciranda = {}
		_pega = {}
		_roda = {}
	if t == "noite":
		_acender_lampioes()
		_criar_vagalumes("quintal")
		# uma luzinha fraca em volta de Adé, para ele não sumir no escuro
		var l := PointLight2D.new()
		l.texture = _luz_tex
		l.color = Color(0.75, 0.8, 1.0)
		l.energy = 0.45
		l.texture_scale = 0.6
		l.position = Vector2(0, -10)
		jogador.add_child(l)
	if t == "nublado" or t == "chuva":
		_criar_sombras_de_nuvem(0.14 if t == "nublado" else 0.2)
	if t == "chuva":
		_criar_chuva()
	if lugar_atual != "":
		_noite.color = cor_dentro if lugares[lugar_atual]["dentro"] else cor_fora


## Sombras grandes e suaves que passam devagar pelo quintal.
func _criar_sombras_de_nuvem(alfa: float) -> void:
	var origem: Vector2 = lugares["quintal"]["origem"]
	var tam: Vector2 = tamanhos["quintal"]
	for i in 4:
		var p := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := randf_range(70, 110)
		var ry := randf_range(30, 45)
		for k in 24:
			var a := k / 24.0 * TAU
			pts.append(Vector2(cos(a) * rx * (1.0 + 0.15 * sin(a * 3.0)), sin(a) * ry))
		p.polygon = pts
		p.color = Color(0.1, 0.1, 0.18, alfa)
		p.z_index = 25
		p.position = origem + Vector2(randf() * tam.x, randf() * tam.y)
		add_child(p)
		_sombras_nuvens.append([p, randf_range(6.0, 10.0)])


## A chuva cai na tela (só lá fora), com respingos no chão e um relâmpago de vez em quando.
func _criar_chuva() -> void:
	_camada_chuva = CanvasLayer.new()
	_camada_chuva.layer = 3
	add_child(_camada_chuva)
	var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		img.set_pixel(0, y, Color(0.75, 0.82, 1.0, 0.25 + y * 0.1))
	var gota := ImageTexture.create_from_image(img)
	var tela := Vector2(Jogo.TELA)
	var chuva := CPUParticles2D.new()
	chuva.texture = gota
	chuva.position = Vector2(tela.x / 2.0 + 30, -10)
	chuva.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	chuva.emission_rect_extents = Vector2(tela.x * 0.7, 4)
	chuva.amount = 140
	chuva.lifetime = 0.9
	chuva.preprocess = 1.0
	chuva.direction = Vector2(-0.25, 1)
	chuva.spread = 2.0
	chuva.gravity = Vector2(0, 0)
	chuva.initial_velocity_min = 240.0
	chuva.initial_velocity_max = 290.0
	chuva.particle_flag_align_y = true
	_camada_chuva.add_child(chuva)
	var respingo := CPUParticles2D.new()
	respingo.position = tela / 2.0
	respingo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	respingo.emission_rect_extents = tela / 2.0
	respingo.amount = 40
	respingo.lifetime = 0.25
	respingo.spread = 180.0
	respingo.gravity = Vector2.ZERO
	respingo.initial_velocity_min = 6.0
	respingo.initial_velocity_max = 12.0
	respingo.scale_amount_min = 1.0
	respingo.scale_amount_max = 1.0
	respingo.color = Color(0.8, 0.88, 1.0, 0.7)
	_camada_chuva.add_child(respingo)
	_clarao_raio = ColorRect.new()
	_clarao_raio.color = Color(0.9, 0.92, 1.0, 0.0)
	_clarao_raio.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clarao_raio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_chuva.add_child(_clarao_raio)
	set_process(true)
	# o barulho da chuva: em laço, mais alto lá fora e abafado dentro de casa
	var som: AudioStreamWAV = load("res://sons/chuva.wav").duplicate()
	som.loop_mode = AudioStreamWAV.LOOP_FORWARD
	som.loop_begin = 0
	som.loop_end = som.data.size() / 2
	_som_chuva = AudioStreamPlayer.new()
	_som_chuva.stream = som
	_som_chuva.bus = "Efeitos"
	_som_chuva.volume_db = -60.0
	add_child(_som_chuva)
	_som_chuva.play()
	if lugar_atual != "":
		_volume_chuva(_volume_do_lugar(lugar_atual), 1.0)


## Volume da chuva em cada lugar: lá fora mais alto, dentro de casa abafada.
func _volume_do_lugar(nome: String) -> float:
	return -30.0 if lugares[nome]["dentro"] else -22.0     # bem baixinho, de fundo


## Muda o volume do barulho da chuva aos poucos.
func _volume_chuva(db: float, tempo := 0.6) -> void:
	if not _som_chuva:
		return
	if _tween_chuva:
		_tween_chuva.kill()            # só vale a última mudança
	_tween_chuva = create_tween()
	_tween_chuva.tween_property(_som_chuva, "volume_db", db, tempo)


func _animar_tempo(delta: float) -> void:
	if _sombras_nuvens.size() > 0:
		var origem: Vector2 = lugares["quintal"]["origem"]
		var largura: float = tamanhos["quintal"].x
		for n in _sombras_nuvens:
			var p: Polygon2D = n[0]
			p.position.x += n[1] * delta
			if p.position.x > origem.x + largura + 120:
				p.position.x = origem.x - 120
	if _clarao_raio and _camada_chuva.visible:
		_proximo_raio -= delta
		if _proximo_raio <= 0.0:
			_proximo_raio = randf_range(7.0, 14.0)
			var t := create_tween()
			t.tween_property(_clarao_raio, "color:a", 0.55, 0.05)
			t.tween_property(_clarao_raio, "color:a", 0.0, 0.12)
			t.tween_property(_clarao_raio, "color:a", 0.35, 0.05)
			t.tween_property(_clarao_raio, "color:a", 0.0, 0.4)
			get_tree().create_timer(0.6).timeout.connect(func(): Jogo.tocar_som("trovao", -4.0))



## À noite, quem ilumina a casa são os lampiões: a claridade geral dos cômodos quase some, e cada lampião
## acende forte, com a chama brilhando (sem sombra) e uma roda de luz quente em volta.
func _acender_lampioes() -> void:
	for l in _luzes_de_ambiente:
		l.energy = 0.0
	for par in _lampioes:
		var l: PointLight2D = par[0]
		var sp: Sprite2D = par[1]
		var forte := 1.1 * FORCA_LUZES
		l.energy = forte
		l.texture_scale = 1.0
		l.position.y += 14          # a luz cai do lampião para o chão
		for c in _chamas:
			if c[0] == l:
				c[1] = forte
		var brilho := Sprite2D.new()   # a chama do lampião brilha mesmo no escuro
		brilho.texture = sp.texture
		brilho.offset = sp.offset
		brilho.position = sp.position
		brilho.material = _material_sem_sombra()
		brilho.modulate = Color(1, 0.9, 0.7, 0.55)
		brilho.z_index = sp.z_index
		sp.get_parent().add_child(brilho)



## Na chuva e à noite o pessoal fica dentro de casa (e a Vó espera Adé no barracão).
func _tempo_de_ficar_dentro() -> bool:
	return _tempo_atual == "chuva" or _tempo_atual == "noite"


# ------------------------------------------------------------------ a alfazema de Iemanjá

## Na volta da praia de Iemanjá (já com o remo da jangada), Adé vem buscar o perfume de alfazema.
func _quer_alfazema() -> bool:
	return _retorno and Jogo.has_meta("iemanja_remo") and not Jogo.has_meta("iemanja_alfazema")


func _vo_e_a_alfazema() -> void:
	match _manjar:
		"":
			await _falar("vo_alfazema")
		"vo_pediu", "tia_pediu":
			await _falar("vo_alfazema_esperando")
		"pronto":
			await _falar("vo_manjar_ver")
			_dica_bornal("Dar à Vó")
		_:
			await _falar("vo_alfazema_buscar")


func _tia_e_o_manjar() -> void:
	match _manjar:
		"vo_pediu":
			await _falar("tia_manjar")
		"tia_pediu":
			var faltam := []
			var com_ade := false
			for id in INGREDIENTES:
				if not _tem_ingrediente(id):
					faltam.append(_dados["nomes_manjar"][id])
				elif Jogo.bornal.tem(id):
					com_ade = true
			if com_ade:
				await _falar("tia_manjar_dar")
				_dica_bornal("Dar à Tia Dora")
			elif not faltam.is_empty():
				var linha: Dictionary = _dados["tia_manjar_falta"][0].duplicate()
				linha["pt"] = linha["pt"].replace("{faltam}", _juntar(faltam))
				await _falar_linhas([linha])
		_:
			await _falar("tia_manjar_depois")


## Adé mexe o manjar no fogão (o mini-jogo da panela); quando fica no ponto, o manjar aparece pronto.
func _cozinhar_manjar() -> void:
	jogador.congelar(true)
	_tia.ativo = false
	jogador.olhar_para(_tia.global_position)
	await _panela.jogar()
	await _mostrar_manjar()
	_tia.ativo = true


## O manjar pronto aparece grande no meio da tela, brilhando; depois fica nas mãos de Adé.
func _mostrar_manjar() -> void:
	await _mostrar_grande(preload("res://arte/manjar_grande.png"), 2.0, "Manjar branco!", "Branquinho como a espuma do mar.")
	# Adé segura o prato com o manjar
	_manjar_na_mao = Sprite2D.new()
	_manjar_na_mao.texture = preload("res://arte/manjar.png")
	_manjar_na_mao.position = Vector2(0, -9)
	_manjar_na_mao.z_index = 1
	jogador.add_child(_manjar_na_mao)
	Jogo.bornal.pegar("manjar")
	_mostrar_aviso("Você guardou no Àpò: Manjar branco")


## Uma coisa importante aparece grande no meio da tela, brilhando, com o nome embaixo
## (o manjar pronto, uma ferramenta nova, o troféu de um orixá).
func _mostrar_grande(tex: Texture2D, escala: float, titulo_txt: String, sub_txt: String, trofeu := false) -> void:
	await get_tree().process_frame
	while $Dialogo.ativo:              # espera a conversa acabar (o troféu chega no meio de uma fala)
		await $Dialogo.terminou
	await get_tree().create_timer(0.2).timeout
	var estava: bool = jogador.pode_mover
	jogador.congelar(true)
	var camada := CanvasLayer.new()
	camada.layer = 9
	add_child(camada)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.0)
	fundo.size = Vector2(Jogo.TELA)
	camada.add_child(fundo)
	var meio := Vector2(Jogo.TELA) / 2.0 + Vector2(0, -12)
	var raios := Sprite2D.new()            # o brilho girando atrás
	raios.texture = preload("res://arte/brilho.png")
	raios.position = meio
	raios.scale = Vector2.ZERO
	raios.modulate = Color(1.0, 0.95, 0.8, 0.85)
	camada.add_child(raios)
	var prato := Sprite2D.new()
	prato.texture = tex
	prato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prato.position = meio
	prato.scale = Vector2.ZERO
	camada.add_child(prato)
	if trofeu:
		raios.modulate = Color(1.0, 0.8, 0.35, 0.95)
	var titulo := _rotulo_manjar(titulo_txt, 12, Color(1.0, 0.86, 0.45), meio.y + 46)
	var sub := _rotulo_manjar(sub_txt, 8, Color(0.85, 0.9, 1.0), meio.y + 62)
	camada.add_child(titulo)
	camada.add_child(sub)
	titulo.modulate.a = 0.0
	sub.modulate.a = 0.0
	Jogo.tocar_som("buzio" if trofeu else "pegar_item", -2.0)
	var t := create_tween().set_parallel()
	t.tween_property(fundo, "color:a", 0.55, 0.3)
	t.tween_property(prato, "scale", Vector2(escala, escala), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(raios, "scale", Vector2(5, 5), 0.5)
	t.tween_property(titulo, "modulate:a", 1.0, 0.3).set_delay(0.3)
	t.tween_property(sub, "modulate:a", 1.0, 0.3).set_delay(0.5)
	var gira := create_tween().set_loops()
	gira.tween_property(raios, "rotation", TAU, 4.0).from(0.0)
	await get_tree().create_timer(3.2 if trofeu else 2.6).timeout
	var t2 := create_tween().set_parallel()
	t2.tween_property(fundo, "color:a", 0.0, 0.3)
	t2.tween_property(prato, "scale", Vector2.ZERO, 0.3)
	t2.tween_property(raios, "modulate:a", 0.0, 0.3)
	t2.tween_property(titulo, "modulate:a", 0.0, 0.2)
	t2.tween_property(sub, "modulate:a", 0.0, 0.2)
	await t2.finished
	gira.kill()
	camada.queue_free()
	if estava:
		jogador.congelar(false)


func _rotulo_manjar(texto: String, tamanho: int, cor: Color, y: float) -> Label:
	var l := Label.new()
	# frase comprida quebra em duas linhas (no espaço mais perto do meio), sem sair da tela
	if texto.length() > 40 and not "\n" in texto:
		var meio := texto.length() / 2
		var corte := -1
		for d in meio:
			if texto[meio - d] == " ":
				corte = meio - d
				break
			if meio + d < texto.length() and texto[meio + d] == " ":
				corte = meio + d
				break
		if corte > 0:
			texto = texto.substr(0, corte) + "\n" + texto.substr(corte + 1)
	l.text = texto
	l.position = Vector2(0, y)
	l.size = Vector2(Jogo.TELA.x, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	return l


## Adé entrega o manjar: o prato sai das mãos dele e fica entre os dois, na frente da Vó.
func _entregar_manjar() -> void:
	if _manjar_na_mao == null:
		return
	var pos := _manjar_na_mao.global_position
	jogador.remove_child(_manjar_na_mao)
	mundo.add_child(_manjar_na_mao)
	_manjar_na_mao.global_position = pos
	_manjar_na_mao.visible = true
	_manjar_na_mao.z_index = 0
	var alvo := vo.global_position.lerp(jogador.global_position, 0.4) + Vector2(0, -8)
	var t := create_tween()
	t.tween_property(_manjar_na_mao, "global_position", alvo, 0.4)
	await t.finished


func _sacudir_coqueiro(coq: Area2D) -> void:
	if _manjar != "tia_pediu" or _tem_ingrediente("coco"):
		return
	# o coqueiro balança e cai um coco
	var t := create_tween()
	for i in 3:
		t.tween_property(coq.sprite, "rotation", 0.06, 0.08)
		t.tween_property(coq.sprite, "rotation", -0.06, 0.08)
	t.tween_property(coq.sprite, "rotation", 0.0, 0.06)
	await t.finished
	await _falar("coco_pegar")


func _pegar_alfazema() -> void:
	if _manjar == "alfazema":
		await _falar("alfazema_pegar")


## Um ingrediente do manjar está com Adé (no bornal) ou já foi entregue à Tia Dora.
func _tem_ingrediente(id: String) -> bool:
	return Jogo.bornal.tem(id) or _ingredientes.has(id)


func _pegar_ingrediente(id: String) -> void:
	var de_onde := jogador.global_position + Vector2(0, -16)
	if id == "coco" and not _coqueiros.is_empty():
		de_onde = _coqueiros[0].global_position + Vector2(0, -40)
	await _pegar_item(id, de_onde)
	_atualizar_manjar()
	var todos := true
	for i in INGREDIENTES:
		todos = todos and _tem_ingrediente(i)
	if todos:
		await get_tree().create_timer(2.6).timeout
		_mostrar_aviso("Leve tudo para a Tia Dora, na cozinha.")


## Liga o que pode ser mexido em cada etapa (coqueiros, prateleira) e o brilho da alfazema.
func _atualizar_manjar() -> void:
	for coq in _coqueiros:
		coq.ativo = _manjar == "tia_pediu" and not _tem_ingrediente("coco")
	for prat in _prateleiras:
		prat.ativo = _manjar == "alfazema"
	if _manjar == "alfazema" and _brilho_alfazema == null and not _prateleiras.is_empty():
		_brilho_alfazema = _luz(_prateleiras[0].global_position + Vector2(0, -18), Color(0.75, 0.55, 1.0), 0.8, 0.9, true)
	if _brilho_alfazema != null:
		_brilho_alfazema.enabled = _manjar == "alfazema"   # (a luz fica na lista das chamas: só apaga)


# ------------------------------------------------------------------ o bornal de Adé (scripts/bornal.gd)
# A cena registra as pessoas, os lugares sagrados e as coisas perto das quais o bornal faz alguma coisa:
#   pessoa → Dar · altar → Arriar (só oferenda) · coisa → Usar.
# E responde, em cada caso, se aceita o item (_aceita_*) e o que acontece (_ao_dar / _ao_arriar / _ao_usar).

var _alvos_bornal: Array = []       # {no, id, nome, tipo, raio, rotulo}


## nome: como aparece no menu ("Dar à Tia Dora", "Arriar na tronqueira", "Usar na jangada").
func _registrar_alvo(no: Node2D, id: String, tipo: String, rotulo: String, raio := 34.0) -> void:
	_alvos_bornal.append({"no": no, "id": id, "tipo": tipo, "rotulo": rotulo, "raio": raio})


func _alvo_perto(tipo: String) -> Dictionary:
	var melhor := {}
	var dist := INF
	for a in _alvos_bornal:
		var no: Node2D = a["no"]
		if a["tipo"] != tipo or not is_instance_valid(no) or not no.is_visible_in_tree():
			continue
		var d := no.global_position.distance_to(jogador.global_position)
		if d < a["raio"] and d < dist:
			dist = d
			melhor = a
	return melhor


func _alvo_por_id(id: String) -> Dictionary:
	for a in _alvos_bornal:
		if a["id"] == id:
			return a
	return {}


func _pode_abrir_bornal() -> bool:
	return jogador != null and jogador.pode_mover and not $Dialogo.ativo and not Jogo.menu.aberto \
		and not Jogo.bornal.aberto and not _trocando


func _abrir_bornal() -> void:
	jogador.congelar(true)
	var r: Dictionary = await Jogo.bornal.abrir(_acoes_do_bornal)
	if not r.is_empty():
		await _fazer_no_bornal(r["id"], r["acao"])
	if not $Dialogo.ativo and estado != "saindo":
		jogador.congelar(false)


## O que dá para fazer com o item ali onde Adé está: [[rótulo, ação], ...].
func _acoes_do_bornal(id: String) -> Array:
	var item: Dictionary = Jogo.bornal.ITENS[id]
	var acoes := []
	var coisa := _alvo_perto("coisa")
	if not coisa.is_empty() and item["tipo"] != "entrega":
		acoes.append([coisa["rotulo"], "usar:" + coisa["id"]])
	var altar := _alvo_perto("altar")
	if not altar.is_empty() and item["tipo"] == "oferenda":
		acoes.append([altar["rotulo"], "arriar:" + altar["id"]])
	var pessoa := _alvo_perto("pessoa")
	if not pessoa.is_empty():
		acoes.append([pessoa["rotulo"], "dar:" + pessoa["id"]])
	if item.get("equipa", false):
		acoes.append(["Guardar" if Jogo.bornal.equipado == id else "Pôr na mão", "equipar"])
	return acoes


func _fazer_no_bornal(id: String, acao: String) -> void:
	var partes := acao.split(":")
	if partes[0] == "equipar":
		Jogo.bornal.equipar(id)
		Jogo.tocar_som("pegar_item", -10.0)
		return
	var alvo := _alvo_por_id(partes[1])
	var no: Node2D = alvo.get("no")
	if no:
		jogador.olhar_para(no.global_position)
	match partes[0]:
		"dar":
			if _aceita_dar(id, alvo["id"]):
				Jogo.bornal.tirar(id, _na_tela(no.global_position + Vector2(0, -16)))
				Jogo.tocar_som("pegar_item", -8.0)
				await get_tree().create_timer(0.5).timeout
				await _ao_dar(id, alvo["id"])
			else:
				await _recusa(id, alvo)
		"arriar":
			if _aceita_arriar(id, alvo["id"]):
				Jogo.bornal.tirar(id, _na_tela(no.global_position + Vector2(0, -6)))
				await get_tree().create_timer(0.5).timeout
				await _ao_arriar(id, alvo["id"])
			else:
				await _recusa(id, alvo)
		"usar":
			if _aceita_usar(id, alvo["id"]):
				await _ao_usar(id, alvo["id"])
			else:
				await _recusa(id, alvo)


## Posição na tela de um ponto do mundo (para o ícone voar do bornal até lá).
func _na_tela(pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * pos


## Põe um item no bornal (com o ícone voando de onde ele estava) e avisa. Na primeira vez, explica o bornal.
func _pegar_item(id: String, de_onde: Vector2 = Vector2(-1, -1)) -> void:
	Jogo.bornal.pegar(id, _na_tela(de_onde) if de_onde.x > -1 else _na_tela(jogador.global_position + Vector2(0, -16)))
	Jogo.tocar_som("pegar_item", -4.0)
	_mostrar_aviso("Você guardou no Àpò: " + Jogo.bornal.ITENS[id]["nome"])
	if Jogo.bornal.ITENS[id]["tipo"] == "ferramenta":
		# uma ferramenta nova aparece grande, depois da conversa em que Adé acha
		await _mostrar_grande(Jogo.bornal.icone(id), 4.0, Jogo.bornal.ITENS[id]["nome"] + "!",
			Jogo.texto(Jogo.bornal.ITENS[id].get("curta", "Guardado no Àpò.")))
	if not Jogo.has_meta("bornal_dica"):
		Jogo.set_meta("bornal_dica", true)
		await get_tree().create_timer(0.6).timeout
		while $Dialogo.ativo:
			await $Dialogo.terminou
		await _falar_linhas([
			{"quem": "", "yo": "", "pt": Jogo.texto("Adé guardou no Àpò, a sua sacola (àpò, em iorubá, quer dizer bolsa). Para ver o que tem nele, aperte {bornal}.")},
			{"quem": "", "yo": "", "pt": "Perto de alguém, escolha um item e DÊ para a pessoa. No lugar certo, USE ou ARRIE a oferenda."},
		])


## Hooks das cenas: aceitam o item? E o que acontece depois. (_aceita_dar, _ao_dar, _aceita_arriar e _ao_arriar
## do terreiro ficam lá embaixo; as fases trocam todos.)
func _aceita_usar(_id: String, _alvo: String) -> bool:
	return false


func _ao_usar(_id: String, _alvo: String) -> void:
	pass


## Quando o item não serve ali: a fala "recusa_<alvo>_<item>" ou "recusa_<alvo>" do diálogo da cena,
## ou um aviso simples.
func _recusa(id: String, alvo: Dictionary) -> void:
	for chave in ["recusa_%s_%s" % [alvo["id"], id], "recusa_" + alvo["id"]]:
		if _dados.has(chave):
			var linhas: Array = _dados[chave].duplicate(true)
			for l in linhas:
				l["pt"] = l["pt"].replace("{item}", Jogo.bornal.ITENS[id]["nome"].to_lower())
			await _falar_linhas(linhas)
			return
	Jogo.tocar_som("erro", -10.0)
	match alvo["tipo"]:
		"pessoa":
			_mostrar_aviso("Não é isso que precisa agora.")
		"altar":
			_mostrar_aviso("Isso não vai nesta oferenda.")
		_:
			_mostrar_aviso("Isso não serve aqui.")


## Dica quando Adé fala com alguém (ou mexe em algo) e a resposta está no bornal.
func _dica_bornal(acao: String) -> void:
	_mostrar_aviso(Jogo.texto("Abra o Àpò ({bornal}) e escolha " + acao + "."))


# ------------------------------------------------------------------ o bornal no terreiro

func _aceita_dar(id: String, alvo: String) -> bool:
	match alvo:
		"tia":
			return (id == "lenha" and tia == "pediu_lenha") or (_manjar == "tia_pediu" and id in INGREDIENTES)
		"vo":
			return id == "manjar" and _manjar == "pronto"
	return false


func _ao_dar(id: String, alvo: String) -> void:
	match alvo:
		"tia":
			if id == "lenha":
				tia = "com_lenha"
				await _falar("tia_lenha")
				return
			_ingredientes[id] = true
			if _ingredientes.size() < INGREDIENTES.size():
				await _falar("tia_recebe_" + id)
				return
			await _falar("tia_recebe_" + id)
			await _falar("tia_manjar_cozinhar")
			await _cozinhar_manjar()
			_manjar = "pronto"
			await _falar("tia_manjar_pronto")
		"vo":
			jogador.congelar(true)
			await _entregar_manjar()
			await _falar("vo_manjar")
			if _manjar_na_mao:
				# a Vó guarda o manjar para a gira de Iemanjá
				var t := create_tween()
				t.tween_property(_manjar_na_mao, "modulate:a", 0.0, 0.6)
				t.tween_callback(_manjar_na_mao.queue_free)
				_manjar_na_mao = null


func _aceita_arriar(id: String, alvo: String) -> bool:
	if alvo != "tronqueira" or estado != "na_tronqueira":
		return false
	if id == "pade":
		return not _arriados.has("pade")
	if id == "luna":
		if not _arriados.has("pade"):
			_mostrar_aviso("A vela só se arria depois do padê.")
			return false
		return not _arriados.has("luna")
	return false


func _ao_arriar(id: String, _alvo: String) -> void:
	await _arriar_na_tronqueira(id)


## Um objeto do cenário pela textura (para o ícone voar de lá até o bornal).
func _objeto_perto(textura: String) -> Vector2:
	var melhor := jogador.global_position + Vector2(0, -16)
	var dist := INF
	for n in mundo.get_children():
		var sp = n.get("sprite") if n is Area2D else (n if n is Sprite2D else null)
		if sp is Sprite2D and sp.texture and sp.texture.resource_path == textura:
			var d: float = n.global_position.distance_to(jogador.global_position)
			if d < dist:
				dist = d
				melhor = n.global_position + Vector2(0, -12)
	return melhor


## O prato do manjar nas mãos de Adé: de costas não aparece (fica na frente dele); de lado, vai para o lado
## para onde ele olha.
func _segurar_manjar() -> void:
	if not _manjar_na_mao or not is_instance_valid(_manjar_na_mao) or _manjar_na_mao.get_parent() != jogador:
		return
	match jogador.direcao_olhar:
		"costas":
			_manjar_na_mao.visible = false
		"lado":
			_manjar_na_mao.visible = true
			_manjar_na_mao.position = Vector2(-5 if jogador.sprite.flip_h else 5, -9)
		_:
			_manjar_na_mao.visible = true
			_manjar_na_mao.position = Vector2(0, -9)


## A Vó mandou Adé ajudar a Tia Dora; se ele tenta passar direto para a despensa (onde está a alfazema),
## a Tia não deixa, com jeitinho.
var _tia_barrou := 0


func _tia_barra_a_despensa() -> void:
	jogador.congelar(true)
	jogador.global_position += Vector2(-14, 0)
	jogador.olhar_para(_tia.global_position)
	_tia.olhar_para_jogador = true
	await _falar("tia_despensa_fechada" if _tia_barrou == 0 else "tia_despensa_de_novo")
	_tia_barrou += 1
