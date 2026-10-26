extends "res://scripts/encruzilhada.gd"
## Òkun Yemọja — o mar de Iemanjá (visão de cima, como a encruzilhada e as matas de Oxóssi e de Nanã).
## Na chegada, Exu explica a Adé quem é Iemanjá e o que vai na oferenda que ele tem de levar até Aiocá,
## o palácio dela no fundo do mar: flores brancas, perfume de alfazema, uma pérola e um espelho.
##
## Lugares (os primeiros na praia, os últimos no fundo do mar):
##   iemanja_praia → a praia das ondas: as ondas sobem pela areia molhada e voltam, num ritmo; a espuma mostra
##                   até onde a próxima vai chegar. Nos apertos (pedras e moitas tomando a areia seca), Adé passa
##                   quando a onda recua. A onda que pega Adé joga ele de volta para a última areia seca (e leva
##                   um búzio de axé). Caranguejos andam na areia molhada e águas-vivas largadas na areia queimam.
##                   No fim da praia, na restinga, as flores brancas.
##   (em seguida: a vila dos pescadores, o jardim de corais, as águas escuras e Aiocá)

const LUGARES_IEMANJA := {
	"iemanja_praia": {"origem": Vector2(0, 0), "dentro": false},
}
const COR_DIA := Color(1.0, 0.98, 0.94)
const SECO := ["s", ",", ";", "*", "t"]
const TEX_ITENS_IEM := preload("res://arte/iemanja_itens.png")
const ORDEM_ITENS := ["flores", "alfazema", "perola", "espelho", "abebe"]
## O ritmo das ondas: calma → aviso (a espuma marca até onde a próxima vai) → sobe → cheia → desce.
const ONDA_TEMPO := {"aviso": 0.9, "sobe": 0.7, "cheia": 0.35, "desce": 1.2}
const ONDAS := [2.4, 4.9, 3.0, 2.2, 5.0, 4.6, 2.6, 5.0]     # até quantos blocos cada onda sobe (repete)

var _iem := {}                  # flags da fase: flores, alfazema...
var _slots_iem := {}              # id → ícone do inventário
var _moldura_trofeu: TextureRect
var _repetindo := false
# a praia das ondas
var _ondas: Node2D              # desenha a água subindo pela areia e a espuma
var _costa: Array = []          # para cada linha do mapa da praia: em que coluna o mar começa
var _onda_fase := "calma"
var _onda_t := 0.0
var _onda_dur := 1.6
var _onda_i := 0
var _alcance := 0.0             # quantos blocos a onda subiu agora
var _alcance_max := 0.0         # até onde esta onda vai
var _ultimo_seco := Vector2.ZERO
var _onda_levou_uma_vez := false
var _queimou_uma_vez := false
var _caranguejos: Array = []    # {s, de, ate, vel, fase}
var _aguasvivas: Array = []     # Sprite2D
var _flores: Area2D


func _ready() -> void:
	lugares = LUGARES_IEMANJA
	terrenos = [[["s", "u", "w", "t"], 8], [["u", "w"], 9], [["w"], 10], [["t"], 1]]
	agua_chars = ["w"]
	cor_fora = COR_DIA
	estado = "caminho"
	Jogo.tocar_musica("musica_iemanja")
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)
	_dados = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/mar_iemanja.json"))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	_ponto_volta["iemanja_praia"] = jogador.global_position
	_ultimo_seco = jogador.global_position
	$HUD.esconder_contador = true

	_criar_interface()
	_criar_inventario()
	$Dialogo.evento.connect(_ao_evento)
	_proximo_raio = 9999.0
	_preparar_ondas()
	_entrar_lugar("iemanja_praia")
	_inicio()


func _inicio() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.8).timeout
	$HUD.mostrar_titulo("Òkun Yemọja", "O Mar de Iemanjá")
	await get_tree().create_timer(1.6).timeout
	if Jogo.trofeus.has("iemanja"):
		_repetindo = true
		await _falar("revisita")
		var r: Dictionary = await Jogo.menu.escolher("O Mar de Iemanjá", ["Fazer a fase de novo", "Voltar ao Ọ̀run"])
		if r["acao"] == "ok" and r["i"] == 1:
			voltar_ao_mapa()
			return
	await _falar("chegada")
	await _exu_explica()


## Exu surge na fumaça, explica quem é Iemanjá e o que vai na oferenda, e vai embora.
func _exu_explica() -> void:
	jogador.congelar(true)
	var e := _exu_surge(marcas.get("exu", jogador.global_position + Vector2(24, 20)))
	await get_tree().create_timer(1.0).timeout
	jogador.olhar_para(e.position)
	await _falar("exu_explica")
	jogador.congelar(true)
	_fumaca_vermelha(e.position + Vector2(0, -12))
	var some := create_tween()
	some.tween_property(e, "modulate:a", 0.0, 0.6)
	some.tween_callback(e.queue_free)
	await some.finished
	jogador.congelar(false)


func _process(delta: float) -> void:
	super._process(delta)
	_mover_ondas(delta)
	_chao_de_ade()
	_mover_caranguejos()
	_aguasvivas_queimam()


## Sem relâmpago no mar de Iemanjá (por enquanto, o céu é limpo).
func _animar_tempo(_delta: float) -> void:
	pass


func teleportar(nome: String, posicao: Vector2) -> void:
	super.teleportar(nome, posicao)
	_ultimo_seco = posicao


# ------------------------------------------------------------------ objetos dos mapas

func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	match c:
		"E":
			marcas["exu"] = base
		"f":
			_flores = _criar_interativo("res://arte/iemanja_flores.png", 2, base, Vector2(14, 6), -22.0)
			_flores.interagiu.connect(_colher_flores)
		"r":
			_criar_cenario("res://arte/iemanja_rocha.png", Vector2(26, 10), base + Vector2(0, 2))
		"C":
			_criar_cenario("res://arte/iemanja_coqueiro.png", Vector2(6, 5), base)
		"k":
			var s := Sprite2D.new()
			s.texture = preload("res://arte/iemanja_caranguejo.png")
			s.hframes = 2
			s.offset = Vector2(0, -4)
			s.position = base
			mundo.add_child(s)
			_caranguejos.append({"s": s, "de": base + Vector2(-20, 0), "ate": base + Vector2(20, 0),
				"vel": 18.0 + celula.y % 3 * 4.0, "fase": celula.y * 0.37})
		"j":
			var a := Sprite2D.new()
			a.texture = preload("res://arte/iemanja_aguaviva.png")
			a.hframes = 2
			a.offset = Vector2(0, -4)
			a.position = base - Vector2(0, 2)
			mundo.add_child(a)
			_aguasvivas.append(a)
		"h":
			var h := Sprite2D.new()
			h.texture = preload("res://arte/iemanja_conchas.png")
			h.hframes = 4
			h.frame = (celula.x + celula.y) % 4
			h.position = base - Vector2(0, 6)
			h.z_index = -4
			add_child(h)
		">":
			var area := Area2D.new()
			area.collision_layer = 0
			area.collision_mask = 2
			area.position = base - Vector2(0, TILE / 2.0)
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2(28, 10)
			forma.shape = ret
			area.add_child(forma)
			area.body_entered.connect(_na_saida_da_praia)
			add_child(area)
		_:
			super._criar_objeto(lugar, c, celula, base, chao)


## Na areia o passo é abafado; na areia molhada, chapinha.
func som_do_chao(pos: Vector2) -> Array:
	var l := _letra_em(pos)
	if l == "u":
		return ["passo_lama", -20.0]
	if l == "s":
		return ["passo_terra", -19.0]
	return super.som_do_chao(pos)


## O mar mexe: faixas de luz passando (como a água de Nanã, mas clara).
func _camada_terreno(_origem: Vector2, i: int, camada: TileMapLayer) -> void:
	if i == 2:
		camada.material = _material_mar()


const SHADER_MAR := """
shader_type canvas_item;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 c = COLOR;
	vec2 p = floor(mundo);
	float onda = sin(p.y * 0.35 + TIME * 1.3 + sin(p.x * 0.21 - TIME * 0.6) * 2.0)
		* sin(p.x * 0.43 + TIME * 0.9 + p.y * 0.07);
	float luz = step(0.7, onda) * 0.10 + step(0.9, onda) * 0.12;
	float sombra = step(onda, -0.82) * 0.05;
	c.rgb += vec3(luz * 0.85, luz, luz) * c.a - vec3(sombra) * c.a;
	COLOR = c;
}
"""
var _shader_mar: ShaderMaterial


func _material_mar() -> ShaderMaterial:
	if not _shader_mar:
		var sh := Shader.new()
		sh.code = SHADER_MAR
		_shader_mar = ShaderMaterial.new()
		_shader_mar.shader = sh
	return _shader_mar


# ------------------------------------------------------------------ inventário

func _criar_inventario() -> void:
	for n in _hud_oferendas:
		n.visible = false
	var camada: CanvasLayer = _icone_buzio.get_parent()
	for i in ORDEM_ITENS.size():
		var caixa := TextureRect.new()
		caixa.texture = preload("res://arte/hud_slot.png")
		caixa.position = Vector2(6 + i * 19, 6)
		camada.add_child(caixa)
		if ORDEM_ITENS[i] == "abebe":
			_moldura_trofeu = caixa
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX_ITENS_IEM
		atlas.region = Rect2(i * 12, 0, 12, 12)
		var item := TextureRect.new()
		item.texture = atlas
		item.position = caixa.position + Vector2(3, 3)
		item.pivot_offset = Vector2(6, 6)
		item.modulate = COR_ITEM_FALTA
		camada.add_child(item)
		_slots_iem[ORDEM_ITENS[i]] = item


func _acender_slot(id: String, texto := "") -> void:
	var icone: TextureRect = _slots_iem[id]
	icone.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(1.6, 1.6), 0.12)
	t.tween_property(icone, "scale", Vector2.ONE, 0.18)
	Jogo.tocar_som("pegar_item", -4.0)
	if texto != "":
		_mostrar_aviso(texto)


# ------------------------------------------------------------------ 1) a praia das ondas

func _preparar_ondas() -> void:
	var mapa: PackedStringArray = _mapas["iemanja_praia"]
	for y in mapa.size():
		var col := mapa[y].find("w")
		_costa.append(col if col >= 0 else mapa[y].length())
	_ondas = Node2D.new()
	_ondas.position = lugares["iemanja_praia"]["origem"]
	_ondas.z_index = -4                     # por cima da areia, por baixo de Adé e das coisas
	_ondas.draw.connect(_desenhar_ondas)
	add_child(_ondas)
	_onda_dur = 1.2


## Quantos pixels a água sobe na linha y (a beira da onda é ondulada e muda um pouco a cada onda).
func _alcance_px(y: float) -> float:
	return _alcance * TILE * (0.88 + 0.12 * sin(y * 0.09 + _onda_i * 1.7))


func _mover_ondas(delta: float) -> void:
	if not _ondas:
		return
	# as ondas só correm enquanto Adé pode andar (nada de onda no meio de uma conversa)
	if jogador.pode_mover and not _voltando:
		_onda_t += delta
	var dur: float = _onda_dur if _onda_fase == "calma" else ONDA_TEMPO[_onda_fase]
	var u := clampf(_onda_t / dur, 0.0, 1.0)
	match _onda_fase:
		"calma", "aviso":
			_alcance = 0.0
		"sobe":
			_alcance = _alcance_max * (1.0 - pow(1.0 - u, 2.0))
		"cheia":
			_alcance = _alcance_max
		"desce":
			_alcance = _alcance_max * (1.0 - u * u)
	if _onda_t >= dur:
		_onda_t = 0.0
		var proxima := {"calma": "aviso", "aviso": "sobe", "sobe": "cheia", "cheia": "desce", "desce": "calma"}
		_onda_fase = proxima[_onda_fase]
		match _onda_fase:
			"aviso":
				_onda_i += 1
				_alcance_max = ONDAS[_onda_i % ONDAS.size()]
			"sobe":
				if lugar_atual == "iemanja_praia":
					Jogo.tocar_som("agua_cai", -20.0 + _alcance_max * 1.6)
			"calma":
				_onda_dur = randf_range(1.3, 2.0)
	_ondas.queue_redraw()
	# a onda pega Adé enquanto sobe ou está cheia (descendo, ela só molha o pé)
	if lugar_atual == "iemanja_praia" and _onda_fase in ["sobe", "cheia"] and jogador.pode_mover and not _voltando:
		if _molhado(jogador.global_position + Vector2(0, -3)):
			_onda_leva_ade()


func _molhado(pos: Vector2) -> bool:
	var rel: Vector2 = pos - lugares["iemanja_praia"]["origem"]
	var linha := floori(rel.y / TILE)
	if linha < 0 or linha >= _costa.size():
		return false
	var beira: float = _costa[linha] * TILE - _alcance_px(rel.y)
	return rel.x > beira


func _desenhar_ondas() -> void:
	var agua := Color(0.33, 0.69, 0.78, 0.86)
	var clara := Color(0.62, 0.86, 0.9, 0.9)
	var espuma := Color(0.96, 0.99, 1.0, 0.95)
	var altura := _costa.size() * TILE
	var y := 0
	while y < altura:
		var linha := y / TILE
		var costa: float = _costa[linha] * TILE
		if _alcance > 0.05:
			var a := _alcance_px(y)
			var x0 := floorf(costa - a)
			_ondas.draw_rect(Rect2(x0, y, costa - x0 + 2, 2), agua)
			_ondas.draw_rect(Rect2(x0 + 3, y, minf(6.0, costa - x0), 2), clara)
			# a espuma na ponta da água, rendada
			_ondas.draw_rect(Rect2(x0 - 1, y, 3, 2), espuma)
			if (y / 2 + _onda_i) % 3 == 0:
				_ondas.draw_rect(Rect2(x0 - 3, y, 2, 2), espuma)
		elif _onda_fase == "aviso":
			# a espuma que avisa até onde a próxima onda vai subir
			var vai := _alcance_max * TILE * (0.88 + 0.12 * sin(y * 0.09 + _onda_i * 1.7))
			var pisca := 0.35 + 0.35 * absf(sin(_onda_t * 9.0))
			if (y / 2) % 2 == 0:
				_ondas.draw_rect(Rect2(floorf(costa - vai) - 1, y, 2, 2), Color(1, 1, 1, pisca))
		y += 2


## Adé pisa na areia seca: é para lá que a onda devolve ele.
func _chao_de_ade() -> void:
	if not jogador.pode_mover or _voltando or lugar_atual != "iemanja_praia":
		return
	if _letra_em(jogador.global_position + Vector2(0, -3)) in SECO:
		_ultimo_seco = jogador.global_position


func _onda_leva_ade() -> void:
	_voltando = true
	jogador.congelar(true)
	Jogo.tocar_som("agua_cai", -2.0)
	_respingo(jogador.global_position)
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.4)
	await c.finished
	axe -= 1
	_atualizar_axe()
	teleportar("iemanja_praia", _ultimo_seco)
	await get_tree().create_timer(0.3).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.4)
	await c2.finished
	if axe <= 0:
		_sem_axe()
		return
	_voltando = false
	_invulneravel = 1.0
	if not _onda_levou_uma_vez:
		_onda_levou_uma_vez = true
		await _falar("onda_levou")
	else:
		jogador.congelar(false)
		_mostrar_aviso("Passe quando a onda recuar.")


func _mover_caranguejos() -> void:
	for k in _caranguejos:
		var s: Sprite2D = k["s"]
		var dist: float = maxf(1.0, k["de"].distance_to(k["ate"]))
		var u := pingpong(_tempo * k["vel"] / dist + k["fase"], 1.0)
		s.position = k["de"].lerp(k["ate"], u).round()
		s.frame = int(_tempo * 6.0 + k["fase"]) % 2
		if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
				and s.position.distance_to(jogador.global_position) < 9.0:
			Jogo.tocar_som("caranguejo", -6.0)
			_tomar_dano(s.position)


func _aguasvivas_queimam() -> void:
	for a in _aguasvivas:
		a.frame = int(_tempo * 1.5 + a.position.x) % 2
		if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
				and a.position.distance_to(jogador.global_position + Vector2(0, -2)) < 9.0:
			_tomar_dano(a.position)
			if not _queimou_uma_vez:
				_queimou_uma_vez = true
				_falar("aguaviva")


func _colher_flores() -> void:
	if _iem.has("flores"):
		await _falar("flores_depois")
		return
	await _falar("flores")
	_flores.sprite.frame = 1


func _na_saida_da_praia(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador") or _voltando or not jogador.pode_mover:
		return
	if not _iem.has("flores"):
		jogador.congelar(true)
		await _falar("saida_sem_flores")
		jogador.congelar(true)
		var volta := create_tween()
		volta.tween_property(jogador, "global_position", jogador.global_position + Vector2(0, -14), 0.25)
		await volta.finished
		jogador.congelar(false)
		return
	# a vila dos pescadores ainda está sendo feita: por enquanto, a praia leva de volta ao Ọ̀run
	jogador.congelar(true)
	await _falar("continua")
	voltar_ao_mapa()


func _ao_evento(nome: String) -> void:
	match nome:
		"pegar_flores":
			_iem["flores"] = true
			_acender_slot("flores", "Flores brancas")
		_:
			super._ao_evento(nome)


# ------------------------------------------------------------------ voltar ao mapa

func pode_voltar_ao_mapa() -> bool:
	return estado != "saindo"


func voltar_ao_mapa() -> void:
	estado = "saindo"
	jogador.congelar(true)
	Jogo.set_meta("no_mapa", "iemanja")
	Jogo.tocar_som("caminho", -6.0)
	Jogo.mudar_cena("res://cenas/mapa_mundo.tscn")


## Guardado aqui, o jogo continua do começo do mar de Iemanjá.
func _local_do_caminho() -> String:
	return "iemanja"


func _pode_guardar() -> bool:
	return false
