extends "res://scripts/terreiro.gd"
## Prólogo, parte 2: Oríta Mẹ́ta, a encruzilhada — visão de cima, como o terreiro.
## Reaproveita do terreiro.gd tudo o que monta os lugares (mapas, portas, árvores, diálogo, barra de axé).
##
## Três lugares, cada um com um desafio até chegar a Exu:
##   enc_trilha → empurrar a pedra até o ponto riscado para abrir a cancela (e fugir do redemoinho)
##   enc_mata   → acender as lamparinas na ordem certa (leste, oeste, meio)
##   enc_orita  → a encruzilhada de verdade: dois caminhos que se cruzam, com velas nas esquinas.
##                Afundar a pedra no riacho para atravessar e olhar a estátua do meio dos dois lados
##                (o gorro vermelho de um lado e preto do outro, como no itã de Exu).
## Exu aparece e abre os caminhos: Adé sai da encruzilhada por qualquer um deles (norte, oeste ou leste)
## e chega ao mapa dos caminhos (cenas/mapa_mundo.tscn), onde escolhe o campo de um orixá.
##
## A volta (Jogo.get_meta("volta")): Adé sai do mapa pela encruzilhada e faz o caminho inverso, do cruzamento
## até a trilha, e de lá para o terreiro (saída "/", no sul da trilha). Os enigmas já estão resolvidos e
## os kiumbas não aparecem: Exu guarda o caminho. Depois da primeira volta, o mapa ganha o atalho direto.
##
## Cada redemoinho que pega Adé leva um búzio de axé; sem axé, ele volta para a entrada do lugar.

const LUGARES_ENC := {
	"enc_trilha": {"origem": Vector2(0, 0), "dentro": false},
	"enc_mata": {"origem": Vector2(0, 600), "dentro": false},
	"enc_orita": {"origem": Vector2(0, 1300), "dentro": false},
}
## letras do arquivo de objetos que ocupam o bloco (a pedra não passa por elas)
const BLOQUEIAM := ["R", "M", "Y", "J", "q", "o", "$", "?", "S", "y"]
const ORDEM_TOCHAS := ["leste", "oeste", "meio"]
const COR_NOITE := Color(0.2, 0.18, 0.34)     # noite fechada: quem ilumina são as tochas e as velas
const RAIO_LUZ := 34.0                         # kiumba não entra nesse raio em volta de uma tocha
const KIUMBA_VE := 76.0                        # de quão longe o kiumba enxerga Adé
const KIUMBA_VEL := 30.0

var axe := AXE_MAX
var _pedras: Array = []          # {no, forma, sprite, lugar, celula, inicio, afundou, movendo}
var _marcas: Array = []          # {lugar, celula, sprite}
var _cancelas := {}              # lugar → {sprite, forma, celulas, aberta}
var _tochas: Array = []          # {no, lugar, lado, acesa, luz}
var _sequencia: Array = []
var _redemoinhos: Array = []     # {no, sprite, de, ate, vel, fase}
var _ocupado := {}
var _pontes := {}
var _estatua: Area2D
var _velas: Array = []
var _viu := {}
var _exu_pos := Vector2.ZERO
var _ponto_volta := {}
var _placa_lida := {}
var _kiumbas: Array = []         # {no, sprite, casa, lugar, fase, sumiu}
var _pontos_de_luz: Array = []   # [lugar, posição] das tochas acesas (as lamparinas entram quando acendem)
var _avisou_kiumba := false
var _fogos: Array = []           # [sprite da tocha, fogo sem sombra, fase]
var _invulneravel := 0.0
var _quem_bateu := ""              # "redemoinho" ou "kiumbas": para o Exu zoar do jeito certo
var _empurrando := 0.0
## Quão fácil é empurrar as pedras: folga de lado (px) e quanto tempo segurando antes de a pedra andar.
var folga_empurrar := 9.0
var tempo_empurrar := 0.22
var _voltando := false
var _sem_axe_agora := false     # Exu está oferecendo a troca (ou é fim de jogo)
const BUZIOS_POR_AXE := 5       # quantos búzios coletados valem um búzio de axé


func _ready() -> void:
	lugares = LUGARES_ENC
	cor_fora = COR_NOITE
	estado = "caminho"
	Jogo.tocar_musica("musica_encruzilhada")
	_cor_fundo_antiga = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)
	_dados = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/encruzilhada.json"))
	_tileset = _criar_tileset()

	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_noite = CanvasModulate.new()
	add_child(_noite)
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	_ponto_volta["enc_trilha"] = jogador.global_position
	_preparar_tochas()
	_luz_de_ade()
	$HUD.esconder_contador = true
	Jogo.bornal.mostrar_hud(true)

	_criar_interface()
	for n in _hud_oferendas:
		n.visible = false
	_icone_buzio.position.x = 8          # sem o inventário, os búzios vão para o canto
	_contador_buzios.position.x = 21
	$Dialogo.evento.connect(_ao_evento)
	_entrar_lugar("enc_trilha")
	for nome in lugares:
		_criar_vagalumes(nome)
	if Jogo.has_meta("volta"):
		Jogo.remove_meta("volta")
		_preparar_volta()
	else:
		_inicio()


func _inicio() -> void:
	jogador.congelar(true)
	await get_tree().create_timer(0.8).timeout
	$HUD.mostrar_titulo("Oríta Mẹ́ta", "A Encruzilhada")
	await get_tree().create_timer(1.6).timeout
	await _falar("chegada")


func _process(delta: float) -> void:
	super._process(delta)
	_invulneravel = maxf(0.0, _invulneravel - delta)
	for r in _redemoinhos:
		var dist: float = maxf(1.0, r["de"].distance_to(r["ate"]))
		var u := pingpong(_tempo * r["vel"] / dist + r["fase"], 1.0)
		r["no"].position = r["de"].lerp(r["ate"], u)
		r["sprite"].frame = int(_tempo * 12.0 + r["fase"] * 10.0) % 4
		if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover and r["no"].overlaps_body(jogador):
			_tomar_dano(r["no"].global_position, "redemoinho")
	_vento_dos_redemoinhos(delta)
	for i in _velas.size():
		_velas[i].frame = int(_tempo * 5.0 + i * 1.7) % 2
	for f in _fogos:
		var q := int(_tempo * 8.0 + f[2]) % 3
		f[0].frame = q
		f[1].frame = q
	_mover_kiumbas(delta)
	_mover_rio(delta)
	if _estatua and estado == "caminho":
		_estatua.sprite.frame = 0 if jogador.global_position.x < _estatua.global_position.x else 1


# ------------------------------------------------------------------ o riacho corre
## A água do riacho (encruzilhada e mata de Oxóssi) corre da esquerda para a direita: riscos de luz descem com a correnteza e
## folhinhas passam boiando.
const SHADER_RIO := """
shader_type canvas_item;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 c = COLOR;
	vec2 p = floor(mundo);
	float corre = p.x - TIME * 14.0;                       // a correnteza
	float faixa = sin(p.y * 0.9 + sin(corre * 0.05) * 1.3);
	float risco = sin(corre * 0.21 + p.y * 1.7) * faixa;
	float luz = step(0.78, risco) * 0.13 + step(0.93, risco) * 0.13;
	float brilho = step(0.985, sin(p.x * 0.7 + p.y * 2.3 - TIME * 3.0)) * 0.12;
	float sombra = step(risco, -0.85) * 0.05;
	c.rgb += vec3(luz * 0.8 + brilho, luz + brilho, luz + brilho) * c.a - vec3(sombra) * c.a;
	COLOR = c;
}
"""
var _rio: Array = []            # folhinhas boiando: {s, y, xmin, xmax, vel, fase}


func _camada_terreno(origem: Vector2, i: int, camada: TileMapLayer) -> void:
	if i != 2:
		return
	var sh := Shader.new()
	sh.code = SHADER_RIO
	var m := ShaderMaterial.new()
	m.shader = sh
	camada.material = m
	# folhinhas boiando no riacho (só onde tem água)
	for nome in lugares:
		if lugares[nome]["origem"] != origem:
			continue
		var mapa: PackedStringArray = _mapas[nome] if _mapas.has(nome) else PackedStringArray()
		for y in mapa.size():
			var xs: Array = []
			for x in mapa[y].length():
				if mapa[y][x] == "~":
					xs.append(x)
			if xs.is_empty():
				continue
			for k in 3:
				var f := Sprite2D.new()
				f.texture = preload("res://arte/ox_folha.png")
				f.hframes = 3
				f.frame = randi() % 3
				f.z_index = -5
				f.scale = Vector2(1.4, 1.4)
				add_child(f)
				_rio.append({"s": f, "y": origem.y + y * TILE + 8.0, "xmin": origem.x + xs[0] * TILE,
					"xmax": origem.x + (xs[-1] + 1) * TILE, "vel": randf_range(10, 16), "fase": randf() * TAU,
					"x": origem.x + randf_range(xs[0], xs[-1] + 1) * TILE})


func _mover_rio(delta: float) -> void:
	for f in _rio:
		f["x"] += f["vel"] * delta
		if f["x"] > f["xmax"] - 2:
			f["x"] = f["xmin"] + 2
			f["fase"] = randf() * TAU
		var s: Sprite2D = f["s"]
		s.position = Vector2(roundf(f["x"]), roundf(f["y"] + sin(_tempo * 1.3 + f["fase"]) * 3.0))
		s.rotation = sin(_tempo * 0.9 + f["fase"]) * 0.6


# ------------------------------------------------------------------ lugares

func teleportar(nome: String, posicao: Vector2) -> void:
	super.teleportar(nome, posicao)
	_ponto_volta[nome] = posicao
	_resetar_pedras(nome)


func _chave(lugar: String, celula: Vector2i) -> String:
	return "%s:%d,%d" % [lugar, celula.x, celula.y]


func _base_celula(lugar: String, celula: Vector2i) -> Vector2:
	return lugares[lugar]["origem"] + Vector2(celula.x * TILE + TILE / 2.0, (celula.y + 1) * TILE)


func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	if c in BLOQUEIAM:
		_ocupado[_chave(lugar, celula)] = true
	match c:
		"@":
			_criar_pedra(lugar, celula, base)
		"`":
			# a entrada da fase: andando de volta por ela, Adé pode voltar ao Ọ̀run
			var area := Area2D.new()
			area.collision_layer = 0
			area.collision_mask = 2
			area.position = base - Vector2(0, TILE / 2.0)
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2(TILE, 8)
			forma.shape = ret
			area.add_child(forma)
			var para_dentro := Vector2(0, 1) if celula.y == 0 else Vector2(0, -1)
			area.body_entered.connect(_na_saida_para_o_orun.bind(para_dentro))
			add_child(area)
		"&":
			var s := Sprite2D.new()
			s.texture = preload("res://arte/enc_marca.png")
			s.hframes = 2
			s.position = base - Vector2(0, TILE / 2.0)
			s.z_index = -4
			add_child(s)
			_marcas.append({"lugar": lugar, "celula": celula, "sprite": s})
		"!":
			_criar_cancela(lugar, celula, base)
		"$":
			var t := _criar_interativo("res://arte/enc_tocha.png", 2, base, Vector2(8, 6), -38.0)
			var tocha := {"no": t, "lugar": lugar, "lado": "", "acesa": false, "luz": null}
			t.interagiu.connect(_acender.bind(tocha))
			_tochas.append(tocha)
		"<", "^":
			_criar_redemoinho(lugar, celula, base, c == "<")
		"?":
			var p := _criar_interativo("res://arte/enc_placa.png", 1, base, Vector2(12, 6), -30.0)
			p.interagiu.connect(_ler_placa.bind(lugar))
		"S":
			_estatua = _criar_interativo("res://arte/enc_estatua.png", 3, base, Vector2(14, 8), -54.0)
			_estatua.olhar_para_jogador = false
			(_estatua.get_node("Alcance").shape as CircleShape2D).radius = 30.0
			_estatua.interagiu.connect(_olhar_estatua)
			_exu_pos = base          # Exu aparece no lugar da estátua, bem no meio do cruzamento
			_luz(base + Vector2(0, -20), Color(0.9, 0.5, 0.9), 1.6, 1.4, false)
		"y":
			_criar_tochao(lugar, base)
		"k":
			_criar_kiumba(lugar, base)
		"x":
			if _exu_pos == Vector2.ZERO:
				_exu_pos = base
		"%":
			# velas vermelha e preta nas esquinas da encruzilhada
			var v := Sprite2D.new()
			v.texture = preload("res://arte/enc_velas.png")
			v.hframes = 2
			v.offset = Vector2(0, -8)
			v.position = base
			mundo.add_child(v)
			_velas.append(v)
			_luz(base + Vector2(0, -12), Color(1.0, 0.55, 0.3), 1.1, 1.3, true)
		"/":
			# saída para o terreiro (só na volta)
			var area_sul := Area2D.new()
			area_sul.collision_layer = 0
			area_sul.collision_mask = 2
			area_sul.position = base - Vector2(0, TILE / 2.0)
			var forma_sul := CollisionShape2D.new()
			var ret_sul := RectangleShape2D.new()
			ret_sul.size = Vector2(14, 12)
			forma_sul.shape = ret_sul
			area_sul.add_child(forma_sul)
			area_sul.body_entered.connect(_voltar_ao_terreiro)
			add_child(area_sul)
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
		_:
			super._criar_objeto(lugar, c, celula, base, chao)


# ------------------------------------------------------------------ pedra que se empurra

func _criar_pedra(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var corpo := StaticBody2D.new()
	corpo.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/enc_pedra.png")
	s.offset = Vector2(0, -10)
	corpo.add_child(s)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(14, 12)
	forma.shape = ret
	forma.position = Vector2(0, -7)
	corpo.add_child(forma)
	mundo.add_child(corpo)
	_pedras.append({"no": corpo, "forma": forma, "sprite": s, "lugar": lugar, "celula": celula,
		"inicio": celula, "afundou": false, "movendo": false})


func _physics_process(delta: float) -> void:
	if not jogador or not jogador.pode_mover or _voltando:
		_empurrando = 0.0
		return
	var ex := Input.get_axis("esquerda", "direita")
	var ey := Input.get_axis("cima", "baixo")
	var dir := Vector2i.ZERO
	if absf(ex) > 0.5 and absf(ey) < 0.3:
		dir = Vector2i(int(signf(ex)), 0)
	elif absf(ey) > 0.5 and absf(ex) < 0.3:
		dir = Vector2i(0, int(signf(ey)))
	var alvo = null
	if dir != Vector2i.ZERO:
		for p in _pedras:
			if p["lugar"] != lugar_atual or p["afundou"] or p["movendo"]:
				continue
			var rel: Vector2 = (p["no"].position + Vector2(0, -7)) - (jogador.global_position + Vector2(0, -3))
			var encostou := false
			if dir.x != 0:
				encostou = absf(rel.y) < folga_empurrar and signf(rel.x) == dir.x and absf(rel.x) < 15.0
			else:
				encostou = absf(rel.x) < folga_empurrar and signf(rel.y) == dir.y and absf(rel.y) < 15.0
			if encostou:
				alvo = p
				break
	if alvo == null:
		_empurrando = 0.0
		return
	_empurrando += delta
	if _empurrando >= tempo_empurrar:
		_empurrando = 0.0
		# Adé se ajeita atrás da pedra, para o próximo empurrão sair reto
		var centro: Vector2 = alvo["no"].position
		if dir.x != 0:
			jogador.global_position.y = centro.y - 4.0
		else:
			jogador.global_position.x = centro.x
		_empurrar(alvo, dir)


func _livre_para_pedra(p: Dictionary, dest: Vector2i) -> bool:
	var lugar: String = p["lugar"]
	var letra := _letra(_mapas[lugar], dest.x, dest.y)
	if not (letra in ANDAVEL or letra == "~"):
		return false
	if _ocupado.has(_chave(lugar, dest)) or _e_porta(lugar, dest):
		return false
	for q in _pedras:
		if q != p and q["lugar"] == lugar and q["celula"] == dest and not q["afundou"]:
			return false
	return true


func _empurrar(p: Dictionary, dir: Vector2i) -> void:
	var dest: Vector2i = p["celula"] + dir
	if not _livre_para_pedra(p, dest):
		return
	var lugar: String = p["lugar"]
	var vai_afundar := _letra(_mapas[lugar], dest.x, dest.y) == "~" and not _pontes.has(_chave(lugar, dest))
	p["movendo"] = true
	p["celula"] = dest
	Jogo.tocar_som("pedra_arrasta", -8.0)
	var t := create_tween()
	t.tween_property(p["no"], "position", _base_celula(lugar, dest), 0.2)
	await t.finished
	p["movendo"] = false
	if vai_afundar:
		await _afundar(p)
	_checar_marcas(lugar)


## A pedra cai no riacho e vira uma pedra de pisar: dá para atravessar por cima dela.
func _afundar(p: Dictionary) -> void:
	p["afundou"] = true
	p["forma"].set_deferred("disabled", true)
	var s: Sprite2D = p["sprite"]
	s.z_index = -4
	var t := create_tween()
	t.tween_property(s, "offset:y", -6.0, 0.25)
	t.parallel().tween_property(s, "modulate", Color(0.62, 0.72, 0.88), 0.25)
	Jogo.tocar_som("agua_cai", -6.0)
	_respingo(p["no"].global_position + Vector2(0, -6))
	var cel: Vector2i = p["celula"]
	_pontes[_chave(p["lugar"], cel)] = true
	_chaos[p["lugar"]].erase_cell(cel)      # tira a água "sólida" deste bloco
	await t.finished
	await _ao_afundar_pedra(p)


## O que se diz quando uma pedra vira ponte (as fases podem trocar).
func _ao_afundar_pedra(_p: Dictionary) -> void:
	await _falar("pedra_ponte")


func _respingo(pos: Vector2) -> void:
	var f := CPUParticles2D.new()
	f.position = pos
	f.z_index = 5
	f.amount = 24
	f.lifetime = 0.7
	f.one_shot = true
	f.explosiveness = 0.9
	f.direction = Vector2(0, -1)
	f.spread = 70.0
	f.gravity = Vector2(0, 160)
	f.initial_velocity_min = 30.0
	f.initial_velocity_max = 60.0
	f.color = Color(0.75, 0.88, 1.0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.2).timeout.connect(f.queue_free)


func _checar_marcas(lugar: String) -> void:
	var todas := true
	var alguma := false
	for m in _marcas:
		if m["lugar"] != lugar:
			continue
		alguma = true
		var em_cima := false
		for p in _pedras:
			if p["lugar"] == lugar and p["celula"] == m["celula"] and not p["afundou"]:
				em_cima = true
		m["sprite"].frame = 1 if em_cima else 0
		todas = todas and em_cima
	if alguma and todas:
		_abrir_cancela(lugar)


## Volta as pedras para o começo (se o enigma daquele lugar ainda não foi resolvido).
func _resetar_pedras(lugar: String) -> bool:
	if _cancelas.has(lugar) and _cancelas[lugar]["aberta"] and lugar != "enc_orita":
		return false
	var mexeu := false
	for p in _pedras:
		if p["lugar"] != lugar or p["afundou"] or p["movendo"] or p["celula"] == p["inicio"]:
			continue
		p["celula"] = p["inicio"]
		p["no"].position = _base_celula(lugar, p["inicio"])
		mexeu = true
	if mexeu:
		_checar_marcas(lugar)
	return mexeu


# ------------------------------------------------------------------ cancelas

func _criar_cancela(lugar: String, celula: Vector2i, base: Vector2) -> void:
	var n := Node2D.new()
	n.position = base
	mundo.add_child(n)
	var s := Sprite2D.new()
	s.texture = preload("res://arte/enc_cancela.png")
	s.hframes = 2
	s.offset = Vector2(0, -15)
	n.add_child(s)
	var corpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(48, 10)
	forma.shape = ret
	forma.position = Vector2(0, -6)
	corpo.add_child(forma)
	n.add_child(corpo)
	var celulas := []
	for dx in [-1, 0, 1]:
		var c := celula + Vector2i(dx, 0)
		celulas.append(c)
		_ocupado[_chave(lugar, c)] = true
	_cancelas[lugar] = {"sprite": s, "forma": forma, "celulas": celulas, "aberta": false}


func _abrir_cancela(lugar: String) -> void:
	if not _cancelas.has(lugar) or _cancelas[lugar]["aberta"]:
		return
	var c: Dictionary = _cancelas[lugar]
	c["aberta"] = true
	c["sprite"].frame = 1
	c["forma"].set_deferred("disabled", true)
	for cel in c["celulas"]:
		_ocupado.erase(_chave(lugar, cel))
	Jogo.tocar_som("caminho", -4.0)
	var camera: Camera2D = jogador.get_node("Camera")
	var t := create_tween()
	for i in 6:
		t.tween_property(camera, "offset", Vector2(randf_range(-2, 2), randf_range(-1, 1)), 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.04)
	if lugar == "enc_trilha":
		_mostrar_aviso("A cancela se abriu!")


# ------------------------------------------------------------------ lamparinas da mata

func _preparar_tochas() -> void:
	var da_mata := _tochas.filter(func(t): return t["lugar"] == "enc_mata")
	da_mata.sort_custom(func(a, b): return a["no"].position.x < b["no"].position.x)
	for i in da_mata.size():
		da_mata[i]["lado"] = "oeste" if i == 0 else ("leste" if i == da_mata.size() - 1 else "meio")


func _acender(t: Dictionary) -> void:
	if t["acesa"] or (_cancelas.has(t["lugar"]) and _cancelas[t["lugar"]]["aberta"]):
		return
	t["acesa"] = true
	t["no"].sprite.frame = 1
	t["luz"] = _luz(t["no"].position + Vector2(0, -22), Color(1.0, 0.62, 0.3), 3.0, 1.5, true)
	Jogo.tocar_som("tocha_acende", -4.0)
	_sequencia.append(t["lado"])
	var n := _sequencia.size()
	if _sequencia[n - 1] != ORDEM_TOCHAS[n - 1]:
		jogador.congelar(true)
		await get_tree().create_timer(0.7).timeout
		for x in _tochas:
			if x["acesa"] and x["lugar"] == t["lugar"]:
				_apagar(x)
		_sequencia.clear()
		Jogo.tocar_som("erro", -6.0)
		await _falar("tocha_errada")
	elif n == ORDEM_TOCHAS.size():
		await get_tree().create_timer(0.4).timeout
		_abrir_cancela(t["lugar"])
		await _falar("cancela_tochas")


func _apagar(t: Dictionary) -> void:
	t["acesa"] = false
	t["no"].sprite.frame = 0
	var l: PointLight2D = t["luz"]
	if l:
		_chamas = _chamas.filter(func(c): return c[0] != l)
		l.queue_free()
	t["luz"] = null


# ------------------------------------------------------------------ redemoinhos e axé

func _criar_redemoinho(lugar: String, celula: Vector2i, base: Vector2, de_lado: bool) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/enc_redemoinho.png")
	s.hframes = 4
	s.offset = Vector2(0, -14)
	a.add_child(s)
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 6.0
	forma.shape = circ
	forma.position = Vector2(0, -5)
	a.add_child(forma)
	mundo.add_child(a)
	# anda de um lado ao outro até encontrar o que não é chão
	var passo := Vector2i(1, 0) if de_lado else Vector2i(0, 1)
	var mapa: PackedStringArray = _mapas[lugar]
	var ini := celula
	while _letra(mapa, ini.x - passo.x, ini.y - passo.y) in ANDAVEL:
		ini -= passo
	var fim := celula
	while _letra(mapa, fim.x + passo.x, fim.y + passo.y) in ANDAVEL:
		fim += passo
	_redemoinhos.append({"no": a, "sprite": s, "de": _base_celula(lugar, ini), "ate": _base_celula(lugar, fim),
		"vel": randf_range(38.0, 50.0), "fase": randf(), "lugar": lugar})


## O vento do redemoinho mais perto de Adé (só um de cada vez, para não embolar).
var _som_redemoinho := 0.0


func _vento_dos_redemoinhos(delta: float) -> void:
	_som_redemoinho -= delta
	if _som_redemoinho > 0.0:
		return
	var perto: Area2D = null
	for r in _redemoinhos:
		if r["lugar"] == lugar_atual and (perto == null or r["no"].position.distance_to(jogador.global_position)
				< perto.position.distance_to(jogador.global_position)):
			perto = r["no"]
	if perto and perto.position.distance_to(jogador.global_position) < 110.0:
		_som_redemoinho = 1.0
		som_perto("redemoinho", perto.position, -6.0)


func _tomar_dano(de: Vector2, quem := "") -> void:
	_invulneravel = 1.4
	_quem_bateu = quem
	axe -= 1
	_atualizar_axe()
	Jogo.tocar_som("dano", -3.0)
	get_tree().create_timer(0.18).timeout.connect(func(): Jogo.tocar_som("perde_axe", -8.0))
	var dir := jogador.global_position - de
	if dir.length() < 1.0:
		dir = Vector2(0, 1)
	jogador.move_and_collide(dir.normalized() * 18.0)
	var piscar := create_tween()
	for i in 7:
		piscar.tween_property(jogador, "modulate:a", 0.25, 0.08)
		piscar.tween_property(jogador, "modulate:a", 1.0, 0.08)
	if axe <= 0:
		_sem_axe()


func _atualizar_axe() -> void:
	for i in _axe_icones.size():
		_axe_icones[i].modulate = Color(1, 1, 1, 1) if i < axe else Color(0.3, 0.25, 0.35, 0.55)


## Acabaram os búzios de axé. Exu surge na fumaça ao lado de Adé e oferece trocar os búzios que ele juntou
## pelo caminho: cada BUZIOS_POR_AXE búzios valem um búzio de axé. Sem búzios bastantes (ou sem querer trocar),
## é fim de jogo: o menu oferece voltar ao último caminho guardado ou ao título.
func _sem_axe() -> void:
	if _sem_axe_agora:
		return
	_sem_axe_agora = true
	_voltando = true
	jogador.congelar(true)
	Jogo.tocar_som("perde_axe", -2.0)
	var sp: Sprite2D = jogador.sprite
	var piscar := create_tween()
	for i in 4:
		piscar.tween_property(sp, "modulate", Color(1, 0.4, 0.4), 0.1)
		piscar.tween_property(sp, "modulate", Color.WHITE, 0.1)
	await piscar.finished
	sp.modulate = Color(0.75, 0.7, 0.8)
	var escurece := create_tween()
	escurece.tween_property(_cortina, "color", Color(0.12, 0.02, 0.06, 0.45), 0.6)
	await escurece.finished
	# Exu surge ao lado de Adé
	var lado := Vector2(22, 0) if _livre_para_exu(jogador.global_position + Vector2(22, 0)) else Vector2(-22, 0)
	var e := _exu_surge(jogador.global_position + lado)
	await get_tree().create_timer(1.1).timeout
	jogador.olhar_para(e.position)
	var trocou := await _exu_troca_buzios()
	# Exu vai embora na fumaça
	_fumaca_vermelha(e.position + Vector2(0, -12))
	var some := create_tween()
	some.tween_property(e, "modulate:a", 0.0, 0.6)
	some.tween_callback(e.queue_free)
	await get_tree().create_timer(0.5).timeout
	if trocou:
		_estrelinhas(jogador.global_position + Vector2(0, -12))
		var clareia := create_tween()
		clareia.tween_property(_cortina, "color", Color(0, 0, 0, 0), 0.6)
		clareia.parallel().tween_property(sp, "modulate", Color.WHITE, 0.6)
		await clareia.finished
		_sem_axe_agora = false
		_voltando = false
		_invulneravel = 1.5
		jogador.congelar(false)
		_mostrar_aviso("O axé voltou! Búzios guardados: %d" % Jogo.buzios)
		return
	# fim de jogo
	estado = "fim_de_jogo"
	var cai := create_tween()
	cai.tween_property(sp, "modulate", Color(0.5, 0.45, 0.6, 0.0), 1.0)
	cai.parallel().tween_property(_cortina, "color", Color(0.12, 0.02, 0.06, 0.85), 1.2)
	await cai.finished
	await get_tree().create_timer(0.3).timeout
	Jogo.menu.fim_de_jogo()


## Exu propõe a troca. Devolve true se Adé trocou búzios por axé.
func _exu_troca_buzios() -> bool:
	var n: int = Jogo.buzios
	var pode := mini(AXE_MAX, n / BUZIOS_POR_AXE)
	var zoeira := "Caiu de novo?"
	if _quem_bateu == "redemoinho":
		zoeira = "O redemoinho te rodou feito pião e te jogou no chão!"
	elif _quem_bateu == "kiumbas":
		zoeira = "Os kiumbas te pegaram de susto, hein? Correndo de sombra..."
	var falas := [
		{"quem": "Èṣù", "yo": "Láròyé!", "pt": "Laroyê, menino! Há há há! %s Desse jeito vou ter que te levar no colo até a Vó!" % zoeira},
	]
	if pode == 0:
		falas.append({"quem": "Èṣù", "yo": "Hi hi hi!", "pt": "Com %d búzios eu devolvo um búzio de axé... mas você só juntou %d. Com isso eu compro um pirulito, não um axé!" % [BUZIOS_POR_AXE, n]})
		falas.append({"quem": "Èṣù", "yo": "", "pt": "Da próxima vez, junte os búzios do caminho. Eu guardo o que é seu... e conto pra Vó que você caiu!"})
		await _falar_linhas(falas)
		jogador.congelar(true)
		return false
	falas.append({"quem": "Èṣù", "yo": "", "pt": "Olha só, juntou %d búzios! Tá rico, hein? Cada %d búzios valem um búzio de axé. Quer trocar?" % [n, BUZIOS_POR_AXE]})
	await _falar_linhas(falas)
	jogador.congelar(true)
	var opcoes := []
	for k in range(1, pode + 1):
		opcoes.append("Trocar %d búzios por %d de axé" % [k * BUZIOS_POR_AXE, k])
	opcoes.append("Não quero trocar")
	var r: Dictionary = {}
	while r.get("acao", "") != "ok":
		r = await Jogo.menu.escolher("Búzios guardados: %d" % n, opcoes, pode - 1)
	jogador.congelar(true)
	if r["i"] >= pode:
		await _falar_linhas([{"quem": "Èṣù", "yo": "Há há há!", "pt": "Então o caminho acaba aqui... por enquanto. Vou ficar rindo desse tombo até amanhã."}])
		jogador.congelar(true)
		return false
	var k: int = r["i"] + 1
	Jogo.buzios -= k * BUZIOS_POR_AXE
	axe = k
	_atualizar_axe()
	Jogo.tocar_som("troca_exu", -2.0)
	await _falar_linhas([{"quem": "Èṣù", "yo": "Hi hi hi!", "pt": "Feito! O axé volta pra quem sabe guardar o que junta. Mas da próxima vez eu cobro em farofa."}])
	jogador.congelar(true)
	return true


## Exu aparece do lado de Adé onde não tem parede nem água.
func _livre_para_exu(pos: Vector2) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos + Vector2(0, -2)
	q.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


# ------------------------------------------------------------------ escuridão, tochas e kiumbas

## Uma luzinha fraca em volta de Adé, para ele não sumir no escuro.
func _luz_de_ade() -> void:
	var l := PointLight2D.new()
	l.texture = _luz_tex
	l.color = Color(0.75, 0.8, 1.0)
	l.energy = 0.5
	l.texture_scale = 0.55
	l.position = Vector2(0, -10)
	jogador.add_child(l)


func _criar_tochao(lugar: String, base: Vector2) -> void:
	var n := StaticBody2D.new()
	n.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/enc_tochao.png")
	s.hframes = 3
	s.offset = Vector2(0, -15)
	s.frame = randi() % 3
	n.add_child(s)
	var fogo := Sprite2D.new()           # o fogo brilha mesmo no escuro
	fogo.texture = s.texture
	fogo.hframes = 3
	fogo.offset = s.offset
	fogo.material = _material_sem_sombra()
	fogo.modulate = Color(1, 1, 1, 0.85)
	n.add_child(fogo)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(6, 4)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	n.add_child(forma)
	mundo.add_child(n)
	_fogos.append([s, fogo, randf() * 3.0])
	_luz(base + Vector2(0, -26), Color(1.0, 0.6, 0.28), 3.0, 1.15, true)
	_pontos_de_luz.append([lugar, base])
	# só a parte de cima (o fogo) fica sem sombra: corta o sprite claro na altura do cesto
	fogo.region_enabled = true
	fogo.region_rect = Rect2(0, 0, 48, 13)
	fogo.offset = Vector2(0, -24.5)


func _criar_kiumba(lugar: String, base: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = base
	var s := Sprite2D.new()
	s.texture = preload("res://arte/enc_kiumba.png")
	s.hframes = 4
	s.offset = Vector2(0, -12)
	s.material = _material_sem_sombra()   # os olhos vermelhos aparecem no escuro
	s.modulate = Color(1, 1, 1, 0.9)
	a.add_child(s)
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 6.0
	forma.shape = circ
	forma.position = Vector2(0, -8)
	a.add_child(forma)
	mundo.add_child(a)
	_kiumbas.append({"no": a, "sprite": s, "casa": base, "lugar": lugar, "fase": randf() * TAU, "sumiu": false})


func _na_luz(lugar: String, pos: Vector2, folga := 0.0) -> bool:
	for p in _pontos_de_luz:
		if p[0] == lugar and pos.distance_to(p[1]) < RAIO_LUZ + folga:
			return true
	for t in _tochas:
		if t["acesa"] and t["lugar"] == lugar and pos.distance_to(t["no"].position) < RAIO_LUZ + folga:
			return true
	return false


func _mover_kiumbas(delta: float) -> void:
	for k in _kiumbas:
		if k["sumiu"]:
			continue
		var no: Area2D = k["no"]
		var s: Sprite2D = k["sprite"]
		s.frame = int(_tempo * 6.0 + k["fase"]) % 4
		if k["lugar"] != lugar_atual:
			continue
		var alvo: Vector2
		var vel := KIUMBA_VEL
		var ade := jogador.global_position
		var ve := no.position.distance_to(ade) < KIUMBA_VE and not _na_luz(k["lugar"], ade)
		if ve and not k.get("viu", false) and jogador.pode_mover:
			Jogo.tocar_som("kiumba_ve", -6.0)        # o kiumba viu Adé
		k["viu"] = ve
		if ve and jogador.pode_mover and not _voltando:
			alvo = ade
		else:
			# volta para perto de casa, flutuando em círculos
			alvo = k["casa"] + Vector2(cos(_tempo * 0.8 + k["fase"]) * 14.0, sin(_tempo * 1.1 + k["fase"]) * 8.0)
			vel = KIUMBA_VEL * 0.6
		var passo := (alvo - no.position).limit_length(vel * delta)
		var novo := no.position + passo
		if not _na_luz(k["lugar"], novo):       # a luz das tochas espanta o kiumba
			no.position = novo
		s.flip_h = passo.x < 0.0
		s.position.y = sin(_tempo * 3.0 + k["fase"]) * 1.5
		if ve and _invulneravel <= 0.0 and not _voltando and jogador.pode_mover and no.overlaps_body(jogador):
			_tomar_dano(no.global_position, "kiumbas")
			_kiumba_recua(k)
			if not _avisou_kiumba:
				_avisou_kiumba = true
				_mostrar_aviso("Um kiumba! As sombras têm medo da luz das tochas.")


func _kiumba_recua(k: Dictionary) -> void:
	k["sumiu"] = true
	k["viu"] = false
	Jogo.tocar_som("kiumba_some", -6.0)
	var no: Area2D = k["no"]
	var t := create_tween()
	t.tween_property(no, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): no.position = k["casa"])
	t.tween_interval(1.6)
	t.tween_property(no, "modulate:a", 1.0, 0.6)
	t.tween_callback(func(): k["sumiu"] = false)


## Quando Exu chega, as sombras e os redemoinhos se desfazem: ele é o guardião da encruzilhada.
func _espantar_sombras() -> void:
	if not _kiumbas.is_empty() or not _redemoinhos.is_empty():
		Jogo.tocar_som("kiumba_some", -4.0)
	for k in _kiumbas:
		k["sumiu"] = true
		var t := create_tween()
		t.tween_property(k["no"], "scale", Vector2(1.6, 0.2), 0.5)
		t.parallel().tween_property(k["no"], "modulate:a", 0.0, 0.5)
		t.tween_callback(k["no"].queue_free)
	for r in _redemoinhos:
		var t := create_tween()
		t.tween_property(r["no"], "modulate:a", 0.0, 0.6)
		t.tween_callback(r["no"].queue_free)
	_redemoinhos.clear()


# ------------------------------------------------------------------ placas, estátua e Exu

func _ler_placa(lugar: String) -> void:
	await _falar("placa_" + lugar.trim_prefix("enc_"))
	if _placa_lida.has(lugar) and _resetar_pedras(lugar):
		Jogo.tocar_som("caminho", -12.0)
		await _falar("placa_reset")
	_placa_lida[lugar] = true


func _olhar_estatua() -> void:
	if estado != "caminho":
		return
	var lado := "vermelho" if jogador.global_position.x < _estatua.global_position.x else "preto"
	var antes := _viu.size()
	_viu[lado] = true
	if _viu.size() == 2 and antes == 1:
		estado = "exu"
		_estatua.sprite.frame = 2
		_estatua.ativo = false
		await _falar("estatua_entendeu")
		await get_tree().create_timer(1.2).timeout
		jogador.olhar_para(_exu_pos)
		await _falar("exu")
		await _falar("exu_fim")
		estado = "livre"
		_mostrar_aviso("Escolha um caminho e saia da encruzilhada.")
	else:
		await _falar("estatua_" + lado)


func _ao_evento(nome: String) -> void:
	match nome:
		"exu_chega":
			marcas["e"] = _exu_pos
			# a estátua se desfaz na fumaça e Exu toma o lugar dela
			_estatua.get_node("Corpo/Forma").set_deferred("disabled", true)
			create_tween().tween_property(_estatua, "modulate:a", 0.0, 0.8)
			_tremer()
			_exu_aparece()
			_espantar_sombras()
			var ponto := _ponto_de_conversa(_exu_pos, Vector2(12, 6), 26.0, -42.0)
			ponto.interagiu.connect(_falar_com_exu)
		"mapa":
			_pendente = "mapa"
		"abrir_caminhos", "abrir_norte":
			_abrir_cancela("enc_orita")
		_:
			super._ao_evento(nome)


func _falar_com_exu() -> void:
	if estado == "volta":
		await _falar("exu_volta_depois")
		return
	if estado != "livre":
		return
	await _falar("exu_depois")


func _abrir_mapa(revelar: bool) -> void:
	jogador.congelar(true)
	var mapa: CanvasLayer = preload("res://scripts/mapa_campos.gd").new()
	add_child(mapa)
	await mapa.abrir(_dados["campos"], revelar)
	await get_tree().create_timer(0.3).timeout
	jogador.congelar(false)


func _sair(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador") or estado != "livre":
		return
	estado = "saindo"
	jogador.congelar(true)
	Jogo.mudar_cena("res://cenas/mapa_mundo.tscn")


# ------------------------------------------------------------------ a volta para o terreiro

func _preparar_volta() -> void:
	estado = "volta"
	# tudo já foi resolvido na ida: cancelas abertas, lamparinas acesas, pedra no riacho
	for lugar in _cancelas:
		var c: Dictionary = _cancelas[lugar]
		c["aberta"] = true
		c["sprite"].frame = 1
		c["forma"].set_deferred("disabled", true)
		for cel in c["celulas"]:
			_ocupado.erase(_chave(lugar, cel))
	for t in _tochas:
		t["acesa"] = true
		t["no"].sprite.frame = 1
		t["no"].ativo = false
		t["luz"] = _luz(t["no"].position + Vector2(0, -22), Color(1.0, 0.62, 0.3), 3.0, 1.5, true)
		_pontos_de_luz.append([t["lugar"], t["no"].position])
	for p in _pedras:
		if p["lugar"] == "enc_orita":
			_pedra_no_riacho(p)
	_espantar_sombras()
	for k in _kiumbas:
		k["no"].visible = false
	# Exu já está no meio da encruzilhada, no lugar da estátua
	if _estatua:
		_estatua.visible = false
		_estatua.ativo = false
		_estatua.get_node("Corpo/Forma").set_deferred("disabled", true)
	marcas["e"] = _exu_pos
	var origem: Vector2 = lugares["enc_orita"]["origem"]
	teleportar("enc_orita", origem + Vector2(13 * TILE + TILE, 2 * TILE - 2))
	jogador.direcao_olhar = "frente"
	jogador.congelar(true)
	_exu_aparece()
	_ponto_de_conversa(_exu_pos, Vector2(12, 6), 26.0, -42.0).interagiu.connect(_falar_com_exu)
	await get_tree().create_timer(0.8).timeout
	$HUD.mostrar_titulo("Oríta Mẹ́ta", "O caminho de volta")
	await get_tree().create_timer(1.6).timeout
	await _falar("volta")


## Põe a pedra no primeiro bloco de água abaixo dela, já afundada (a passagem do riacho).
func _pedra_no_riacho(p: Dictionary) -> void:
	var lugar: String = p["lugar"]
	var cel: Vector2i = p["celula"]
	var mapa: PackedStringArray = _mapas[lugar]
	while cel.y > 0 and _letra(mapa, cel.x, cel.y) != "~":
		cel.y -= 1
	if _letra(mapa, cel.x, cel.y) != "~":
		return
	p["celula"] = cel
	p["no"].position = _base_celula(lugar, cel)
	p["afundou"] = true
	p["forma"].set_deferred("disabled", true)
	var s: Sprite2D = p["sprite"]
	s.z_index = -4
	s.offset.y = -6.0
	s.modulate = Color(0.62, 0.72, 0.88)
	_pontes[_chave(lugar, cel)] = true
	_chaos[lugar].erase_cell(cel)


func _voltar_ao_terreiro(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador") or estado != "volta":
		return
	estado = "saindo"
	jogador.congelar(true)
	Jogo.set_meta("volta_feita", true)     # daqui para a frente, o mapa tem o atalho direto
	Jogo.set_meta("retorno", true)
	Jogo.mudar_cena("res://cenas/terreiro.tscn")


# ------------------------------------------------------------------ quartinha de Exu (salvar)

## Guardado aqui, o jogo continua no mapa, na encruzilhada.
func _local_do_caminho() -> String:
	return "orita"


## Só depois que Exu chegou (ou na volta, quando ele já está no cruzamento).
func _pode_guardar() -> bool:
	return estado in ["livre", "volta"]


# ------------------------------------------------------------------ a entrada da fase (volta ao Ọ̀run)

var _saindo_pela_entrada := false


func _na_saida_para_o_orun(corpo: Node2D, _para_dentro: Vector2) -> void:
	if not corpo.is_in_group("jogador") or _saindo_pela_entrada or not jogador.pode_mover:
		return
	if not has_method("voltar_ao_mapa") or estado == "saindo":
		return
	_saindo_pela_entrada = true
	call("voltar_ao_mapa")
