extends "res://scripts/encruzilhada.gd"
## Ilẹ̀ Ẹrẹ̀ Nàná — a terra da lama de Nanã (visão de cima, como a encruzilhada e a mata de Oxóssi).
## Chove a fase inteira; na lagoa, a chuva engrossa. O ritmo é de quem é mais velho: devagar, olhando.
##
## Quatro lugares:
##   nana_brejo    → a lama firme e a lama funda são iguaizinhas: só as garças pousam onde dá pé.
##                   Pisou na funda, a lama puxa Adé de volta para o começo. Uma velhinha pede que ele
##                   leve o pote dela (rachado) até a lagoa — "eu chego lá do meu jeito".
##   nana_bambuzal → o taboal fecha o caminho. A faca de ferro do toco não serve: na terra de Nanã o ferro
##                   escorrega e some na lama. Com a lasca de um bambu rachado (lâmina de bambu), a taboa abre.
##   nana_mangue   → a maré sobe e desce: na baixa, dá para passar pelas raízes (e os caranguejos saem da lama);
##                   na alta, a água cobre tudo e leva Adé de volta. Numa ilhota, as flores lilás.
##                   Do outro lado, a velhinha já está esperando...
##   nana_lagoa    → Adé conserta o pote com o barro da lagoa, deixa a chuva encher o pote numa pedra e faz
##                   a oferenda no lugar de Nanã. A velhinha chega devagar — e era Nanã o tempo todo.
##                   Ela fala da lama de onde viemos, da memória e dos mais velhos, e dá o ibiri a Adé:
##                   o troféu que ele leva para o terreiro da Vó.

const LUGARES_NANA := {
	"nana_brejo": {"origem": Vector2(0, 0), "dentro": false},
	"nana_bambuzal": {"origem": Vector2(0, 600), "dentro": false},
	"nana_mangue": {"origem": Vector2(0, 1000), "dentro": false},
	"nana_lagoa": {"origem": Vector2(0, 1600), "dentro": false},
}
## Cor do dia chuvoso e quantidade de gotas em cada lugar (na lagoa, a chuva é mais forte).
const CHUVA := {
	"nana_brejo": [Color(0.66, 0.68, 0.8), 110],
	"nana_bambuzal": [Color(0.64, 0.68, 0.76), 110],
	"nana_mangue": [Color(0.58, 0.61, 0.74), 140],
	"nana_lagoa": [Color(0.5, 0.52, 0.66), 230],
}
const COR_DEPOIS := Color(0.74, 0.72, 0.84)       # quando Nanã vai embora, a chuva acalma
const LAMA := ["l", "L", "z"]
const OFERENDAS := ["pote", "flores"]
const TEX_NANA_ITENS := preload("res://arte/nana_itens.png")
const TEX_TERRENO := preload("res://arte/terreno_snes.png")
# a maré do mangue: baixa → subindo → alta → descendo (segundos)
const MARE := {"baixa": 6.5, "subindo": 1.8, "alta": 4.5, "descendo": 1.5}

var _nana := {}                 # flags da fase: pote (rachado/vazio/na_pedra/cheio), lamina, flores, faca...
var _slots_nana := {}           # id → ícone do inventário (pote, lamina, flores, ibiri)
var _moldura_trofeu: TextureRect
var _repetindo := false         # a terra já tinha sido vencida: no fim, Adé reencontra Nanã
var _visitou := {}                  # lugares já visitados (para as falas de chegada)
# brejo
var _garcas: Array = []         # {s, casa, foi, fase, lugar}
var _sapos: Array = []          # {s, casa, lugar, pulando}
var _lama_funda: Array = []     # células L do brejo (para as bolhas)
var _proxima_bolha := 0.5
var _lama_beira: Array = []     # células L encostadas no caminho firme (onde as bolhas mais aparecem)
var _bolhas_vivas := 0
var _bolha_em := {}
const MAX_BOLHAS := 16
var _tempo_no_fundo := 0.0
var _afundou_uma_vez := false
var _velhinha: Area2D
# bambuzal
var _taboas: Array = []         # Area2D de cada taboa
var _toco_faca: Area2D
var _lascas: Area2D
# mangue
var _mare := "baixa"
var _mare_tempo := 0.0
var _camada_mare: TileMapLayer
var _celulas_mare: Array = []   # células z do mangue
var _caranguejos: Array = []    # {a, s, de, ate, vel, fase}
var _ultimo_firme := Vector2.ZERO
var _mare_levou_uma_vez := false
var _velhinha_mangue: Area2D
var _falou_mangue := false
# lagoa
var _barro: Area2D
var _pedra: Area2D
var _pote_na_pedra: Sprite2D
var _balao_pedra: Sprite2D
var _balao_barro: Sprite2D
var _proxima_bolha_barro := 1.0
var _enchendo := 0.0
var _lugar_nana: Area2D
var _chegada_velhinha := Vector2.ZERO
var _nana_sprite: Sprite2D
var _anim_nana := ""
var _saida_moita: Array = []
var _chuva: CPUParticles2D
var _chuva_forte := false


func _ready() -> void:
	lugares = LUGARES_NANA
	terrenos = [[["t", "_"], 1], [LAMA + ["m"], 5], [["v", "y"], 6], [["z", "v", "y"], 6]]
	agua_chars = ["v"]
	tex_moita = "res://arte/nana_moita.png"
	cor_fora = CHUVA["nana_brejo"][0]
	estado = "caminho"
	Jogo.tocar_musica("musica_nana")
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)
	_dados = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/mata_nana.json"))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	_ponto_volta["nana_brejo"] = jogador.global_position
	$HUD.esconder_contador = true

	_criar_interface()
	_criar_inventario()
	$Dialogo.evento.connect(_ao_evento)
	_criar_chuva()
	_chuva = _camada_chuva.get_child(0)
	_proximo_raio = 9999.0
	_guardar_celulas()
	_entrar_lugar("nana_brejo")
	_inicio()


func _inicio() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.8).timeout
	$HUD.mostrar_titulo("Ilẹ̀ Ẹrẹ̀ Nàná", "A Terra da Lama de Nanã")
	await get_tree().create_timer(1.6).timeout
	if Jogo.trofeus.has("nana"):
		_repetindo = true
		await _falar("revisita")
		var r: Dictionary = await Jogo.menu.escolher("A Terra de Nanã", ["Fazer a fase de novo", "Voltar ao mapa"])
		if r["acao"] == "ok" and r["i"] == 1:
			voltar_ao_mapa()
			return
	await _falar("chegada")
	await _velhinha_chama()


func _process(delta: float) -> void:
	super._process(delta)
	_chao_de_ade(delta)
	_mover_garcas(delta)
	_mover_sapos()
	_mover_puladores(delta)
	_mover_folhas(delta)
	_bolhas(delta)
	_pingos_na_agua(delta)
	_mover_mare(delta)
	_mover_caranguejos()
	_encher_pote(delta)
	_atualizar_balao_pedra()
	_animar_poca_barro(delta)
	_perto_da_velhinha_do_mangue()
	if _nana_sprite and _anim_nana == "parada":
		_nana_sprite.frame = int(_tempo * 2.5) % 4


## Só na lagoa, com a chuva forte, cai relâmpago.
func _animar_tempo(delta: float) -> void:
	if lugar_atual == "nana_lagoa" and _chuva_forte:
		super._animar_tempo(delta)


func _entrar_lugar(nome: String) -> void:
	cor_fora = CHUVA[nome][0] if not (nome == "nana_lagoa" and _nana.has("acalmou")) else COR_DEPOIS
	super._entrar_lugar(nome)
	if _chuva:
		_chuva.amount = CHUVA[nome][1] if not (nome == "nana_lagoa" and _nana.has("acalmou")) else 70


## A chuva soa mais forte onde cai mais: na lagoa, e mais ainda depois da oferenda.
func _volume_do_lugar(nome: String) -> float:
	if nome == "nana_lagoa":
		if _nana.has("acalmou"):
			return -28.0
		return -14.0 if _chuva_forte else -18.0
	return -20.0 if nome == "nana_mangue" else -22.0


func teleportar(nome: String, posicao: Vector2) -> void:
	super.teleportar(nome, posicao)
	_ultimo_firme = posicao
	if not _visitou.has(nome):
		_visitou[nome] = true
		if _dados.has("chegada_" + nome.trim_prefix("nana_")):
			_chegou.call_deferred(nome)


func _chegou(nome: String) -> void:
	await get_tree().create_timer(0.45).timeout
	await _falar("chegada_" + nome.trim_prefix("nana_"))


# ------------------------------------------------------------------ objetos dos mapas

func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	match c:
		"p":
			marcas["p_" + lugar] = base - Vector2(0, 2)
		"V":
			var v := _criar_interativo("res://arte/nana_velhinha.png", 5, base, Vector2(12, 6), -38.0)
			v.animar = true
			v.olhar_para_jogador = true
			if lugar == "nana_brejo":
				_velhinha = v
				v.interagiu.connect(_falar_com_velhinha)
			else:
				_velhinha_mangue = v
				v.interagiu.connect(_falar_com_velhinha_do_mangue)
		"g":
			_criar_garca(lugar, base)
		"G":
			_criar_sapo_pulador(lugar, base)
		"W", "E":
			_criar_folha(lugar, celula, base, c == "E")
		"s":
			_criar_sapo(lugar, base)
		"K":
			_criar_cenario("res://arte/nana_bambu.png", Vector2(26, 8), base)
		"X":
			_criar_cenario("res://arte/nana_mangue.png", Vector2(14, 8), base)
		"j":
			_lascas = _criar_interativo("res://arte/nana_lascas.png", 2, base, Vector2(14, 6), -20.0)
			_lascas.interagiu.connect(_no_bambu_rachado)
		"F":
			_toco_faca = _criar_interativo("res://arte/nana_faca.png", 2, base, Vector2(12, 8), -30.0)
			_toco_faca.interagiu.connect(_no_toco_da_faca)
		"T":
			var t := _criar_interativo("res://arte/nana_taboa.png", 2, base, Vector2(16, 10), -34.0)
			t.interagiu.connect(_na_taboa)
			_taboas.append(t)
		"k":
			_criar_caranguejo(lugar, celula, base)
		"u":
			var moita := _criar_interativo("res://arte/nana_flores.png", 2, base, Vector2(12, 6), -22.0)
			moita.interagiu.connect(_colher_flores.bind(moita))
		"b":
			# a poça de barro mole da ilhota (Adé pisa por cima; o barro bom está ali)
			_barro = _criar_interativo("res://arte/nana_poca_barro.png", 2, base + Vector2(8, -1), Vector2(2, 2), -22.0)
			_barro.z_index = -3
			(_barro.get_node("Alcance").shape as CircleShape2D).radius = 24.0
			_barro.interagiu.connect(_no_barro)
			_balao_barro = Sprite2D.new()
			_balao_barro.texture = preload("res://arte/balao.png")
			_balao_barro.z_index = 5
			add_child(_balao_barro)
		"O":
			_pedra = _criar_interativo("res://arte/obj_pedras.png", 1, base, Vector2(14, 6), -24.0)
			_pedra.interagiu.connect(_na_pedra)
			(_pedra.get_node("Alcance").shape as CircleShape2D).radius = 26.0
			# um balão sempre boiando em cima da pedra enquanto tem algo para fazer nela
			_balao_pedra = Sprite2D.new()
			_balao_pedra.texture = preload("res://arte/balao.png")
			_balao_pedra.position = base + Vector2(0, -26)
			_balao_pedra.z_index = 5
			add_child(_balao_pedra)
		"N":
			_lugar_nana = _criar_interativo("res://arte/nana_lugar.png", 2, base, Vector2(22, 8), -30.0)
			_lugar_nana.interagiu.connect(_no_lugar_de_nana)
			_luz(base + Vector2(0, -12), Color(0.8, 0.6, 1.0), 0.5, 1.2, false)
		"x":
			_chegada_velhinha = base
		"w":
			_criar_vitoria_regia(base, celula)
		# a vegetação do brejo, do mangue e da lagoa (no lugar das árvores do quintal)
		"R":
			_criar_cenario("res://arte/nana_arvore_velha.png", Vector2(12, 8), base)
		"M":
			if lugar == "nana_mangue":
				_criar_cenario("res://arte/nana_mangue.png", Vector2(14, 8), base)
			else:
				_criar_cenario("res://arte/nana_arvore_velha.png", Vector2(12, 8), base)
		"q", "J", "Y":
			_criar_cenario("res://arte/nana_buriti.png", Vector2(6, 6), base)
		"n":
			_criar_cenario("res://arte/nana_aninga.png", Vector2(10, 6), base)
		"f", "i":
			var j := _criar_cenario("res://arte/nana_juncos.png", Vector2.ZERO, base)
			j.hframes = 2
			j.frame = 1 if c == "f" else 0
		"h":
			_criar_aguape(base, celula)
		">":
			var area := Area2D.new()
			area.collision_layer = 0
			area.collision_mask = 2
			area.position = base - Vector2(0, TILE / 2.0)
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2(14, 12)
			forma.shape = ret
			area.add_child(forma)
			area.body_entered.connect(_sair)
			add_child(area)
			var fecha := _criar_cenario("res://arte/nana_moita.png", Vector2(16, 14), base)
			fecha.hframes = 2
			_saida_moita.append(fecha)
		_:
			super._criar_objeto(lugar, c, celula, base, chao)


## Na lama o passo chapinha; em cima da vitória-régia, faz "plop".
func som_do_chao(pos: Vector2) -> Array:
	var l := _letra_em(pos)
	if l in LAMA or l == "m":
		return ["passo_lama", -14.0]
	if l == "y":
		return ["folha_pisa", -16.0]
	return super.som_do_chao(pos)


## A camada da maré (água por cima das raízes do mangue) começa invisível.
func _camada_terreno(origem: Vector2, i: int, camada: TileMapLayer) -> void:
	if i >= 2:
		camada.material = _material_agua()        # a água escura mexe (brejo, mangue e lagoa)
	if i == 3:
		camada.modulate.a = 0.0
		if origem == LUGARES_NANA["nana_mangue"]["origem"]:
			_camada_mare = camada


## A água parada mexe devagar: faixas de luz que passam e somem, em pixels (sem borrar a arte).
const SHADER_AGUA := """
shader_type canvas_item;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 c = COLOR;                         // (a cor do bloco já vem com a textura)
	vec2 p = floor(mundo);
	float onda = sin(p.x * 0.31 + TIME * 1.6 + sin(p.y * 0.23 + TIME * 0.7) * 2.2)
		* sin(p.y * 0.47 - TIME * 1.1 + p.x * 0.05);
	float luz = step(0.72, onda) * 0.09 + step(0.9, onda) * 0.09;
	float sombra = step(onda, -0.8) * 0.05;
	c.rgb += vec3(luz * 0.75, luz, luz * 0.95) * c.a - vec3(sombra) * c.a;
	COLOR = c;
}
"""
var _shader_agua: ShaderMaterial


func _material_agua() -> ShaderMaterial:
	if not _shader_agua:
		var sh := Shader.new()
		sh.code = SHADER_AGUA
		_shader_agua = ShaderMaterial.new()
		_shader_agua.shader = sh
	return _shader_agua


## Anéis dos pingos de chuva abrindo na água.
var _agua_de := {}              # lugar → células de água escura
var _proximo_pingo := 0.0
var _tex_anel: ImageTexture


func _pingos_na_agua(delta: float) -> void:
	var celulas: Array = _agua_de.get(lugar_atual, [])
	if celulas.is_empty():
		return
	_proximo_pingo -= delta
	if _proximo_pingo > 0.0:
		return
	var forte := lugar_atual == "nana_lagoa" and _chuva_forte
	_proximo_pingo = randf_range(0.03, 0.08) if forte else randf_range(0.08, 0.2)
	var camera: Camera2D = jogador.get_node("Camera")
	var centro := camera.get_screen_center_position()
	var origem: Vector2 = lugares[lugar_atual]["origem"]
	for tentativa in 6:                    # só onde aparece na tela
		var cel: Vector2i = celulas[randi() % celulas.size()]
		var pos := origem + Vector2(cel) * TILE + Vector2(randf_range(2, 14), randf_range(2, 14))
		if absf(pos.x - centro.x) < 140 and absf(pos.y - centro.y) < 125:
			_anel(pos)
			return


func _anel(pos: Vector2) -> void:
	if not _tex_anel:
		var img := Image.create(9, 5, false, Image.FORMAT_RGBA8)
		for x in 9:
			for y in 5:
				var dx := (x - 4) / 4.0
				var dy := (y - 2) / 2.0
				var r := dx * dx + dy * dy
				if r > 0.55 and r < 1.15:
					img.set_pixel(x, y, Color(0.75, 0.88, 0.85, 0.8))
		_tex_anel = ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.texture = _tex_anel
	s.position = pos
	s.z_index = -3
	s.scale = Vector2(0.3, 0.3)
	add_child(s)
	var t := create_tween()
	t.tween_property(s, "scale", Vector2(1.2, 1.2), 0.55)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.55)
	t.tween_callback(s.queue_free)


func _guardar_celulas() -> void:
	var brejo: PackedStringArray = _mapas["nana_brejo"]
	for y in brejo.size():
		for x in brejo[y].length():
			if brejo[y][x] == "L":
				_lama_funda.append(Vector2i(x, y))
				var beira := false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if _letra(brejo, x + dx, y + dy) == "l":
							beira = true
				if beira:
					_lama_beira.append(Vector2i(x, y))
	for lugar in lugares:
		var m: PackedStringArray = _mapas[lugar]
		var lista := []
		for y in m.size():
			for x in m[y].length():
				if m[y][x] == "v" or m[y][x] == "y":
					lista.append(Vector2i(x, y))
		_agua_de[lugar] = lista
	var mangue: PackedStringArray = _mapas["nana_mangue"]
	for y in mangue.size():
		for x in mangue[y].length():
			if mangue[y][x] == "z":
				_celulas_mare.append(Vector2i(x, y))


## Aguapé boiando na água escura, com flor lilás de vez em quando.
func _criar_aguape(base: Vector2, celula: Vector2i) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_aguape.png")
	s.hframes = 2
	s.frame = (celula.x + celula.y) % 2
	s.position = base - Vector2(0, TILE / 2.0) + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	s.z_index = -3
	add_child(s)
	var t := create_tween().set_loops()
	t.tween_property(s, "position:x", s.position.x + 1.5, 1.8 + randf()).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "position:x", s.position.x, 1.8 + randf()).set_trans(Tween.TRANS_SINE)


func _criar_vitoria_regia(base: Vector2, celula: Vector2i) -> void:
	var s := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = TEX_TERRENO
	at.region = Rect2((5 + (celula.x + celula.y) % 2) * TILE, 7 * TILE, TILE, TILE)
	s.texture = at
	s.position = base - Vector2(0, TILE / 2.0)
	s.z_index = -3
	add_child(s)
	var t := create_tween().set_loops()
	t.tween_property(s, "position:y", s.position.y + 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "position:y", s.position.y, 1.4).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ inventário: pote, lâmina, flores e o troféu

func _criar_inventario() -> void:
	for n in _hud_oferendas:
		n.visible = false
	var camada: CanvasLayer = _icone_buzio.get_parent()
	var ordem := ["pote", "lamina", "flores", "ibiri"]
	for i in ordem.size():
		var caixa := TextureRect.new()
		caixa.texture = preload("res://arte/hud_slot.png")
		caixa.position = Vector2(6 + i * 19, 6)
		camada.add_child(caixa)
		if ordem[i] == "ibiri":
			_moldura_trofeu = caixa
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX_NANA_ITENS
		atlas.region = Rect2(i * 12, 0, 12, 12)
		var item := TextureRect.new()
		item.texture = atlas
		item.position = caixa.position + Vector2(3, 3)
		item.pivot_offset = Vector2(6, 6)
		item.modulate = COR_ITEM_FALTA
		camada.add_child(item)
		_slots_nana[ordem[i]] = item


func _acender_slot(id: String, texto := "") -> void:
	var icone: TextureRect = _slots_nana[id]
	icone.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(1.6, 1.6), 0.12)
	t.tween_property(icone, "scale", Vector2.ONE, 0.18)
	Jogo.tocar_som("pegar_item", -4.0)
	if texto != "":
		_mostrar_aviso("Você pegou: " + texto)


# ------------------------------------------------------------------ o chão: lama que prende e lama que afunda

func _chao_de_ade(delta: float) -> void:
	if not jogador.pode_mover or _voltando:
		jogador.fator_chao = 1.0
		_tempo_no_fundo = 0.0
		return
	var letra := _letra_em(jogador.global_position + Vector2(0, -3))
	# o chão de lama (m) prende só um pouco; a lama do brejo e as raízes do mangue prendem mais
	jogador.fator_chao = 0.6 if letra in LAMA else (0.85 if letra == "m" else 1.0)
	if lugar_atual == "nana_brejo":
		if letra == "L":
			_tempo_no_fundo += delta
			if _tempo_no_fundo > 0.25:
				_afundar_ade()
		else:
			_tempo_no_fundo = 0.0
	elif lugar_atual == "nana_mangue" and letra != "z" and letra != " ":
		_ultimo_firme = jogador.global_position
	elif lugar_atual == "nana_lagoa":
		_na_travessia(letra, delta)


func _afundar_ade() -> void:
	_voltando = true
	_tempo_no_fundo = 0.0
	jogador.congelar(true)
	Jogo.tocar_som("lama_afunda", -2.0)
	var sp: Sprite2D = jogador.sprite
	var y0 := sp.position.y
	_lama_espirra(jogador.global_position)
	var t := create_tween()
	t.tween_property(sp, "position:y", y0 + 14.0, 0.8).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sp, "modulate", Color(0.45, 0.32, 0.24), 0.8)
	await t.finished
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.35)
	await c.finished
	sp.position.y = y0
	sp.modulate = Color.WHITE
	axe -= 1
	_atualizar_axe()
	teleportar("nana_brejo", _ponto_volta.get("nana_brejo", jogador.global_position))
	for g in _garcas:                     # as garças voltam a pousar onde dá pé
		g["foi"] = false
		g["s"].position = g["casa"]
		g["s"].modulate.a = 1.0
		g["s"].frame = 0
	await get_tree().create_timer(0.3).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.35)
	await c2.finished
	if axe <= 0:
		_sem_axe()                        # já em chão firme: Exu pode aparecer ali
		return
	_voltando = false
	if not _afundou_uma_vez:
		_afundou_uma_vez = true
		await _falar("afundou")
	else:
		jogador.congelar(false)
		_mostrar_aviso("Pise onde as garças pisam.")
	_invulneravel = 0.6


func _lama_espirra(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos + Vector2(0, -4)
	f.z_index = 6
	f.amount = 16
	f.lifetime = 0.7
	f.one_shot = true
	f.explosiveness = 0.9
	f.spread = 70.0
	f.direction = Vector2(0, -1)
	f.gravity = Vector2(0, 160)
	f.initial_velocity_min = 30.0
	f.initial_velocity_max = 60.0
	f.scale_amount_min = 1.5
	f.scale_amount_max = 2.5
	f.color = Color(0.36, 0.26, 0.2)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.2).timeout.connect(f.queue_free)


## Bolhas sobem da lama funda, sobretudo na beira do caminho firme e perto de Adé: elas crescem devagar,
## ficam um tempo e só depois estouram — quem olha com calma vê por onde NÃO pisar até a próxima garça.
func _bolhas(delta: float) -> void:
	if lugar_atual != "nana_brejo" or _lama_funda.is_empty():
		return
	_proxima_bolha -= delta
	if _proxima_bolha > 0.0 or _bolhas_vivas >= MAX_BOLHAS:
		return
	_proxima_bolha = randf_range(0.12, 0.28)
	var origem: Vector2 = lugares["nana_brejo"]["origem"]
	var cel: Vector2i
	var perto := _lama_beira.filter(func(c: Vector2i):
		return (origem + Vector2(c) * TILE + Vector2(8, 8)).distance_to(jogador.global_position) < 90.0)
	if not perto.is_empty() and randf() < 0.8:
		cel = perto[randi() % perto.size()]
	else:
		cel = _lama_funda[randi() % _lama_funda.size()]
	var chave := "%d,%d" % [cel.x, cel.y]
	if _bolha_em.has(chave):
		return
	_bolha_em[chave] = true
	_bolhas_vivas += 1
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_bolha.png")
	s.hframes = 5
	s.position = origem + Vector2(cel.x * TILE + TILE / 2.0, cel.y * TILE + TILE / 2.0) \
		+ Vector2(randf_range(-2, 2), randf_range(-2, 2))
	s.z_index = -4
	add_child(s)
	var t := create_tween()
	for q in [1, 2, 3]:                    # cresce devagar...
		t.tween_interval(0.4)
		t.tween_callback(func(): s.frame = q)
	# ...fica um tempo inchada, balançando...
	t.tween_property(s, "scale", Vector2(1.12, 0.92), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "scale", Vector2(0.94, 1.08), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "scale", Vector2(1.1, 0.94), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	# ...e estoura
	t.tween_callback(func(): s.frame = 4)
	t.tween_property(s, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		_bolhas_vivas -= 1
		_bolha_em.erase(chave)
		s.queue_free())


# ------------------------------------------------------------------ garças e sapos

func _criar_garca(lugar: String, base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_garca.png")
	s.hframes = 4
	s.offset = Vector2(0, -11)
	s.position = base - Vector2(0, 3)
	s.flip_h = randf() < 0.5
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	sombra.scale = Vector2(0.8, 0.8)
	s.add_child(sombra)
	mundo.add_child(s)
	_garcas.append({"s": s, "casa": s.position, "foi": false, "fase": randf() * 10.0, "lugar": lugar})


func _mover_garcas(_delta: float) -> void:
	for g in _garcas:
		var s: Sprite2D = g["s"]
		if g["foi"]:
			s.frame = 2 + int(_tempo * 8.0) % 2
			continue
		s.frame = 1 if fmod(_tempo + g["fase"], 5.0) < 1.2 else 0      # de vez em quando, pesca
		if g["lugar"] == lugar_atual and jogador.pode_mover and s.position.distance_to(jogador.global_position) < 20.0:
			g["foi"] = true
			Jogo.tocar_som("asas", -8.0)
			var lado := 1.0 if s.position.x >= jogador.global_position.x else -1.0
			s.flip_h = lado < 0.0
			var t := create_tween()
			t.tween_property(s, "position", s.position + Vector2(lado * 70.0, -90.0), 1.6)
			t.parallel().tween_property(s, "modulate:a", 0.0, 1.6).set_delay(0.6)


func _criar_sapo(lugar: String, base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_sapo.png")
	s.hframes = 3
	s.offset = Vector2(0, -5)
	s.position = base - Vector2(0, 2)
	mundo.add_child(s)
	_sapos.append({"s": s, "casa": s.position, "lugar": lugar, "pulando": false, "fase": randf() * 6.0})


## Sapos-puladores do bambuzal: de tempos em tempos coaxam, a sombra aparece no chão onde vão cair e eles pulam;
## se Adé estiver perto, pulam em cima dele — cair debaixo do sapo leva um búzio de axé. Basta sair da sombra.
var _puladores: Array = []      # {s, sombra, casa, lugar, espera, no_ar}
const PULO_ALCANCE := 44.0


func _criar_sapo_pulador(lugar: String, base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_sapo.png")
	s.hframes = 3
	s.offset = Vector2(0, -5)
	s.position = base - Vector2(0, 2)
	s.scale = Vector2(1.25, 1.25)        # um pouco maior que os sapos de enfeite
	mundo.add_child(s)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.modulate = Color(0, 0, 0, 0)
	sombra.z_index = -3
	add_child(sombra)
	_puladores.append({"s": s, "sombra": sombra, "casa": s.position, "lugar": lugar,
		"espera": randf_range(0.8, 2.5), "no_ar": false})


func _mover_puladores(delta: float) -> void:
	for p in _puladores:
		if p["no_ar"] or p["lugar"] != lugar_atual:
			continue
		var s: Sprite2D = p["s"]
		if not jogador.pode_mover or _voltando:
			s.frame = 0
			continue
		p["espera"] -= delta
		s.frame = 1 if p["espera"] < 0.5 else 0          # coaxa antes de pular
		if p["espera"] <= 0.0:
			_pular(p)


func _pular(p: Dictionary) -> void:
	var s: Sprite2D = p["s"]
	var ade := jogador.global_position
	var alvo: Vector2
	var longe_de_casa: bool = s.position.distance_to(p["casa"]) > 90.0
	if longe_de_casa:
		alvo = s.position + (p["casa"] - s.position).limit_length(PULO_ALCANCE)   # não vai longe: volta para o seu canto
	elif s.position.distance_to(ade) < 80.0:
		alvo = s.position + (ade - s.position).limit_length(PULO_ALCANCE)      # pula em cima de Adé
	else:
		var casa: Vector2 = p["casa"]
		alvo = casa + Vector2(randf_range(-28, 28), randf_range(-20, 20))       # passeia perto de casa
		alvo = s.position + (alvo - s.position).limit_length(PULO_ALCANCE)
	if not _pode_pousar(alvo):
		p["espera"] = randf_range(0.4, 0.9)
		return
	p["no_ar"] = true
	s.flip_h = alvo.x < s.position.x
	var sombra: Sprite2D = p["sombra"]
	sombra.position = alvo
	sombra.scale = Vector2(0.6, 0.6)
	# a sombra aparece onde o sapo vai cair (dá tempo de sair)
	var aviso := create_tween()
	aviso.tween_property(sombra, "modulate:a", 0.45, 0.35)
	aviso.parallel().tween_property(sombra, "scale", Vector2(1.1, 1.1), 0.35)
	await aviso.finished
	if not is_instance_valid(s):
		return
	s.frame = 2
	s.z_index = 2
	som_perto("sapo_pulo", s.position, -8.0)
	var de := s.position
	var t := create_tween()
	t.tween_method(func(u: float):
		s.position = de.lerp(alvo, u) + Vector2(0, -sin(u * PI) * 18.0), 0.0, 1.0, 0.45)
	await t.finished
	if not is_instance_valid(s):
		return
	s.frame = 0
	s.z_index = 0
	create_tween().tween_property(sombra, "modulate:a", 0.0, 0.15)
	_lama_espirra(alvo + Vector2(0, 2))
	if lugar_atual == p["lugar"] and jogador.global_position.distance_to(alvo) < 11.0 and _invulneravel <= 0.0 \
			and jogador.pode_mover and not _voltando:
		Jogo.tocar_som("sapo_coaxa", -4.0)
		_tomar_dano(alvo)
	p["no_ar"] = false
	p["espera"] = randf_range(1.2, 2.6)


## ------------------------------------------------------------------ a travessia de vitórias-régias (lagoa)
## Na água "y" não tem parede: só dá para ficar em cima das vitórias-régias gigantes, que andam de um lado para o
## outro (cada fileira num ritmo) e levam Adé junto. As marcadas com "E" afundam se Adé ficar parado em cima
## (vão escurecendo; depois voltam a boiar). Pisou fora, tchibum: perde um búzio de axé e volta ao último chão firme.
var _folhas: Array = []         # {s, de, ate, vel, fase, afunda, peso, sumida, x_antes}
var _chao_firme_lagoa := Vector2.ZERO
var _tempo_na_agua := 0.0
const FOLHA_MEIA_LARGURA := 10.0
const FOLHA_MEIA_ALTURA := 6.0


func _criar_folha(lugar: String, celula: Vector2i, base: Vector2, afunda: bool) -> void:
	# a fileira vai de uma ponta à outra da água "y" desta linha
	var mapa: PackedStringArray = _mapas[lugar]
	var ini := celula.x
	while _letra(mapa, ini - 1, celula.y) == "y":
		ini -= 1
	var fim := celula.x
	while _letra(mapa, fim + 1, celula.y) == "y":
		fim += 1
	var origem: Vector2 = lugares[lugar]["origem"]
	var y := origem.y + celula.y * TILE + TILE / 2.0
	var de := origem.x + ini * TILE + 9.0
	var ate := origem.x + (fim + 1) * TILE - 9.0
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_vitoria_grande.png")
	s.hframes = 3
	s.frame = 1 if afunda == false and celula.y % 2 == 0 else 0
	s.position = Vector2(base.x, y)
	s.z_index = -2
	add_child(s)
	var vel := 16.0 + (celula.y % 3) * 7.0
	_folhas.append({"s": s, "de": de, "ate": ate, "vel": vel, "fase": randf(), "afunda": afunda,
		"peso": 0.0, "sumida": 0.0, "x_antes": s.position.x, "lugar": lugar,
		"xmin": origem.x + ini * TILE + 5.0, "xmax": origem.x + (fim + 1) * TILE - 5.0})


func _mover_folhas(delta: float) -> void:
	for f in _folhas:
		var s: Sprite2D = f["s"]
		f["x_antes"] = s.position.x
		if jogador.pode_mover or f["lugar"] != lugar_atual:
			var dist: float = maxf(1.0, f["ate"] - f["de"])
			f["fase"] += f["vel"] * delta / dist
			s.position.x = lerpf(f["de"], f["ate"], pingpong(f["fase"], 1.0))
		# afundando / voltando a boiar
		if f["sumida"] > 0.0:
			f["sumida"] -= delta
			if f["sumida"] <= 0.0:
				f["peso"] = 0.0
				create_tween().tween_property(s, "modulate:a", 1.0, 0.6)
		elif not _ade_em_cima(f):
			f["peso"] = maxf(0.0, f["peso"] - delta * 0.5)
		var p: float = f["peso"]
		if f["sumida"] <= 0.0:
			s.frame = 2 if p > 0.35 else (1 if not f["afunda"] and s.frame == 1 else 0)
			s.scale = Vector2(1.0 - p * 0.15, 1.0 - p * 0.15)
			s.modulate = Color(1.0 - p * 0.35, 1.0 - p * 0.3, 1.0 - p * 0.2, s.modulate.a)


func _ade_em_cima(f: Dictionary) -> bool:
	if f["lugar"] != lugar_atual or f["sumida"] > 0.0:
		return false
	var d: Vector2 = (jogador.global_position + Vector2(0, -3)) - f["s"].position
	return absf(d.x) <= FOLHA_MEIA_LARGURA and absf(d.y) <= FOLHA_MEIA_ALTURA


## Em cima da água da travessia: a folha leva Adé junto; sem folha embaixo, ele cai.
func _na_travessia(letra: String, delta: float) -> void:
	if letra != "y":
		if letra != " " and letra != "v":
			_chao_firme_lagoa = jogador.global_position
		_tempo_na_agua = 0.0
		return
	var folha: Dictionary = {}
	for f in _folhas:
		if _ade_em_cima(f):
			folha = f
			break
	if folha.is_empty():
		_tempo_na_agua += delta
		if _tempo_na_agua > 0.12:              # um tiquinho de folga entre uma folha e outra
			_cair_na_lagoa()
		return
	_tempo_na_agua = 0.0
	# a folha anda e leva Adé junto
	jogador.global_position.x = clampf(jogador.global_position.x + folha["s"].position.x - folha["x_antes"],
		folha["xmin"], folha["xmax"])          # a folha não leva Adé para dentro da margem
	if folha["afunda"]:
		folha["peso"] += delta / 2.2                # uns 2 segundos parado em cima e ela afunda
		if folha["peso"] >= 1.0:
			folha["sumida"] = 1.6
			var s: Sprite2D = folha["s"]
			create_tween().tween_property(s, "modulate:a", 0.0, 0.25)
			_respingo(s.position)
			_cair_na_lagoa()


func _cair_na_lagoa() -> void:
	if _voltando:
		return
	_voltando = true
	_tempo_na_agua = 0.0
	jogador.congelar(true)
	Jogo.tocar_som("agua_cai", -2.0)
	_respingo(jogador.global_position)
	var sp: Sprite2D = jogador.sprite
	var y0 := sp.position.y
	var t := create_tween()
	t.tween_property(sp, "position:y", y0 + 10.0, 0.35).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sp, "modulate:a", 0.0, 0.35)
	await t.finished
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.3)
	await c.finished
	sp.position.y = y0
	sp.modulate.a = 1.0
	axe -= 1
	_atualizar_axe()
	var volta: Vector2 = _chao_firme_lagoa if _chao_firme_lagoa != Vector2.ZERO else _ponto_volta.get("nana_lagoa", jogador.global_position)
	teleportar("nana_lagoa", volta)
	await get_tree().create_timer(0.25).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.35)
	await c2.finished
	if axe <= 0:
		_sem_axe()
		return
	_voltando = false
	_invulneravel = 0.8
	if not _nana.has("caiu_na_lagoa"):
		_nana["caiu_na_lagoa"] = true
		await _falar("caiu_na_lagoa")
	else:
		jogador.congelar(false)
		_mostrar_aviso("Tchibum! Espere a vitória-régia chegar perto.")


## O sapo só pousa onde dá pé: chão de lama ou grama, sem bambu, árvore ou parede.
func _pode_pousar(pos: Vector2) -> bool:
	var letra := _letra_em(pos + Vector2(0, -2))
	if not (letra in ANDAVEL):
		return false
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos + Vector2(0, -2)
	q.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


func _mover_sapos() -> void:
	for p in _sapos:
		var s: Sprite2D = p["s"]
		if p["pulando"]:
			continue
		s.frame = 1 if fmod(_tempo + p["fase"], 3.0) < 0.4 else 0       # o papo incha: coaxando
		if p["lugar"] == lugar_atual and s.position.distance_to(jogador.global_position) < 22.0:
			p["pulando"] = true
			Jogo.tocar_som("sapo_pulo", -12.0)
			var lado := 1.0 if s.position.x >= jogador.global_position.x else -1.0
			var destino: Vector2 = p["casa"] + Vector2(lado * 18.0, randf_range(-6, 6))
			if destino.distance_to(p["casa"]) < 4.0 or s.position.distance_to(p["casa"]) > 4.0:
				destino = p["casa"]
			var t := create_tween()
			t.tween_property(s, "position", (s.position + destino) / 2.0 + Vector2(0, -10), 0.18)
			t.tween_property(s, "position", destino, 0.18)
			t.tween_interval(1.2)
			t.tween_callback(func(): p["pulando"] = false)


# ------------------------------------------------------------------ 1) a velhinha e o pote

func _velhinha_chama() -> void:
	if not _velhinha:
		return
	_velhinha.olhar_para_jogador = true
	jogador.olhar_para(_velhinha.position)
	await _falar("velhinha_pedido")


func _falar_com_velhinha() -> void:
	if _nana.has("pote"):
		await _falar("velhinha_depois")
	else:
		await _falar("velhinha_pedido")


func _falar_com_velhinha_do_mangue() -> void:
	_falou_mangue = true
	await _falar("velhinha_mangue_depois" if _nana.has("viu_velhinha_mangue") else "velhinha_mangue")
	_nana["viu_velhinha_mangue"] = true


## No mangue, a velhinha chama Adé quando ele chega do outro lado.
func _perto_da_velhinha_do_mangue() -> void:
	if _falou_mangue or not _velhinha_mangue or lugar_atual != "nana_mangue" or not jogador.pode_mover:
		return
	if _velhinha_mangue.position.distance_to(jogador.global_position) < 56.0:
		_falou_mangue = true
		_falar_com_velhinha_do_mangue()


# ------------------------------------------------------------------ 2) o taboal: ferro não, bambu sim

func _no_toco_da_faca() -> void:
	if _nana.has("faca") or _nana.has("faca_foi"):
		await _falar("toco_vazio")
		return
	await _falar("faca_achou")


func _no_bambu_rachado() -> void:
	if _nana.has("lamina"):
		await _falar("lascas_depois")
		return
	await _falar("lamina")


func _na_taboa() -> void:
	if _nana.has("taboa_cortada"):
		return
	if _nana.has("lamina"):
		await _cortar_taboa()
	elif _nana.has("faca"):
		await _falar("faca_falha")
	else:
		await _falar("taboa_dura")


func _cortar_taboa() -> void:
	_nana["taboa_cortada"] = true
	jogador.congelar(true)
	for t in _taboas:
		Jogo.tocar_som("caminho", -10.0)
		t.sprite.frame = 1
		t.ativo = false
		t.get_node("Corpo/Forma").set_deferred("disabled", true)
		_folhas_de_taboa(t.position + Vector2(0, -14))
		await get_tree().create_timer(0.22).timeout
	await _falar("taboa_cortada")


func _folhas_de_taboa(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 12
	f.amount = 10
	f.lifetime = 1.0
	f.one_shot = true
	f.explosiveness = 0.9
	f.spread = 180.0
	f.gravity = Vector2(0, 50)
	f.initial_velocity_min = 15.0
	f.initial_velocity_max = 35.0
	f.scale_amount_min = 1.5
	f.scale_amount_max = 2.0
	f.color = Color(0.36, 0.6, 0.3)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)


# ------------------------------------------------------------------ 3) o mangue: a maré e os caranguejos

func _mover_mare(delta: float) -> void:
	if not _camada_mare:
		return
	# a maré só corre enquanto Adé pode andar (nada de ser levado no meio de uma conversa)
	if jogador.pode_mover and not _voltando:
		_mare_tempo += delta
	var dur: float = MARE[_mare]
	var u := clampf(_mare_tempo / dur, 0.0, 1.0)
	match _mare:
		"baixa":
			_camada_mare.modulate.a = 0.0
		"subindo":
			_camada_mare.modulate.a = u * 0.85
		"alta":
			_camada_mare.modulate.a = 0.85 + sin(_tempo * 2.0) * 0.05
		"descendo":
			_camada_mare.modulate.a = (1.0 - u) * 0.85
	if _mare_tempo >= dur:
		_mare_tempo = 0.0
		var proxima := {"baixa": "subindo", "subindo": "alta", "alta": "descendo", "descendo": "baixa"}
		_mare = proxima[_mare]
		match _mare:
			"subindo":
				if lugar_atual == "nana_mangue":
					Jogo.tocar_som("caminho", -16.0)
			"alta":
				_bloquear_mare(true)
			"descendo":
				_bloquear_mare(false)
	if _mare == "alta" and lugar_atual == "nana_mangue" and jogador.pode_mover and not _voltando:
		if _letra_em(jogador.global_position + Vector2(0, -3)) == "z":
			_mare_leva_ade()


func _bloquear_mare(alta: bool) -> void:
	var chao: TileMapLayer = _chaos["nana_mangue"]
	for cel in _celulas_mare:
		if alta:
			chao.set_cell(cel, 0, Vector2i(INVISIVEL, 0))
		else:
			chao.erase_cell(cel)


func _mare_leva_ade() -> void:
	_voltando = true
	jogador.congelar(true)
	Jogo.tocar_som("agua_cai", -2.0)
	_respingo(jogador.global_position)
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.4)
	await c.finished
	axe -= 1
	_atualizar_axe()
	teleportar("nana_mangue", _ultimo_firme)
	await get_tree().create_timer(0.3).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.4)
	await c2.finished
	if axe <= 0:
		_sem_axe()
		return
	_voltando = false
	_invulneravel = 1.0
	if not _mare_levou_uma_vez:
		_mare_levou_uma_vez = true
		await _falar("mare_levou")
	else:
		jogador.congelar(false)
		_mostrar_aviso("Espere a maré baixar.")


func _criar_caranguejo(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base - Vector2(0, 3)
	var s := Sprite2D.new()
	s.texture = preload("res://arte/nana_caranguejo.png")
	s.hframes = 3
	s.offset = Vector2(0, -5)
	a.add_child(s)
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 6.0
	forma.shape = circ
	forma.position = Vector2(0, -4)
	a.add_child(forma)
	mundo.add_child(a)
	var mapa: PackedStringArray = _mapas[lugar]
	var ini := celula
	while _letra(mapa, ini.x - 1, ini.y) == "z" and celula.x - ini.x < 4:
		ini.x -= 1
	var fim := celula
	while _letra(mapa, fim.x + 1, fim.y) == "z" and fim.x - celula.x < 4:
		fim.x += 1
	_caranguejos.append({"a": a, "s": s, "de": _base_celula(lugar, ini) - Vector2(0, 3),
		"ate": _base_celula(lugar, fim) - Vector2(0, 3), "vel": randf_range(22.0, 30.0), "fase": randf(), "lugar": lugar})


## Na maré baixa os caranguejos andam de lado pelas raízes; quando a água volta, se enfiam na lama.
func _mover_caranguejos() -> void:
	var fora := _mare == "baixa"
	for c in _caranguejos:
		var s: Sprite2D = c["s"]
		if not fora:
			s.frame = 2
			s.modulate.a = 0.0 if _mare == "alta" else 0.6
			continue
		s.modulate.a = 1.0
		var dist: float = maxf(1.0, c["de"].distance_to(c["ate"]))
		var u := pingpong(_tempo * c["vel"] / dist + c["fase"], 1.0)
		c["a"].position = c["de"].lerp(c["ate"], u)
		s.frame = int(_tempo * 8.0 + c["fase"] * 3.0) % 2
		if c["lugar"] == lugar_atual and _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
				and c["a"].overlaps_body(jogador):
			Jogo.tocar_som("caranguejo", -4.0)
			_tomar_dano(c["a"].global_position)


func _colher_flores(moita: Area2D) -> void:
	if _nana.has("flores"):
		await _falar("flores_depois")
		return
	await _falar("flores")
	moita.sprite.frame = 1


# ------------------------------------------------------------------ 4) a lagoa: o barro, a chuva no pote e a oferenda

func _no_barro() -> void:
	if _nana.get("pote", "") == "rachado":
		# Adé se abaixa e pega um punhado de barro
		jogador.congelar(true)
		jogador.olhar_para(_barro.position)
		var sp: Sprite2D = jogador.sprite
		var abaixa := create_tween()
		abaixa.tween_property(sp, "scale", Vector2(1.1, 0.82), 0.18)
		abaixa.parallel().tween_property(sp, "position:y", sp.position.y + 3.0, 0.18)
		abaixa.tween_interval(0.35)
		abaixa.tween_property(sp, "scale", Vector2.ONE, 0.18)
		abaixa.parallel().tween_property(sp, "position:y", sp.position.y, 0.18)
		_lama_espirra(_barro.position + Vector2(0, -2))
		await abaixa.finished
		await _falar("barro_conserta")
	else:
		await _falar("barro_depois")


func _na_pedra() -> void:
	match _nana.get("pote", ""):
		"rachado":
			await _falar("pedra_rachado")
		"vazio":
			await _falar("pedra_coloca")
			_nana["pote"] = "na_pedra"
			_enchendo = 0.0
			_slots_nana["pote"].modulate = COR_ITEM_FALTA
			_pote_na_pedra = Sprite2D.new()
			_pote_na_pedra.texture = preload("res://arte/nana_pote.png")
			_pote_na_pedra.hframes = 4
			_pote_na_pedra.frame = 1
			_pote_na_pedra.offset = Vector2(0, -7)
			_pote_na_pedra.position = _pedra.position + Vector2(0, -7)
			_pote_na_pedra.z_index = 1
			mundo.add_child(_pote_na_pedra)
		"na_pedra":
			_mostrar_aviso("Ainda está enchendo... A chuva não tem pressa.")
		"pronto":
			_nana["pote"] = "cheio"
			_pote_na_pedra.queue_free()
			_pote_na_pedra = null
			_acender_slot("pote", _dados["nomes"]["pote"])
		_:
			await _falar("pedra_depois")


## A poça de barro: balão boiando enquanto o pote está rachado, e bolhinhas subindo de vez em quando.
func _animar_poca_barro(delta: float) -> void:
	if not _barro or lugar_atual != "nana_lagoa":
		if _balao_barro:
			_balao_barro.visible = false
		return
	_balao_barro.visible = _nana.get("pote", "") == "rachado" and not $Dialogo.ativo and not _barro.balao.visible
	_balao_barro.position = _barro.position + Vector2(0, -22 + round(sin(_tempo * 3.0 + 1.0) * 1.5))
	_proxima_bolha_barro -= delta
	if _proxima_bolha_barro > 0.0:
		return
	_proxima_bolha_barro = randf_range(0.9, 2.0)
	var b := Sprite2D.new()
	b.texture = preload("res://arte/nana_bolha.png")
	b.hframes = 5
	b.scale = Vector2(0.7, 0.7)
	b.position = _barro.position + Vector2(randf_range(-9, 9), randf_range(-11, -5))
	b.z_index = -2
	add_child(b)
	var t := create_tween()
	for q in [1, 2, 3, 4]:
		t.tween_interval(0.35)
		t.tween_callback(func(): b.frame = q)
	t.tween_property(b, "modulate:a", 0.0, 0.2)
	t.tween_callback(b.queue_free)


## O balão da pedra aparece enquanto Adé tem o que fazer nela (deixar o pote, buscar o pote cheio),
## some enquanto a chuva enche o pote e depois que o pote cheio já foi pego.
func _atualizar_balao_pedra() -> void:
	if not _balao_pedra:
		return
	var estado_pote: String = _nana.get("pote", "")
	_balao_pedra.visible = estado_pote in ["rachado", "vazio", "pronto"] and lugar_atual == "nana_lagoa" \
		and not $Dialogo.ativo and not _pedra.balao.visible
	_balao_pedra.position.y = _pedra.position.y - 26 + round(sin(_tempo * 3.0) * 1.5)


func _encher_pote(delta: float) -> void:
	if _nana.get("pote", "") != "na_pedra" or not _pote_na_pedra:
		return
	_enchendo += delta
	_pote_na_pedra.frame = 1 + mini(2, int(_enchendo / 2.5))
	if _enchendo >= 7.5:
		_nana["pote"] = "pronto"
		Jogo.tocar_som("buzio", -6.0)
		_mostrar_aviso("O pote encheu de água da chuva!")


func _no_lugar_de_nana() -> void:
	if _nana.has("oferenda"):
		if _nana_sprite and estado != "livre":
			await _falar("nana_de_novo")
		else:
			await _falar("lugar_depois")
		return
	var faltam := []
	if _nana.get("pote", "") != "cheio":
		faltam.append(_dados["nomes"]["pote"])
	if not _nana.has("flores"):
		faltam.append(_dados["nomes"]["flores"])
	if faltam.is_empty():
		await _falar("oferenda")
		if _pendente == "velhinha_vem":
			_pendente = ""
			await _velhinha_vem()
	else:
		var linha: Dictionary = _dados["lugar_falta"][0].duplicate()
		linha["pt"] = linha["pt"].replace("{faltam}", _juntar(faltam))
		await _falar_linhas([linha])


func _fazer_oferenda() -> void:
	_nana["oferenda"] = true
	_lugar_nana.sprite.frame = 1
	_lugar_nana.ativo = false
	for id in OFERENDAS:
		_slots_nana[id].modulate = COR_ITEM_FALTA
	_luz(_lugar_nana.position + Vector2(0, -12), Color(0.85, 0.65, 1.0), 0.5, 1.2, true)
	Jogo.tocar_som("buzio", -2.0)
	# a chuva engrossa e o céu escurece
	_chuva_forte = true
	_proximo_raio = 1.5
	_chuva.amount = 320
	_volume_chuva(-14.0, 1.5)
	create_tween().tween_property(_noite, "color", Color(0.42, 0.42, 0.58), 1.5)


## A velhinha chega devagar pelo caminho da lagoa... e era Nanã.
func _velhinha_vem() -> void:
	jogador.congelar(true)
	var v := _criar_interativo("res://arte/nana_velhinha.png", 5, _chegada_velhinha + Vector2(0, 40), Vector2(12, 6), -38.0)
	v.ativo = false
	v.animar = false
	v.olhar_para_jogador = false
	v.modulate.a = 0.0
	v.get_node("Corpo/Forma").set_deferred("disabled", true)
	var perto := jogador.global_position + Vector2(-22 if _chegada_velhinha.x < jogador.global_position.x else 22, 14)
	var anda := create_tween().set_loops()
	anda.tween_callback(func(): v.sprite.frame = 2).set_delay(0.3)
	anda.tween_callback(func(): v.sprite.frame = 3).set_delay(0.3)
	var t := create_tween()
	t.tween_property(v, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(v, "position", _chegada_velhinha, 2.0)
	t.tween_property(v, "position", perto, v.position.distance_to(perto) / 16.0 + 1.0)
	jogador.olhar_para(_chegada_velhinha)
	await t.finished
	anda.kill()
	v.sprite.frame = 0
	v.sprite.flip_h = jogador.global_position.x < v.position.x
	jogador.olhar_para(v.position)
	await get_tree().create_timer(0.4).timeout
	await _falar("velhinha_lagoa_de_novo" if _repetindo else "velhinha_lagoa")
	jogador.congelar(true)
	v.sprite.frame = 4                         # ela olha para cima, para a chuva
	await get_tree().create_timer(0.8).timeout
	await _revelar(v)
	if _repetindo:
		await _falar("nana_reencontro")
		await _abraco()
		await _falar("nana_despedida")
	else:
		await _falar("nana")
	await _nana_vai_embora()


func _revelar(v: Area2D) -> void:
	_tremer()
	Jogo.tocar_som("caminho", -2.0)
	_brilho_lilas(v.position + Vector2(0, -16))
	var clarao := create_tween()
	clarao.tween_property(_cortina, "color", Color(0.9, 0.85, 1.0, 0.85), 0.35)
	await clarao.finished
	_nana_sprite = Sprite2D.new()
	_nana_sprite.texture = preload("res://arte/nana_anim.png")
	_nana_sprite.hframes = 7
	_nana_sprite.offset = Vector2(0, -22)
	_nana_sprite.position = v.position
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	_nana_sprite.add_child(sombra)
	mundo.add_child(_nana_sprite)
	_anim_nana = "parada"
	v.queue_free()
	_luz(_nana_sprite.position + Vector2(0, -20), Color(0.85, 0.7, 1.0), 0.35, 1.0, true)
	await get_tree().create_timer(0.3).timeout
	var volta := create_tween()
	volta.tween_property(_cortina, "color", Color(0, 0, 0, 0), 0.9)
	await volta.finished
	_anim_nana = ""
	_nana_sprite.frame = 4                    # o ibiri erguido
	await get_tree().create_timer(1.0).timeout
	_anim_nana = "parada"


func _brilho_lilas(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 12
	f.amount = 30
	f.lifetime = 1.6
	f.one_shot = true
	f.explosiveness = 0.7
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 10.0
	f.spread = 180.0
	f.gravity = Vector2(0, -20)
	f.initial_velocity_min = 10.0
	f.initial_velocity_max = 30.0
	f.scale_amount_min = 1.0
	f.scale_amount_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.85, 1.0))
	g.set_color(1, Color(0.7, 0.5, 0.95, 0.0))
	f.color_ramp = g
	add_child(f)
	f.emitting = true
	get_tree().create_timer(2.5).timeout.connect(f.queue_free)


## Na fase repetida, Adé agradece e os dois se abraçam.
func _abraco() -> void:
	jogador.congelar(true)
	var meio: Vector2 = (jogador.global_position + _nana_sprite.position) / 2.0
	jogador.olhar_para(_nana_sprite.position)
	var vai := create_tween()
	vai.tween_property(jogador, "global_position", meio + Vector2(0, 4), 0.5)
	vai.parallel().tween_property(_nana_sprite, "position", meio, 0.5)
	await vai.finished
	var abraco := Sprite2D.new()
	abraco.texture = preload("res://arte/nana_abraco.png")
	abraco.hframes = 2
	abraco.offset = Vector2(0, -24)
	abraco.position = meio + Vector2(0, 4)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	abraco.add_child(sombra)
	mundo.add_child(abraco)
	jogador.visible = false
	_nana_sprite.visible = false
	Jogo.tocar_som("buzio", -4.0)
	for i in 6:
		abraco.frame = 1 if i % 2 == 0 else 0
		if i == 2:
			_brilho_lilas(abraco.position + Vector2(0, -40))
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(0.4).timeout
	abraco.queue_free()
	jogador.visible = true
	_nana_sprite.visible = true
	var volta := create_tween()
	volta.tween_property(_nana_sprite, "position", meio + Vector2(0, -10), 0.4)
	await volta.finished
	jogador.olhar_para(_nana_sprite.position)


func _nana_vai_embora() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.4).timeout
	# Nanã volta para a lagoa, devagar, e some na água
	_anim_nana = ""
	var lagoa: Vector2 = _lugar_nana.position + Vector2(0, -44)
	var anda := create_tween().set_loops()
	anda.tween_callback(func(): _nana_sprite.frame = 5).set_delay(0.3)
	anda.tween_callback(func(): _nana_sprite.frame = 6).set_delay(0.3)
	var t := create_tween()
	t.tween_property(_nana_sprite, "position", lagoa, _nana_sprite.position.distance_to(lagoa) / 18.0 + 0.5)
	t.parallel().tween_property(_nana_sprite, "modulate:a", 0.0, 2.6).set_delay(1.0)
	await t.finished
	anda.kill()
	_respingo(lagoa)
	_brilho_lilas(lagoa + Vector2(0, -10))
	_nana_sprite.visible = false
	# a chuva acalma
	_nana["acalmou"] = true
	_chuva_forte = false
	_chuva.amount = 70
	_volume_chuva(-28.0, 2.5)
	cor_fora = COR_DEPOIS
	create_tween().tween_property(_noite, "color", COR_DEPOIS, 2.0)
	await get_tree().create_timer(1.0).timeout
	_abrir_saida()
	estado = "livre"
	jogador.congelar(false)
	_mostrar_aviso("A chuva acalmou e um caminho abriu ao norte. Volte para o mapa.")


func _abrir_saida() -> void:
	Jogo.tocar_som("caminho", -4.0)
	for m in _saida_moita:
		var t := create_tween()
		t.tween_property(m, "modulate:a", 0.0, 0.6)
		t.tween_callback(m.queue_free)
	for corpo in get_children():
		if corpo is StaticBody2D:
			for m in _saida_moita:
				if corpo.position == m.position:
					corpo.queue_free()


func _ganhar_trofeu() -> void:
	Jogo.trofeus["nana"] = "Ibiri de Nanã"
	_nana["trofeu"] = true
	var icone: TextureRect = _slots_nana["ibiri"]
	icone.modulate = Color.WHITE
	_moldura_trofeu.modulate = Color(1.0, 0.85, 0.35)
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(2.0, 2.0), 0.2)
	t.tween_property(icone, "scale", Vector2.ONE, 0.3)
	var brilho := create_tween().set_loops()
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.95, 0.6), 0.6)
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.78, 0.3), 0.6)
	Jogo.tocar_som("buzio", 0.0)
	if Jogo.assentados.has("nana"):
		_mostrar_aviso("O Ibiri de Nanã de novo! O dela já está no quarto de santo da Vó.")
	else:
		_mostrar_aviso("Troféu: o Ibiri de Nanã! Leve para o terreiro da Vó.")


# ------------------------------------------------------------------ eventos dos diálogos e saída

func _ao_evento(nome: String) -> void:
	match nome:
		"ganhar_pote":
			_nana["pote"] = "rachado"
			_acender_slot("pote", "o pote de barro da velhinha (rachado)")
			_slots_nana["pote"].modulate = Color(1, 1, 1, 0.75)
		"pegar_faca":
			_nana["faca"] = true
			_toco_faca.sprite.frame = 1
			Jogo.tocar_som("buzio", -8.0)
			_mostrar_aviso("Você pegou: uma faca de ferro velha")
		"faca_afunda":
			_nana.erase("faca")
			_nana["faca_foi"] = true
			_lama_espirra(jogador.global_position + Vector2(8, 0))
			Jogo.tocar_som("lama_afunda", -8.0)
		"ganhar_lamina":
			_nana["lamina"] = true
			# a lasca vai para o inventário: o bambu rachado some do chão
			_lascas.ativo = false
			_lascas.get_node("Corpo/Forma").set_deferred("disabled", true)
			var some := create_tween()
			some.tween_property(_lascas, "modulate:a", 0.0, 0.4)
			some.tween_callback(_lascas.queue_free)
			_acender_slot("lamina", "uma lâmina de bambu")
		"ganhar_flores":
			_nana["flores"] = true
			_acender_slot("flores", _dados["nomes"]["flores"])
		"consertar_pote":
			_nana["pote"] = "vazio"
			_barro.sprite.frame = 1
			_slots_nana["pote"].modulate = Color.WHITE
			Jogo.tocar_som("pegar_item", -4.0)
		"oferenda":
			_fazer_oferenda()
		"velhinha_vem":
			_pendente = "velhinha_vem"
		"trofeu":
			_ganhar_trofeu()
		_:
			super._ao_evento(nome)


## Numa terra já vencida, o menu de pausa oferece "Voltar ao mapa".
func pode_voltar_ao_mapa() -> bool:
	return Jogo.trofeus.has("nana") and estado != "saindo"


func voltar_ao_mapa() -> void:
	estado = "saindo"
	jogador.congelar(true)
	Jogo.set_meta("no_mapa", "nana")
	Jogo.tocar_som("caminho", -6.0)
	Jogo.mudar_cena("res://cenas/mapa_mundo.tscn")


func _sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador") or estado != "livre":
		return
	Jogo.set_meta("no_mapa", "nana")
	super._sair(corpo)


# ------------------------------------------------------------------ quartinha de Exu (salvar)

## Guardado aqui, o jogo continua do começo da terra de Nanã.
func _local_do_caminho() -> String:
	return "nana"


func _pode_guardar() -> bool:
	return true
