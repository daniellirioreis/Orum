extends "res://scripts/encruzilhada.gd"
## Igbó Ọ̀ṣọ́ọ̀sì — a Mata de Oxóssi (visão de cima, como a encruzilhada).
## Reaproveita da encruzilhada o axé (búzios de vida), o dano, as placas e a saída para o mapa.
##
## Quatro lugares, cada um ensina uma coisa do caçador:
##   ox_rastro   → observar: seguir o rastro do veado (duas unhas); os outros rastros enganam.
##                 Três acertos seguidos e Adé sai do labirinto; um erro e a mata o devolve ao começo.
##   ox_campo    → paciência: passar pelos veados andando devagar (SHIFT / C). Quem corre espanta a caça.
##                 No milharal, a espiga de milho para a oferenda.
##   ox_ofa      → mirar: Adé acha o ofá (arco) com UMA flecha. Corta a corda do tronco (vira ponte),
##                 acerta a colmeia (as abelhas espantam o javali e cai o favo de mel), espanta as cobras.
##                 O coco fica debaixo do coqueiro.
##   ox_clareira → o pássaro das Iyami: flechas não adiantam. Com milho, coco e mel, Adé faz a oferenda a Exu
##                 (como a mãe do caçador do itan); o pássaro baixa a guarda, Oxóssi chega e, com uma flecha só,
##                 espanta o pássaro. Ao pôr do sol, Adé e Oxóssi conversam sobre o sonho.
##                 Oxóssi dá o ofá a Adé: o troféu que ele vai levar para o terreiro da Vó.

const LUGARES_MATA := {
	"ox_rastro": {"origem": Vector2(0, 0), "dentro": false},
	"ox_campo": {"origem": Vector2(0, 400), "dentro": false},
	"ox_ofa": {"origem": Vector2(0, 1000), "dentro": false},
	"ox_clareira": {"origem": Vector2(0, 1700), "dentro": false},
}
const COR_MATA := Color(0.84, 0.95, 0.8)        # sombra verde das folhas
const COR_POR_DO_SOL := Color(1.0, 0.85, 0.72)
const OFERENDAS := ["milho", "coco", "mel"]
const RODADAS := 3                              # acertos seguidos para sair do labirinto
const VEADO_OUVE := 46.0                        # de quão longe o veado ouve passos apressados
const FLECHA_VEL := 230.0
const FLECHA_ALCANCE := 170.0
const TEX_OX_ITENS := preload("res://arte/ox_itens.png")

var _ox := {}                   # flags da fase (tem_ofa, ponte, javali_foi, oferenda, passaro_chegou...)
var _ox_slots := {}             # id → ícone do inventário (milho, coco, mel, ofa)
var _moldura_trofeu: TextureRect
# rastros
var _rodada := 0
var _saida_certa := ""
var _saidas := {}               # W/N/E → ponto da saída
var _rastros: Node2D
var _escolhendo := false
# veados
var _veados: Array = []         # {s, casa, alerta, fugiu, passeia, fase, lugar}
var _espantou := false
# flecha
var _flecha := {}               # {s, dir, voando, andou, no_chao}
var _alvos: Array = []          # {tipo, no, lugar, ...}
var _avisou_volta := false
# bichos
var _cobras: Array = []         # {a, s, de, ate, vel, fase, foi}
var _javali := {}
var _colmeia := {}
var _tronco := {}
var _coletaveis: Array = []     # {s, id, lugar}
# pássaro e Oxóssi
var _passaro := {}
var _assentamento: Area2D
var _oxossi: Sprite2D
var _oxossi_pos := Vector2.ZERO
var _anim_oxossi := "parado"
var _repetindo := false   # a mata já tinha sido vencida: no fim, Adé reencontra Oxóssi
var _saida_moita: Array = []    # moitas que fecham a saída até o fim
var _viu_clareira := false
var _conversa: Area2D
# mais bichos da mata
var _passarinhos: Array = []    # {s, casa, lugar, cor, voou, volta}
var _bandos: Array = []         # passarinhos voando pelo céu: {s, vel, base_y, fase}
var _proximo_bando := 3.0
var _pavoes: Array = []         # {no, casa, alvo, espera, aberto}
var _oncas: Array = []          # {a, s, casa, lugar, estado, tempo}
var _viu_onca := false


func _ready() -> void:
	lugares = LUGARES_MATA
	cor_fora = COR_MATA
	estado = "caminho"
	Jogo.tocar_musica()
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)
	_dados = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/mata_oxossi.json"))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	_rastros = Node2D.new()
	_rastros.z_index = -4
	add_child(_rastros)
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	_ponto_volta["ox_rastro"] = jogador.global_position
	$HUD.esconder_contador = true

	_criar_interface()
	_criar_inventario()
	$Dialogo.evento.connect(_ao_evento)
	_entrar_lugar("ox_rastro")
	_novos_rastros()
	_inicio()


func _inicio() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.8).timeout
	$HUD.mostrar_titulo("Igbó Ọ̀ṣọ́ọ̀sì", "A Mata de Oxóssi")
	await get_tree().create_timer(1.6).timeout
	if Jogo.trofeus.has("oxossi"):
		_repetindo = true
		# a mata já foi vencida: Adé pode fazer a fase de novo (do começo) ou voltar logo para o mapa
		await _falar("revisita")
		var r: Dictionary = await Jogo.menu.escolher("A Mata de Oxóssi", ["Fazer a fase de novo", "Voltar ao mapa"])
		if r["acao"] == "ok" and r["i"] == 1:
			voltar_ao_mapa()
			return
	await _falar("chegada")


func _process(delta: float) -> void:
	super._process(delta)
	_mover_veados(delta)
	_mover_flecha(delta)
	_mover_cobras(delta)
	_mover_javali(delta)
	_mover_passaro(delta)
	_pegar_coletaveis()
	_mover_passarinhos(delta)
	_mover_bandos(delta)
	_mover_pavoes(delta)
	_mover_oncas(delta)
	if _oxossi and _anim_oxossi == "parado":
		_oxossi.frame = int(_tempo * 3.0) % 4


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("atirar") and jogador.pode_mover and not _voltando:
		_atirar()
		return
	super._unhandled_input(ev)


func teleportar(nome: String, posicao: Vector2) -> void:
	super.teleportar(nome, posicao)
	if nome == "ox_clareira" and not _viu_clareira:
		_viu_clareira = true
		_chegar_na_clareira.call_deferred()


# ------------------------------------------------------------------ objetos dos mapas

func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	match c:
		"W", "N", "E":
			if not _saidas.has(c):
				_saidas[c] = base - Vector2(0, TILE / 2.0)
				var area := _area(base - Vector2(0, TILE / 2.0) + (Vector2(TILE / 2.0, 0) if c == "N" else Vector2(0, TILE / 2.0)),
					Vector2(30, 14) if c == "N" else Vector2(10, 30))
				area.body_entered.connect(_escolher_saida.bind(c))
			else:
				_saidas[c] = (_saidas[c] + base - Vector2(0, TILE / 2.0)) / 2.0
		"p":
			marcas["p_" + lugar] = base - Vector2(0, 2)
		"v", "V":
			_criar_veado(lugar, base, c == "V")
		"m", "u":
			if c == "m":
				var s := _criar_cenario("res://arte/ox_milho.png", Vector2(6, 4), base)
				s.hframes = 2
				s.frame = 1
			else:
				var pe := _criar_interativo("res://arte/ox_milho.png", 2, base, Vector2(6, 4), -30.0)
				pe.interagiu.connect(_colher_milho.bind(pe))
		"O":
			var toco := _criar_interativo("res://arte/ox_toco.png", 2, base, Vector2(14, 8), -30.0)
			toco.interagiu.connect(_pegar_ofa.bind(toco))
		"T":
			_criar_tronco(lugar, celula, base)
		"s":
			_criar_cobra(lugar, celula, base)
		"j":
			_criar_javali(lugar, base)
		"H":
			_criar_cenario("res://arte/obj_arvore.png", Vector2(12, 8), base)
			var col := Sprite2D.new()
			col.texture = preload("res://arte/ox_colmeia.png")
			col.hframes = 2
			col.position = base + Vector2(-17, -30)
			col.z_index = 3
			add_child(col)
			_colmeia = {"s": col, "lugar": lugar, "caiu": false}
			_alvos.append({"tipo": "colmeia", "lugar": lugar, "centro": col.position, "raio": 9.0})
		"k":
			_criar_coletavel(lugar, "coco", base, preload("res://arte/ox_coco.png"))
		"B":
			_criar_passaro(lugar, base)
		"X":
			_assentamento = _criar_interativo("res://arte/ox_assentamento.png", 2, base, Vector2(16, 8), -26.0)
			_assentamento.interagiu.connect(_no_assentamento)
		"x":
			_oxossi_pos = base
		"b":
			for k in 3:
				_criar_passarinho(lugar, base + Vector2(randf_range(-14, 14), randf_range(-8, 6)))
		"G":
			_criar_pavao(lugar, base)
		"Q":
			_criar_onca(lugar, base)
		">":
			var area := _area(base - Vector2(0, TILE / 2.0), Vector2(14, 12))
			area.body_entered.connect(_sair)
			# a mata fecha a saída até o fim
			var moita := _criar_cenario("res://arte/arbusto.png", Vector2(16, 14), base)
			moita.hframes = 2
			_saida_moita.append(moita)
		_:
			super._criar_objeto(lugar, c, celula, base, chao)


func _area(pos: Vector2, tam: Vector2) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = pos
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = tam
	forma.shape = ret
	area.add_child(forma)
	add_child(area)
	return area


# ------------------------------------------------------------------ inventário: oferendas e o troféu

func _criar_inventario() -> void:
	for n in _hud_oferendas:
		n.visible = false
	var camada: CanvasLayer = _icone_buzio.get_parent()
	var ordem := ["milho", "coco", "mel", "ofa"]
	for i in ordem.size():
		var caixa := TextureRect.new()
		caixa.texture = preload("res://arte/hud_slot.png")
		caixa.position = Vector2(6 + i * 19, 6)
		camada.add_child(caixa)
		if ordem[i] == "ofa":
			_moldura_trofeu = caixa
		var atlas := AtlasTexture.new()
		atlas.atlas = TEX_OX_ITENS
		atlas.region = Rect2(i * 12, 0, 12, 12)
		var item := TextureRect.new()
		item.texture = atlas
		item.position = caixa.position + Vector2(3, 3)
		item.pivot_offset = Vector2(6, 6)
		item.modulate = COR_ITEM_FALTA
		camada.add_child(item)
		_ox_slots[ordem[i]] = item


func _ganhar_item(id: String, texto: String) -> void:
	_ox[id] = true
	var icone: TextureRect = _ox_slots[id]
	icone.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(1.6, 1.6), 0.12)
	t.tween_property(icone, "scale", Vector2.ONE, 0.18)
	Jogo.tocar_som("buzio", -2.0)
	_mostrar_aviso("Você pegou: " + texto)


func _criar_coletavel(lugar: String, id: String, base: Vector2, tex: Texture2D) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	s.position = base - Vector2(0, 2)
	mundo.add_child(s)
	_coletaveis.append({"s": s, "id": id, "lugar": lugar})


func _pegar_coletaveis() -> void:
	for c in _coletaveis.duplicate():
		if c["lugar"] != lugar_atual or not jogador.pode_mover:
			continue
		if c["s"].global_position.distance_to(jogador.global_position) < 12.0:
			_coletaveis.erase(c)
			c["s"].queue_free()
			_ganhar_item(c["id"], _dados["nomes"][c["id"]])


# ------------------------------------------------------------------ 1) o labirinto dos rastros

## Desenha os rastros desta rodada: o do veado leva à saída certa; o de pássaro, a outra.
func _novos_rastros() -> void:
	for f in _rastros.get_children():
		f.queue_free()
	var nomes := ["W", "N", "E"]
	_saida_certa = nomes[randi() % 3]
	var outras := nomes.filter(func(n): return n != _saida_certa)
	var engano: String = outras[randi() % 2]
	var origem: Vector2 = lugares["ox_rastro"]["origem"]
	var inicio := origem + Vector2(8 * TILE, 11 * TILE)
	_trilha_de_pegadas(inicio + Vector2(randf_range(-4, 4), 0), _saidas[_saida_certa], 0)
	_trilha_de_pegadas(inicio + Vector2(randf_range(-10, 10), -6), _saidas[engano], 1)


func _trilha_de_pegadas(de: Vector2, ate: Vector2, tipo: int) -> void:
	var meio := (de + ate) / 2.0 + Vector2(randf_range(-30, 30), randf_range(-24, 10))
	var passo := 11.0 if tipo == 0 else 9.0
	var total := de.distance_to(meio) + meio.distance_to(ate)
	var n := int(total / passo)
	var anterior := de
	for i in range(1, n - 1):
		var u := float(i) / n
		var p := de.lerp(meio, u).lerp(meio.lerp(ate, u), u)       # curva (Bézier) até a saída
		var dir := (p - anterior).normalized()
		anterior = p
		var lado := Vector2(-dir.y, dir.x) * (2.5 if i % 2 else -2.5)
		var s := Sprite2D.new()
		s.texture = preload("res://arte/ox_pegadas.png")
		s.hframes = 2
		s.frame = tipo
		s.position = p + lado
		s.rotation = dir.angle() + PI / 2.0
		s.modulate.a = 0.85
		_rastros.add_child(s)


func _escolher_saida(corpo: Node2D, saida: String) -> void:
	if not corpo.is_in_group("jogador") or _escolhendo or not jogador.pode_mover:
		return
	_escolhendo = true
	jogador.congelar(true)
	var certo := saida == _saida_certa
	_rodada = _rodada + 1 if certo else 0
	Jogo.tocar_som("pulo", -14.0)
	var t := create_tween()
	t.tween_property(_cortina, "color:a", 1.0, 0.3)
	await t.finished
	if _rodada >= RODADAS:
		_rastros.visible = false
		teleportar("ox_campo", marcas["p_ox_campo"])
	else:
		teleportar("ox_rastro", _ponto_volta["ox_rastro"])
		_novos_rastros()
	await get_tree().create_timer(0.25).timeout
	var t2 := create_tween()
	t2.tween_property(_cortina, "color:a", 0.0, 0.35)
	await t2.finished
	if _rodada >= RODADAS:
		await _falar("rastro_fim")
	elif certo:
		_mostrar_aviso("Os rastros te levaram mais fundo na mata... (%d de %d)" % [_rodada, RODADAS])
		jogador.congelar(false)
	else:
		await _falar("rastro_errado")
	_escolhendo = false


# ------------------------------------------------------------------ 2) os veados

func _criar_veado(lugar: String, base: Vector2, passeia: bool) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_veado.png")
	s.hframes = 5
	s.offset = Vector2(0, -11)
	s.position = base
	s.flip_h = randf() < 0.5
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.scale = Vector2(1.4, 1.0)
	sombra.show_behind_parent = true
	s.add_child(sombra)
	mundo.add_child(s)
	_veados.append({"s": s, "casa": base, "alerta": 0.0, "fugiu": false, "passeia": passeia,
		"fase": randf() * TAU, "lugar": lugar})


func _mover_veados(delta: float) -> void:
	for v in _veados:
		var s: Sprite2D = v["s"]
		if v["fugiu"]:
			continue
		if v["passeia"]:
			var x := sin(_tempo * 0.35 + v["fase"]) * 26.0
			var antes := s.position.x
			s.position.x = v["casa"].x + x
			if absf(s.position.x - antes) > 0.01:
				s.flip_h = s.position.x < antes
		if v["lugar"] != lugar_atual or _espantou:
			continue
		var d := s.position.distance_to(jogador.global_position)
		var rapido := jogador.velocity.length() > 40.0
		if d < 14.0 or (d < VEADO_OUVE and rapido):
			v["alerta"] += delta * (4.0 if d < 14.0 else 2.4)
		else:
			v["alerta"] = maxf(0.0, v["alerta"] - delta * 0.8)
		if v["alerta"] > 0.15:
			s.frame = 2                       # cabeça erguida, orelhas em pé
			s.flip_h = jogador.global_position.x < s.position.x
		else:
			s.frame = int(_tempo * 1.2 + v["fase"]) % 2
		if v["alerta"] >= 0.6:
			_veado_foge(v)


func _veado_foge(v: Dictionary) -> void:
	_espantou = true
	v["fugiu"] = true
	jogador.congelar(true)
	var s: Sprite2D = v["s"]
	var fuga := (s.position - jogador.global_position).normalized()
	if fuga == Vector2.ZERO:
		fuga = Vector2.UP
	s.flip_h = fuga.x < 0.0
	Jogo.tocar_som("erro", -6.0)
	var corre := create_tween().set_loops(8)
	corre.tween_callback(func(): s.frame = 3).set_delay(0.08)
	corre.tween_callback(func(): s.frame = 4).set_delay(0.08)
	var t := create_tween()
	t.tween_property(s, "position", s.position + fuga * 110.0, 1.1)
	t.parallel().tween_property(s, "modulate:a", 0.0, 1.1)
	await t.finished
	await _falar("veado_fugiu")
	jogador.congelar(true)
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.35)
	await c.finished
	for o in _veados:                      # todos de volta para o lugar
		o["fugiu"] = false
		o["alerta"] = 0.0
		o["s"].position = o["casa"]
		o["s"].modulate.a = 1.0
	teleportar(lugar_atual, _ponto_volta.get(lugar_atual, jogador.global_position))
	await get_tree().create_timer(0.25).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.35)
	await c2.finished
	_espantou = false
	jogador.congelar(false)
	_mostrar_aviso("Segure {devagar} para andar devagar.")


func _colher_milho(pe: Area2D) -> void:
	if _ox.has("milho"):
		await _falar("milho_depois")
		return
	await _falar("milho")
	pe.sprite.frame = 1
	_ganhar_item("milho", _dados["nomes"]["milho"])


# ------------------------------------------------------------------ 3) o ofá e a flecha

func _pegar_ofa(toco: Area2D) -> void:
	if _ox.has("tem_ofa"):
		await _falar("toco_vazio")
		return
	await _falar("achou_ofa")


func _atirar() -> void:
	if not _ox.has("tem_ofa") or not _flecha.is_empty():
		if _ox.has("tem_ofa") and not _flecha.is_empty() and _flecha["no_chao"]:
			_mostrar_aviso("Primeiro vá buscar a flecha!")
		return
	var dir: Vector2 = jogador.direcao()
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_flecha.png")
	s.rotation = dir.angle()
	s.position = jogador.global_position + Vector2(0, -10) + dir * 6.0
	s.z_index = 8
	add_child(s)
	_flecha = {"s": s, "dir": dir, "voando": true, "andou": 0.0, "no_chao": false}
	_ox_slots["ofa"].modulate = Color(1, 1, 1, 0.5)
	Jogo.tocar_som("pulo", -6.0)


func _mover_flecha(delta: float) -> void:
	if _flecha.is_empty():
		return
	var s: Sprite2D = _flecha["s"]
	if _flecha["no_chao"]:
		if jogador.pode_mover and s.global_position.distance_to(jogador.global_position + Vector2(0, -4)) < 13.0:
			_recolher_flecha()
		return
	if not _flecha["voando"]:
		return
	var dir: Vector2 = _flecha["dir"]
	var passos := int(ceil(FLECHA_VEL * delta / 3.0))
	for i in passos:
		var antes := s.position
		s.position += dir * 3.0
		_flecha["andou"] += 3.0
		var alvo := _alvo_em(s.position)
		if not alvo.is_empty():
			_flecha_acertou(alvo)
			return
		if _bate_em_parede(s.position):
			s.position = antes
			_flecha_cai()
			return
		if _flecha["andou"] >= FLECHA_ALCANCE:
			_flecha_cai()
			return


func _alvo_em(p: Vector2) -> Dictionary:
	for a in _alvos:
		if a["lugar"] != lugar_atual or a.get("feito", false):
			continue
		match a["tipo"]:
			"corda":
				var base: Vector2 = a["base"]
				if absf(p.x - base.x) < 8.0 and p.y > base.y - 44.0 and p.y < base.y + 2.0:
					return a
			"cobra":
				var c: Dictionary = a["cobra"]
				if not c["foi"] and p.distance_to(c["a"].position + Vector2(0, -5)) < 10.0:
					return a
			"javali":
				if not _javali["foi"] and p.distance_to(_javali["s"].position + Vector2(0, -8)) < 12.0:
					return a
			"onca":
				var o: Dictionary = a["onca"]
				if p.distance_to(o["a"].position + Vector2(0, -9)) < 14.0:
					return a
			"passaro":
				if not _passaro["foi"] and p.distance_to(_passaro["s"].position + Vector2(0, -20)) < 22.0:
					return a
			_:
				if p.distance_to(a["centro"]) < a["raio"]:
					return a
	return {}


## A flecha passa por cima da água, mas para em moita, árvore e pedra.
func _bate_em_parede(p: Vector2) -> bool:
	var origem: Vector2 = lugares[lugar_atual]["origem"]
	var rel := p - origem
	var cel := Vector2i(floori(rel.x / TILE), floori(rel.y / TILE))
	var letra := _letra(_mapas[lugar_atual], cel.x, cel.y)
	if letra == "~":
		return false
	if not (letra in ANDAVEL):
		return true
	var pe := p + Vector2(0, 10)           # a flecha voa na altura do peito: confere o pé do que está embaixo
	var rel_pe := pe - origem
	if _letra(_mapas[lugar_atual], floori(rel_pe.x / TILE), floori(rel_pe.y / TILE)) == "~":
		return false                       # embaixo é água: nada para bater
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pe
	q.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


func _flecha_cai() -> void:
	_flecha["voando"] = false
	var s: Sprite2D = _flecha["s"]
	var t := create_tween()
	t.tween_property(s, "position:y", s.position.y + 8.0, 0.12)
	await t.finished
	if _no_chao_firme(s.position):
		_flecha["no_chao"] = true
		s.z_index = -3
		Jogo.tocar_som("texto", -8.0)
	else:
		# caiu na água ou no mato fechado: a mata devolve a flecha
		await get_tree().create_timer(0.4).timeout
		_recolher_flecha()
		if not _avisou_volta:
			_avisou_volta = true
			_mostrar_aviso("A flecha caiu longe... e voltou para o ofá.")


func _no_chao_firme(p: Vector2) -> bool:
	var origem: Vector2 = lugares[lugar_atual]["origem"]
	var rel := p - origem
	var letra := _letra(_mapas[lugar_atual], floori(rel.x / TILE), floori(rel.y / TILE))
	return letra in ANDAVEL and not _bate_em_parede(p - Vector2(0, 10))


func _recolher_flecha() -> void:
	if _flecha.is_empty():
		return
	_flecha["s"].queue_free()
	_flecha = {}
	_ox_slots["ofa"].modulate = Color.WHITE
	Jogo.tocar_som("buzio", -10.0)


func _flecha_acertou(a: Dictionary) -> void:
	match a["tipo"]:
		"corda":
			a["feito"] = true
			_flecha_cai()
			_derrubar_tronco()
		"cobra":
			_flecha_cai()
			_cobra_foge(a["cobra"])
			a["feito"] = true
		"colmeia":
			a["feito"] = true
			_flecha_cai()
			_quebrar_colmeia()
		"javali":
			_flecha_cai()
			Jogo.tocar_som("erro", -8.0)
			_mostrar_aviso("A flecha bateu no couro grosso do javali...")
			_javali["bravo"] = 1.0
		"onca":
			_flecha_cai()
			_acordar_onca(a["onca"])
			_mostrar_aviso("Oxóssi não caça por caçar. Deixe a onça dormir!")
		"passaro":
			_flecha_cai()
			Jogo.tocar_som("erro", -6.0)
			_passaro["tremer"] = 0.3
			if not _ox.has("desviou"):
				_ox["desviou"] = true
				await _falar("flecha_desviou")


# ------------------------------------------------------------------ o tronco que vira ponte

func _criar_tronco(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var corpo := StaticBody2D.new()
	corpo.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_tronco.png")
	s.offset = Vector2(0, -26)
	corpo.add_child(s)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10, 6)
	forma.shape = ret
	forma.position = Vector2(0, -3)
	corpo.add_child(forma)
	mundo.add_child(corpo)
	_tronco = {"no": corpo, "s": s, "forma": forma, "lugar": lugar, "celula": celula}
	_alvos.append({"tipo": "corda", "lugar": lugar, "base": base})


func _derrubar_tronco() -> void:
	var lugar: String = _tronco["lugar"]
	var celula: Vector2i = _tronco["celula"]
	var base: Vector2 = _tronco["no"].position
	Jogo.tocar_som("caminho", -4.0)
	_tronco["forma"].set_deferred("disabled", true)
	var s: Sprite2D = _tronco["s"]
	# o tronco tomba para a frente, por cima do riacho
	var t := create_tween()
	t.tween_property(s, "scale:y", 0.15, 0.35).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.35)
	await t.finished
	var ponte := Sprite2D.new()
	ponte.texture = preload("res://arte/ox_ponte.png")
	ponte.centered = false
	ponte.position = base + Vector2(-8, -2)
	ponte.z_index = -4
	add_child(ponte)
	ponte.scale.y = 0.2
	var t2 := create_tween()
	t2.tween_property(ponte, "scale:y", 1.0, 0.25).set_ease(Tween.EASE_IN)
	await t2.finished
	_respingo(base + Vector2(0, 40))
	_tremer()
	var mapa: PackedStringArray = _mapas[lugar]
	for y in range(celula.y + 1, celula.y + 5):
		if _letra(mapa, celula.x, y) == "~":
			_chaos[lugar].erase_cell(Vector2i(celula.x, y))   # dá para pisar no tronco
	_ox["ponte"] = true
	await _falar("tronco_caiu")


# ------------------------------------------------------------------ cobras e javali

func _criar_cobra(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_cobra.png")
	s.hframes = 2
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
	while _letra(mapa, ini.x - 1, ini.y) in ANDAVEL and celula.x - ini.x < 5:
		ini.x -= 1
	var fim := celula
	while _letra(mapa, fim.x + 1, fim.y) in ANDAVEL and fim.x - celula.x < 5:
		fim.x += 1
	var c := {"a": a, "s": s, "de": _base_celula(lugar, ini), "ate": _base_celula(lugar, fim),
		"vel": randf_range(26.0, 34.0), "fase": randf(), "foi": false, "lugar": lugar}
	_cobras.append(c)
	_alvos.append({"tipo": "cobra", "lugar": lugar, "cobra": c})


func _mover_cobras(_delta: float) -> void:
	for c in _cobras:
		if c["foi"]:
			continue
		var dist: float = maxf(1.0, c["de"].distance_to(c["ate"]))
		var u := pingpong(_tempo * c["vel"] / dist + c["fase"], 1.0)
		var antes: Vector2 = c["a"].position
		c["a"].position = c["de"].lerp(c["ate"], u)
		c["s"].flip_h = c["a"].position.x < antes.x
		c["s"].frame = int(_tempo * 5.0 + c["fase"] * 3.0) % 2
		if c["lugar"] == lugar_atual and _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
				and c["a"].overlaps_body(jogador):
			_tomar_dano(c["a"].global_position)


func _cobra_foge(c: Dictionary) -> void:
	c["foi"] = true
	Jogo.tocar_som("caminho", -14.0)
	var t := create_tween()
	t.tween_property(c["a"], "position:x", c["a"].position.x + (30.0 if randf() < 0.5 else -30.0), 0.5)
	t.parallel().tween_property(c["a"], "modulate:a", 0.0, 0.5)
	t.tween_callback(c["a"].queue_free)
	_mostrar_aviso("A cobra se assustou e sumiu no mato.")


func _criar_javali(lugar: String, base: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_javali.png")
	s.hframes = 3
	s.offset = Vector2(0, -8)
	a.add_child(s)
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 8.0
	forma.shape = circ
	forma.position = Vector2(0, -6)
	a.add_child(forma)
	# o javali guarda o cantinho do coqueiro: um corpo sólido onde ele fica
	var corpo := StaticBody2D.new()
	var f2 := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(34, 10)          # fecha a abertura do cantinho do coqueiro (2 blocos)
	f2.shape = r2
	f2.position = Vector2(8, -6)
	corpo.add_child(f2)
	a.add_child(corpo)
	mundo.add_child(a)
	_javali = {"s": a, "sprite": s, "casa": base, "lugar": lugar, "foi": false, "bravo": 0.0, "corpo": f2,
		"carga": Vector2.ZERO, "tempo_carga": 0.0}
	_alvos.append({"tipo": "javali", "lugar": lugar})


func _mover_javali(delta: float) -> void:
	if _javali.is_empty() or _javali["foi"]:
		return
	var a: Area2D = _javali["s"]
	var s: Sprite2D = _javali["sprite"]
	var casa: Vector2 = _javali["casa"]
	if _javali["tempo_carga"] > 0.0:
		_javali["tempo_carga"] -= delta
		a.position += _javali["carga"] * 120.0 * delta
		s.frame = 1 + int(_tempo * 12.0) % 2
		s.flip_h = _javali["carga"].x < 0.0
	else:
		var volta := casa - a.position
		if volta.length() > 1.0:
			a.position += volta.limit_length(40.0 * delta)
			s.frame = 1 + int(_tempo * 8.0) % 2
		else:
			s.frame = 0
			s.flip_h = int(_tempo / 2.0) % 2 == 0
		if _javali["lugar"] == lugar_atual and jogador.pode_mover and not _voltando:
			var d := jogador.global_position - a.position
			_javali["bravo"] = maxf(0.0, _javali["bravo"] - delta)
			if (d.length() < 50.0 or _javali["bravo"] > 0.5) and volta.length() < 2.0:
				_javali["bravo"] = 0.0
				_javali["carga"] = d.normalized()
				_javali["tempo_carga"] = 0.45
				Jogo.tocar_som("erro", -10.0)
	if _javali["lugar"] == lugar_atual and _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
			and a.overlaps_body(jogador):
		_tomar_dano(a.global_position)
		_javali["tempo_carga"] = 0.0


func _quebrar_colmeia() -> void:
	var col: Sprite2D = _colmeia["s"]
	col.frame = 1
	Jogo.tocar_som("caminho", -8.0)
	# as abelhas saem e vão para cima do javali
	var abelhas := CPUParticles2D.new()
	abelhas.position = col.position
	abelhas.z_index = 9
	abelhas.amount = 26
	abelhas.lifetime = 1.2
	abelhas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	abelhas.emission_sphere_radius = 5.0
	abelhas.spread = 180.0
	abelhas.gravity = Vector2.ZERO
	abelhas.initial_velocity_min = 10.0
	abelhas.initial_velocity_max = 24.0
	abelhas.color = Color(1.0, 0.85, 0.2)
	abelhas.scale_amount_min = 1.0
	abelhas.scale_amount_max = 1.5
	add_child(abelhas)
	var t := create_tween()
	if not _javali.is_empty() and not _javali["foi"]:
		t.tween_property(abelhas, "position", _javali["s"].position + Vector2(0, -12), 0.9)
	await t.finished
	# o favo de mel cai no chão
	var favo := AtlasTexture.new()
	favo.atlas = TEX_OX_ITENS
	favo.region = Rect2(24, 0, 12, 12)
	_criar_coletavel(_colmeia["lugar"], "mel", col.position + Vector2(4, 34), favo)
	if not _javali.is_empty() and not _javali["foi"]:
		_javali["foi"] = true
		_javali["corpo"].set_deferred("disabled", true)
		var j: Area2D = _javali["s"]
		var corre := create_tween().set_loops(10)
		corre.tween_callback(func(): _javali["sprite"].frame = 1).set_delay(0.07)
		corre.tween_callback(func(): _javali["sprite"].frame = 2).set_delay(0.07)
		var fuga := create_tween()
		fuga.tween_property(j, "position", j.position + Vector2(0, -70), 1.2)
		fuga.parallel().tween_property(j, "modulate:a", 0.0, 1.2)
		fuga.parallel().tween_property(abelhas, "position", j.position + Vector2(0, -90), 1.2)
		await fuga.finished
	abelhas.emitting = false
	get_tree().create_timer(1.5).timeout.connect(abelhas.queue_free)
	await _falar("colmeia")


# ------------------------------------------------------------------ 4) a clareira: o pássaro das Iyami

func _criar_passaro(lugar: String, base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_passaro.png")
	s.hframes = 3
	s.offset = Vector2(0, -22)
	s.position = base
	s.z_index = 10
	add_child(s)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.modulate = Color(0, 0, 0, 0.0)
	sombra.z_index = -3
	sombra.position = base
	add_child(sombra)
	_passaro = {"s": s, "casa": base - Vector2(0, 6), "lugar": lugar, "sombra": sombra, "espera": 2.5,
		"mergulhando": false, "calmo": false, "foi": false, "tremer": 0.0}
	_alvos.append({"tipo": "passaro", "lugar": lugar})


func _mover_passaro(delta: float) -> void:
	if _passaro.is_empty() or _passaro["foi"]:
		return
	var s: Sprite2D = _passaro["s"]
	var bate := 6.0 if not _passaro["calmo"] else 2.5
	s.frame = 1 + int(_tempo * bate) % 2
	if _passaro["tremer"] > 0.0:
		_passaro["tremer"] -= delta
		s.offset.x = randf_range(-2, 2)
	else:
		s.offset.x = 0.0
	if _passaro["mergulhando"]:
		return
	s.position = _passaro["casa"] + Vector2(sin(_tempo * 0.9) * 10.0, sin(_tempo * 1.7) * 3.0)
	if _passaro["calmo"] or _passaro["lugar"] != lugar_atual or not jogador.pode_mover or _voltando:
		return
	_passaro["espera"] -= delta
	if _passaro["espera"] <= 0.0:
		_mergulho()


## A sombra cresce no chão onde o pássaro vai mergulhar; é só sair de baixo dela.
func _mergulho() -> void:
	_passaro["mergulhando"] = true
	var s: Sprite2D = _passaro["s"]
	var sombra: Sprite2D = _passaro["sombra"]
	var alvo := jogador.global_position
	sombra.position = alvo
	sombra.scale = Vector2(1, 1)
	sombra.modulate = Color(0, 0, 0, 0.0)
	var t := create_tween()
	t.tween_property(sombra, "scale", Vector2(3.2, 3.2), 0.9)
	t.parallel().tween_property(sombra, "modulate:a", 0.6, 0.9)
	t.tween_property(s, "position", alvo + Vector2(0, 2), 0.22).set_ease(Tween.EASE_IN)
	await t.finished
	Jogo.tocar_som("caminho", -10.0)
	if jogador.global_position.distance_to(alvo) < 16.0 and _invulneravel <= 0.0 and jogador.pode_mover:
		_tomar_dano(alvo + Vector2(0, -8))
	var volta := create_tween()
	volta.tween_property(s, "position", _passaro["casa"], 0.7).set_ease(Tween.EASE_OUT)
	volta.parallel().tween_property(sombra, "modulate:a", 0.0, 0.4)
	await volta.finished
	_passaro["espera"] = randf_range(1.6, 2.6)
	_passaro["mergulhando"] = false


func _chegar_na_clareira() -> void:
	await get_tree().create_timer(0.5).timeout
	await _falar("clareira")


func _no_assentamento() -> void:
	if _ox.has("oferenda"):
		await _falar("assentamento_depois")
		return
	var faltam := []
	for id in OFERENDAS:
		if not _ox.has(id):
			faltam.append(_dados["nomes"][id])
	if faltam.is_empty():
		await _falar("oferenda")
		if _pendente == "oxossi_chega":
			_pendente = ""
			await _oxossi_chega()
	else:
		var linha: Dictionary = _dados["assentamento_falta"][0].duplicate()
		linha["pt"] = linha["pt"].replace("{faltam}", _juntar(faltam))
		await _falar_linhas([linha])


func _fazer_oferenda() -> void:
	_ox["oferenda"] = true
	_assentamento.sprite.frame = 1
	_assentamento.ativo = false
	for id in OFERENDAS:
		_ox_slots[id].modulate = COR_ITEM_FALTA
	_luz(_assentamento.position + Vector2(0, -10), Color(1.0, 0.5, 0.35), 1.6, 1.4, true)
	Jogo.tocar_som("buzio", -2.0)
	# o pássaro para de atacar e baixa a guarda
	_passaro["calmo"] = true
	create_tween().tween_property(_passaro["sombra"], "modulate:a", 0.0, 0.3)
	_passaro["casa"] = _passaro["casa"] + Vector2(0, 10)


## Oxóssi sai da mata, mira com o ofá e, com uma flecha só, espanta o pássaro das Iyami.
func _oxossi_chega() -> void:
	jogador.congelar(true)
	_oxossi = Sprite2D.new()
	_oxossi.texture = preload("res://arte/oxossi_anim.png")
	_oxossi.hframes = 9
	_oxossi.offset = Vector2(0, -22)
	_oxossi.position = _oxossi_pos + Vector2(24, 0)
	_oxossi.modulate.a = 0.0
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	_oxossi.add_child(sombra)
	mundo.add_child(_oxossi)
	_folhas(_oxossi.position + Vector2(0, -20))
	var t := create_tween()
	t.tween_property(_oxossi, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(_oxossi, "position", _oxossi_pos, 0.8)
	await t.finished
	jogador.olhar_para(_oxossi.position)
	await get_tree().create_timer(0.5).timeout
	# a mira: puxa a corda devagar...
	_anim_oxossi = "atirando"
	for q in [4, 5, 6]:
		_oxossi.frame = q
		await get_tree().create_timer(0.45 if q < 6 else 0.9).timeout
	# ...e solta
	_oxossi.frame = 7
	Jogo.tocar_som("pulo", -2.0)
	var s: Sprite2D = _passaro["s"]
	var flecha := Sprite2D.new()
	flecha.texture = preload("res://arte/ox_flecha.png")
	flecha.z_index = 11
	flecha.position = _oxossi.position + Vector2(-8, -25)
	var alvo := s.position + Vector2(0, -24)
	flecha.rotation = (alvo - flecha.position).angle()
	add_child(flecha)
	var voa := create_tween()
	voa.tween_property(flecha, "position", alvo, 0.22)
	await voa.finished
	_oxossi.frame = 8
	# a flecha passa raspando: o pássaro grita, perde penas e vai embora para sempre
	_passaro["foi"] = true
	Jogo.tocar_som("erro", -2.0)
	_tremer()
	_penas(s.position + Vector2(0, -20))
	var some := create_tween()
	some.tween_property(flecha, "position", alvo + Vector2.from_angle(flecha.rotation) * 90.0, 0.3)
	some.parallel().tween_property(flecha, "modulate:a", 0.0, 0.3)
	var foge := create_tween()
	foge.tween_property(s, "position", s.position + Vector2(-40, -200), 1.6).set_ease(Tween.EASE_IN)
	foge.parallel().tween_property(s, "scale", Vector2(0.5, 0.5), 1.6)
	foge.parallel().tween_property(s, "modulate:a", 0.0, 1.6)
	var bate := create_tween().set_loops(16)
	bate.tween_callback(func(): s.frame = 1).set_delay(0.05)
	bate.tween_callback(func(): s.frame = 2).set_delay(0.05)
	await foge.finished
	flecha.queue_free()
	_anim_oxossi = "parado"
	# o sol se põe sobre a mata
	var sol := create_tween()
	sol.tween_property(_noite, "color", COR_POR_DO_SOL, 2.5)
	_criar_vagalumes("ox_clareira")
	await get_tree().create_timer(0.8).timeout
	# Oxóssi vem andando até perto de Adé
	var perto := jogador.global_position + Vector2(30 if _oxossi.position.x > jogador.global_position.x else -30, 0)
	var anda := create_tween()
	anda.tween_property(_oxossi, "position", perto, _oxossi.position.distance_to(perto) / 55.0)
	await anda.finished
	_oxossi.flip_h = false
	jogador.olhar_para(_oxossi.position)
	await get_tree().create_timer(0.4).timeout
	_conversa = _ponto_de_conversa(_oxossi.position, Vector2(12, 6), 26.0, -50.0)
	_conversa.interagiu.connect(_falar_com_oxossi)
	if _repetindo:
		await _falar("oxossi_reencontro")
		await _abraco()
		await _falar("oxossi_despedida")
	else:
		await _falar("oxossi")
	await _oxossi_vai_embora()


## Na fase repetida, Adé agradece e os dois se abraçam.
func _abraco() -> void:
	jogador.congelar(true)
	var meio: Vector2 = (jogador.global_position + _oxossi.position) / 2.0
	# Adé vai até Oxóssi
	jogador.olhar_para(_oxossi.position)
	var vai := create_tween()
	vai.tween_property(jogador, "global_position", meio + Vector2(0, 4), 0.5)
	vai.parallel().tween_property(_oxossi, "position", meio, 0.5)
	await vai.finished
	var abraco := Sprite2D.new()
	abraco.texture = preload("res://arte/ox_abraco.png")
	abraco.hframes = 2
	abraco.offset = Vector2(0, -24)
	abraco.position = meio + Vector2(0, 4)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.show_behind_parent = true
	abraco.add_child(sombra)
	mundo.add_child(abraco)
	jogador.visible = false
	_oxossi.visible = false
	Jogo.tocar_som("buzio", -4.0)
	for i in 6:
		abraco.frame = 1 if i % 2 == 0 else 0
		if i == 2:
			_folhas(abraco.position + Vector2(0, -40))
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(0.4).timeout
	abraco.queue_free()
	jogador.visible = true
	_oxossi.visible = true
	# Oxóssi dá um passo para trás
	var volta := create_tween()
	volta.tween_property(_oxossi, "position", meio + Vector2(0, -10), 0.4)
	await volta.finished
	jogador.olhar_para(_oxossi.position)


func _falar_com_oxossi() -> void:
	if estado == "livre":
		return
	await _falar("oxossi_de_novo")


func _oxossi_vai_embora() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.4).timeout
	_folhas(_oxossi.position + Vector2(0, -20))
	var t := create_tween()
	t.tween_property(_oxossi, "modulate:a", 0.0, 1.0)
	t.parallel().tween_property(_oxossi, "position", _oxossi.position + Vector2(20, -6), 1.0)
	await t.finished
	# a mata abre o caminho de volta
	if _conversa:
		_conversa.ativo = false
	_abrir_saida()
	estado = "livre"
	jogador.congelar(false)
	_mostrar_aviso("A mata abriu um caminho ao norte. Volte para o mapa.")


func _abrir_saida() -> void:
	Jogo.tocar_som("caminho", -4.0)
	for m in _saida_moita:
		_folhas(m.position + Vector2(0, -8))
		var t := create_tween()
		t.tween_property(m, "modulate:a", 0.0, 0.6)
		t.tween_callback(m.queue_free)
	# as moitas têm um corpo sólido logo ao lado (criado em _criar_cenario): tira também
	for corpo in get_children():
		if corpo is StaticBody2D:
			for m in _saida_moita:
				if corpo.position == m.position:
					corpo.queue_free()


func _ganhar_trofeu() -> void:
	Jogo.trofeus["oxossi"] = "Ofá de Oxóssi"
	_ox["trofeu"] = true
	var icone: TextureRect = _ox_slots["ofa"]
	icone.modulate = Color.WHITE
	_moldura_trofeu.modulate = Color(1.0, 0.85, 0.35)
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(2.0, 2.0), 0.2)
	t.tween_property(icone, "scale", Vector2.ONE, 0.3)
	var brilho := create_tween().set_loops()
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.95, 0.6), 0.6)
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.78, 0.3), 0.6)
	Jogo.tocar_som("buzio", 0.0)
	if Jogo.assentados.has("oxossi"):
		_mostrar_aviso("O Ofá de Oxóssi de novo! O dele já está no quarto de santo da Vó.")
	else:
		_mostrar_aviso("Troféu: o Ofá de Oxóssi! Leve para o terreiro da Vó.")


func _folhas(pos: Vector2) -> void:
	_particulas(pos, [Color(0.4, 0.75, 0.3), Color(0.25, 0.55, 0.2)], 18)


func _penas(pos: Vector2) -> void:
	_particulas(pos, [Color(0.3, 0.2, 0.42), Color(0.08, 0.05, 0.12)], 22)


func _particulas(pos: Vector2, cores: Array, n: int) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 12
	f.amount = n
	f.lifetime = 1.4
	f.one_shot = true
	f.explosiveness = 0.85
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 8.0
	f.spread = 180.0
	f.gravity = Vector2(0, 30)
	f.initial_velocity_min = 15.0
	f.initial_velocity_max = 40.0
	f.scale_amount_min = 1.5
	f.scale_amount_max = 2.5
	var g := Gradient.new()
	g.set_color(0, cores[0])
	g.set_color(1, Color(cores[1].r, cores[1].g, cores[1].b, 0.0))
	f.color_ramp = g
	add_child(f)
	f.emitting = true
	get_tree().create_timer(2.0).timeout.connect(f.queue_free)


# ------------------------------------------------------------------ eventos dos diálogos e saída

func _ao_evento(nome: String) -> void:
	match nome:
		"ganhar_ofa":
			_ox["tem_ofa"] = true
			_ox_slots["ofa"].modulate = Color.WHITE
			for n in mundo.get_children():
				var sp = n.get("sprite") if n is Area2D else null
				if sp is Sprite2D and sp.texture == preload("res://arte/ox_toco.png"):
					sp.frame = 1
			Jogo.tocar_som("buzio", -2.0)
		"oferenda":
			_fazer_oferenda()
		"oxossi_chega":
			_pendente = "oxossi_chega"
		"trofeu":
			_ganhar_trofeu()
		_:
			super._ao_evento(nome)


## Num campo já concluído, o menu de pausa oferece "Voltar ao mapa".
func pode_voltar_ao_mapa() -> bool:
	return Jogo.trofeus.has("oxossi") and estado != "saindo"


func voltar_ao_mapa() -> void:
	estado = "saindo"
	jogador.congelar(true)
	Jogo.set_meta("no_mapa", "oxossi")
	Jogo.tocar_som("caminho", -6.0)
	Jogo.mudar_cena("res://cenas/mapa_mundo.tscn")


func _sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador") or estado != "livre":
		return
	Jogo.set_meta("no_mapa", "oxossi")
	super._sair(corpo)


# ------------------------------------------------------------------ passarinhos, pavão e onça

func _criar_passarinho(lugar: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_passarinhos.png")
	s.hframes = 4
	s.vframes = 3
	s.offset = Vector2(0, -4)
	s.position = pos
	var cor := randi() % 3
	s.frame = cor * 4
	s.flip_h = randf() < 0.5
	mundo.add_child(s)
	_passarinhos.append({"s": s, "casa": pos, "lugar": lugar, "cor": cor, "voou": false, "volta": 0.0,
		"fase": randf() * 10.0})


func _mover_passarinhos(delta: float) -> void:
	for b in _passarinhos:
		var s: Sprite2D = b["s"]
		var cor: int = b["cor"]
		if b["voou"]:
			b["volta"] -= delta
			if b["volta"] <= 0.0 and b["casa"].distance_to(jogador.global_position) > 60.0:
				# volta voando e pousa de novo
				b["voou"] = false
				s.position = b["casa"] + Vector2(-50 if s.flip_h else 50, -60)
				s.modulate.a = 1.0
				var t := create_tween()
				t.tween_property(s, "position", b["casa"], 1.0)
			else:
				s.frame = cor * 4 + 2 + int(_tempo * 14.0) % 2
			continue
		if s.position.distance_to(b["casa"]) > 1.0:
			s.frame = cor * 4 + 2 + int(_tempo * 14.0) % 2
			continue
		# bicando o chão
		var bica := fmod(_tempo + b["fase"], 2.4) < 0.5
		s.frame = cor * 4 + (1 if bica and int(_tempo * 6.0) % 2 == 0 else 0)
		if b["lugar"] == lugar_atual and s.position.distance_to(jogador.global_position) < 34.0:
			_passarinho_voa(b)


func _passarinho_voa(b: Dictionary) -> void:
	b["voou"] = true
	b["volta"] = randf_range(6.0, 9.0)
	var s: Sprite2D = b["s"]
	var lado := 1.0 if s.position.x > jogador.global_position.x else -1.0
	s.flip_h = lado < 0.0
	Jogo.tocar_som("texto", -18.0)
	var t := create_tween()
	t.tween_property(s, "position", s.position + Vector2(lado * randf_range(60, 90), randf_range(-90, -60)), 1.2)
	t.parallel().tween_property(s, "modulate:a", 0.0, 1.2).set_delay(0.5)


## De vez em quando um bando de passarinhos atravessa o céu da mata.
func _mover_bandos(delta: float) -> void:
	_proximo_bando -= delta
	if _proximo_bando <= 0.0:
		_proximo_bando = randf_range(7.0, 13.0)
		var camera: Camera2D = jogador.get_node("Camera")
		var centro := camera.get_screen_center_position()
		var da_esquerda := randf() < 0.5
		var y0 := centro.y - randf_range(30, 90)
		var cor := randi() % 3
		for k in randi_range(3, 6):
			var s := Sprite2D.new()
			s.texture = preload("res://arte/ox_passarinhos.png")
			s.hframes = 4
			s.vframes = 3
			s.z_index = 15
			s.flip_h = not da_esquerda
			s.position = Vector2(centro.x + (-150.0 if da_esquerda else 150.0) - (k * 14.0 if da_esquerda else -k * 14.0),
				y0 + randf_range(-12, 12))
			s.set_meta("cor", cor)
			add_child(s)
			_bandos.append({"s": s, "vel": (60.0 if da_esquerda else -60.0) + randf_range(-6, 6),
				"base_y": s.position.y, "fase": randf() * TAU, "vida": 6.0})
	for b in _bandos.duplicate():
		var s: Sprite2D = b["s"]
		b["vida"] -= delta
		s.position.x += b["vel"] * delta
		s.position.y = b["base_y"] + sin(_tempo * 3.0 + b["fase"]) * 4.0
		s.frame = int(s.get_meta("cor")) * 4 + 2 + int(_tempo * 12.0 + b["fase"]) % 2
		if b["vida"] <= 0.0:
			s.queue_free()
			_bandos.erase(b)


func _criar_pavao(lugar: String, base: Vector2) -> void:
	var n := _criar_interativo("res://arte/ox_pavao.png", 3, base, Vector2(12, 6), -40.0)
	n.olhar_para_jogador = false
	n.sprite.offset = Vector2(0, -18)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.scale = Vector2(1.3, 1.0)
	n.add_child(sombra)
	n.move_child(sombra, 0)
	n.interagiu.connect(_olhar_pavao.bind(n))
	_pavoes.append({"no": n, "casa": base, "alvo": base, "espera": 1.0, "aberto": 0.0, "lugar": lugar})


func _mover_pavoes(delta: float) -> void:
	for p in _pavoes:
		var n: Area2D = p["no"]
		var perto: bool = p["lugar"] == lugar_atual and n.position.distance_to(jogador.global_position) < 44.0
		if perto:
			p["aberto"] = 2.0                  # abre a cauda quando Adé chega perto
		p["aberto"] = maxf(0.0, p["aberto"] - delta)
		if p["aberto"] > 0.0:
			n.sprite.frame = 2
			continue
		if p["espera"] > 0.0:
			p["espera"] -= delta
			n.sprite.frame = 0
			if p["espera"] <= 0.0:
				p["alvo"] = p["casa"] + Vector2(randf_range(-28, 28), randf_range(-12, 12))
			continue
		var para: Vector2 = p["alvo"] - n.position
		if para.length() < 1.0:
			p["espera"] = randf_range(1.5, 3.5)
			continue
		n.position += para.normalized() * minf(12.0 * delta, para.length())
		n.sprite.flip_h = para.x < 0.0
		n.sprite.frame = int(_tempo * 4.0) % 2


func _olhar_pavao(_n: Area2D) -> void:
	await _falar("pavao")


func _criar_onca(lugar: String, base: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/ox_onca.png")
	s.hframes = 4
	s.offset = Vector2(0, -10)
	s.flip_h = true
	a.add_child(s)
	var sombra := Sprite2D.new()
	sombra.texture = TEX_SOMBRA
	sombra.scale = Vector2(2.2, 1.2)
	sombra.show_behind_parent = true
	s.add_child(sombra)
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 9.0
	forma.shape = circ
	forma.position = Vector2(0, -6)
	a.add_child(forma)
	var corpo := StaticBody2D.new()
	var f2 := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(26, 8)
	f2.shape = r2
	f2.position = Vector2(0, -4)
	corpo.add_child(f2)
	a.add_child(corpo)
	mundo.add_child(a)
	var o := {"a": a, "s": s, "casa": base, "lugar": lugar, "estado": "dorme", "tempo": 0.0}
	_oncas.append(o)
	_alvos.append({"tipo": "onca", "lugar": lugar, "onca": o})


func _mover_oncas(delta: float) -> void:
	for o in _oncas:
		var s: Sprite2D = o["s"]
		var a: Area2D = o["a"]
		o["tempo"] -= delta
		match o["estado"]:
			"dorme":
				s.frame = int(_tempo * 0.8) % 2          # respira devagar
				if o["lugar"] == lugar_atual and jogador.pode_mover and not _voltando:
					var d := a.position.distance_to(jogador.global_position)
					if d < 18.0 or (d < 80.0 and jogador.velocity.length() > 40.0):
						_acordar_onca(o)
			"acordada":
				s.frame = 2
				s.flip_h = jogador.global_position.x < a.position.x
				if o["tempo"] <= 0.0:
					_bote(o)
			"bote":
				s.frame = 3
				if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover and a.overlaps_body(jogador):
					_tomar_dano(a.global_position)
			"volta":
				s.frame = 2
				var para: Vector2 = o["casa"] - a.position
				if para.length() < 1.0:
					o["estado"] = "dorme"
					s.flip_h = true
				else:
					a.position += para.normalized() * minf(30.0 * delta, para.length())
					s.flip_h = para.x < 0.0


func _acordar_onca(o: Dictionary) -> void:
	if o["estado"] != "dorme":
		return
	o["estado"] = "acordada"
	o["tempo"] = 0.7
	Jogo.tocar_som("erro", -4.0)
	var t := create_tween()                      # o rugido: a onça se estica
	t.tween_property(o["s"], "scale", Vector2(1.12, 1.12), 0.15)
	t.tween_property(o["s"], "scale", Vector2.ONE, 0.2)
	if not _viu_onca:
		_viu_onca = true
		_mostrar_aviso("Uma onça! Perto dela, ande devagar (segure {devagar}).")


func _bote(o: Dictionary) -> void:
	o["estado"] = "bote"
	var a: Area2D = o["a"]
	var alvo := jogador.global_position
	var dir := (alvo - a.position)
	if dir.length() > 80.0:
		alvo = a.position + dir.normalized() * 80.0
	var t := create_tween()
	t.tween_property(a, "position", alvo, 0.3).set_ease(Tween.EASE_OUT)
	await t.finished
	await get_tree().create_timer(0.5).timeout
	o["estado"] = "volta"


# ------------------------------------------------------------------ quartinha de Exu (salvar)

## Guardado aqui, o jogo continua do começo da mata de Oxóssi.
func _local_do_caminho() -> String:
	return "oxossi"


func _pode_guardar() -> bool:
	return true
