extends Node2D
## Monta a fase a partir de um arquivo de texto (fases/prologo.txt).
## Cada caractere é um bloco de 16x16 pixels. Veja a legenda no README.

@export_file("*.txt") var arquivo_fase := "res://fases/prologo.txt"
@export var titulo_fase := "Prólogo"
@export var subtitulo_fase := "Oríta Mẹ́ta · A Encruzilhada"

const TILE := 16

# posição de cada bloco na folha arte/tiles.png
const T_GRAMA := Vector2i(0, 0)
const T_TERRA := Vector2i(1, 0)
const T_TERRA_ESCURA := Vector2i(2, 0)
const T_TABUA := Vector2i(3, 0)
const T_MATO := Vector2i(4, 0)
const T_CAPIM := Vector2i(5, 0)

const CENA_JOGADOR := preload("res://cenas/jogador.tscn")
const CENA_EXU := preload("res://cenas/exu.tscn")
const CENA_BUZIO := preload("res://cenas/buzio.tscn")
const CENA_PORTAL := preload("res://cenas/portal.tscn")

var largura := 0
var altura := 0
var jogador: CharacterBody2D

var _chao: TileMapLayer
var _mato: TileMapLayer


func _ready() -> void:
	Jogo.reiniciar()
	Jogo.tocar_musica()
	_criar_fundo()

	var tileset := _criar_tileset()
	_chao = TileMapLayer.new()
	_chao.tile_set = tileset
	add_child(_chao)
	_mato = TileMapLayer.new()
	_mato.tile_set = tileset
	add_child(_mato)

	_construir(_ler_mapa())

	var camera: Camera2D = jogador.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = largura * TILE
	camera.limit_bottom = altura * TILE
	camera.reset_smoothing()
	jogador.limite_queda = altura * TILE + 48

	$Dialogo.evento.connect(_ao_evento)
	$HUD.mostrar_titulo(titulo_fase, subtitulo_fase)


func _unhandled_input(_ev: InputEvent) -> void:
	pass   # o Esc (ou Start) abre o menu de pausa, que fica no Jogo (scripts/menu.gd)


func _ao_evento(nome: String) -> void:
	if nome == "abrir_caminho":
		Jogo.falou_com_exu = true
		_abrir_mato()


## O mato fechado se abre e deixa Adé seguir.
func _abrir_mato() -> void:
	Jogo.tocar_som("caminho", -2.0)
	_mato.collision_enabled = false
	var t := create_tween()
	t.tween_property(_mato, "modulate:a", 0.0, 1.2)
	t.tween_callback(_mato.clear)


# ------------------------------------------------------------------ mapa

func _ler_mapa() -> PackedStringArray:
	var texto := FileAccess.get_file_as_string(arquivo_fase)
	var linhas := PackedStringArray()
	for linha in texto.split("\n"):
		linha = linha.strip_edges(false, true)
		if linha != "":
			linhas.append(linha)
	altura = linhas.size()
	for linha in linhas:
		largura = maxi(largura, linha.length())
	return linhas


func _bloco(mapa: PackedStringArray, x: int, y: int) -> String:
	if y < 0 or y >= mapa.size() or x < 0 or x >= mapa[y].length():
		return "."
	return mapa[y][x]


func _construir(mapa: PackedStringArray) -> void:
	Jogo.buzios_total = 0
	for y in altura:
		for x in mapa[y].length():
			var c := mapa[y][x]
			var celula := Vector2i(x, y)
			# centro do bloco e base do bloco (onde ficam os pés)
			var centro := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			var base := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			match c:
				"#":
					_chao.set_cell(celula, 0, _tipo_de_terra(mapa, x, y))
				"=":
					_chao.set_cell(celula, 0, T_TABUA)
				",":
					_chao.set_cell(celula, 0, T_CAPIM)
				"B":
					_mato.set_cell(celula, 0, T_MATO)
				"o":
					var b := CENA_BUZIO.instantiate()
					b.position = centro
					add_child(b)
					Jogo.buzios_total += 1
				"E":
					var e := CENA_EXU.instantiate()
					e.position = base
					add_child(e)
				"X":
					var p := CENA_PORTAL.instantiate()
					p.position = base
					add_child(p)
				"P":
					jogador = CENA_JOGADOR.instantiate()
					jogador.position = base
	# o jogador entra por último para ficar na frente de tudo
	add_child(jogador)


## Grama em cima, terra no meio, terra escura no fundo.
func _tipo_de_terra(mapa: PackedStringArray, x: int, y: int) -> Vector2i:
	if _bloco(mapa, x, y - 1) != "#":
		return T_GRAMA
	if _bloco(mapa, x, y - 2) != "#":
		return T_TERRA
	return T_TERRA_ESCURA


# ------------------------------------------------------------------ tileset

func _criar_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)

	var fonte := TileSetAtlasSource.new()
	fonte.texture = preload("res://arte/tiles.png")
	fonte.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(fonte, 0)

	var m := TILE / 2.0
	var quadrado := PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
	var tabua := PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, -m + 6), Vector2(-m, -m + 6)])

	for coord in [T_GRAMA, T_TERRA, T_TERRA_ESCURA, T_TABUA, T_MATO, T_CAPIM]:
		fonte.create_tile(coord)
		var dados := fonte.get_tile_data(coord, 0)
		if coord == T_CAPIM:
			continue  # só decoração, sem colisão
		dados.add_collision_polygon(0)
		if coord == T_TABUA:
			dados.set_collision_polygon_points(0, 0, tabua)
			dados.set_collision_polygon_one_way(0, 0, true)  # atravessa por baixo
		else:
			dados.set_collision_polygon_points(0, 0, quadrado)
	return ts


# ------------------------------------------------------------------ fundo

func _criar_fundo() -> void:
	var fundo := ParallaxBackground.new()
	add_child(fundo)
	for camada in [["fundo_ceu", 0.0], ["fundo_montes", 0.15], ["fundo_arvores", 0.4]]:
		var p := ParallaxLayer.new()
		p.motion_scale = Vector2(camada[1], 0.0)
		p.motion_mirroring = Vector2(384, 0)
		var s := Sprite2D.new()
		s.texture = load("res://arte/%s.png" % camada[0])
		s.centered = false
		p.add_child(s)
		fundo.add_child(p)
