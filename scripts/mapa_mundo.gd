extends Node2D
## O mapa dos caminhos: depois que Exu abre os caminhos, Adé sai da encruzilhada e escolhe
## para qual campo de orixá ele vai — andando pelo mapa, de ponto em ponto, como nos mapas-múndi
## dos jogos de 16 bits. O mapa é maior que a tela (512x448) e a câmera segue o Adé; na primeira vez,
## ela se afasta para mostrar a ilha inteira enquanto os caminhos se abrem.
##
## A ilha (arte/mundo_0.png a mundo_3.png: o mar, o rio e a cachoeira mexem entre eles) e as trilhas
## (fases/mapa_mundo.json) são feitas pelo gerar_mapa_mundo.py. As trilhas, os pontos e o Adé são desenhados aqui. Os textos de cada campo vêm de dialogos/encruzilhada.json ("campos").
##
## Controles: setas para andar de um ponto a outro, E / Enter para entrar no campo.

## Os pontos de cada campo e as trilhas entre eles vêm de fases/mapa_mundo.json
## (gravado pelo gerar_mapa_mundo.py junto com a arte da ilha, para os dois baterem).
const ARQUIVO_MAPA := "res://fases/mapa_mundo.json"
## cor do ponto de cada campo (as cores de cada orixá)
const CORES := {
	"orita": [Color(0.85, 0.12, 0.12), Color(0.1, 0.08, 0.12)],
	"oxala": [Color(1, 1, 1), Color(0.86, 0.88, 0.95)],
	"iansa": [Color(0.86, 0.3, 0.3), Color(0.65, 0.12, 0.2)],
	"xango": [Color(0.9, 0.2, 0.15), Color(1, 1, 1)],
	"iemanja": [Color(0.45, 0.75, 1.0), Color(0.18, 0.4, 0.8)],
	"oxum": [Color(1.0, 0.85, 0.2), Color(0.9, 0.62, 0.1)],
	"nana": [Color(0.7, 0.55, 0.85), Color(0.45, 0.3, 0.6)],
	"omolu": [Color(0.95, 0.85, 0.6), Color(0.15, 0.12, 0.1)],
	"oxossi": [Color(0.3, 0.75, 0.55), Color(0.1, 0.5, 0.35)],
	"ogum": [Color(0.2, 0.45, 0.9), Color(0.1, 0.4, 0.25)],
}
const ORDEM_ICONES := ["oxala", "iansa", "xango", "iemanja", "oxum", "nana", "omolu", "oxossi", "ogum"]
const VELOCIDADE := 70.0
const COR_CAMINHO := Color(0.95, 0.83, 0.56)
const COR_CAMINHO_ESCURO := Color(0.3, 0.19, 0.1)
## cores da trilha de terra
const TRILHA_BORDA := Color(0.3, 0.12, 0.07)      # terra vermelha (laterita), como na terra iorubá
const TRILHA_TERRA := Color(0.7, 0.35, 0.21)
const TRILHA_CLARA := Color(0.8, 0.47, 0.3)
const TRILHA_CISCO := Color(0.54, 0.24, 0.14)
const TRILHA_PEDRINHA := Color(0.9, 0.7, 0.54)
const TUFO := Color(0.2, 0.48, 0.22)
const MADEIRA := Color(0.56, 0.35, 0.17)
const MADEIRA_CLARA := Color(0.72, 0.5, 0.27)

## os campos que já têm fase
const CENAS_DOS_CAMPOS := {"oxossi": "res://cenas/mata_oxossi.tscn", "nana": "res://cenas/mata_nana.tscn"}

var _campos := {}                     # id → dados do campo (nome, yo, saudacao, campo)
var _caminhos: Array = []             # {a, b, pontos: PackedVector2Array, aberto: 0..1}
var _vistos := {}                     # pontos que já apareceram (na abertura)
var NOS := {}                         # id → posição do ponto
var _enfeites: Array = []             # sprites que balançam (mariwô)
var _trilhas: Node2D                  # desenha as trilhas (só redesenha quando muda)
var _no_atual := "orita"
var _andando := false
var _ocupado := true                  # durante a abertura e as mensagens
var _tempo := 0.0

var _nuvens: Array = []               # {no, base, amplitude, velocidade, fase}
var _tempestade: Array = []
var _proximo_raio := 2.0
var _fundo: Sprite2D
var _camera: Camera2D
var _vendo_ilha := false               # câmera afastada, mostrando a ilha inteira (tecla M / Tab)
var _tamanho := Vector2(512, 448)      # o mapa é maior que a tela: a câmera segue o Adé
var _texturas: Array = []
var _ade: Sprite2D
var _nome: Label
var _saudacao: Label
var _trofeu: Label            # "★ Troféu: ..." numa linha própria (a faixa cresce quando tem troféu)
var _faixa: Panel
var _descricao: Label
var _icone: TextureRect
var _caixa: PanelContainer
var _texto_caixa: Label
var _seta_caixa: Label
var _legenda: Label                   # a faixa de baixo com os controles


func _ready() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://dialogos/encruzilhada.json"))
	for c in dados["campos"]:
		_campos[c["id"]] = c
	_texturas = [preload("res://arte/mundo_0.png"), preload("res://arte/mundo_1.png"),
		preload("res://arte/mundo_2.png"), preload("res://arte/mundo_3.png")]
	_fundo = Sprite2D.new()
	_fundo.texture = _texturas[0]
	_fundo.centered = false
	_fundo.z_index = -10
	add_child(_fundo)

	_criar_nuvens()
	_criar_gaivotas()
	_criar_nuvens_de_oxala()
	_criar_vento_de_iansa()
	_criar_bufalos()
	_criar_bichos_dos_mundos()

	var mapa: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_MAPA))
	if mapa.has("tamanho"):
		_tamanho = Vector2(mapa["tamanho"][0], mapa["tamanho"][1])
	for id in mapa["nos"]:
		NOS[id] = Vector2(mapa["nos"][id][0], mapa["nos"][id][1])
	for c in mapa["caminhos"]:
		var pts := PackedVector2Array()
		for p in c["pontos"]:
			pts.append(Vector2(p[0], p[1]))
		var ponte := {}
		for i in c["ponte"]:
			ponte[int(i)] = true
		var esconder := {}                  # pedaço dentro da cruz da encruzilhada (lá o chão já é caminho)
		for i in c.get("esconder", []):
			esconder[int(i)] = true
		var escada := {}                    # onde a trilha sobe um paredão: degraus (e Adé anda mais devagar)
		for e in c.get("escada", []):
			escada[int(e[0])] = Color8(int(e[1]), int(e[2]), int(e[3]))
		_caminhos.append({"a": c["a"], "b": c["b"], "pontos": pts, "ponte": ponte, "esconder": esconder,
			"escada": escada, "aberto": 0.0})
	for f in mapa.get("fumacas", []):     # a fumaça da panela no mercado de Exu
		_criar_fumaca(Vector2(f[0], f[1]))
	for e in mapa.get("enfeites", []):
		var en := Sprite2D.new()           # coisas que ficam por cima da trilha (o portal de mariwô)
		en.texture = load(e[0])
		en.hframes = int(e[1])
		en.offset = Vector2(0, -en.texture.get_height() / 2.0 + 1)
		en.position = Vector2(e[2], e[3])
		en.z_index = 1
		add_child(en)
		_enfeites.append(en)
	_trilhas = Node2D.new()
	_trilhas.z_index = -5
	_trilhas.draw.connect(_desenhar_trilhas)
	add_child(_trilhas)

	_ade = Sprite2D.new()
	_ade.texture = preload("res://arte/ade_mapa.png")   # Adé pequenininho, do tamanho do mapa
	_ade.hframes = 6
	_ade.offset = Vector2(0, -6)
	if Jogo.has_meta("no_mapa") and NOS.has(Jogo.get_meta("no_mapa")):
		_no_atual = Jogo.get_meta("no_mapa")      # voltando de um campo: Adé aparece lá
	_ade.position = NOS[_no_atual]
	var sombra := Sprite2D.new()
	sombra.texture = preload("res://arte/sombra.png")
	sombra.scale = Vector2(0.75, 0.75)
	sombra.show_behind_parent = true
	_ade.add_child(sombra)
	add_child(_ade)

	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_tamanho.x)
	_camera.limit_bottom = int(_tamanho.y)
	_camera.position = _ade.position
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	add_child(_camera)
	_camera.make_current()

	_criar_interface()
	Jogo.dispositivo_mudou.connect(func(): if _modo_legenda != "": _mudar_legenda(_modo_legenda))
	Jogo.tocar_musica("musica_mapa")
	# sempre que Adé chega ao Ọ̀run, o letreiro diz onde ele está, como na chegada de cada mundo
	var hud := preload("res://scripts/hud.gd").new()
	hud.esconder_contador = true
	hud.layer = 7
	add_child(hud)
	hud.mostrar_titulo.call_deferred("Ọ̀run", "O lar dos orixás")
	if Jogo.has_meta("mapa_aberto"):
		_mudar_legenda("andar")
		for c in _caminhos:
			c["aberto"] = 1.0
		_trilhas.queue_redraw()
		for id in NOS:
			_vistos[id] = true
		_ocupado = false
		_mostrar_no(_no_atual)
	else:
		_vistos["orita"] = true
		_abrir_caminhos()


func _process(delta: float) -> void:
	_tempo += delta
	_fundo.texture = _texturas[int(_tempo * 4.0) % _texturas.size()]
	_mexer_nuvens(delta)
	_mexer_gaivotas()
	_mexer_nuvens_de_oxala(delta)
	_mexer_vento_de_iansa()
	_mexer_bufalos()
	_mexer_riscos_de_vento(delta)
	_mexer_poeira_e_nevoa(delta)
	if _camera.zoom.x >= 0.999:
		_camera.position = _ade.position + Vector2(0, -8)
	for en in _enfeites:
		en.frame = int(_tempo * 1.5) % en.hframes
	queue_redraw()
	if _ocupado or _andando:
		return
	var dir := Vector2(Input.get_axis("esquerda", "direita"), Input.get_axis("cima", "baixo"))
	if dir != Vector2.ZERO:
		var c = _caminho_na_direcao(_no_atual, dir)
		if c != null:
			_andar(c)
	_ade.frame = 0


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ver_mapa") and not _andando and not _caixa.visible and (not _ocupado or _vendo_ilha):
		get_viewport().set_input_as_handled()
		_ver_ilha(not _vendo_ilha)
		return
	if not ev.is_action_pressed("interagir"):
		return
	if _vendo_ilha:
		get_viewport().set_input_as_handled()
		_ver_ilha(false)
		return
	get_viewport().set_input_as_handled()
	if _caixa.visible:
		_fechar_caixa()
	elif not _ocupado and not _andando:
		_entrar()


# ------------------------------------------------------------------ nuvens que andam e raios de Iansã

func _criar_nuvens() -> void:
	# [textura, posição, quanto anda para os lados, velocidade]
	var lista := [
		["res://arte/mundo_nuvem.png", Vector2(330, 70), 10.0, 0.3],
		["res://arte/mundo_nuvem.png", Vector2(150, 60), 12.0, 0.25],
		["res://arte/mundo_nuvem_p.png", Vector2(196, 136), 10.0, 0.3],   # na encosta, abaixo do templo
		["res://arte/mundo_nuvem_p.png", Vector2(292, 144), 9.0, 0.38],
		["res://arte/mundo_nuvem_p.png", Vector2(244, 156), 12.0, 0.22],
		["res://arte/mundo_tempestade.png", Vector2(390, 76), 5.0, 0.9],
		["res://arte/mundo_tempestade.png", Vector2(480, 84), 4.0, 1.1],
		["res://arte/mundo_tempestade.png", Vector2(440, 64), 6.0, 0.8],
		["res://arte/mundo_tempestade.png", Vector2(420, 100), 4.0, 1.0],
		["res://arte/mundo_tempestade.png", Vector2(346, 88), 6.0, 0.85],     # a tempestade cobre a planície toda
		["res://arte/mundo_tempestade.png", Vector2(448, 140), 5.0, 0.95],
	]
	for i in lista.size():
		var n := Sprite2D.new()
		n.texture = load(lista[i][0])
		n.position = lista[i][1]
		n.z_index = 2
		add_child(n)
		_nuvens.append({"no": n, "base": lista[i][1], "amplitude": lista[i][2], "velocidade": lista[i][3], "fase": i * 1.7})
		if "tempestade" in lista[i][0]:
			_tempestade.append(n)


## O reino de Oxalá fica no meio das nuvens: muitas nuvens passam devagar por cima do morro branco,
## da esquerda para a direita; somem na beirada e voltam do outro lado.
var _nuvens_oxala: Array = []
const OXALA_X := Vector2(150, 342)       # de onde até onde elas passam
const OXALA_Y := Vector2(122, 170)      # na cintura do Kilimanjaro: o cume nevado fica acima das nuvens


func _criar_nuvens_de_oxala() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 5
	for i in 8:
		var n := Sprite2D.new()
		n.texture = load("res://arte/mundo_nuvem.png" if i % 3 == 0 else "res://arte/mundo_nuvem_p.png")
		n.z_index = 2
		add_child(n)
		_nuvens_oxala.append({"no": n, "x": lerpf(OXALA_X.x, OXALA_X.y, float(i) / 8.0 + rnd.randf() * 0.05),
			"y": rnd.randf_range(OXALA_Y.x, OXALA_Y.y), "vel": rnd.randf_range(5.0, 10.0), "fase": rnd.randf() * TAU})


func _mexer_nuvens_de_oxala(delta: float) -> void:
	var largura := OXALA_X.y - OXALA_X.x
	for c in _nuvens_oxala:
		c["x"] += c["vel"] * delta
		if c["x"] > OXALA_X.y:
			c["x"] -= largura
		var n: Sprite2D = c["no"]
		n.position = Vector2(c["x"], c["y"] + sin(_tempo * 0.6 + c["fase"]) * 1.5).round()
		var borda := minf(c["x"] - OXALA_X.x, OXALA_X.y - c["x"])        # aparece e some devagar nas pontas
		n.modulate.a = clampf(borda / 30.0, 0.0, 0.9)


## Iansã: redemoinhos de vento andando pelo planalto dela, e chuva caindo das nuvens de tempestade.
var _redemoinhos: Array = []


func _criar_vento_de_iansa() -> void:
	for i in 4:
		var r := Sprite2D.new()
		r.texture = preload("res://arte/mundo_redemoinho.png")
		r.hframes = 4
		r.offset = Vector2(0, -8)
		r.z_index = 1
		add_child(r)
		_redemoinhos.append({"no": r, "fase": i * 2.2, "vel": 0.22 + i * 0.07})
	_criar_ceu_de_tempestade()
	_criar_folhas_de_bambu()
	var gota := Image.create(1, 3, false, Image.FORMAT_RGBA8)
	gota.fill(Color(0.8, 0.86, 1.0, 0.75))
	var tex_gota := ImageTexture.create_from_image(gota)
	for n in _tempestade:                               # a cortina de chuva embaixo de cada nuvem de tempestade
		var chuva := CPUParticles2D.new()
		chuva.texture = tex_gota
		chuva.position = Vector2(0, 6)
		chuva.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		chuva.emission_rect_extents = Vector2(11, 1)
		chuva.amount = 18
		chuva.lifetime = 0.35
		chuva.direction = Vector2(0.25, 1)
		chuva.spread = 4.0
		chuva.gravity = Vector2.ZERO
		chuva.initial_velocity_min = 70.0
		chuva.initial_velocity_max = 90.0
		chuva.show_behind_parent = true
		n.add_child(chuva)


## O céu de tempestade: uma sombra escura sobre a planície de Iansã (em camadas, borda macia), que clareia a cada raio.
const SOMBRA_ALFA := 1.0
var _sombra_tempestade: Node2D


func _criar_ceu_de_tempestade() -> void:
	_sombra_tempestade = Node2D.new()
	_sombra_tempestade.z_index = 1
	add_child(_sombra_tempestade)
	for escala in [1.0, 0.86, 0.72, 0.58]:
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			var r: float = escala * (1.0 + 0.08 * sin(a * 5.0 + escala * 4.0))     # borda irregular, como nuvem
			pts.append(Vector2(412, 108) + Vector2(cos(a) * 90.0, sin(a) * 42.0) * r)
		var camada := Polygon2D.new()
		camada.polygon = pts
		camada.color = Color(0.12, 0.1, 0.24, 0.07)
		_sombra_tempestade.add_child(camada)


## Folhas arrancadas do bambuzal pelo vento, voando para a direita.
const BAMBUZAIS := [Vector2(392, 90), Vector2(470, 86), Vector2(460, 138), Vector2(336, 94), Vector2(412, 70)]


func _criar_folhas_de_bambu() -> void:
	var img := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.62, 0.82, 0.28))
	img.set_pixel(0, 1, Color(0, 0, 0, 0))
	img.set_pixel(2, 0, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	for b in BAMBUZAIS:
		var f := CPUParticles2D.new()
		f.texture = tex
		f.position = b
		f.z_index = 2
		f.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		f.emission_rect_extents = Vector2(6, 6)
		f.amount = 6
		f.lifetime = 1.8
		f.direction = Vector2(1, -0.15)
		f.spread = 20.0
		f.gravity = Vector2(0, 6)
		f.initial_velocity_min = 22.0
		f.initial_velocity_max = 36.0
		f.angular_velocity_min = -300.0
		f.angular_velocity_max = 300.0
		var fade := Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 1))
		fade.set_color(1, Color(1, 1, 1, 0))
		f.color_ramp = fade
		add_child(f)


## Os outros mundos também mexem: passarinhos na mata de Oxóssi e um antílope, a garça e a névoa de Nanã,
## urubus e redemoinhos de poeira na terra seca de Omolu, pombas em volta do templo de Oxalá.
var _poeiras: Array = []
var _nevoas: Array = []
const NEVOA_X := Vector2(14, 176)


func _voador(tex: Texture2D, centro: Vector2, raio: Vector2, vel: float, fase: float, extra := {}) -> void:
	var g := Sprite2D.new()
	g.texture = tex
	g.hframes = 2
	g.z_index = 3
	add_child(g)
	var d := {"no": g, "centro": centro, "raio": raio, "vel": vel, "fase": fase}
	d.merge(extra)
	_gaivotas.append(d)


func _bicho(tex: Texture2D, de: Vector2, ate, fase: float) -> void:
	var b := Sprite2D.new()
	b.texture = tex
	b.hframes = 4
	b.offset = Vector2(0, -tex.get_height() / 2.0 + 1)
	b.position = de
	b.z_index = 0
	add_child(b)
	_bufalos.append({"no": b, "de": de, "ate": ate, "fase": fase})


func _criar_bichos_dos_mundos() -> void:
	var passaro := preload("res://arte/mundo_passaro.png")
	for i in 6:                         # Oxóssi: bando de passarinhos sobre a mata
		_voador(passaro, Vector2(66 + (i % 3) * 6, 244 + (i % 2) * 8), Vector2(34 + i * 3, 22 + i * 2), 0.7 + i * 0.05,
			i * 0.35, {"some": true, "asas": 9.0})
	_bicho(preload("res://arte/mundo_antilope.png"), Vector2(156, 272), Vector2(176, 276), 0.0)
	_bicho(preload("res://arte/mundo_antilope.png"), Vector2(158, 212), null, 1.1)
	_bicho(preload("res://arte/mundo_garca.png"), Vector2(70, 372), Vector2(100, 380), 0.4)   # Nanã: as garças
	_bicho(preload("res://arte/mundo_garca.png"), Vector2(52, 366), null, 2.0)
	var urubu := preload("res://arte/mundo_urubu.png")
	for i in 3:                         # Omolu: urubus rodando lá no alto
		_voador(urubu, Vector2(236, 334), Vector2(34 + i * 10, 12 + i * 3), 0.28 + i * 0.05, i * 2.1, {"asas": 1.5})
	var gaivota := preload("res://arte/mundo_gaivota.png")
	for i in 3:                         # Oxalá: pombas voando em volta do templo, no cume do Kilimanjaro
		_voador(gaivota, Vector2(244, 76), Vector2(40 + i * 6, 12 + i * 2), 0.5 + i * 0.1, i * 2.0, {"asas": 7.0})
	_bicho(preload("res://arte/mundo_elefante.png"), Vector2(220, 180), Vector2(244, 182), 0.3)   # elefantes na savana
	_bicho(preload("res://arte/mundo_elefante.png"), Vector2(280, 180), null, 1.7)
	var floco := Image.create(1, 1, false, Image.FORMAT_RGBA8)   # a neve fininha caindo no cume
	floco.fill(Color(1, 1, 1, 0.9))
	var neve := CPUParticles2D.new()
	neve.texture = ImageTexture.create_from_image(floco)
	neve.position = Vector2(244, 70)
	neve.z_index = 2
	neve.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	neve.emission_rect_extents = Vector2(32, 6)
	neve.amount = 16
	neve.lifetime = 1.6
	neve.direction = Vector2(0.3, 1)
	neve.spread = 20.0
	neve.gravity = Vector2.ZERO
	neve.initial_velocity_min = 8.0
	neve.initial_velocity_max = 14.0
	var some := Gradient.new()
	some.set_color(0, Color(1, 1, 1, 1))
	some.set_color(1, Color(1, 1, 1, 0))
	neve.color_ramp = some
	add_child(neve)
	for i in 2:                         # Omolu: redemoinhos de poeira no chão rachado
		var r := Sprite2D.new()
		r.texture = preload("res://arte/mundo_redemoinho.png")
		r.hframes = 4
		r.offset = Vector2(0, -8)
		r.z_index = 1
		r.modulate = Color(1.0, 0.78, 0.5, 0.75)
		add_child(r)
		_poeiras.append({"no": r, "fase": i * 3.0, "vel": 0.18 + i * 0.07})
	var img := Image.create(36, 9, false, Image.FORMAT_RGBA8)      # Nanã: a névoa baixa sobre a lama
	for y in 9:
		for x in 36:
			var d := Vector2((x - 17.5) / 18.0, (y - 4.0) / 4.5).length()
			if d < 1.0 and (x + y) % 2 == 0:
				img.set_pixel(x, y, Color(0.86, 0.9, 0.92, (1.0 - d) * 0.9))
	var tex := ImageTexture.create_from_image(img)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 11
	for i in 6:
		var n := Sprite2D.new()
		n.texture = tex
		n.z_index = 1
		add_child(n)
		_nevoas.append({"no": n, "x": lerpf(NEVOA_X.x, NEVOA_X.y, i / 6.0), "y": rnd.randf_range(350, 402),
			"vel": rnd.randf_range(3.0, 6.0)})


func _criar_fumaca(onde: Vector2) -> void:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.85, 0.85, 0.8))
	img.set_pixel(0, 0, Color(0, 0, 0, 0)); img.set_pixel(2, 2, Color(0, 0, 0, 0))
	var f := CPUParticles2D.new()
	f.texture = ImageTexture.create_from_image(img)
	f.position = onde
	f.z_index = 2
	f.amount = 6
	f.lifetime = 2.2
	f.direction = Vector2(0.2, -1)
	f.spread = 12.0
	f.gravity = Vector2(3, 0)
	f.initial_velocity_min = 6.0
	f.initial_velocity_max = 9.0
	f.scale_amount_min = 0.8
	f.scale_amount_max = 1.6
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.8))
	fade.set_color(1, Color(1, 1, 1, 0))
	f.color_ramp = fade
	add_child(f)


func _mexer_poeira_e_nevoa(delta: float) -> void:
	for r in _poeiras:
		var t: float = _tempo * r["vel"] + r["fase"]
		var s: Sprite2D = r["no"]
		s.position = (Vector2(236, 356) + Vector2(sin(t) * 58.0, sin(t * 1.4 + 0.5) * 12.0)).round()
		s.frame = int(_tempo * 8.0 + r["fase"]) % 4
		s.modulate.a = 0.6 + 0.3 * absf(sin(t * 0.8))
	var largura := NEVOA_X.y - NEVOA_X.x
	for c in _nevoas:
		c["x"] += c["vel"] * delta
		if c["x"] > NEVOA_X.y:
			c["x"] -= largura
		var n: Sprite2D = c["no"]
		n.position = Vector2(c["x"], c["y"] + sin(_tempo * 0.4 + c["vel"]) * 1.5).round()
		var borda := minf(c["x"] - NEVOA_X.x, NEVOA_X.y - c["x"])
		n.modulate.a = clampf(borda / 30.0, 0.0, 0.95)


## A manada de búfalos de Iansã na planície: uns pastando (baixam a cabeça de vez em quando), outros andando devagar.
var _bufalos: Array = []
## Os riscos de vento de Iansã: linhas brancas com um caracol na ponta, cruzando a planície para a direita.
var _riscos: Array = []
var _proximo_risco := 0.5


func _criar_bufalos() -> void:
	var lista := [  # [posição, pasta (parado) ou anda até onde]
		[Vector2(356, 98), null], [Vector2(374, 96), null], [Vector2(452, 98), null],
		[Vector2(396, 158), Vector2(440, 158)], [Vector2(420, 132), Vector2(476, 126)], [Vector2(392, 118), Vector2(446, 112)],
	]
	for i in lista.size():
		var b := Sprite2D.new()
		b.texture = preload("res://arte/mundo_bufalo.png")
		b.hframes = 4
		b.offset = Vector2(0, -5)
		b.position = lista[i][0]
		b.flip_h = i % 2 == 1
		b.z_index = 0
		add_child(b)
		_bufalos.append({"no": b, "de": lista[i][0], "ate": lista[i][1], "fase": i * 1.3})


func _mexer_bufalos() -> void:
	for f in _bufalos:
		var b: Sprite2D = f["no"]
		if f["ate"] == null:
			b.frame = 1 if fmod(_tempo * 0.5 + f["fase"], 3.0) < 1.8 else 0     # pastando, de cabeça baixa
			continue
		var de: Vector2 = f["de"]
		var ate: Vector2 = f["ate"]
		var u := pingpong(_tempo * 6.0 / de.distance_to(ate) + f["fase"], 1.0)    # anda bem devagar, vai e volta
		var antes := b.position
		b.position = de.lerp(ate, u).round()
		if b.position.x != antes.x:
			b.flip_h = b.position.x < antes.x
		b.frame = 2 + int(_tempo * 3.0 + f["fase"]) % 2


func _mexer_riscos_de_vento(delta: float) -> void:
	_proximo_risco -= delta
	if _proximo_risco <= 0.0:
		_proximo_risco = randf_range(0.6, 1.4)
		var v := Sprite2D.new()
		v.texture = preload("res://arte/mundo_vento.png")
		v.position = Vector2(randf_range(300, 400), randf_range(76, 156))
		v.z_index = 3
		v.modulate.a = 0.0
		add_child(v)
		_riscos.append({"no": v, "vida": 0.0, "dura": randf_range(1.6, 2.4), "vel": randf_range(55.0, 80.0)})
	for r in _riscos.duplicate():
		r["vida"] += delta
		var v: Sprite2D = r["no"]
		v.position.x += r["vel"] * delta
		var u: float = r["vida"] / r["dura"]                 # aparece, atravessa e some
		v.modulate.a = clampf(minf(u * 4.0, (1.0 - u) * 3.0), 0.0, 0.85)
		if u >= 1.0:
			v.queue_free()
			_riscos.erase(r)


func _mexer_vento_de_iansa() -> void:
	for r in _redemoinhos:
		var t: float = _tempo * r["vel"] + r["fase"]
		var s: Sprite2D = r["no"]
		s.position = (Vector2(428, 110) + Vector2(sin(t) * 50.0, sin(t * 1.7 + 1.0) * 16.0)).round()
		s.frame = int(_tempo * 10.0 + r["fase"]) % 4


## Gaivotas voando em roda sobre o mar de Iemanjá (no canto de baixo, à direita).
var _gaivotas: Array = []


func _criar_gaivotas() -> void:
	for i in 3:
		var g := Sprite2D.new()
		g.texture = preload("res://arte/mundo_gaivota.png")
		g.hframes = 2
		g.z_index = 3
		add_child(g)
		_gaivotas.append({"no": g, "centro": Vector2(462 + i * 14, 400 + i * 10), "raio": Vector2(30 + i * 8, 14 + i * 4),
			"vel": 0.45 + i * 0.12, "fase": i * 2.1})


func _mexer_gaivotas() -> void:
	for g in _gaivotas:
		var t: float = _tempo * g["vel"] + g["fase"]
		var s: Sprite2D = g["no"]
		var antes := s.position
		s.position = (g["centro"] + Vector2(cos(t) * g["raio"].x, sin(t) * g["raio"].y)).round()
		s.flip_h = s.position.x < antes.x
		s.frame = int(_tempo * g.get("asas", 5.0) + g["fase"]) % 2
		if g.get("some", false):            # os passarinhos pousam na mata (somem) e levantam voo de novo
			s.modulate.a = clampf(sin(_tempo * 0.35 + g["fase"]) * 3.0, 0.0, 1.0)


func _mexer_nuvens(delta: float) -> void:
	for c in _nuvens:
		var t: float = _tempo * c["velocidade"] + c["fase"]
		c["no"].position = c["base"] + Vector2(sin(t) * c["amplitude"], sin(t * 0.7) * 1.5).round()
	_proximo_raio -= delta
	if _proximo_raio <= 0.0:
		_proximo_raio = randf_range(2.0, 4.5)
		var nuvem: Sprite2D = _tempestade.pick_random()
		var t := create_tween()
		t.tween_property(nuvem, "modulate", Color(2.2, 2.2, 1.6), 0.05)
		t.tween_property(nuvem, "modulate", Color.WHITE, 0.08)
		t.tween_property(nuvem, "modulate", Color(1.8, 1.8, 1.4), 0.05)
		t.tween_property(nuvem, "modulate", Color.WHITE, 0.2)
		_raio_caindo(nuvem.position + Vector2(randf_range(-8, 8), 4))


## O raio de Iansã: um zigue-zague que sai da nuvem e bate no chão, clareando a planície escura por um instante.
func _raio_caindo(de: Vector2) -> void:
	var pontos := PackedVector2Array([de])
	var altura := randf_range(28.0, 42.0)
	var p := de
	while p.y < de.y + altura:
		p += Vector2(randf_range(-5, 5), randf_range(5, 9))
		pontos.append(p.round())
	var raio := Node2D.new()
	raio.z_index = 3
	add_child(raio)
	for camada in [[3.0, Color(0.7, 0.75, 1.0, 0.55)], [1.0, Color(1.0, 1.0, 0.85)]]:   # brilho azulado + miolo branco
		var l := Line2D.new()
		l.points = pontos
		l.width = camada[0]
		l.default_color = camada[1]
		l.joint_mode = Line2D.LINE_JOINT_SHARP
		raio.add_child(l)
	if randf() < 0.6:                                    # às vezes o raio se divide num galho
		var k := randi_range(1, maxi(1, pontos.size() - 2))
		var g := PackedVector2Array([pontos[k]])
		var q := pontos[k]
		var lado := 1.0 if randf() < 0.5 else -1.0
		for i in 3:
			q += Vector2(lado * randf_range(3, 6), randf_range(3, 6))
			g.append(q.round())
		var lg := Line2D.new()
		lg.points = g
		lg.width = 1.0
		lg.default_color = Color(0.9, 0.92, 1.0, 0.8)
		raio.add_child(lg)
	var clarao := Sprite2D.new()                         # o estouro no chão
	clarao.texture = _textura_clarao()
	clarao.position = p
	raio.add_child(clarao)
	var t := create_tween()
	t.tween_interval(0.06)
	t.tween_property(raio, "modulate:a", 0.2, 0.03)
	t.tween_property(raio, "modulate:a", 1.0, 0.03)
	t.tween_property(raio, "modulate:a", 0.0, 0.18)
	t.tween_callback(raio.queue_free)
	if _sombra_tempestade:
		var s := create_tween()
		s.tween_property(_sombra_tempestade, "modulate:a", 0.15, 0.05)
		s.tween_property(_sombra_tempestade, "modulate:a", SOMBRA_ALFA, 0.5)


var _tex_clarao: ImageTexture


func _textura_clarao() -> ImageTexture:
	if _tex_clarao == null:
		var img := Image.create(9, 5, false, Image.FORMAT_RGBA8)
		for y in 5:
			for x in 9:
				var d := Vector2((x - 4) / 4.5, (y - 2) / 2.5).length()
				if d < 1.0:
					img.set_pixel(x, y, Color(1.0, 1.0, 0.8, 1.0 - d))
		_tex_clarao = ImageTexture.create_from_image(img)
	return _tex_clarao


# ------------------------------------------------------------------ andar pelos caminhos

## Para onde a trilha sai de um ponto (olhando os primeiros pixels dela).
func _saida(c: Dictionary, no: String) -> Vector2:
	var pts: PackedVector2Array = c["pontos"]
	var k := mini(7, pts.size() - 1)
	if c["a"] == no:
		return (pts[k] - pts[0]).normalized()
	return (pts[pts.size() - 1 - k] - pts[pts.size() - 1]).normalized()


## A trilha que sai do ponto mais na direção apertada (as trilhas fazem curvas, então vale a mais parecida).
func _caminho_na_direcao(no: String, dir: Vector2):
	var melhor = null
	var nota := 0.45
	for c in _caminhos:
		if c["a"] != no and c["b"] != no:
			continue
		var d := _saida(c, no).dot(dir.normalized())
		if d > nota:
			nota = d
			melhor = c
	return melhor


func _andar(c: Dictionary) -> void:
	_andando = true
	var pts: PackedVector2Array = c["pontos"]
	var destino: String = c["b"]
	if c["b"] == _no_atual:
		pts = pts.duplicate()
		pts.reverse()
		destino = c["a"]
	_esconder_no()
	Jogo.tocar_som("pulo", -18.0)
	var invertido: bool = c["b"] != destino
	var andado := 0.0
	for i in range(1, pts.size()):
		var de := pts[i - 1]
		var para := pts[i]
		var passo := de.distance_to(para)
		var original: int = (pts.size() - 1 - i) if invertido else i
		var vel := VELOCIDADE * (0.5 if c["escada"].has(original) else 1.0)   # na escada, mais devagar
		var t := 0.0
		while t < passo:
			var dt := get_process_delta_time()
			t += vel * dt
			andado += vel * dt
			_ade.position = de.lerp(para, minf(1.0, t / passo))
			_animar_ade(para - de, andado)
			await get_tree().process_frame
	_ade.position = NOS[destino]
	_ade.flip_h = false
	_ade.frame = 0
	_no_atual = destino
	_andando = false
	Jogo.tocar_som("buzio", -14.0)
	_mostrar_no(destino)


func _animar_ade(d: Vector2, andado: float) -> void:
	var passo := int(andado / 5.0) % 2
	if absf(d.x) > absf(d.y):
		_ade.frame = 4 + passo
		_ade.flip_h = d.x < 0.0
	elif d.y < 0.0:
		_ade.frame = 2 + passo
		_ade.flip_h = false
	else:
		_ade.frame = passo
		_ade.flip_h = false


var _modo_legenda := ""


func _mudar_legenda(modo: String) -> void:
	_modo_legenda = modo
	match modo:
		"ilha":
			_legenda.text = Jogo.texto("{ver_mapa}  voltar para perto do Adé")
		"caixa":
			_legenda.text = Jogo.texto("{interagir}  continuar")
		"andar":
			_legenda.text = Jogo.texto("{setas}  andar      {interagir}  entrar      {ver_mapa}  ver a ilha inteira")
		_:
			_legenda.text = ""
	_legenda.get_parent().get_child(_legenda.get_index() - 1).visible = _legenda.text != ""


## Afasta a câmera para mostrar a ilha inteira (ou volta para perto do Adé).
func _ver_ilha(longe: bool) -> void:
	_vendo_ilha = longe
	_mudar_legenda("ilha" if longe else "andar")
	_ocupado = true
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	if longe:
		var z := Jogo.TELA.x / _tamanho.x
		_camera.position_smoothing_enabled = false
		_camera.limit_left = -100000; _camera.limit_top = -100000
		_camera.limit_right = 100000; _camera.limit_bottom = 100000
		_camera.position = _camera.get_screen_center_position()
		t.tween_property(_camera, "zoom", Vector2(z, z), 0.6)
		t.tween_property(_camera, "position", _tamanho / 2.0 + Vector2(0, -12), 0.6)
		Jogo.tocar_som("caminho", -16.0)
		_descricao.text = Jogo.texto("A ilha inteira. Aperte {ver_mapa} para voltar.")
	else:
		t.tween_property(_camera, "zoom", Vector2.ONE, 0.6)
		t.tween_property(_camera, "position", _ade.position + Vector2(0, -8), 0.6)
	await t.finished
	if not longe:
		_camera.limit_left = 0; _camera.limit_top = 0
		_camera.limit_right = int(_tamanho.x); _camera.limit_bottom = int(_tamanho.y)
		_camera.position_smoothing_enabled = true
		_mostrar_no(_no_atual)
		_ocupado = false


# ------------------------------------------------------------------ abertura dos caminhos

func _abrir_caminhos() -> void:
	_nome.text = "Oríta Mẹ́ta"
	_saudacao.text = "Laroyê!"
	_descricao.text = "Exu abriu os caminhos..."
	await get_tree().create_timer(0.6).timeout
	# a câmera se afasta para ver a ilha inteira enquanto os caminhos se abrem
	var longe := Jogo.TELA.x / _tamanho.x
	var t0 := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_camera.position_smoothing_enabled = false
	_camera.limit_right = 100000; _camera.limit_bottom = 100000; _camera.limit_left = -100000; _camera.limit_top = -100000
	t0.tween_property(_camera, "zoom", Vector2(longe, longe), 1.0)
	t0.tween_property(_camera, "position", _tamanho / 2.0 + Vector2(0, -12), 1.0)
	await t0.finished
	# abre em ondas: primeiro o que sai da encruzilhada, depois o que sai dos pontos novos
	var feitos := {}
	var fronteira := ["orita"]
	while fronteira.size() > 0:
		var proximos := []
		var abrindo := []
		for i in _caminhos.size():
			var c: Dictionary = _caminhos[i]
			if feitos.has(i):
				continue
			if c["a"] in fronteira or c["b"] in fronteira:
				feitos[i] = true
				abrindo.append(c)
		if abrindo.is_empty():
			break
		Jogo.tocar_som("caminho", -12.0)
		var t := create_tween().set_parallel()
		for c in abrindo:
			c["inverso"] = c["b"] in fronteira and not (c["a"] in fronteira)
			t.tween_method(_abrir_um.bind(c), 0.0, 1.0, 0.7)
		await t.finished
		for c in abrindo:
			for id in [c["a"], c["b"]]:
				if not _vistos.has(id):
					_vistos[id] = true
					proximos.append(id)
		if proximos.size() > 0:
			Jogo.tocar_som("buzio", -6.0)
		fronteira = proximos
		await get_tree().create_timer(0.25).timeout
	Jogo.set_meta("mapa_aberto", true)
	await get_tree().create_timer(0.6).timeout
	var t1 := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t1.tween_property(_camera, "zoom", Vector2.ONE, 1.0)
	t1.tween_property(_camera, "position", _ade.position + Vector2(0, -8), 1.0)
	await t1.finished
	_camera.limit_left = 0; _camera.limit_top = 0
	_camera.limit_right = int(_tamanho.x); _camera.limit_bottom = int(_tamanho.y)
	_camera.position_smoothing_enabled = true
	await get_tree().create_timer(0.2).timeout
	_abrir_caixa("Os caminhos estão abertos! Cada braço da cruz leva aos orixás daquele lado.\nAnde com {andar} e escolha por onde começar.\nPara ver a ilha inteira, aperte {ver_mapa}.")
	_mostrar_no("orita")


func _abrir_um(v: float, c: Dictionary) -> void:
	c["aberto"] = v
	_trilhas.queue_redraw()


# ------------------------------------------------------------------ desenho dos caminhos e pontos

func _draw() -> void:
	# não há "bolinha" nos campos: a trilha termina numa clareira dentro de cada lugar.
	# Só um brilho leve no chão mostra onde Adé está parado.
	if not _andando:
		var p: Vector2 = NOS[_no_atual]
		var a := 0.35 + 0.3 * sin(_tempo * 5.0)
		draw_arc(p + Vector2(0, 1), 6.0 + sin(_tempo * 5.0), 0, TAU, 24, Color(1, 1, 0.8, a), 1.0)
	if not _ocupado and not _andando:
		_desenhar_setas()


## Trilhas de terra batida: borda escura, terra, o meio mais claro, ciscos, pedrinhas,
## tufos de capim na beirada e pontes de madeira onde passam pelo rio.
func _desenhar_trilhas() -> void:
	var visiveis := []
	for c in _caminhos:
		var pts: PackedVector2Array = c["pontos"]
		var n := int(round(c["aberto"] * (pts.size() - 1)))
		if n <= 0:
			continue
		var lista := []
		for k in n + 1:
			var i: int = (pts.size() - 1 - k) if c.get("inverso", false) else k
			if not c["esconder"].has(i):
				lista.append(i)
		visiveis.append([c, lista])
	# clareira de terra onde cada trilha termina
	var fins := {}
	for v in visiveis:
		var c: Dictionary = v[0]
		if c["aberto"] >= 0.999:
			fins[c["a"]] = true
			fins[c["b"]] = true
		else:
			fins[c["b"] if c.get("inverso", false) else c["a"]] = true
	fins.erase("orita")                 # a encruzilhada tem a cruz desenhada na arte
	for id in fins:
		_trilhas.draw_circle(NOS[id], 6.0, TRILHA_BORDA)
	for camada in 4:
		if camada == 1:
			for id in fins:
				_trilhas.draw_circle(NOS[id], 5.0, TRILHA_TERRA)
		if camada == 2:
			for id in fins:
				_trilhas.draw_circle(NOS[id] + Vector2(-0.5, -1), 3.2, TRILHA_CLARA)
		for v in visiveis:
			var c: Dictionary = v[0]
			var pts: PackedVector2Array = c["pontos"]
			for i: int in v[1]:
				var p := pts[i].round()
				var antes := pts[maxi(0, i - 1)]
				var depois := pts[mini(pts.size() - 1, i + 1)]
				var normal := (depois - antes).normalized().orthogonal()
				var ponte: bool = c["ponte"].has(i)
				var degrau: bool = c["escada"].has(i)
				var largura := 2.2 + 0.4 * sin(i * 0.37 + pts[0].x)   # trilha estreita, do tamanho do Adé do mapa
				match camada:
					0:
						_trilhas.draw_circle(p, largura + 1.0, TRILHA_BORDA)
					1:
						var cor_chao: Color = c["escada"][i] if degrau else (MADEIRA if ponte else TRILHA_TERRA)
						_trilhas.draw_circle(p, largura, cor_chao)
					2:
						if ponte:
							if i % 3 == 0:     # vão entre as tábuas
								for k in range(-3, 4):
									_trilhas.draw_rect(Rect2((p + normal * k).round(), Vector2.ONE), TRILHA_BORDA)
							else:
								_trilhas.draw_rect(Rect2((p + normal * -2).round(), Vector2(1, 1)), MADEIRA_CLARA)
						elif degrau:
							# degraus: uma linha escura (o espelho do degrau) e uma clara (a pisada), alternando
							var cor_d: Color = c["escada"][i]
							var cor_linha: Color = cor_d.darkened(0.45) if i % 3 == 0 else (cor_d.lightened(0.25) if i % 3 == 1 else cor_d)
							for k in range(-2, 3):
								_trilhas.draw_rect(Rect2((p + normal * k).round(), Vector2.ONE), cor_linha)
						else:
							_trilhas.draw_circle(p + Vector2(-0.5, -0.5), maxf(0.8, largura - 1.3), TRILHA_CLARA)
					3:
						if degrau:
							continue
						if ponte:
							for lado in [-4, 4]:   # corrimão
								_trilhas.draw_rect(Rect2((p + normal * lado).round(), Vector2.ONE), Color(0.25, 0.14, 0.06))
							continue
						var h: int = (i * 73 + int(pts[0].x) * 31) % 17
						if h == 0 or h == 7:
							_trilhas.draw_rect(Rect2((p + normal * (h % 3 - 1)).round(), Vector2.ONE), TRILHA_CISCO)
						elif h == 3:
							_trilhas.draw_rect(Rect2((p + normal).round(), Vector2.ONE), TRILHA_PEDRINHA)
						if i % 9 == 4:     # tufo de capim na beirada
							var lado := 1.0 if (i / 9) % 2 == 0 else -1.0
							var t := (p + normal * lado * (largura + 2.5)).round()
							_trilhas.draw_rect(Rect2(t, Vector2(1, 2)), TUFO)
							_trilhas.draw_rect(Rect2(t + Vector2(1, 1), Vector2(1, 1)), TUFO)
							_trilhas.draw_rect(Rect2(t + Vector2(-1, 1), Vector2(1, 1)), TUFO)


func _desenhar_setas() -> void:
	if fmod(_tempo, 0.8) > 0.55:
		return
	var p: Vector2 = NOS[_no_atual]
	for c in _caminhos:
		if c["a"] != _no_atual and c["b"] != _no_atual:
			continue
		var v := _saida(c, _no_atual)
		var ponta := p + v * 12.0 + (Vector2(0, -4) if v.y < -0.7 else Vector2.ZERO)
		var lado := v.orthogonal() * 3.0
		var pts := PackedVector2Array([ponta + v * 3.0, ponta - lado, ponta + lado])
		draw_colored_polygon(pts, Color(1, 0.95, 0.6))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), COR_CAMINHO_ESCURO, 1.0)


# ------------------------------------------------------------------ faixa de cima e caixa de texto

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 5
	add_child(camada)
	var fonte := preload("res://fontes/NotoSans-SemiBold.ttf")

	var faixa := Panel.new()
	faixa.position = Vector2(4, 3)
	faixa.size = Vector2(248, 28)
	faixa.add_theme_stylebox_override("panel", _estilo())
	camada.add_child(faixa)
	_faixa = faixa
	_icone = TextureRect.new()
	_icone.position = Vector2(8, 9)
	camada.add_child(_icone)
	_nome = _rotulo(fonte, 9, Color(1, 0.97, 0.88))
	_nome.position = Vector2(27, 4)
	camada.add_child(_nome)
	_saudacao = _rotulo(fonte, 9, Color(1, 0.82, 0.35))
	_saudacao.position = Vector2(140, 4)
	_saudacao.size = Vector2(106, 14)
	_saudacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	camada.add_child(_saudacao)
	_descricao = _rotulo(null, 7, Color(0.85, 0.88, 1.0))
	_descricao.position = Vector2(27, 17)
	_descricao.size = Vector2(222, 12)
	_descricao.clip_text = true
	camada.add_child(_descricao)
	_trofeu = _rotulo(fonte, 7, Color(1, 0.82, 0.35))
	_trofeu.position = Vector2(27, 27)
	_trofeu.size = Vector2(222, 11)
	_trofeu.clip_text = true
	camada.add_child(_trofeu)

	_caixa = PanelContainer.new()
	_caixa.position = Vector2(12, 160)
	_caixa.custom_minimum_size = Vector2(232, 52)
	_caixa.size = Vector2(232, 52)
	var estilo := _estilo()
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 5
	estilo.content_margin_bottom = 5
	_caixa.add_theme_stylebox_override("panel", estilo)
	_texto_caixa = _rotulo(null, 8, Color.WHITE)
	_texto_caixa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_caixa.custom_minimum_size = Vector2(216, 0)
	_caixa.add_child(_texto_caixa)
	_caixa.visible = false
	camada.add_child(_caixa)
	_seta_caixa = _rotulo(fonte, 8, Color(1, 0.85, 0.3))
	_seta_caixa.text = "▼"
	_seta_caixa.visible = false
	camada.add_child(_seta_caixa)

	# legenda embaixo: os controles do mapa
	var faixa_baixo := Panel.new()
	faixa_baixo.position = Vector2(4, 207)
	faixa_baixo.size = Vector2(248, 15)
	var estilo_baixo := _estilo()
	estilo_baixo.set_border_width_all(1)
	estilo_baixo.set_corner_radius_all(3)
	faixa_baixo.add_theme_stylebox_override("panel", estilo_baixo)
	camada.add_child(faixa_baixo)
	_legenda = _rotulo(fonte, 7, Color(0.92, 0.93, 1.0))
	_legenda.position = Vector2(4, 208)
	_legenda.size = Vector2(248, 12)
	_legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legenda.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	camada.add_child(_legenda)
	_mudar_legenda("")


func _estilo() -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.06, 0.07, 0.24, 0.92)
	e.border_color = Color(0.95, 0.95, 1.0)
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	e.shadow_color = Color(0, 0, 0, 0.4)
	e.shadow_size = 2
	return e


func _rotulo(fonte: Font, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	if fonte:
		l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	return l


## As bifurcações: os quatro caminhos que saem da encruzilhada se dividem aqui, cada um para os mundos do seu lado.
const BIFURCACOES := {
	"bif_norte": ["O caminho do Norte", "Daqui se vai a Oxalá e a Iansã."],
	"bif_oeste": ["O caminho do Oeste", "Daqui se vai a Oxum e a Oxóssi."],
	"bif_leste": ["O caminho do Leste", "Daqui se vai a Ogum e a Xangô."],
	"bif_sul": ["O caminho do Sul", "Daqui se vai a Nanã, a Omolu e a Iemanjá."],
}


func _mostrar_no(id: String) -> void:
	_faixa.visible = true
	if BIFURCACOES.has(id):
		_nome.text = BIFURCACOES[id][0]
		_saudacao.text = ""
		_descricao.text = BIFURCACOES[id][1]
		_icone.texture = null
		_mostrar_trofeu("")
		return
	if id == "orita":
		_nome.text = "Oríta Mẹ́ta · a encruzilhada"
		_saudacao.text = "Laroyê!"
		_descricao.text = Jogo.texto("Aperte {interagir} para voltar ao terreiro da Vó.") if Jogo.has_meta("mapa_aberto") else "Todo caminho começa e termina aqui."
		_icone.texture = null
		_mostrar_trofeu("")
		return
	var c: Dictionary = _campos[id]
	_nome.text = "%s · %s" % [c["nome"], c["yo"]]
	_saudacao.text = c["saudacao"]
	_descricao.text = c["campo"]
	_mostrar_trofeu(Jogo.trofeus.get(id, ""))
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://arte/mapa_icones.png")
	atlas.region = Rect2(ORDEM_ICONES.find(id) * 16, 0, 16, 16)
	_icone.texture = atlas
	_icone.position = Vector2(8, 9)


## O troféu ganho do orixá aparece numa linha própria, embaixo da descrição; sem troféu, a faixa volta ao normal.
func _mostrar_trofeu(trofeu: String) -> void:
	_trofeu.text = ("★ Troféu: " + trofeu) if trofeu != "" else ""
	_faixa.size.y = 38 if trofeu != "" else 28


## Andando pelo caminho (fora de um lugar), a faixa de cima some: não fica uma caixa vazia.
func _esconder_no() -> void:
	_faixa.visible = false
	_nome.text = ""
	_saudacao.text = ""
	_descricao.text = ""
	_mostrar_trofeu("")
	_icone.texture = null


func _entrar() -> void:
	if _no_atual == "orita":
		# voltar para o terreiro da Vó: a pé pela encruzilhada na primeira vez, depois pelo atalho
		_ocupado = true
		Jogo.tocar_som("caminho", -6.0)
		if Jogo.has_meta("volta_feita"):
			Jogo.set_meta("retorno", true)
			Jogo.mudar_cena("res://cenas/terreiro.tscn")
		else:
			Jogo.set_meta("volta", true)
			Jogo.mudar_cena("res://cenas/encruzilhada.tscn")
		return
	if BIFURCACOES.has(_no_atual):
		return                                  # na bifurcação não tem o que entrar: é só escolher a direção
	if CENAS_DOS_CAMPOS.has(_no_atual):
		_ocupado = true
		Jogo.tocar_som("caminho", -6.0)
		Jogo.mudar_cena(CENAS_DOS_CAMPOS[_no_atual])
		return
	var c: Dictionary = _campos[_no_atual]
	Jogo.tocar_som("caminho", -10.0)
	_abrir_caixa("%s %s\nO caminho até o campo de %s ainda está se abrindo... Em breve!" % [c["saudacao"], c["nome"], c["nome"]])


func _abrir_caixa(texto: String) -> void:
	_ocupado = true
	_mudar_legenda("caixa")
	_texto_caixa.text = Jogo.texto(texto)
	_caixa.visible = true
	var y_tela := _ade.get_global_transform_with_canvas().origin.y     # a caixa não cobre o Adé
	_caixa.position.y = 150.0 if y_tela < 130.0 else 36.0
	_seta_caixa.position = _caixa.position + Vector2(220, 40)
	_seta_caixa.visible = true
	Jogo.tocar_som("texto", -14.0)


func _fechar_caixa() -> void:
	_mudar_legenda("andar")
	_caixa.visible = false
	_seta_caixa.visible = false
	await get_tree().create_timer(0.15).timeout
	_ocupado = false
