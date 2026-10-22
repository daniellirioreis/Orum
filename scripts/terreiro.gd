extends Node2D
## Prólogo, parte 1: o terreiro da Vó, em visão de cima (estilo RPG).
##
## Adé sonha com os orixás, acorda no barracão, pede a bênção à Vó e descobre que
## precisa chamar Exu. Cada oferenda está num canto da casa:
##   Efum  → Tia Dora, na cozinha (ela pede lenha do quintal antes)
##   Epó   → escondido na despensa (é preciso procurar)
##   Oti   → Ogã Bené, nos atabaques (mini-jogo: repetir o toque)
##   Luma  → Lia, a cambone, no congá (só depois das outras três)
## Com tudo em mãos, a Vó vai para a tronqueira, faz-se o ritual, Exu chega e abre a porteira.
##
## O chão e as paredes estão em fases/terreiro.txt; os objetos e as pessoas em
## fases/terreiro_objetos.txt; as falas em dialogos/terreiro.json.

const TILE := 16
const ARQUIVO_MAPA := "res://fases/terreiro.txt"
const ARQUIVO_OBJETOS := "res://fases/terreiro_objetos.txt"
const ARQUIVO_DIALOGO := "res://dialogos/terreiro.json"
const ITENS := ["efum", "epo", "oti", "luna"]

# posição de cada bloco na folha arte/tiles_rpg.png
const T_PISO := Vector2i(0, 0)
const T_LADRILHO := Vector2i(1, 0)
const T_TABUA := Vector2i(2, 0)
const T_GRAMA := Vector2i(3, 0)
const T_GRAMA2 := Vector2i(4, 0)
const T_CAMINHO := Vector2i(5, 0)
const T_PAREDE_FRENTE := Vector2i(6, 0)
const T_PAREDE_TOPO := Vector2i(7, 0)
const T_MURO_FRENTE := Vector2i(8, 0)
const T_MURO_TOPO := Vector2i(9, 0)
const T_PAREDE_ALTO := Vector2i(10, 0)
const T_JANELA := Vector2i(11, 0)
const T_PISO2 := Vector2i(12, 0)
const T_MURO_ALTO := Vector2i(13, 0)
const T_GRAMA3 := Vector2i(14, 0)
const T_CAMINHO2 := Vector2i(15, 0)
const T_TERRA := Vector2i(16, 0)
const TOTAL_TILES := 17
const CHAO := {
	".": T_PISO, ":": T_PISO2, "c": T_LADRILHO, "d": T_TABUA,
	",": T_GRAMA, ";": T_GRAMA2, "*": T_GRAMA3, "_": T_CAMINHO, "=": T_CAMINHO2, "t": T_TERRA,
}
const PAREDES := ["#", "j", "M"]
const SOLIDOS := [T_PAREDE_FRENTE, T_PAREDE_TOPO, T_MURO_FRENTE, T_MURO_TOPO, T_PAREDE_ALTO, T_JANELA, T_MURO_ALTO]

## Cor da noite (tudo fica mais escuro; os lampiões, velas e o fogão iluminam).
const COR_NOITE := Color(0.46, 0.43, 0.64)

## Objetos de cenário: imagem e tamanho do "pé" que bloqueia a passagem (0 = não bloqueia).
const CENARIO := {
	"C": ["res://arte/obj_conga.png", Vector2(52, 14)],
	"A": ["res://arte/obj_atabaques.png", Vector2(48, 10)],
	"F": ["res://arte/obj_fogao.png", Vector2(36, 14)],
	"m": ["res://arte/obj_mesa.png", Vector2(32, 10)],
	"O": ["res://arte/obj_pote.png", Vector2(12, 6)],
	"Q": ["res://arte/obj_prateleira.png", Vector2(46, 8)],
	"H": ["res://arte/obj_horta.png", Vector2(46, 22)],
	"R": ["res://arte/obj_arvore.png", Vector2(10, 6)],
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
}
## Coisas que ficam no chão, por baixo das pessoas.
const NO_CHAO := {"E": "res://arte/obj_esteira.png", "r": "res://arte/obj_tapete.png"}

const CENA_JOGADOR := preload("res://cenas/jogador_rpg.tscn")
const CENA_INTERATIVO := preload("res://cenas/interativo.tscn")
const TEX_ITENS := preload("res://arte/itens.png")

## Etapas: sonho → acordou → buscando → pronto → na_tronqueira → ritual → aberto
var estado := "sonho"
var coletados := {}
var tia := "inicio"          # inicio → pediu_lenha → com_lenha → deu_efum

var largura := 0
var altura := 0
var mundo: Node2D             # tudo que precisa de profundidade (ordenado por y)
var jogador: CharacterBody2D
var vo: Area2D
var tronqueira: Area2D
var porteira: Node2D
var exu: Sprite2D
var marcas := {}              # posições especiais: "v" (Vó na tronqueira), "e" (Exu)

var _dados: Dictionary
var _chao: TileMapLayer
var _toque: CanvasLayer
var _lista: Control
var _icones := {}
var _aviso: Label
var _clarao: ColorRect
var _pendente := ""
var _buscas := 0
var _porteira_corpo: CollisionShape2D
var _porteira_aberta := false
var _luz_tex: Texture2D = preload("res://arte/luz.png")
var _bichos: Array = []        # galinhas que andam pelo quintal
var _gatos: Array = []
var _chamas: Array = []        # luzes que tremulam
var _tempo := 0.0


func _ready() -> void:
	Jogo.reiniciar()
	Jogo.tocar_musica()
	_dados = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_DIALOGO))

	_chao = TileMapLayer.new()
	_chao.tile_set = _criar_tileset()
	add_child(_chao)
	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	var noite := CanvasModulate.new()
	noite.color = COR_NOITE
	add_child(noite)
	_construir()
	_criar_vagalumes()

	var camera: Camera2D = jogador.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = largura * TILE
	camera.limit_bottom = altura * TILE
	camera.reset_smoothing()

	_toque = preload("res://scripts/toque.gd").new()
	add_child(_toque)
	_criar_interface()
	$Dialogo.evento.connect(_ao_evento)
	_sonho()


func _process(delta: float) -> void:
	_tempo += delta
	for chama in _chamas:
		var l: PointLight2D = chama[0]
		l.energy = chama[1] * (0.88 + 0.12 * sin(_tempo * chama[2]) + randf_range(-0.04, 0.04))
	for b in _bichos:
		_mover_galinha(b, delta)
	for g in _gatos:
		g.frame = int(_tempo * 0.8) % 2


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("sair"):
		Jogo.mudar_cena("res://cenas/titulo.tscn")


# ------------------------------------------------------------------ história

func _sonho() -> void:
	jogador.congelar(true)
	var camada := CanvasLayer.new()
	camada.layer = 8
	add_child(camada)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(raiz)
	var ceu := TextureRect.new()
	ceu.texture = preload("res://arte/sonho_fundo.png")
	raiz.add_child(ceu)
	var figuras := []
	for i in 7:
		var s := Sprite2D.new()
		s.texture = preload("res://arte/sonho_orixas.png")
		s.hframes = 7
		s.frame = i
		s.position = Vector2(42 + i * 50, 104 + (6 if i % 2 else 0))
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
			_pendente = nome          # acontece quando a conversa terminar
		"vo_saudacao":
			vo.animar = false
			vo.sprite.frame = 2       # braços erguidos
		"tremer":
			_tremer()
		"exu_chega":
			_exu_aparece()
		"abrir_porteira":
			_abrir_porteira()


func _ganhar(id: String) -> void:
	coletados[id] = true
	_icones[id].modulate = Color(1, 1, 1, 1)
	Jogo.tocar_som("buzio", -2.0)
	_mostrar_aviso("Você pegou: " + _dados["pegou"][id])
	if coletados.size() == ITENS.size():
		estado = "pronto"
		await get_tree().create_timer(2.6).timeout
		_mostrar_aviso("Leve tudo para a Vó, no barracão.")


## A Vó vai na frente e espera na tronqueira.
func _vo_vai_para_tronqueira() -> void:
	estado = "na_tronqueira"
	vo.ativo = false
	var t := create_tween()
	t.tween_property(vo, "modulate:a", 0.0, 0.6)
	await t.finished
	vo.position = marcas["v"]
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
	_luz(tronqueira.position + Vector2(0, -6), Color(1.0, 0.7, 0.4), 1.3, 1.6, true)
	var pulsar := create_tween().set_loops()
	pulsar.tween_property(brilho, "modulate:a", 0.6, 0.5)
	pulsar.tween_property(brilho, "modulate:a", 1.0, 0.5)

	await _falar("ritual")
	jogador.congelar(true)
	await get_tree().create_timer(0.4).timeout
	await _falar("exu")

	vo.animar = true
	var t := create_tween()
	t.tween_property(exu, "position", porteira.position + Vector2(0, 6), 1.4)
	t.tween_property(exu, "modulate:a", 0.0, 0.6)
	await t.finished
	estado = "aberto"
	vo.ativo = true
	jogador.congelar(false)
	_mostrar_aviso("A porteira está aberta. Siga Exu.")


func _exu_aparece() -> void:
	Jogo.tocar_som("caminho", -2.0)
	exu = Sprite2D.new()
	exu.texture = preload("res://arte/exu.png")
	exu.hframes = 2
	exu.offset = Vector2(0, -16)
	exu.position = marcas["e"]
	exu.modulate = Color(1, 1, 1, 0)
	mundo.add_child(exu)
	var luz_exu := PointLight2D.new()
	luz_exu.texture = _luz_tex
	luz_exu.color = Color(1.0, 0.3, 0.25)
	luz_exu.texture_scale = 1.4
	luz_exu.energy = 0.0
	luz_exu.position = Vector2(0, -14)
	exu.add_child(luz_exu)
	create_tween().tween_property(luz_exu, "energy", 1.0, 1.0)

	var fumaca := CPUParticles2D.new()
	fumaca.position = exu.position + Vector2(0, -14)
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
	$Dialogo.posicionar(y_na_tela > 120.0)
	$Dialogo.iniciar(linhas)
	await $Dialogo.terminou


func _juntar(lista: Array) -> String:
	if lista.size() <= 1:
		return "".join(lista)
	return ", ".join(lista.slice(0, lista.size() - 1)) + " e " + lista[-1]


# ------------------------------------------------------------------ interface

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 6
	add_child(camada)

	_lista = HBoxContainer.new()
	_lista.position = Vector2(8, 6)
	_lista.add_theme_constant_override("separation", 3)
	_lista.visible = false
	camada.add_child(_lista)
	for i in ITENS.size():
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX_ITENS
		atlas.region = Rect2(i * 12, 0, 12, 12)
		var icone := TextureRect.new()
		icone.texture = atlas
		icone.modulate = Color(0.2, 0.15, 0.25, 0.8)
		_lista.add_child(icone)
		_icones[ITENS[i]] = icone

	_aviso = Label.new()
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.size = Vector2(384, 14)
	_aviso.position = Vector2(0, 22)
	_aviso.add_theme_font_size_override("font_size", 9)
	_aviso.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_aviso.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.12))
	_aviso.add_theme_constant_override("outline_size", 3)
	_aviso.modulate.a = 0.0
	camada.add_child(_aviso)

	_clarao = ColorRect.new()
	_clarao.color = Color(0.8, 0.1, 0.1, 0.0)
	_clarao.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_clarao)


func _mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	var t := create_tween()
	t.tween_property(_aviso, "modulate:a", 1.0, 0.25)
	t.tween_interval(2.0)
	t.tween_property(_aviso, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ mapa

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


func _construir() -> void:
	var mapa := _ler(ARQUIVO_MAPA)
	altura = mapa.size()
	for linha in mapa:
		largura = maxi(largura, linha.length())

	# chão, paredes e muro (parede com a frente à mostra quando embaixo dela não há parede)
	for y in altura:
		for x in mapa[y].length():
			var c := mapa[y][x]
			var abaixo := _letra(mapa, x, y + 1)
			var abaixo2 := _letra(mapa, x, y + 2)
			if c in PAREDES:
				# parede com 2 blocos de frente: o de baixo (barra azul) e o de cima (cal, às vezes com janela)
				var muro := c == "M"
				var tile := T_MURO_TOPO if muro else T_PAREDE_TOPO
				if not abaixo in PAREDES:
					tile = T_MURO_FRENTE if muro else T_PAREDE_FRENTE
				elif not abaixo2 in PAREDES:
					tile = T_MURO_ALTO if muro else (T_JANELA if c == "j" else T_PAREDE_ALTO)
				_chao.set_cell(Vector2i(x, y), 0, tile)
			elif CHAO.has(c):
				_chao.set_cell(Vector2i(x, y), 0, CHAO[c])

	# objetos e pessoas
	var objetos := _ler(ARQUIVO_OBJETOS)
	for y in objetos.size():
		for x in objetos[y].length():
			var c := objetos[y][x]
			if c == ".":
				continue
			var base := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			if CENARIO.has(c):
				_criar_cenario(CENARIO[c][0], CENARIO[c][1], base)
				match c:
					"l":
						_luz(base + Vector2(0, -8), Color(1.0, 0.78, 0.45), 0.6, 2.0, true)
					"u":
						_luz(base + Vector2(0, -38), Color(1.0, 0.8, 0.5), 0.75, 2.4, true)
					"F":
						_luz(base + Vector2(-8, -10), Color(1.0, 0.55, 0.25), 0.7, 1.3, true)
						_fumaca(base + Vector2(15, -40))
					"C":
						_luz(base + Vector2(0, -24), Color(1.0, 0.85, 0.6), 0.7, 1.8, true)
				continue
			if NO_CHAO.has(c):
				var tapete := Sprite2D.new()
				tapete.texture = load(NO_CHAO[c])
				tapete.position = base + Vector2(0, -tapete.texture.get_height() / 2.0)
				add_child(tapete)   # fica no chão, fora da ordenação
				move_child(tapete, _chao.get_index() + 1)
				continue
			match c:
				"b":
					var varal := Sprite2D.new()
					varal.texture = preload("res://arte/obj_bandeirinhas.png")
					varal.centered = false
					varal.position = Vector2(x * TILE, y * TILE)
					varal.z_index = 20      # no teto: por cima de todo mundo
					add_child(varal)
				"+":
					_luz(base + Vector2(0, -8), Color(1.0, 0.8, 0.55), 0.45, 2.6, false)
				"g":
					_criar_galinha(base)
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
					vo = _criar_pessoa("res://arte/vo.png", 3, base)
					vo.interagiu.connect(_falar_com_vo)
				"D":
					_criar_pessoa("res://arte/tia.png", 2, base).interagiu.connect(_falar_com_tia)
				"G":
					_criar_pessoa("res://arte/oga.png", 2, base).interagiu.connect(_falar_com_oga)
				"N":
					_criar_pessoa("res://arte/cambone.png", 2, base).interagiu.connect(_falar_com_cambone)
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
	mundo.add_child(jogador)


func _criar_cenario(caminho: String, pe: Vector2, base: Vector2) -> void:
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
	var n := _criar_interativo(caminho, quadros, base, Vector2(12, 6), -38.0)
	n.animar = true
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
	fonte.texture = preload("res://arte/tiles_rpg.png")
	fonte.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(fonte, 0)
	var m := TILE / 2.0
	var quadrado := PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
	for i in TOTAL_TILES:
		var coord := Vector2i(i, 0)
		fonte.create_tile(coord)
		if coord in SOLIDOS:
			var dados := fonte.get_tile_data(coord, 0)
			dados.add_collision_polygon(0)
			dados.set_collision_polygon_points(0, 0, quadrado)
	return ts


# ------------------------------------------------------------------ luz, bichos e partículas

## Uma luz quente (lampião, vela, fogo). "tremula" faz a luz piscar de leve como chama.
func _luz(pos: Vector2, cor: Color, energia: float, escala: float, tremula: bool) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = _luz_tex
	l.position = pos
	l.color = cor
	l.energy = energia
	l.texture_scale = escala
	add_child(l)
	if tremula:
		_chamas.append([l, energia, randf_range(5.0, 9.0)])
	return l


func _material_sem_sombra() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # brilha mesmo no escuro
	return m


func _criar_vagalumes() -> void:
	var v := CPUParticles2D.new()
	v.material = _material_sem_sombra()
	v.z_index = 15
	v.position = Vector2(largura * TILE / 2.0, (altura - 9) * TILE)
	v.amount = 36
	v.lifetime = 5.0
	v.preprocess = 5.0
	v.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	v.emission_rect_extents = Vector2(largura * TILE / 2.0 - 24, 8 * TILE)
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
	var cor := 0 if randf() < 0.5 else 2   # branca ou pedrês
	_bichos.append({"sprite": g, "origem": base, "alvo": base, "espera": randf_range(0.5, 2.0), "cor": cor})


## Galinha: anda um pouco, para, bica o chão, anda de novo (sempre perto de onde nasceu).
func _mover_galinha(b: Dictionary, delta: float) -> void:
	var g: Sprite2D = b["sprite"]
	if b["espera"] > 0.0:
		b["espera"] -= delta
		g.frame = b["cor"] + (1 if fmod(_tempo, 0.6) < 0.3 else 0)   # bicando
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
