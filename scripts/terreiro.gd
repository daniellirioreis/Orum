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
	ESCADA, AGUA, MARGEM, DEGRAU, ESTRADA, TOTAL_TILES
}
const CHAO := {
	",": GRAMA, ";": GRAMA_TUFO, "*": GRAMA_FLOR, "_": CAMINHO, "t": TERRA,
	".": PISO, ":": PISO2, "c": LADRILHO, "d": TABUA, "+": SOLEIRA, "P": FACHADA_PORTA,
	"=": CALCADA, "r": ESTRADA, "o": DEGRAU, "E": ESCADA, "a": ARBUSTO, "e": ESTACA,
	"^": BARRANCO_BORDA, "B": BARRANCO_FACE, "b": BARRANCO_PE, "~": AGUA, "|": MARGEM,
}
const ANDAVEL := [",", ";", "*", "_", "t", ".", ":", "c", "d", "+", "P", "=", "r", "o", "E"]
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

## Etapas: sonho → acordou → buscando → pronto → na_tronqueira → ritual → aberto
var estado := "sonho"
var coletados := {}
var tia := "inicio"          # inicio → pediu_lenha → com_lenha → deu_efum
var lugar_atual := ""

var mundo: Node2D             # tudo que precisa de profundidade (ordenado por y)
var jogador: CharacterBody2D
var vo: Area2D
var tronqueira: Area2D
var porteira: Node2D
var exu: Sprite2D
var marcas := {}              # posições especiais: "v" (Vó na tronqueira), "e" (Exu)
var portas := {}              # número da porta → lista de [lugar, posição do bloco]
var tamanhos := {}            # lugar → tamanho em pixels

var _dados: Dictionary
var _tileset: TileSet
var _noite: CanvasModulate
var _toque: CanvasLayer
var _lista: Control
var _medidor: ColorRect
var _item: TextureRect
var _contador_buzios: Label
var _contador_oferendas: Label
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
var _chamas: Array = []
var _tempo := 0.0
var _cor_fundo_antiga: Color


func _ready() -> void:
	Jogo.reiniciar()
	Jogo.tocar_musica()
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)   # fora das salas é tudo escuro
	_dados = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_DIALOGO))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	for nome in LUGARES:
		_construir(nome)
	mundo.add_child(jogador)
	$HUD.esconder_contador = true   # o terreiro tem a barra própria, lá em cima

	_toque = preload("res://scripts/toque.gd").new()
	add_child(_toque)
	_criar_interface()
	$Dialogo.evento.connect(_ao_evento)
	_entrar_lugar(LUGAR_INICIAL)
	_sonho()


func _exit_tree() -> void:
	RenderingServer.set_default_clear_color(_cor_fundo_antiga)


func _process(delta: float) -> void:
	_tempo += delta
	for chama in _chamas:
		var l: PointLight2D = chama[0]
		l.energy = chama[1] * (0.88 + 0.12 * sin(_tempo * chama[2]) + randf_range(-0.04, 0.04))
	for b in _bichos:
		_mover_galinha(b, delta)
	if _contador_buzios:
		_contador_buzios.text = "%03d" % Jogo.buzios
	for g in _gatos:
		g.frame = int(_tempo * 0.8) % 2


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("sair"):
		Jogo.mudar_cena("res://cenas/titulo.tscn")


# ------------------------------------------------------------------ lugares e portas

## Ajusta a câmera e a luz para o lugar onde Adé está.
func _entrar_lugar(nome: String) -> void:
	lugar_atual = nome
	var origem: Vector2 = LUGARES[nome]["origem"]
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
	_noite.color = COR_DENTRO if LUGARES[nome]["dentro"] else COR_FORA


## Leva Adé (com a tela escurecendo) para outro lugar.
func teleportar(nome: String, posicao: Vector2) -> void:
	jogador.global_position = posicao
	_entrar_lugar(nome)


func _ao_pisar_porta(corpo: Node2D, numero: String, lugar: String) -> void:
	if _trocando or not corpo.is_in_group("jogador") or not jogador.pode_mover:
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
			await get_tree().create_timer(0.08).timeout
			var t2 := create_tween()
			t2.tween_property(_cortina, "color:a", 0.0, 0.22)
			await t2.finished
			jogador.congelar(false)
			_trocando = false
			return


## Onde Adé aparece ao chegar por uma porta: no primeiro bloco livre ao lado dela.
func _chegada(lugar: String, celula: Vector2i) -> Vector2:
	var mapa: PackedStringArray = _mapas[lugar]
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var c: Vector2i = celula + dir
		var letra := _letra(mapa, c.x, c.y)
		if letra in ANDAVEL and letra != "+" and letra != "P" and not _e_porta(lugar, c):
			var origem: Vector2 = LUGARES[lugar]["origem"]
			return origem + Vector2(c.x * TILE + TILE / 2.0, (c.y + 1) * TILE - 2)
	return LUGARES[lugar]["origem"]


func _e_porta(lugar: String, celula: Vector2i) -> bool:
	for numero in portas:
		for p in portas[numero]:
			if p[0] == lugar and p[1] == celula:
				return true
	return false


# ------------------------------------------------------------------ história

func _sonho() -> void:
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
	for i in 7:
		var s := Sprite2D.new()
		s.texture = preload("res://arte/sonho_orixas.png")
		s.hframes = 7
		s.frame = i
		s.position = Vector2(tela.x / 2.0 + (i - 3) * 34, 84 + (6 if i % 2 else 0))
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
	if estado == "acordou" or estado == "sonho":
		await _falar("tia_antes")
	elif tia == "inicio":
		await _falar("tia_pedido")
	elif tia == "pediu_lenha":
		await _falar("tia_esperando")
	elif tia == "com_lenha":
		await _falar("tia_lenha")
	else:
		await _falar("tia_depois")


func _pegar_lenha() -> void:
	if tia == "pediu_lenha":
		await _falar("lenha_pegar")
	else:
		await _falar("lenha_nada")


func _procurar_na_despensa(tem_epo: bool) -> void:
	if estado != "buscando":
		await _falar("despensa_antes")
	elif tem_epo and not coletados.has("epo"):
		await _falar("despensa_epo")
	else:
		var opcoes: Array = _dados["despensa_nada"]
		await _falar_linhas([opcoes[_buscas % opcoes.size()]])
		_buscas += 1


func _falar_com_oga() -> void:
	if estado == "acordou" or estado == "sonho":
		await _falar("oga_antes")
	elif coletados.has("oti"):
		await _falar("oga_depois")
	else:
		await _falar("oga_pedido")
		if _pendente == "comecar_toque":
			_pendente = ""
			jogador.congelar(true)
			await _toque.jogar()
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
			tia = "com_lenha"
			_mostrar_aviso("Você pegou: " + _dados["pegou"]["lenha"])
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


func _ganhar(id: String) -> void:
	coletados[id] = true
	var atlas := AtlasTexture.new()
	atlas.atlas = TEX_ITENS
	atlas.region = Rect2(ITENS.find(id) * 12, 0, 12, 12)
	_item.texture = atlas
	_atualizar_hud()
	Jogo.tocar_som("buzio", -2.0)
	_mostrar_aviso("Você pegou: " + _dados["pegou"][id])
	if coletados.size() == ITENS.size():
		estado = "pronto"
		await get_tree().create_timer(2.6).timeout
		_mostrar_aviso("Leve tudo para a Vó, no barracão.")


func _vo_vai_para_tronqueira() -> void:
	estado = "na_tronqueira"
	vo.ativo = false
	var t := create_tween()
	t.tween_property(vo, "modulate:a", 0.0, 0.6)
	await t.finished
	vo.global_position = marcas["v"]
	var t2 := create_tween()
	t2.tween_property(vo, "modulate:a", 1.0, 0.6)
	tronqueira.ativo = true
	_mostrar_aviso("Vá até a tronqueira, perto da porteira.")


func _fazer_ritual() -> void:
	if estado != "na_tronqueira":
		return
	estado = "ritual"
	tronqueira.ativo = false
	jogador.congelar(true)
	jogador.olhar_para(tronqueira.global_position)
	_lista.visible = false

	var lugares := [-12.0, -4.0, 4.0, 12.0]
	for i in ITENS.size():
		var oferenda := Sprite2D.new()
		oferenda.texture = TEX_ITENS
		oferenda.hframes = 5
		oferenda.frame = i
		oferenda.position = Vector2(lugares[i], 4)
		oferenda.modulate.a = 0.0
		tronqueira.get_node("Oferendas").add_child(oferenda)
		create_tween().tween_property(oferenda, "modulate:a", 1.0, 0.25)
		Jogo.tocar_som("buzio", -6.0)
		await get_tree().create_timer(0.45).timeout
	tronqueira.sprite.frame = 1
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
	Jogo.tocar_som("caminho", -2.0)
	exu = Sprite2D.new()
	exu.texture = preload("res://arte/exu_snes.png")
	exu.hframes = 2
	exu.offset = Vector2(0, -16)
	exu.position = marcas["e"]
	exu.modulate = Color(1, 1, 1, 0)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	exu.add_child(sombra)
	mundo.add_child(exu)
	var luz_exu := PointLight2D.new()
	luz_exu.texture = _luz_tex
	luz_exu.color = Color(1.0, 0.3, 0.25)
	luz_exu.texture_scale = 1.2
	luz_exu.energy = 0.0
	luz_exu.position = Vector2(0, -16)
	exu.add_child(luz_exu)
	create_tween().tween_property(luz_exu, "energy", 1.0, 1.0)

	var fumaca := CPUParticles2D.new()
	fumaca.position = exu.position + Vector2(0, -12)
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

	create_tween().tween_property(exu, "modulate:a", 1.0, 1.0)
	var piscar := create_tween().set_loops()
	piscar.tween_callback(func(): exu.frame = (exu.frame + 1) % 2).set_delay(0.6)


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
	Jogo.mudar_cena("res://cenas/jogo.tscn")


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

	# medidor das oferendas (à esquerda): enche a cada oferenda recolhida
	var medidor := TextureRect.new()
	medidor.texture = preload("res://arte/hud_medidor.png")
	medidor.position = Vector2(6, 5)
	camada.add_child(medidor)
	_medidor = ColorRect.new()
	_medidor.color = Color(0.98, 0.78, 0.25)
	_medidor.position = Vector2(8, 48)
	_medidor.size = Vector2(10, 0)
	camada.add_child(_medidor)

	# caixa do item: mostra a última oferenda recolhida
	var caixa := TextureRect.new()
	caixa.texture = preload("res://arte/hud_caixa.png")
	caixa.position = Vector2(24, 8)
	camada.add_child(caixa)
	_item = TextureRect.new()
	_item.position = Vector2(30, 14)
	camada.add_child(_item)

	# contadores: búzios e oferendas
	var icone_buzio := TextureRect.new()
	icone_buzio.texture = preload("res://arte/buzio_axe.png")
	icone_buzio.position = Vector2(56, 8)
	camada.add_child(icone_buzio)
	_contador_buzios = _rotulo_hud("000", 10, Color.WHITE)
	_contador_buzios.add_theme_font_override("font", fonte_forte)
	_contador_buzios.position = Vector2(52, 16)
	camada.add_child(_contador_buzios)
	var atlas := AtlasTexture.new()
	atlas.atlas = TEX_ITENS
	atlas.region = Rect2(36, 0, 12, 12)
	var icone_of := TextureRect.new()
	icone_of.texture = atlas
	icone_of.position = Vector2(86, 5)
	camada.add_child(icone_of)
	_contador_oferendas = _rotulo_hud("0/4", 10, Color.WHITE)
	_contador_oferendas.add_theme_font_override("font", fonte_forte)
	_contador_oferendas.position = Vector2(80, 16)
	camada.add_child(_contador_oferendas)

	# AXÉ (à direita): búzios no lugar dos corações
	var axe := _rotulo_hud("— AXÉ —", 7, Color(1.0, 0.9, 0.6))
	axe.add_theme_font_override("font", fonte_forte)
	axe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	axe.size = Vector2(70, 10)
	axe.position = Vector2(tela.x - 78, 3)
	camada.add_child(axe)
	for i in 5:
		var b := TextureRect.new()
		b.texture = preload("res://arte/buzio_axe.png")
		b.position = Vector2(tela.x - 76 + i * 13, 15)
		camada.add_child(b)

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
	_contador_oferendas.text = "%d/4" % coletados.size()
	_medidor.size.y = 41.0 * coletados.size() / 4.0
	_medidor.position.y = 48.0 - _medidor.size.y


func _rotulo_hud(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
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
	var origem: Vector2 = LUGARES[nome]["origem"]
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
	if LUGARES[nome]["dentro"]:
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
	if c == "m" and lugar == "quintal":
		c = "m2"   # no quintal, "m" é mato alto (na cozinha é a mesa)
	if CENARIO.has(c):
		var s := _criar_cenario(CENARIO[c][0], CENARIO[c][1], base)
		if c == "a" and randf() < 0.3:
			s.hframes = 2
			s.frame = 1   # arbusto com frutinhas
		elif c == "a":
			s.hframes = 2
		match c:
			"l":
				_luz(base + Vector2(0, -8), Color(1.0, 0.78, 0.45), 0.6, 1.8, true)
			"u":
				_luz(base + Vector2(0, -38), Color(1.0, 0.8, 0.5), 0.75, 2.2, true)
			"F":
				_luz(base + Vector2(-8, -10), Color(1.0, 0.55, 0.25), 0.7, 1.2, true)
				_fumaca(base + Vector2(15, -40))
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
			_luz(base + Vector2(0, -8), Color(1.0, 0.8, 0.55), 0.45, 2.4, false)
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
			vo = _criar_pessoa("res://arte/vo_snes.png", 3, base)
			vo.interagiu.connect(_falar_com_vo)
		"D":
			_criar_pessoa("res://arte/tia_snes.png", 2, base).interagiu.connect(_falar_com_tia)
		"G":
			_criar_pessoa("res://arte/oga_snes.png", 2, base).interagiu.connect(_falar_com_oga)
		"N":
			_criar_pessoa("res://arte/cambone_snes.png", 2, base).interagiu.connect(_falar_com_cambone)
		"K", "S", "k":
			var tex := "res://arte/obj_caixote.png" if c != "S" else "res://arte/obj_saco.png"
			var spot := _criar_interativo(tex, 1, base, Vector2(14, 8), -22.0)
			spot.interagiu.connect(_procurar_na_despensa.bind(c == "k"))
		"L":
			var lenha := _criar_interativo("res://arte/obj_lenha.png", 1, base, Vector2(26, 10), -22.0)
			lenha.interagiu.connect(_pegar_lenha)
		"T":
			tronqueira = _criar_interativo("res://arte/tronqueira.png", 2, base, Vector2(26, 8), -46.0)
			tronqueira.ativo = false
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


func _criar_vagalumes() -> void:
	var tam: Vector2 = tamanhos["quintal"]
	var v := CPUParticles2D.new()
	v.material = _material_sem_sombra()
	v.z_index = 15
	v.position = LUGARES["quintal"]["origem"] + Vector2(tam.x / 2.0, tam.y * 0.62)
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
const SOBRE_TERRENO := ["M", "R", "h", "H", "J", "P", "^", "B", "b", "E"]


func _criar_tileset_terreno() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = preload("res://arte/terreno_snes.png")
	fonte.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(fonte, 0)
	for y in 5:
		for x in 16:
			fonte.create_tile(Vector2i(x, y))
	return ts


func _construir_terreno(mapa: PackedStringArray, origem: Vector2, topo: TileMapLayer) -> void:
	var ts := _criar_tileset_terreno()
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
	for i in TERRENOS.size():
		var camada := TileMapLayer.new()
		camada.tile_set = ts
		camada.position = origem - Vector2(TILE / 2.0, TILE / 2.0)
		camada.z_index = -9 + i
		add_child(camada)
		var letras: Array = TERRENOS[i]
		for vy in altura + 1:
			for vx in largura + 1:
				var indice := 0
				if _letra(mapa, vx - 1, vy - 1) in letras: indice += 1
				if _letra(mapa, vx, vy - 1) in letras: indice += 2
				if _letra(mapa, vx - 1, vy) in letras: indice += 4
				if _letra(mapa, vx, vy) in letras: indice += 8
				if indice > 0:
					camada.set_cell(Vector2i(vx, vy), 0, Vector2i(indice, i + 1))

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

	# 4) por cima: muro, casa, barranco e escada (com colisão); água bloqueia passagem
	for y in altura:
		for x in mapa[y].length():
			var c := mapa[y][x]
			if c in SOBRE_TERRENO:
				topo.set_cell(Vector2i(x, y), 0, Vector2i(_tile_para(mapa, x, y), 0))
			elif c in AGUA_CHARS:
				topo.set_cell(Vector2i(x, y), 0, Vector2i(INVISIVEL, 0))
			elif c == "a":
				_criar_cenario_quadros("res://arte/arbusto.png", 2, 1 if (x * 3 + y) % 4 == 0 else 0, Vector2(14, 8), origem + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE))
			elif c == "e":
				_criar_cenario("res://arte/estaca.png", Vector2(10, 6), origem + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE + 2))


func _criar_cenario_quadros(caminho: String, quadros: int, quadro: int, pe: Vector2, base: Vector2) -> void:
	var s := _criar_cenario(caminho, pe, base)
	s.hframes = quadros
	s.frame = quadro
