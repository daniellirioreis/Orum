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
## Exu aparece, abre o mapa dos campos dos orixás e libera o caminho de Ogum (fim do prólogo).
##
## Cada redemoinho que pega Adé leva um búzio de axé; sem axé, ele volta para a entrada do lugar.

const LUGARES_ENC := {
	"enc_trilha": {"origem": Vector2(0, 0), "dentro": false},
	"enc_mata": {"origem": Vector2(0, 600), "dentro": false},
	"enc_orita": {"origem": Vector2(0, 1300), "dentro": false},
}
const AXE_MAX := 5
## letras do arquivo de objetos que ocupam o bloco (a pedra não passa por elas)
const BLOQUEIAM := ["R", "M", "Y", "J", "q", "o", "$", "?", "S"]
const ORDEM_TOCHAS := ["leste", "oeste", "meio"]
const COR_NOITE := Color(0.5, 0.45, 0.76)

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
var _invulneravel := 0.0
var _empurrando := 0.0
var _voltando := false


func _ready() -> void:
	lugares = LUGARES_ENC
	cor_fora = COR_NOITE
	estado = "caminho"
	Jogo.tocar_musica()
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
	$HUD.esconder_contador = true

	_criar_interface()
	for n in _hud_oferendas:
		n.visible = false
	_icone_buzio.position.x = 8          # sem o inventário, os búzios vão para o canto
	_contador_buzios.position.x = 21
	$Dialogo.evento.connect(_ao_evento)
	_entrar_lugar("enc_trilha")
	for nome in lugares:
		_criar_vagalumes(nome)
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
			_tomar_dano(r["no"].global_position)
	for i in _velas.size():
		_velas[i].frame = int(_tempo * 5.0 + i * 1.7) % 2
	if _estatua and estado == "caminho":
		_estatua.sprite.frame = 0 if jogador.global_position.x < _estatua.global_position.x else 1


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
				encostou = absf(rel.y) < 9.0 and signf(rel.x) == dir.x and absf(rel.x) < 15.0
			else:
				encostou = absf(rel.x) < 9.0 and signf(rel.y) == dir.y and absf(rel.y) < 15.0
			if encostou:
				alvo = p
				break
	if alvo == null:
		_empurrando = 0.0
		return
	_empurrando += delta
	if _empurrando >= 0.22:
		_empurrando = 0.0
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
	Jogo.tocar_som("pulo", -16.0)
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
	Jogo.tocar_som("caminho", -10.0)
	_respingo(p["no"].global_position + Vector2(0, -6))
	var cel: Vector2i = p["celula"]
	_pontes[_chave(p["lugar"], cel)] = true
	_chaos[p["lugar"]].erase_cell(cel)      # tira a água "sólida" deste bloco
	await t.finished
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
	Jogo.tocar_som("buzio", -4.0)
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
		"vel": randf_range(38.0, 50.0), "fase": randf()})


func _tomar_dano(de: Vector2) -> void:
	_invulneravel = 1.4
	axe -= 1
	_atualizar_axe()
	Jogo.tocar_som("erro", -4.0)
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


func _sem_axe() -> void:
	_voltando = true
	jogador.congelar(true)
	await get_tree().create_timer(0.4).timeout
	var t := create_tween()
	t.tween_property(_cortina, "color:a", 1.0, 0.4)
	await t.finished
	teleportar(lugar_atual, _ponto_volta.get(lugar_atual, jogador.global_position))
	axe = AXE_MAX
	_atualizar_axe()
	await get_tree().create_timer(0.3).timeout
	var t2 := create_tween()
	t2.tween_property(_cortina, "color:a", 0.0, 0.4)
	await t2.finished
	_mostrar_aviso("O axé voltou. Tente de novo!")
	jogador.congelar(false)
	_voltando = false
	_invulneravel = 1.0


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
		if _pendente == "mapa":
			_pendente = ""
			await _abrir_mapa(true)
		await _falar("exu_fim")
		estado = "livre"
		_mostrar_aviso("Siga pelo caminho de Ogum, ao norte.")
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
			var ponto := _ponto_de_conversa(_exu_pos, Vector2(12, 6), 26.0, -42.0)
			ponto.interagiu.connect(_falar_com_exu)
		"mapa":
			_pendente = "mapa"
		"abrir_norte":
			_abrir_cancela("enc_orita")
		_:
			super._ao_evento(nome)


func _falar_com_exu() -> void:
	if estado != "livre":
		return
	await _falar("exu_depois")
	if _pendente == "mapa":
		_pendente = ""
		await _abrir_mapa(false)


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
	Jogo.mudar_cena("res://cenas/fim.tscn")
