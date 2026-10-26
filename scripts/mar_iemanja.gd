extends "res://scripts/encruzilhada.gd"
## Òkun Yemọja — o mar de Iemanjá (visão de cima, como a encruzilhada e as matas de Oxóssi e de Nanã).
## Na chegada, Exu explica a Adé quem é Iemanjá e o que vai na oferenda que ele tem de levar até Aiocá,
## o palácio dela no fundo do mar: flores brancas, perfume de alfazema, uma pérola e um espelho.
##
## Lugares (os primeiros na praia, os últimos no fundo do mar):
##   iemanja_praia → a praia das ondas (deitada: Adé anda para a direita, o mar fica embaixo): as ondas vêm de
##                   baixo, sobem pela areia molhada e voltam, num ritmo; a espuma mostra
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
const ONDAS := [1.9, 3.9, 2.4, 1.7, 4.0, 3.7, 2.1, 4.0]     # até quantos blocos cada onda sobe (repete)

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
# o caminho pelas moitas (o coqueiral): coco caindo e caranguejo no meio da trilha
var _cocos: Array = []          # {base, estado, t, espera, sombra, coco}
var _caranguejos_trilha: Array = []   # {s, base, lado, estado, t}


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
	_cair_cocos(delta)
	_mover_caranguejos_trilha(delta)


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
		"q":
			_criar_ponto_do_coco(base)
		"K":
			_criar_caranguejo_da_trilha(lugar, celula, base)
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
			ret.size = Vector2(10, 32)
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
	# a praia é deitada: o mar fica embaixo; para cada coluna, a linha onde o mar começa
	var mapa: PackedStringArray = _mapas["iemanja_praia"]
	var largura := 0
	for linha in mapa:
		largura = maxi(largura, linha.length())
	for x in largura:
		var y0 := mapa.size()
		for y in mapa.size():
			if x < mapa[y].length() and mapa[y][x] == "w":
				y0 = y
				break
		_costa.append(y0)
	_ondas = Node2D.new()
	_ondas.position = lugares["iemanja_praia"]["origem"]
	_ondas.z_index = -4                     # por cima da areia, por baixo de Adé e das coisas
	_ondas.draw.connect(_desenhar_ondas)
	add_child(_ondas)
	_onda_dur = 1.2


## Quantos pixels a água sobe na coluna x (a beira da onda é ondulada e muda um pouco a cada onda).
func _alcance_px(x: float, alcance := -1.0) -> float:
	if alcance < 0.0:
		alcance = _alcance
	return alcance * TILE * (0.9 + 0.07 * sin(x * 0.05 + _onda_i * 1.7) + 0.03 * sin(x * 0.23 - _tempo * 2.2))


## Onde o mar começa na coluna x (em pixels), suave de uma coluna do mapa para a outra.
func _costa_px(x: float) -> float:
	var f := x / TILE - 0.5
	var i := clampi(floori(f), 0, _costa.size() - 1)
	var j := clampi(i + 1, 0, _costa.size() - 1)
	var onda := -4.0 + 3.0 * sin(x * 0.031) + 1.5 * sin(x * 0.093 + 1.0)     # a beira não é reta
	return lerpf(_costa[i], _costa[j], clampf(f - floorf(f), 0.0, 1.0)) * TILE + 4.0 + onda


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
	var coluna := floori(rel.x / TILE)
	if coluna < 0 or coluna >= _costa.size():
		return false
	var beira: float = _costa_px(rel.x) - _alcance_px(rel.x)
	return rel.y > beira


## A onda em pixel art, vindo de baixo: água funda e água rasa (transparentes), a crista de espuma rendada na
## frente, bolhinhas logo atrás; quando ela recua, fica a renda de espuma desmanchando e a areia molhada mais
## escura onde ela chegou. Desenhada coluna por coluna, só as que aparecem na tela.
func _desenhar_ondas() -> void:
	var funda := Color(0.17, 0.55, 0.74, 0.82)
	var rasa := Color(0.5, 0.84, 0.9, 0.62)
	var espuma := Color(0.97, 1.0, 1.0, 0.95)
	var bolha := Color(0.92, 0.98, 1.0, 0.7)
	var molhada := Color(0.3, 0.22, 0.12, 0.0)
	var largura := _costa.size() * TILE
	var renda := 0.0                      # a espuma que fica para trás quando a onda volta
	var areia := 0.0                      # a areia escura onde a onda chegou
	match _onda_fase:
		"desce":
			var u := clampf(_onda_t / ONDA_TEMPO["desce"], 0.0, 1.0)
			renda = 1.0 - u * 0.6
			areia = 1.0
		"calma":
			var u2 := clampf(_onda_t / 1.2, 0.0, 1.0)
			renda = 0.4 * (1.0 - u2)
			areia = 1.0 - u2
	var quadro := int(_tempo * 8.0)
	var mar := Color(0.17, 0.53, 0.7)
	var mar_claro := Color(0.33, 0.69, 0.78)
	var meio := jogador.global_position.x - _ondas.global_position.x
	for x in range(maxi(0, int(meio) - 150), mini(largura, int(meio) + 150)):
		var costa := _costa_px(x)
		# a beira do mar, lisa (por cima dos degraus dos blocos), com a espuminha que vai e vem na areia
		_ondas.draw_rect(Rect2(x, floorf(costa), 1, 18), mar)
		if (x * 7 + quadro) % 11 == 0:
			_ondas.draw_rect(Rect2(x, floorf(costa) + 4 + (x * 3) % 9, 1, 2), mar_claro)
		var respira := 1.0 + sin(_tempo * 1.8 + x * 0.04)
		_ondas.draw_rect(Rect2(x, floorf(costa - respira) - 1, 1, 2), mar_claro)
		if (x + quadro / 2) % 3 != 0:
			_ondas.draw_rect(Rect2(x, floorf(costa - respira) - 2, 1, 1), Color(1, 1, 1, 0.85))
		var agua := _alcance_px(x)
		var beira := floorf(costa - agua)
		var maxima := floorf(costa - _alcance_px(x, _alcance_max))
		# a areia molhada que a onda deixou (escurece e vai secando)
		if areia > 0.0 and maxima < beira:
			molhada.a = 0.16 * areia
			_ondas.draw_rect(Rect2(x, maxima, 1, beira - maxima), molhada)
		# a renda de espuma desmanchando onde a onda chegou
		if renda > 0.0 and (x * 7 + int(maxima)) % 5 < 2:
			var c := espuma
			c.a = 0.8 * renda
			_ondas.draw_rect(Rect2(x, maxima + (x * 3) % 4 - 1, 1, 1 + int(x % 3 == 0)), c)
		if agua < 1.0:
			if _onda_fase == "aviso" and (x / 2) % 2 == 0:
				# a espuma que avisa até onde a próxima onda vai subir
				var vai := floorf(costa - _alcance_px(x, _alcance_max))
				var pisca := 0.25 + 0.4 * absf(sin(_onda_t * 7.0))
				_ondas.draw_rect(Rect2(x, vai, 1, 1), Color(1, 1, 1, pisca))
			continue
		var forca := 1.0 if _onda_fase in ["sobe", "cheia"] else 0.75
		var f := funda
		f.a *= forca
		var r := rasa
		r.a *= forca
		var altura_rasa := minf(7.0, agua)
		_ondas.draw_rect(Rect2(x, beira + altura_rasa, 1, costa - beira - altura_rasa), f)
		_ondas.draw_rect(Rect2(x, beira, 1, altura_rasa), r)
		# riscos de luz na água que sobe (deitados, como a onda)
		if (x * 7 + quadro) % 13 == 0 and costa - beira > 10:
			var ly := beira + 6.0 + float((x * 13 + quadro * 5) % int(maxf(1.0, costa - beira - 9)))
			_ondas.draw_rect(Rect2(x, ly, 4, 1), Color(0.6, 0.88, 0.94, 0.8 * forca))
		# a crista: espuma de 2 px, às vezes 3, com a frente rendada
		var crista := 2.0 + float((x + quadro) % 5 == 0) + float(_onda_fase == "cheia")
		var e := espuma
		e.a = 0.95 * forca
		_ondas.draw_rect(Rect2(x, beira - float((x * 5 + quadro) % 7 == 0), 1, crista), e)
		# bolhinhas atrás da crista
		for k in 2:
			var by := beira + 3.0 + float((x * 11 + k * 5 + quadro * 3) % 7)
			if (x + k * 3 + quadro) % 4 == 0 and by < costa:
				_ondas.draw_rect(Rect2(x, by, 1, 1), bolha)


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


# ------------------------------------------------------------------ o caminho pelas moitas

## Num coqueiro da beira da trilha, de tempos em tempos cai um coco: primeiro a sombra aparece e cresce no chão
## (é o aviso), depois o coco cai. Quem estiver em cima da sombra leva um búzio de axé.
func _criar_ponto_do_coco(base: Vector2) -> void:
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.position = base - Vector2(0, 3)
	sombra.z_index = -3
	sombra.modulate.a = 0.0
	add_child(sombra)
	var c := Sprite2D.new()
	c.texture = preload("res://arte/iemanja_coco.png")
	c.offset = Vector2(0, -3)
	c.visible = false
	mundo.add_child(c)
	_cocos.append({"base": base - Vector2(0, 3), "estado": "espera", "t": 0.0, "espera": randf_range(0.5, 3.0),
		"sombra": sombra, "coco": c})


func _cair_cocos(delta: float) -> void:
	for k in _cocos:
		var base: Vector2 = k["base"]
		if base.distance_to(jogador.global_position) > 220.0 and k["estado"] == "espera":
			continue                                # longe da tela, o coqueiro descansa
		k["t"] += delta
		var sombra: Sprite2D = k["sombra"]
		var c: Sprite2D = k["coco"]
		match k["estado"]:
			"espera":
				if k["t"] >= k["espera"]:
					k["estado"] = "aviso"; k["t"] = 0.0
			"aviso":
				var u: float = clampf(k["t"] / 1.0, 0.0, 1.0)
				sombra.modulate.a = 0.25 + 0.55 * u
				sombra.scale = Vector2.ONE * (0.4 + 0.6 * u)
				if k["t"] >= 1.0:
					k["estado"] = "cai"; k["t"] = 0.0
					c.visible = true
					c.modulate.a = 1.0
			"cai":
				var u2: float = clampf(k["t"] / 0.22, 0.0, 1.0)
				c.position = base + Vector2(0, -40.0 * (1.0 - u2 * u2))
				if k["t"] >= 0.22:
					k["estado"] = "chao"; k["t"] = 0.0
					sombra.modulate.a = 0.0
					som_perto("tronco_cai", base, -12.0)
					if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
							and base.distance_to(jogador.global_position) < 10.0:
						_tomar_dano(base)
						if not _iem.has("coco_caiu"):
							_iem["coco_caiu"] = true
							_falar("coco")
			"chao":
				# o coco quica e rola um pouquinho, depois some
				var u3: float = clampf(k["t"] / 0.35, 0.0, 1.0)
				c.position = base + Vector2(6.0 * u3, -4.0 * sin(u3 * PI))
				c.rotation = u3 * 3.0
				if k["t"] > 0.9:
					c.modulate.a = clampf(1.0 - (k["t"] - 0.9) / 0.4, 0.0, 1.0)
				if k["t"] >= 1.3:
					c.visible = false
					c.rotation = 0.0
					k["estado"] = "espera"; k["t"] = 0.0
					k["espera"] = randf_range(1.2, 3.2)


## O caranguejo que mora na trilha: fica parado no meio do caminho, abrindo e fechando as garras (quem encosta
## leva um beliscão); de vez em quando ele corre de lado para a toca, na beira da moita, e o caminho abre.
func _criar_caranguejo_da_trilha(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var mapa: PackedStringArray = _mapas[lugar]
	var lado := Vector2(1, 0)
	if _letra(mapa, celula.x + 1, celula.y) != "a":
		lado = Vector2(-1, 0) if _letra(mapa, celula.x - 1, celula.y) == "a" else Vector2(0, -1)
	var toca := Sprite2D.new()                       # o buraquinho da toca, na beira da moita
	toca.texture = TEX_SOMBRA
	toca.scale = Vector2(0.5, 0.4)
	toca.modulate = Color(0.2, 0.12, 0.06, 0.8)
	toca.position = base + lado * 9.0 - Vector2(0, 3)
	toca.z_index = -3
	add_child(toca)
	var s := Sprite2D.new()
	s.texture = preload("res://arte/iemanja_caranguejo.png")
	s.hframes = 2
	s.offset = Vector2(0, -4)
	s.position = base
	mundo.add_child(s)
	_caranguejos_trilha.append({"s": s, "base": base, "lado": lado, "estado": "caminho", "t": randf_range(0.0, 1.5)})


func _mover_caranguejos_trilha(delta: float) -> void:
	for k in _caranguejos_trilha:
		k["t"] += delta
		var s: Sprite2D = k["s"]
		var base: Vector2 = k["base"]
		var toca: Vector2 = base + k["lado"] * 9.0
		match k["estado"]:
			"caminho":
				s.frame = int(_tempo * 5.0) % 2                 # abrindo e fechando as garras
				s.position = base + Vector2(sin(_tempo * 3.0) * 1.5, 0).round()
				if k["t"] >= 3.2:
					k["estado"] = "sai"; k["t"] = 0.0
			"sai":
				var u: float = clampf(k["t"] / 0.35, 0.0, 1.0)
				s.position = base.lerp(toca, u).round()
				s.frame = int(_tempo * 12.0) % 2
				s.modulate.a = 1.0 - u * 0.9
				if k["t"] >= 0.35:
					k["estado"] = "toca"; k["t"] = 0.0
					s.visible = false
			"toca":
				if k["t"] >= 1.8:
					k["estado"] = "volta"; k["t"] = 0.0
					s.visible = true
			"volta":
				var u2: float = clampf(k["t"] / 0.35, 0.0, 1.0)
				s.position = toca.lerp(base, u2).round()
				s.frame = int(_tempo * 12.0) % 2
				s.modulate.a = 0.1 + u2 * 0.9
				if k["t"] >= 0.35:
					k["estado"] = "caminho"; k["t"] = 0.0
		if s.visible and k["estado"] != "toca" and _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
				and s.position.distance_to(jogador.global_position) < 10.0:
			Jogo.tocar_som("caranguejo", -6.0)
			_tomar_dano(s.position)
			if not _iem.has("beliscou"):
				_iem["beliscou"] = true
				_falar("caranguejo_trilha")


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
		volta.tween_property(jogador, "global_position", jogador.global_position + Vector2(-14, 0), 0.25)
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
