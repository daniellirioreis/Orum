extends "res://scripts/encruzilhada.gd"
## Òkun Yemọja — o mar de Iemanjá (visão de cima, de noite, ao luar).
## Na chegada, Exu explica a Adé quem é Iemanjá e o que vai na oferenda que ele tem de levar até Aiocá,
## o palácio dela no fundo do mar: flores brancas, perfume de alfazema e uma pérola.
##
## Lugares:
##   iemanja_praia → a praia de cima para baixo: Adé desce das dunas e do coqueiral até a beira; o mar fica
##                   embaixo e as ondas vêm de baixo, sobem pela areia molhada e voltam, num ritmo (a espuma pisca antes, mostrando até onde a próxima vai).
##                   A onda que pega Adé devolve ele à última areia seca (e leva um búzio de axé). A onda traz
##                   búzios; caranguejos beliscam; águas-vivas queimam. Adé procura uma jangada para entrar no mar:
##                   ela está lá embaixo, na beira d'água, mas o remo ficou enrolado na rede de pesca.
##   iemanja_mar   → o mar ao luar (de cima para baixo: a praia em cima): Adé navega de jangada, descendo, até a
##                   pedra das flores brancas. A jangada tem embalo; os rolos de onda vêm subindo do mar aberto (de frente e com força, a jangada fura a onda; parada ou de lado,
##                   a onda empurra para trás); pedras e recifes (bater custa um búzio de axé); correntezas puxam
##                   para os lados (os brilhos na água mostram para onde).
##   (em seguida: o mergulho, o jardim de corais, as águas escuras e Aiocá)

const LUGARES_IEMANJA := {
	"iemanja_praia": {"origem": Vector2(0, 0), "dentro": false},
	"iemanja_mar": {"origem": Vector2(0, 1000), "dentro": false},
	"iemanja_gruta": {"origem": Vector2(400, 0), "dentro": false},
	"iemanja_fundo": {"origem": Vector2(1200, 0), "dentro": false},
	"iemanja_camara": {"origem": Vector2(1800, 0), "dentro": false},
}
const COR_GRUTA := Color(0.22, 0.22, 0.38)    # a gruta é escura: só brilham as algas, as águas-vivas e a luz de Adé
const COR_LUA := Color(0.19, 0.24, 0.5)       # noite de lua: escuro e azulado; só a lua, a espuma e as luzinhas brilham
const SECO := ["s", ",", ";", "*", "t"]
const TEX_ITENS_IEM := preload("res://arte/iemanja_itens.png")
const CAMARA_ORIGEM := Vector2(1800, 0)      # a câmara de Aiocá, à direita do fundo do mar
## Os itens da oferenda no altar (id da bornal → nome na meta) e onde cada um fica sobre o altar.
const ALTAR_ITENS := {"alfazema": "alfazema", "flores_iemanja": "flores", "perola": "perola"}
const COR_CAMARA_CLARA := Color(0.75, 0.9, 1.0)   # a câmara toda clara, quando a pérola está no altar
const ALTAR_POS := {"alfazema": Vector2(-11, -14), "flores_iemanja": Vector2(11, -14), "perola": Vector2(0, -20)}
const ORDEM_ITENS := ["flores", "alfazema", "perola", "abebe"]
## O ritmo das ondas da praia: calma → aviso (a espuma marca até onde a próxima vai) → sobe → cheia → desce.
const ONDA_TEMPO := {"aviso": 0.9, "sobe": 0.7, "cheia": 0.35, "desce": 1.2}
const ONDAS := [1.9, 3.9, 2.4, 1.7, 4.0, 3.7, 2.1, 4.0]     # até quantos blocos cada onda sobe (repete)
# a jangada
const REMADA := 150.0          # aceleração (px/s²)
const VEL_MAX := 70.0
const ARRASTO := 1.1           # a água freia a jangada (por segundo)
const CORRENTEZA := 26.0
const ROLO_VEL := 24.0         # os rolos de onda descendo
const ROLO_CADA := 3.4
# o mergulho: Adé desce com as setas até a areia do fundo; o ar tem um limite
const FUNDO_ORIGEM := Vector2(1200, 0)
const FUNDO_COLUNAS := 31
const FUNDO_LINHAS := 21
const COR_FUNDO := Color(0.008, 0.014, 0.05)   # o fundo do mar: bem escuro mesmo, só as lanternas dos peixes clareiam
const AR_MAX := 10.0
const NADO_VEL := 60.0

var _tartaruga := {}            # a tartaruga velha: anda devagar pela beira, para e olha para Adé
var _iem := {}                  # flags da fase: flores, remo...
var _slots_iem := {}            # id → ícone do inventário
var _moldura_trofeu: TextureRect
var _repetindo := false
# a faixa de areia
var _lua: Node2D                # o caminho da lua no mar
var _ondas: Node2D              # desenha a água subindo pela areia, a espuma e o caminho da lua
var _costa: Array = []          # para cada linha do mapa da praia: em que coluna o mar começa
var _onda_fase := "calma"
var _onda_t := 0.0
var _onda_dur := 1.6
var _onda_i := 0
var _alcance := 0.0
var _alcance_max := 0.0
var _ultimo_seco := Vector2.ZERO
var _onda_levou_uma_vez := false
var _queimou_uma_vez := false
var _caranguejos: Array = []
var _aguasvivas: Array = []
var _jangada_praia: Area2D
var _remo: Area2D
var _espirros: Array = []       # {pos, t, estado}: onde a onda espirra entre as pedras da gruta
var _falou_tartaruga := false
# o mar
var _navegando := false
var _jangada: Sprite2D
var _rastro: CPUParticles2D
var _pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _inicio_mar := Vector2.ZERO
var _pedras_mar: Array = []     # [posição, raio]
var _correntes := {}            # célula → direção (-1 ou 1)
var _rolos: Array = []          # {y}
var _proximo_rolo := 1.0
var _flores_pos := Vector2.ZERO
var _flores: Sprite2D
var _mar_desenho: Node2D
var _furou_uma_vez := false
var _bateu_uma_vez := false
var _mergulhando := false
var _bolhas_ar: Array = []     # fontes de bolha de ar: {pos, nodo, espera}
var _tetos: Array = []                # tetos de corais da câmara: {s}
var _animais: Array = []         # bichos da câmara: polvo, tripé, pelicano e cavalo-marinho
var _peixes: Array = []        # peixes nadando pelo labirinto: {nodo, x0, x1, vel, dir}
var _ar := 0.0
var _barra_ar: ColorRect
var _proa := PI                 # para onde a proa aponta (0 = para cima; começa apontando mar adentro, para baixo)


func _ready() -> void:
	lugares = LUGARES_IEMANJA
	terrenos = [[["s", "u", "w", "t"], 8], [["u", "w"], 9], [["w"], 10], [["t"], 1], [["r"], 1], [["~"], 10]]
	agua_chars = ["w", "~"]
	folga_empurrar = 13.0      # na gruta escura, empurrar as pedras é mais fácil de acertar
	tempo_empurrar = 0.12
	cor_fora = COR_LUA
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
	_preparar_mar()
	for nome in lugares:
		_construir(nome)
	mundo.add_child(jogador)
	_ponto_volta["iemanja_praia"] = jogador.global_position
	_ultimo_seco = jogador.global_position
	$HUD.esconder_contador = true
	Jogo.bornal.mostrar_hud(true)

	_criar_interface()
	_criar_inventario()
	_barra_ar = ColorRect.new()
	_barra_ar.position = Vector2(8, 22)
	_barra_ar.size = Vector2(60, 3)
	_barra_ar.color = Color(0.5, 0.85, 1.0)
	_barra_ar.visible = false
	$HUD.add_child(_barra_ar)
	$Dialogo.evento.connect(_ao_evento)
	_proximo_raio = 9999.0
	_preparar_ondas()
	_criar_vagalumes_das_dunas()
	_luz_de_ade()
	# no escuro da noite, a luz em volta de Adé é a da lua: fria, larga e fraquinha
	for l in jogador.get_children():
		if l is PointLight2D:
			l.color = Color(0.7, 0.8, 1.0)
			l.energy = 0.75
			l.texture_scale = 1.0
	# o mar aberto, mais fundo e escuro (a noite pesa mais longe da praia)
	var fundo := ColorRect.new()
	fundo.position = lugares["iemanja_mar"]["origem"] + Vector2(0, 3 * TILE)
	fundo.size = tamanhos["iemanja_mar"] - Vector2(0, 3 * TILE)
	fundo.color = Color(0.03, 0.08, 0.24, 0.5)
	fundo.z_index = -5
	add_child(fundo)
	_entrar_lugar("iemanja_praia")
	_inicio()


func _inicio() -> void:
	jogador.congelar(true)
	if Jogo.has_meta("iemanja_no_camara"):
		Jogo.remove_meta("iemanja_no_camara")
		_retomar()
		_jangada.visible = false
		_navegando = false
		_mergulhando = true
		jogador.set_physics_process(false)
		_ar = AR_MAX
		teleportar("iemanja_camara", CAMARA_ORIGEM + Vector2(10 * TILE, 10 * TILE))
		_clarear_camara(false)
		_barra_ar.visible = false
		jogador.congelar(false)
		return
	if Jogo.has_meta("iemanja_no_fundo") or (Jogo.has_meta("iemanja_flores") and not Jogo.trofeus.has("iemanja")):
		# o jogo foi guardado no labirinto, ou as flores já foram pegas: volta direto para o labirinto
		if Jogo.has_meta("iemanja_no_fundo"):
			Jogo.remove_meta("iemanja_no_fundo")
		_retomar()
		_jangada.visible = false
		_navegando = false
		_mergulhando = true
		jogador.set_physics_process(false)      # sem física de chão/gravidade: debaixo d'água só o _nadar move Adé
		_ar = AR_MAX
		teleportar("iemanja_fundo", FUNDO_ORIGEM + Vector2(15.5 * TILE, 9.5 * TILE))
		_barra_ar.size.x = 60.0
		_barra_ar.visible = true
		jogador.congelar(false)
		return
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
	if Jogo.has_meta("iemanja_remo") and not _repetindo:
		# voltando à praia: o remo já está com Adé (e talvez a alfazema e as flores)
		_retomar()
		var fala := "volta_sem_alfazema"
		if Jogo.has_meta("iemanja_flores"):
			fala = "volta_com_flores"
		elif Jogo.has_meta("iemanja_alfazema"):
			fala = "volta_com_alfazema"
		await _falar(fala)
		jogador.congelar(false)
		return
	await _falar("chegada")
	await _exu_explica()


## Acende no inventário o que Adé já trouxe (flores e alfazema) e deixa o remo com ele.
func _retomar() -> void:
	_iem["remo"] = true
	if not Jogo.bornal.tem("remo"):
		Jogo.bornal.pegar("remo")
	_falou_tartaruga = true
	if _remo:
		_remo.visible = false
		_remo.ativo = false
	if Jogo.has_meta("iemanja_flores"):
		_iem["flores"] = true
		if _flores:
			_flores.frame = 1
		_slots_iem["flores"].modulate = Color.WHITE
		if not Jogo.bornal.tem("flores_iemanja") and not Jogo.has_meta("iemanja_arriou_flores"):
			Jogo.bornal.pegar("flores_iemanja")
	if Jogo.has_meta("iemanja_alfazema") and not Jogo.bornal.tem("alfazema") and not Jogo.has_meta("iemanja_arriou_alfazema"):
		Jogo.bornal.pegar("alfazema")
	if Jogo.has_meta("iemanja_alfazema"):
		_slots_iem["alfazema"].modulate = Color.WHITE


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
	_nadar(delta)
	_mover_peixes(delta)
	_mover_animais(delta)
	_atualizar_tetos(delta)
	if lugar_atual == "iemanja_praia":
		_mover_tartaruga(delta)
		_mover_ondas(delta)
		_chao_de_ade()
		_mover_caranguejos()
		_aguasvivas_queimam()
		_ondas.queue_redraw()
		_lua.queue_redraw()
	elif lugar_atual == "iemanja_gruta":
		_espirrar(delta)
		_mover_caranguejos()
		_aguasvivas_queimam()
	elif _navegando:
		_navegar(delta)
		_mar_desenho.queue_redraw()


## Sem relâmpago: o céu é limpo, de lua.
func _animar_tempo(_delta: float) -> void:
	pass


func teleportar(nome: String, posicao: Vector2) -> void:
	super.teleportar(nome, posicao)
	_ultimo_seco = posicao
	if nome == "iemanja_gruta" and not _iem.has("viu_gruta"):
		_iem["viu_gruta"] = true
		_falar_depois.call_deferred("chegada_gruta")


func _falar_depois(chave: String) -> void:
	await get_tree().create_timer(0.5).timeout
	await _falar(chave)


# ------------------------------------------------------------------ objetos dos mapas

func _criar_objeto(lugar: String, c: String, celula: Vector2i, base: Vector2, chao: TileMapLayer) -> void:
	match c:
		"E":
			marcas["exu"] = base
		"Q":
			# o altar da câmara de Aiocá: a oferenda vai ali (a pérola, por último, no centro)
			_altar = _criar_interativo("res://arte/iemanja_altar.png", 1, base, Vector2(30, 8), -26.0)
			_altar.interagiu.connect(_na_altar)
			_registrar_alvo(_altar, "altar_iem", "altar", "Arriar no altar", 44.0)
			_luz_altar = PointLight2D.new()
			_luz_altar.color = Color(0.7, 0.95, 1.0)
			_luz_altar.energy = 0.0                  # o altar fica no escuro; só acende quando a oferenda se completa
			_luz_altar.texture = _luz_tex
			_luz_altar.texture_scale = 2.6
			_luz_altar.position = base + Vector2(0, -12)
			mundo.add_child(_luz_altar)
			var bolhas := _criar_emissor_bolhas(8, 3.0, 8.0)
			bolhas.position = base + Vector2(0, -6)
			mundo.add_child(bolhas)
			for bid in ALTAR_ITENS:
				if Jogo.has_meta("iemanja_arriou_" + ALTAR_ITENS[bid]):
					_pos_oferenda(bid, false)
		"Z":
			# a pérola da oferenda: brilha quando Adé chega perto
			if Jogo.has_meta("iemanja_perola"):
				_perola_pega = true
				return
			if lugar != "iemanja_fundo":
				return                               # só a pérola do labirinto é a que Adé pega
			_perola = Sprite2D.new()
			_perola.texture = TEX_ITENS_IEM
			_perola.hframes = 5
			_perola.frame = 2                      # a pérola no conjunto de ícones
			_perola.position = base + Vector2(0, -4)
			_perola.z_index = 5
			_perola.material = _material_sem_sombra()
			mundo.add_child(_perola)
			_perola_luz = PointLight2D.new()
			_perola_luz.color = Color(0.7, 0.95, 1.0)
			_perola_luz.energy = 0.0
			_perola_luz.texture = _luz_tex
			_perola_luz.texture_scale = 1.1
			_perola_luz.position = base + Vector2(0, -4)
			mundo.add_child(_perola_luz)
		"N":
			var rede := _criar_interativo("res://arte/iemanja_rede.png", 1, base + Vector2(0, 4), Vector2(40, 4), -30.0)
			(rede.get_node("Alcance").shape as CircleShape2D).radius = 30.0
			rede.interagiu.connect(_na_rede)
		"Y":
			# a tartaruga velha da beira: sabe onde o mar deixou o remo
			var tt := _criar_interativo("res://arte/iemanja_tartaruga.png", 6, base, Vector2(18, 8), -26.0)
			tt.animar = false
			tt.sprite.offset.y += 3
			var sombra := Sprite2D.new()
			sombra.texture = preload("res://arte/sombra.png")
			sombra.scale = Vector2(1.6, 1.0)
			tt.add_child(sombra)
			tt.move_child(sombra, 0)
			tt.interagiu.connect(_na_tartaruga)
			_registrar_alvo(tt, "tartaruga", "pessoa", "Dar à Tartaruga")
			_tartaruga = {"no": tt, "casa": base.x, "alvo": base.x + 20.0, "espera": 1.0, "piscar": 2.0, "escondida": 0.0}
		# --- a gruta do costão
		"X":
			var pa := _criar_cenario("res://arte/iemanja_rocha.png", Vector2(16, 14), base + Vector2(0, 2))
			pa.flip_h = (celula.x * 3 + celula.y) % 2 == 0
			pa.modulate = Color(0.72, 0.72, 0.82)
			_ocupado[_chave(lugar, celula)] = true
		"O":
			_remo = _criar_interativo("res://arte/iemanja_remo.png", 1, base, Vector2(2, 2), -22.0)
			(_remo.get_node("Alcance").shape as CircleShape2D).radius = 22.0
			_remo.interagiu.connect(_no_remo)
			_luz(base + Vector2(0, -6), Color(1.0, 0.9, 0.7), 0.6, 0.6, false)
		"L":
			_luz(base + Vector2(0, -6), Color(0.4, 1.0, 0.85), 1.0, 0.9, false)    # algas que brilham
			var alga := Sprite2D.new()
			alga.texture = preload("res://arte/iemanja_conchas.png")
			alga.hframes = 4
			alga.frame = 3
			alga.modulate = Color(0.5, 1.0, 0.85)
			alga.material = _material_sem_sombra()
			alga.position = base - Vector2(0, 6)
			alga.z_index = -4
			add_child(alga)
		"v":
			_espirros.append({"pos": base - Vector2(0, 6), "t": randf_range(0.0, 2.0), "estado": "calmo"})
		"J":
			_jangada_praia = _criar_interativo("res://arte/iemanja_jangada_cima.png", 16, base + Vector2(0, 12), Vector2(30, 12), -36.0)
			_jangada_praia.sprite.vframes = 2
			_jangada_praia.sprite.offset.y = -_jangada_praia.sprite.texture.get_height() / 4.0
			_jangada_praia.sprite.frame = 4              # na areia, com a ponta virada para o mar
			(_jangada_praia.get_node("Alcance").shape as CircleShape2D).radius = 34.0
			_jangada_praia.interagiu.connect(_na_jangada)
			_registrar_alvo(_jangada_praia, "jangada", "coisa", "Usar na jangada", 44.0)
		"b":
			_criar_cenario("res://arte/iemanja_cesto.png", Vector2(10, 5), base)
		"g":
			var sal := Sprite2D.new()
			sal.texture = preload("res://arte/iemanja_salsa.png")
			sal.hframes = 2
			sal.frame = (celula.x + celula.y) % 2
			sal.position = base - Vector2(0, 7)
			sal.z_index = -3
			add_child(sal)
		"c":
			super._criar_objeto(lugar, c, celula, base, chao)
			_luz(base + Vector2(0, -8), Color(0.75, 0.85, 1.0), 0.7, 0.45, false)   # o búzio brilha na areia
		"[", "]":
			# coral animado: balança alternando entre dois frames com tween em loop
			var tex_a := preload("res://arte/iemanja_coral_a.png")
			var tex_b := preload("res://arte/iemanja_coral_b.png")
			var coral := Sprite2D.new()
			coral.texture = tex_a
			coral.centered = false
			coral.position = base + Vector2(0, -tex_a.get_height() + 4)
			coral.z_index = -2
			add_child(coral)
			# tween em loop: alterna frame a → b → a com pequeno intervalo (dessincronizado)
			var fase_offset := randf_range(0.0, 1.2)
			var tw := coral.create_tween()
			tw.set_loops()
			tw.tween_callback(func(): coral.texture = tex_a).set_delay(fase_offset)
			tw.tween_interval(0.5)
			tw.tween_callback(func(): coral.texture = tex_b)
			tw.tween_interval(0.5)
		")":
			_criar_bolha_ar(base)
		"-":
			_criar_peixe(base)
		"A":
			_criar_agua_viva(base)
		"G":
			_criar_animal("res://arte/iemanja_polvo.png", 2, base, false)
		"B":
			_criar_animal("res://arte/iemanja_tripe.png", 2, base, false)
		"D":
			_criar_animal("res://arte/iemanja_pelicano.png", 2, base, false)
		"F":
			_criar_animal("res://arte/iemanja_cavalo.png", 2, base, true)
		"I":
			_criar_animal("res://arte/iemanja_enguia.png", 2, base, false)
		"V":
			# estalactite: pendurada no teto, pinga água de vez em quando
			var est := Sprite2D.new()
			est.texture = preload("res://arte/iemanja_estalactite.png")
			est.centered = false
			est.position = base + Vector2(-4, -TILE)
			est.z_index = -1
			mundo.add_child(est)
			_criar_gotejo(base + Vector2(0, -TILE + est.texture.get_height()))
			# o teto de corais: uma copa baixa por cima de Adé, que fica transparente quando ela passa por baixo
			var teto := Sprite2D.new()
			teto.texture = preload("res://arte/iemanja_teto.png")
			teto.position = base + Vector2(0, -21)
			teto.z_index = 21
			mundo.add_child(teto)
			_tetos.append({"s": teto})
		"U":
			# estalagmite: sobe do chão da câmara
			var esg := Sprite2D.new()
			esg.texture = preload("res://arte/iemanja_estalagmite.png")
			esg.offset = Vector2(0, -esg.texture.get_height() / 2.0)
			esg.position = base
			esg.z_index = -1
			mundo.add_child(esg)
		"(":
			# a quartinha de Exu: aqui se guarda o caminho do mar de Iemanjá
			_criar_quartinha(base)
		"C":
			var qual := "res://arte/iemanja_coqueiro_g.png" if celula.y % 2 else "res://arte/iemanja_coqueiro_g2.png"
			_criar_cenario(qual, Vector2(8, 5), base + Vector2(0, 2))
		"K":
			# caranguejo da gruta: anda de lado, de uma parede à outra
			var s := Sprite2D.new()
			s.texture = preload("res://arte/iemanja_caranguejo.png")
			s.hframes = 2
			s.offset = Vector2(0, -4)
			s.position = base
			mundo.add_child(s)
			_caranguejos.append({"s": s, "de": base + Vector2(-48, 0), "ate": base + Vector2(48, 0),
				"vel": 30.0 + celula.y % 3 * 4.0, "fase": celula.x * 0.29})
		"k":
			var s := Sprite2D.new()
			s.texture = preload("res://arte/iemanja_caranguejo.png")
			s.hframes = 2
			s.offset = Vector2(0, -4)
			s.position = base
			mundo.add_child(s)
			_caranguejos.append({"s": s, "de": base + Vector2(0, -20), "ate": base + Vector2(0, 20),
				"vel": 18.0 + celula.y % 3 * 4.0, "fase": celula.y * 0.37})
		"j":
			var a := Sprite2D.new()
			a.texture = preload("res://arte/iemanja_aguaviva.png")
			a.hframes = 2
			a.offset = Vector2(0, -4)
			a.position = base - Vector2(0, 2)
			a.material = _material_sem_sombra()      # a água-viva brilha no escuro
			mundo.add_child(a)
			_aguasvivas.append(a)
			_luz(a.position + Vector2(0, -4), Color(0.6, 0.5, 1.0), 0.8, 0.5, false)
		"h":
			var h := Sprite2D.new()
			h.texture = preload("res://arte/iemanja_conchas.png")
			h.hframes = 4
			h.frame = (celula.x + celula.y) % 4
			h.position = base - Vector2(0, 6)
			h.z_index = -4
			add_child(h)
		# --- o mar
		"S":
			_inicio_mar = base - Vector2(0, 6)
		"R":
			var p := _criar_cenario("res://arte/iemanja_pedra.png", Vector2.ZERO, base + Vector2(0, 4))
			p.flip_h = (celula.x + celula.y) % 2 == 0
			_pedras_mar.append([base - Vector2(0, 4), 13.0])
		"f":
			_criar_cenario("res://arte/iemanja_pedra.png", Vector2.ZERO, base + Vector2(0, 4))
			_flores = Sprite2D.new()
			_flores.texture = preload("res://arte/iemanja_flores.png")
			_flores.hframes = 2
			_flores.offset = Vector2(0, -13)
			_flores.position = base + Vector2(0, 5)
			mundo.add_child(_flores)
			_flores_pos = base - Vector2(0, 4)
			_pedras_mar.append([_flores_pos, 13.0])
			_luz(base + Vector2(0, -12), Color(0.95, 0.95, 1.0), 1.4, 1.8, false)
		"{", "}":
			_correntes[Vector2i(celula)] = -1 if c == "{" else 1
		_:
			super._criar_objeto(lugar, c, celula, base, chao)


## Na areia o passo é abafado; na areia molhada, chapinha.
func som_do_chao(pos: Vector2) -> Array:
	if _navegando:
		return []
	var l := _letra_em(pos)
	if l == "u":
		return ["passo_lama", -20.0]
	if l == "s":
		return ["passo_terra", -19.0]
	return super.som_do_chao(pos)


## No fundo do mar não existe grama: a camada de grama some e fica só o escuro.
func _construir_terreno(mapa: PackedStringArray, origem: Vector2, topo: TileMapLayer) -> void:
	super._construir_terreno(mapa, origem, topo)
	if origem.x >= FUNDO_ORIGEM.x - 4.0:
		for c in get_children():
			if c is TileMapLayer and c.z_index == -10:
				c.visible = false


## No labirinto do fundo do mar, Exu fala de debaixo d'água.
func _fala_quartinha(chave: String) -> void:
	if lugar_atual == "iemanja_fundo" and _dados.has("fundo_quartinha_" + chave):
		await _falar("fundo_quartinha_" + chave)
		return
	await super._fala_quartinha(chave)


## O mar mexe: faixas de luz passando.
func _camada_terreno(origem: Vector2, i: int, camada: TileMapLayer) -> void:
	# detecta o fundo do mar pela posição de origem (x >= 1200)
	var e_fundo := origem.x >= FUNDO_ORIGEM.x - 4.0
	if e_fundo:
		# o fundo do mar: a parede vira rocha (desenhada à parte); o chão/areia continua
		if i == 4:
			camada.visible = false                 # a textura de parede soma à rocha; escondida para não dobrar
			_rochas_do_fundo(origem)
			return
		if i == 2:
			camada.material = _material_fundo_mar()  # água escura: só as lanternas dos peixes iluminam
		return
	if i == 2 or i == 5:
		camada.material = _material_mar()


## Uma rocha por célula de parede, do tamanho exato de um bloco.
func _rochas_do_fundo(origem: Vector2) -> void:
	var nome := "iemanja_camara" if origem.x > 1700.0 else "iemanja_fundo"
	var mapa: PackedStringArray = _mapas[nome]
	var tex: Texture2D = preload("res://arte/iemanja_rocha.png")
	var tex_lateral: Texture2D = preload("res://arte/iemanja_parede_lateral.png")
	for y in mapa.size():
		for x in mapa[y].length():
			if mapa[y][x] == "r":
				var s := Sprite2D.new()
				# as bordas da esquerda e da direita do fundo e da câmara ganham paredes com dobras, como as da referência
				var lateral := (x == 0 or x == mapa[y].length() - 1)
				s.texture = tex_lateral if lateral else tex
				s.scale = Vector2(TILE, TILE) / Vector2(s.texture.get_size())
				s.position = origem + Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
				s.z_index = -5
				add_child(s)
	if nome != "iemanja_fundo":
		return
	# a saída: um buraco na rocha que solta bolhas, passagem para o fundo mais fundo do mar
	var buraco := Sprite2D.new()
	buraco.texture = preload("res://arte/iemanja_buraco.png")
	buraco.centered = false
	buraco.position = origem + Vector2((FUNDO_COLUNAS - 2) * TILE, (FUNDO_LINHAS - 1) * TILE + TILE / 2.0 - buraco.texture.get_height() / 2.0)
	buraco.z_index = -3
	buraco.material = _material_sem_sombra()
	add_child(buraco)
	var luz_buraco := PointLight2D.new()
	luz_buraco.color = Color(0.6, 0.92, 1.0)
	luz_buraco.energy = 1.6
	luz_buraco.texture = _luz_tex
	luz_buraco.texture_scale = 2.0
	luz_buraco.position = origem + Vector2((FUNDO_COLUNAS - 2) * TILE + TILE / 2.0, (FUNDO_LINHAS - 1) * TILE + TILE / 2.0)
	add_child(luz_buraco)
	var pulso := create_tween().set_loops()
	pulso.tween_property(luz_buraco, "energy", 2.6, 0.7)
	pulso.tween_property(luz_buraco, "energy", 1.2, 0.7)
	var bolhas_saida := _criar_emissor_bolhas(10, 2.2, 12.0)
	bolhas_saida.position = origem + Vector2((FUNDO_COLUNAS - 2) * TILE + TILE / 2.0, (FUNDO_LINHAS - 1) * TILE)
	add_child(bolhas_saida)


const SHADER_FUNDO := """
shader_type canvas_item;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 c = COLOR;
	vec2 p = floor(mundo);
	// quase sem luz própria: só uma sombra escurecendo a água, sem clarear (o brilho vem dos peixes)
	c.rgb = c.rgb * 0.22 + vec3(0.004, 0.007, 0.02) * c.a;
	COLOR = c;
}
"""
var _shader_fundo: ShaderMaterial


func _material_fundo_mar() -> ShaderMaterial:
	if not _shader_fundo:
		var sh := Shader.new()
		sh.code = SHADER_FUNDO
		_shader_fundo = ShaderMaterial.new()
		_shader_fundo.shader = sh
	return _shader_fundo


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
		caixa.visible = false        # a barra antiga não aparece: tudo fica no bornal
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
		item.visible = false
		camada.add_child(item)
		_slots_iem[ORDEM_ITENS[i]] = item
	_esconder_inventario()


func _acender_slot(id: String, texto := "") -> void:
	var icone: TextureRect = _slots_iem[id]
	icone.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(icone, "scale", Vector2(1.6, 1.6), 0.12)
	t.tween_property(icone, "scale", Vector2.ONE, 0.18)
	Jogo.tocar_som("pegar_item", -4.0)
	if texto != "":
		_mostrar_aviso(texto)


# ------------------------------------------------------------------ 1) a faixa de areia: as ondas

func _preparar_ondas() -> void:
	# a praia é deitada: o mar fica embaixo; para cada coluna, a linha onde o mar começa
	var mapa: PackedStringArray = _mapas["iemanja_praia"]
	var largura := 0
	for linha in mapa:
		largura = maxi(largura, linha.length())
	for x in largura:
		var y0 := mapa.size()
		for y in mapa.size():
			if x < mapa[y].length() and mapa[y][x] in ["w", "z"]:
				y0 = y
				break
		_costa.append(y0)
	_ondas = Node2D.new()
	_ondas.position = lugares["iemanja_praia"]["origem"]
	_ondas.z_index = -4                     # por cima da areia, por baixo de Adé e das coisas
	_ondas.draw.connect(_desenhar_ondas)
	_ondas.material = _material_sem_sombra()      # a espuma brilha de noite (as cores já são de noite)
	add_child(_ondas)
	_lua = Node2D.new()                            # o caminho da lua no mar
	_lua.position = _ondas.position
	_lua.z_index = -4
	_lua.material = _material_sem_sombra()
	_lua.draw.connect(_desenhar_lua)
	add_child(_lua)
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
		if _molhado(jogador.global_position + Vector2(0, -3)) and _letra_em(jogador.global_position + Vector2(0, -3)) != "z":
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
	var funda := Color(0.06, 0.2, 0.42, 0.78)
	var rasa := Color(0.16, 0.42, 0.56, 0.62)
	var espuma := Color(0.72, 1.0, 0.94, 0.95)        # a espuma brilhando, verde-água
	var bolha := Color(0.6, 0.95, 0.9, 0.8)
	var molhada := Color(0.05, 0.04, 0.12, 0.0)
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
	var mar := Color(0.07, 0.2, 0.4)
	var mar_claro := Color(0.16, 0.4, 0.55)
	# só as colunas que aparecem na tela (a câmera, e não Adé: perto da borda ela para e Adé anda sozinho)
	var camera: Camera2D = jogador.get_node("Camera")
	var meio := camera.get_screen_center_position().x - _ondas.global_position.x
	var metade := Jogo.TELA.x / 2.0 + 8.0
	for x in range(maxi(0, int(meio - metade)), mini(largura, int(meio + metade))):
		var costa := _costa_px(x)
		# a beira do mar, lisa (por cima dos degraus dos blocos), com a espuminha que vai e vem na areia
		_ondas.draw_rect(Rect2(x, floorf(costa), 1, 18), mar)
		if (x * 7 + quadro) % 11 == 0:
			_ondas.draw_rect(Rect2(x, floorf(costa) + 4 + (x * 3) % 9, 1, 2), mar_claro)
		var respira := 1.0 + sin(_tempo * 1.8 + x * 0.04)
		_ondas.draw_rect(Rect2(x, floorf(costa - respira) - 1, 1, 2), mar_claro)
		if (x + quadro / 2) % 3 != 0:
			_ondas.draw_rect(Rect2(x, floorf(costa - respira) - 2, 1, 1), Color(0.7, 1.0, 0.92, 0.85))
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
				_ondas.draw_rect(Rect2(x, vai, 1, 1), Color(0.7, 1.0, 0.92, pisca))
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
			_ondas.draw_rect(Rect2(x, ly, 4, 1), Color(0.5, 0.75, 0.95, 0.8 * forca))
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



## O caminho da lua no mar (embaixo da praia): brilhos prateados que tremem numa faixa que abre mar adentro,
## sempre um pouco ao lado de Adé (a lua fica longe, no céu: o reflexo anda junto com quem olha).
func _desenhar_lua() -> void:
	var meio := jogador.global_position.x - _lua.global_position.x
	var centro := meio + 30.0
	var q := int(_tempo * 6.0)
	for x in range(0, _costa.size() * TILE):
		var costa := _costa_px(x) + 6.0
		var fundo: float = tamanhos["iemanja_praia"].y
		var y := costa
		while y < fundo:
			var d := absf(x - centro) / (16.0 + (y - costa) * 0.6)
			if d < 1.0 and int(x * 0.7 + y * 1.3 + sin(y * 0.5 + _tempo * 2.0) * 3.0 + q) % 4 == 0:
				_lua.draw_rect(Rect2(x, y, 2 if d < 0.5 else 1, 1), Color(0.86, 0.9, 1.0, 0.9 - d * 0.5))
			elif (x * 13 + int(y) * 7 + q / 3) % 211 == 0:
				_lua.draw_rect(Rect2(x, y, 1, 1), Color(0.7, 0.8, 1.0, 0.7))
			y += 2.0


## Adé pisa na areia seca: é para lá que a onda devolve ele.
func _chao_de_ade() -> void:
	if not jogador.pode_mover or _voltando:
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


func _criar_vagalumes_das_dunas() -> void:
	var tam: Vector2 = tamanhos["iemanja_praia"]
	var v := CPUParticles2D.new()
	v.material = _material_sem_sombra()
	v.z_index = 15
	v.position = lugares["iemanja_praia"]["origem"] + Vector2(3.5 * TILE, tam.y / 2.0)
	v.amount = 30
	v.lifetime = 5.0
	v.preprocess = 5.0
	v.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	v.emission_rect_extents = Vector2(2.5 * TILE, tam.y / 2.0 - 16)
	v.gravity = Vector2.ZERO
	v.direction = Vector2(0, -1)
	v.spread = 180.0
	v.initial_velocity_min = 2.0
	v.initial_velocity_max = 6.0
	var cores := Gradient.new()
	cores.set_color(0, Color(0.85, 1.0, 0.45, 0.0))
	cores.add_point(0.2, Color(0.85, 1.0, 0.45, 1.0))
	cores.add_point(0.45, Color(0.85, 1.0, 0.45, 0.15))
	cores.add_point(0.7, Color(0.85, 1.0, 0.45, 1.0))
	cores.set_color(cores.get_point_count() - 1, Color(0.85, 1.0, 0.45, 0.0))
	v.color_ramp = cores
	add_child(v)


# ------------------------------------------------------------------ a rede (o remo) e a jangada

func _na_rede() -> void:
	await _falar("rede_vazia")


func _na_tartaruga() -> void:
	if _iem.has("remo"):
		await _falar("tartaruga_remo")
	elif _falou_tartaruga:
		await _falar("tartaruga_depois")
	else:
		_falou_tartaruga = true
		await _falar("tartaruga")


func _no_remo() -> void:
	if _iem.has("remo"):
		return
	await _falar("remo_achou")
	_remo.visible = false


## Na entrada da gruta, a onda bate nas pedras e espirra: primeiro borbulha (o aviso), depois estoura.
func _espirrar(delta: float) -> void:
	for e in _espirros:
		e["t"] += delta
		match e["estado"]:
			"calmo":
				if e["t"] > 2.2:
					e["estado"] = "borbulha"; e["t"] = 0.0
			"borbulha":
				if fmod(e["t"], 0.2) < delta:
					var b := CPUParticles2D.new()
					b.position = e["pos"]
					b.amount = 4
					b.lifetime = 0.3
					b.one_shot = true
					b.explosiveness = 0.8
					b.spread = 180.0
					b.gravity = Vector2.ZERO
					b.initial_velocity_min = 6.0
					b.initial_velocity_max = 12.0
					b.color = Color(0.7, 1.0, 0.95)
					b.material = _material_sem_sombra()
					add_child(b)
					b.emitting = true
					get_tree().create_timer(0.6).timeout.connect(b.queue_free)
				if e["t"] > 0.7:
					e["estado"] = "estoura"; e["t"] = 0.0
					_respingo(e["pos"])
					som_perto("agua_cai", e["pos"], -6.0)
					var l := _luz(e["pos"], Color(0.6, 1.0, 0.95), 1.2, 0.8, false)
					get_tree().create_timer(0.4).timeout.connect(l.queue_free)
			"estoura":
				if _invulneravel <= 0.0 and not _voltando and jogador.pode_mover \
						and e["pos"].distance_to(jogador.global_position + Vector2(0, -4)) < 16.0:
					_tomar_dano(e["pos"])
					if not _iem.has("espirro"):
						_iem["espirro"] = true
						_falar("espirro")
				if e["t"] > 0.5:
					e["estado"] = "calmo"; e["t"] = randf_range(-0.6, 0.4)


## A gruta é escura; a praia e o mar, de lua.
func _entrar_lugar(nome: String) -> void:
	cor_fora = COR_GRUTA if nome == "iemanja_gruta" else (COR_FUNDO if nome in ["iemanja_fundo", "iemanja_camara"] else COR_LUA)
	super._entrar_lugar(nome)
	if nome == "iemanja_fundo" and not has_node("BolhasMapa"):
		# bolhinhas subindo pelo fundo do mar, espalhadas pelo mapa
		var bolhas := _criar_emissor_bolhas(40, 4.5, 14.0)
		bolhas.name = "BolhasMapa"
		bolhas.position = FUNDO_ORIGEM + Vector2(FUNDO_COLUNAS * TILE / 2.0, FUNDO_LINHAS * TILE / 2.0)
		bolhas.preprocess = 4.5
		bolhas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		bolhas.emission_rect_extents = Vector2(FUNDO_COLUNAS * TILE / 2.0, FUNDO_LINHAS * TILE / 2.0)
		bolhas.spread = 8.0
		add_child(bolhas)
	if has_node("BolhasMapa"):
		$BolhasMapa.visible = nome == "iemanja_fundo"      # as bolhas do mapa só aparecem no fundo do mar
	if nome == "iemanja_fundo" and not _mergulhando:
		# partículas de plâncton flutuando no fundo do mar
		if not has_node("Plancton"):
			var plancton := CPUParticles2D.new()
			plancton.name = "Plancton"
			plancton.position = FUNDO_ORIGEM + Vector2(FUNDO_COLUNAS * TILE / 2.0, FUNDO_LINHAS * TILE / 2.0)
			plancton.amount = 60
			plancton.lifetime = 5.0
			plancton.preprocess = 5.0
			plancton.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			plancton.emission_rect_extents = Vector2(FUNDO_COLUNAS * TILE / 2.0, FUNDO_LINHAS * TILE / 2.0)
			plancton.gravity = Vector2(0, -6.0)
			plancton.direction = Vector2(1, -1)
			plancton.spread = 80.0
			plancton.initial_velocity_min = 3.0
			plancton.initial_velocity_max = 10.0
			plancton.scale_amount_min = 0.5
			plancton.scale_amount_max = 1.5
			plancton.material = _material_sem_sombra()
			plancton.z_index = 20
			var gpl := Gradient.new()
			gpl.set_color(0, Color(0.5, 1.0, 0.85, 0.0))
			gpl.add_point(0.2, Color(0.5, 1.0, 0.85, 0.9))
			gpl.add_point(0.7, Color(0.4, 0.8, 1.0, 0.6))
			gpl.set_color(gpl.get_point_count()-1, Color(0.3, 0.7, 1.0, 0.0))
			plancton.color_ramp = gpl
			add_child(plancton)


## Chegando por uma passagem: o primeiro bloco livre ao lado (na praia, areia; na gruta, o chão de pedra).
func _chegada(lugar: String, celula: Vector2i) -> Vector2:
	var mapa: PackedStringArray = _mapas[lugar]
	for dir in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
		var c: Vector2i = celula + dir
		var letra := _letra(mapa, c.x, c.y)
		if not (letra in agua_chars) and letra != "a" and not _ocupado.has(_chave(lugar, c)) and not _e_porta(lugar, c):
			var origem: Vector2 = lugares[lugar]["origem"]
			return origem + Vector2(c.x * TILE + TILE / 2.0, (c.y + 1) * TILE - 2)
	return super._chegada(lugar, celula)


func _na_jangada() -> void:
	if not Jogo.bornal.tem("remo"):
		await _falar("jangada_sem_remo")
		return
	await _falar("jangada_remo_dica")
	_dica_bornal("o remo → Usar na jangada")


## Adé usa o remo do bornal na jangada.
func _aceita_usar(id: String, alvo: String) -> bool:
	return id == "remo" and alvo == "jangada"


func _ao_usar(_id: String, _alvo: String) -> void:
	if not Jogo.bornal.tem("alfazema"):
		# sem a alfazema, a oferenda fica faltando: Adé não entra no mar e vai ao terreiro pedir à Vó
		await _falar("jangada_sem_alfazema")
		jogador.congelar(true)
		voltar_ao_mapa()
		return
	await _falar("jangada_vamos")
	await _entrar_no_mar()


## Adé empurra a jangada para a água e sobe nela: a tela escurece e ele já está no mar.
func _entrar_no_mar() -> void:
	_voltando = true
	jogador.congelar(true)
	Jogo.tocar_som("agua_cai", -6.0)
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.5)
	await c.finished
	_jangada_praia.visible = false
	_pos = _inicio_mar
	_vel = Vector2.ZERO
	_proa = PI
	_jangada.position = _pos
	_jangada.visible = true
	teleportar("iemanja_mar", _pos + Vector2(0, -7))
	_navegando = true
	await get_tree().create_timer(0.3).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.5)
	await c2.finished
	_voltando = false
	if not _iem.has("explicou_mar"):
		_iem["explicou_mar"] = true
		await _falar("no_mar")
	jogador.congelar(true)


# ------------------------------------------------------------------ 2) o mar: navegando de jangada

func _preparar_mar() -> void:
	_jangada = Sprite2D.new()
	_jangada.texture = preload("res://arte/iemanja_jangada_cima.png")
	_jangada.hframes = 16                          # a proa em 16 direções (0 = para cima, girando no sentido do relógio)
	_jangada.vframes = 2                           # e 2 quadros de balanço
	_jangada.z_index = -1                          # Adé fica em pé por cima da jangada
	_jangada.visible = false
	mundo.add_child(_jangada)
	_rastro = CPUParticles2D.new()               # a espuma que a jangada deixa para trás
	_rastro.material = _material_sem_sombra()
	_rastro.amount = 24
	_rastro.lifetime = 1.0
	_rastro.emitting = false
	_rastro.gravity = Vector2.ZERO
	_rastro.spread = 30.0
	_rastro.initial_velocity_min = 4.0
	_rastro.initial_velocity_max = 10.0
	_rastro.scale_amount_min = 1.0
	_rastro.scale_amount_max = 2.0
	var cor := Gradient.new()
	cor.set_color(0, Color(0.75, 1.0, 0.95, 0.9))
	cor.set_color(1, Color(0.75, 1.0, 0.95, 0.0))
	_rastro.color_ramp = cor
	_rastro.z_index = -3
	add_child(_rastro)
	_mar_desenho = Node2D.new()                   # os rolos de onda, as correntezas e o caminho da lua
	_mar_desenho.z_index = -4
	_mar_desenho.material = _material_sem_sombra()
	_mar_desenho.draw.connect(_desenhar_mar)
	add_child(_mar_desenho)


func _navegar(delta: float) -> void:
	if jogador.pode_mover:
		jogador.congelar(true)                    # no mar, quem anda é a jangada
	var origem: Vector2 = lugares["iemanja_mar"]["origem"]
	var tam: Vector2 = tamanhos["iemanja_mar"]
	var remando: bool = not $Dialogo.ativo and not _voltando and estado != "saindo"
	var dir := Input.get_vector("esquerda", "direita", "cima", "baixo") if remando else Vector2.ZERO
	_vel += dir * REMADA * delta
	_vel = _vel.limit_length(VEL_MAX)
	_vel -= _vel * minf(1.0, ARRASTO * delta)
	# a correnteza
	var cel := Vector2i(floori((_pos.x - origem.x) / TILE), floori((_pos.y - origem.y) / TILE))
	if _correntes.has(cel) and remando:
		_vel.x += _correntes[cel] * CORRENTEZA * delta * 3.0
	var antes := _pos
	_pos += _vel * delta
	_pos.x = clampf(_pos.x, origem.x + 18.0, origem.x + tam.x - 18.0)
	_pos.y = clampf(_pos.y, origem.y + 3.6 * TILE, origem.y + tam.y - 20.0)
	# as pedras
	for p in _pedras_mar:
		var centro: Vector2 = p[0]
		var raio: float = p[1]
		if _pos.distance_to(centro) < raio + 6.0:
			var fora := (_pos - centro).normalized()
			if fora == Vector2.ZERO:
				fora = Vector2.DOWN
			_pos = centro + fora * (raio + 6.0)
			_vel = fora * 40.0
			if _invulneravel <= 0.0 and remando:
				_bater_na_pedra()
	# os rolos de onda
	if remando:
		_proximo_rolo -= delta
		if _proximo_rolo <= 0.0:
			_proximo_rolo = ROLO_CADA + randf_range(-0.4, 0.6)
			_rolos.append({"y": _pos.y + 150.0})       # os rolos vêm subindo do mar aberto (lá de baixo)
	for r in _rolos.duplicate():
		var y0: float = r["y"]
		if remando:
			r["y"] -= ROLO_VEL * delta
		if y0 > antes.y and r["y"] <= _pos.y and remando:
			if _vel.y > 30.0:                      # de frente e com força: a jangada fura a onda
				_vel.y *= 0.6
				Jogo.tocar_som("agua_cai", -16.0)
				if not _furou_uma_vez:
					_furou_uma_vez = true
					_mostrar_aviso("Furou a onda!")
			else:                                  # parada ou de lado: a onda empurra para trás
				_vel.y -= 80.0
				_vel.x *= 0.5
				Jogo.tocar_som("agua_cai", -8.0)
				_respingo(_pos)
		if r["y"] < origem.y + 2.0 * TILE:
			_rolos.erase(r)
	# a proa vira devagar para o lado em que a jangada anda (como um barco de verdade)
	if _vel.length() > 6.0:
		var alvo := atan2(_vel.x, -_vel.y)
		_proa = rotate_toward(_proa, alvo, 4.0 * delta)
	var frente := Vector2(sin(_proa), -cos(_proa))
	var q := int(round(fposmod(_proa, TAU) / (TAU / 16.0))) % 16
	_jangada.frame = q + 16 * (int(_tempo * 2.0) % 2)
	_jangada.position = (_pos + Vector2(0, sin(_tempo * 2.2) * 0.6)).round()
	jogador.global_position = (_pos + Vector2(0, 3)).round()
	jogador.olhar_para(jogador.global_position + frente * 10.0)
	_rastro.position = _pos - frente * 13.0          # a espuma sai de trás (da popa)
	_rastro.direction = -frente
	_rastro.emitting = _vel.length() > 18.0
	# as flores
	if remando and _pos.distance_to(_flores_pos) < 36.0 and not _iem.has("flores"):
		if not _iem.has("viu_flores"):
			_iem["viu_flores"] = true
			_mostrar_aviso("Aperte para pegar as flores")
		if Input.is_action_just_pressed("interagir"):
			_colher_flores()


func _bater_na_pedra() -> void:
	_invulneravel = 1.4
	axe -= 1
	_atualizar_axe()
	Jogo.tocar_som("dano", -3.0)
	_respingo(_pos)
	var piscar := create_tween()
	for i in 6:
		piscar.tween_property(jogador, "modulate:a", 0.3, 0.08)
		piscar.tween_property(jogador, "modulate:a", 1.0, 0.08)
	if axe <= 0:
		_sem_axe()
		return
	if not _bateu_uma_vez:
		_bateu_uma_vez = true
		_falar("bateu_pedra")


func _desenhar_mar() -> void:
	var origem: Vector2 = lugares["iemanja_mar"]["origem"]
	var tam: Vector2 = tamanhos["iemanja_mar"]
	var quadro := int(_tempo * 8.0)
	var x0 := maxf(origem.x, _pos.x - 150.0)
	var x1 := minf(origem.x + tam.x, _pos.x + 150.0)
	# o caminho da lua, à frente da jangada
	for y in range(int(_pos.y + 10.0), int(_pos.y + 110.0), 2):
		var d := absf(y - (_pos.y + 60.0)) / 50.0
		if d >= 1.0:
			continue
		var x := x0 + float((y * 13 + quadro * 3) % 7)
		while x < x1:
			if int(x * 0.7 + y * 1.3 + sin(y * 0.5 + _tempo * 2.0) * 3.0 + quadro) % 6 == 0:
				_mar_desenho.draw_rect(Rect2(x, y, 2 if d < 0.4 else 1, 1), Color(0.86, 0.9, 1.0, 0.85 - d * 0.6))
			x += 3.0
	# as correntezas: riscos de brilho correndo para o lado da corrente
	for cel in _correntes:
		var p: Vector2 = origem + Vector2(cel) * TILE
		if absf(p.y - _pos.y) > 140.0:
			continue
		var lado: int = _correntes[cel]
		var k := fmod(_tempo * 40.0 * lado + cel.y * 7.0, 16.0)
		if k < 0.0:
			k += 16.0
		if (cel.x + cel.y) % 2 == 0:
			_mar_desenho.draw_rect(Rect2(p.x + k, p.y + 6, 5, 1), Color(0.55, 0.85, 1.0, 0.55))
	# os rolos de onda: uma faixa de espuma brilhando, com a água mais clara atrás
	for r in _rolos:
		var y: float = r["y"]
		if absf(y - _pos.y) > 140.0:
			continue
		var x := x0
		while x < x1:
			var crista := y + 2.0 * sin(x * 0.12 + _tempo * 3.0) + 1.5 * sin(x * 0.31)
			_mar_desenho.draw_rect(Rect2(x, crista + 2.0, 1, 6), Color(0.2, 0.45, 0.65, 0.45))
			_mar_desenho.draw_rect(Rect2(x, crista, 1, 2), Color(0.72, 1.0, 0.94, 0.95))
			if (int(x) + quadro) % 3 == 0:
				_mar_desenho.draw_rect(Rect2(x, crista - 1.0, 1, 1), Color(0.6, 0.95, 0.9, 0.7))
			x += 1.0


# ------------------------------------------------------------------ as flores

## Depois das flores, Adé se joga do lado da pedra e desce até a areia do fundo do mar.
func _mergulhar() -> void:
	_voltando = true
	jogador.congelar(true)
	Jogo.tocar_som("agua_cai", -6.0)
	var c := create_tween()
	c.tween_property(_cortina, "color:a", 1.0, 0.5)
	await c.finished
	_jangada.visible = false
	_navegando = false
	_mergulhando = true
	jogador.set_physics_process(false)      # sem física de chão/gravidade: debaixo d'água só o _nadar move Adé
	_ar = AR_MAX
	teleportar("iemanja_fundo", FUNDO_ORIGEM + Vector2(15.5 * TILE, 9.5 * TILE))
	_barra_ar.size.x = 60.0
	_barra_ar.visible = true
	await get_tree().create_timer(0.3).timeout
	var c2 := create_tween()
	c2.tween_property(_cortina, "color:a", 0.0, 0.5)
	await c2.finished
	_voltando = false
	await _falar("mergulho")


## Nadando: as setas movem Adé pela água; pedra não passa, e o ar vai acabando.
func _nadar(delta: float) -> void:
	if not _mergulhando or $Dialogo.ativo or _voltando:
		jogador.sprite.rotation = 0.0               # fora da água, Adé volta ao jeito normal
		jogador.sprite.position.y = 0.0
		if _bolhas_nado:
			_bolhas_nado.emitting = false
		return
	var dir := Input.get_vector("esquerda", "direita", "cima", "baixo")
	jogador.velocity = Vector2.ZERO               # na água não há gravidade: a física de chão não pode puxar Adé para a parede
	jogador.collision_mask = 0                    # debaixo d'água quem barra é o mapa (_nado_livre), não o corpo de Adé (mais largo que a passagem)
	var p := jogador.global_position
	var nx := p + Vector2(dir.x * NADO_VEL * delta, 0.0)
	if _nado_livre(nx):
		p.x = nx.x
	var ny := Vector2(p.x, p.y + dir.y * NADO_VEL * delta)
	if _nado_livre(ny):
		p.y = ny.y
	if not _nado_livre(p):
		p = jogador.global_position              # nunca fica numa parede/coral: se o resultado caiu nela, volta
	jogador.global_position = p
	_animar_nado(dir, delta)
	_atualizar_perola(delta, p)
	if lugar_atual != "iemanja_camara":
		_ar -= delta
	for b in _bolhas_ar:
		b["espera"] = maxf(0.0, b["espera"] - delta)
		if b["espera"] <= 0.0 and p.distance_to(b["pos"]) < 12.0:
			b["espera"] = 2.0                      # a fonte continua ali: respira de novo depois de uma pausa
			_ar = minf(AR_MAX, _ar + 10.0)
			Jogo.tocar_som("bolha", -6.0)
	_barra_ar.size.x = 60.0 * clampf(_ar / AR_MAX, 0.0, 1.0)
	if _ar <= 0.0:
		_mergulhando = false
		_sem_ar()
	elif _letra_em(p) == "s":
		_entrar_camara()


## Braçadas: Adé inclina para onde nada e balança como na água.
var _tempo_nado := 0.0

func _animar_nado(dir: Vector2, delta: float) -> void:
	var s: Sprite2D = jogador.sprite
	_tempo_nado += delta
	if dir.x != 0.0:
		s.flip_h = dir.x < 0.0
	if dir.length() > 0.1:
		s.frame = [2, 3, 4, 5][int(_tempo_nado * 8.0) % 4]     # braçadas
	else:
		s.frame = [0, 1][int(_tempo_nado * 1.5) % 2]           # boiando parada
	var alvo := dir.x * 0.3 + sin(_tempo_nado * 5.0) * 0.06
	s.rotation = lerpf(s.rotation, alvo, minf(1.0, 8.0 * delta))
	s.position.y = sin(_tempo_nado * 4.0) * 1.0
	# bolhinhas saindo da cabeça de Adé enquanto ela nada
	if _bolhas_nado == null:
		_bolhas_nado = _criar_emissor_bolhas(3, 1.2, 4.0)
		mundo.add_child(_bolhas_nado)
	_bolhas_nado.global_position = jogador.global_position + Vector2(-5.0 * (-1.0 if s.flip_h else 1.0), -8.0)
	_bolhas_nado.emitting = true


var _bolhas_nado: CPUParticles2D

## Um emissor de bolhas: sobe devagar, aumenta e some no topo.
func _criar_emissor_bolhas(quantidade: int, vida: float, velocidade: float) -> CPUParticles2D:
	var b := CPUParticles2D.new()
	b.amount = quantidade
	b.lifetime = vida
	b.direction = Vector2(0, -1)
	b.spread = 15.0
	b.gravity = Vector2(0, -velocidade)
	b.initial_velocity_min = 2.0
	b.initial_velocity_max = 6.0
	b.scale_amount_min = 0.8
	b.scale_amount_max = 2.2
	var grad := Gradient.new()
	grad.set_color(0, Color(0.7, 0.96, 1.0, 0.0))
	grad.add_point(0.25, Color(0.7, 0.96, 1.0, 0.9))
	grad.set_color(grad.get_point_count() - 1, Color(0.4, 0.8, 1.0, 0.0))
	b.color_ramp = grad
	b.z_index = 20
	return b


func _criar_bolha_ar(base: Vector2) -> void:
	# luz suave que identifica a bolha de longe
	_luz(base + Vector2(0, -4), Color(0.4, 0.85, 1.0), 0.7, 0.55, false)
	var bolha := CPUParticles2D.new()
	bolha.position = base
	bolha.amount = 10
	bolha.lifetime = 1.8
	bolha.direction = Vector2(0, -1)
	bolha.spread = 20.0
	bolha.gravity = Vector2(-2.0, -4.0)   # deriva levemente para o lado
	bolha.initial_velocity_min = 8.0
	bolha.initial_velocity_max = 16.0
	bolha.scale_amount_min = 0.8
	bolha.scale_amount_max = 2.5
	bolha.texture = preload("res://arte/bolha_ar.png")
	var grad := Gradient.new()
	grad.set_color(0, Color(0.7, 0.96, 1.0, 0.9))
	grad.add_point(0.4, Color(0.5, 0.88, 1.0, 0.7))
	grad.set_color(grad.get_point_count()-1, Color(0.3, 0.7, 1.0, 0.0))
	bolha.color_ramp = grad
	mundo.add_child(bolha)
	_bolhas_ar.append({"pos": base, "nodo": bolha, "espera": 0.0})


## Bichos que nadam pela câmara (polvo, tripé, pelicano, cavalo-marinho). Nunca passam por cima do altar.
func _criar_animal(caminho: String, quadros: int, base: Vector2, vertical: bool) -> void:
	var s := Sprite2D.new()
	s.texture = load(caminho)
	s.hframes = quadros
	s.position = base + Vector2(0, -8)
	s.z_index = 4
	s.material = _material_sem_sombra()
	mundo.add_child(s)
	_animais.append({"nodo": s, "x0": base.x - 36.0, "x1": base.x + 36.0, "base_y": base.y - 8.0,
		"vel": 9.0 + randf() * 7.0, "dir": 1.0 if randf() < 0.5 else -1.0, "t": randf() * 6.0,
		"quadros": quadros, "vertical": vertical,
		"eletrica": caminho.contains("enguia"), "choque": randf_range(1.0, 3.0)})


## Água-viva grande: flutua devagar e pisca uma luz rosa, que pulsa como o movimento do sino.
func _criar_agua_viva(base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://arte/iemanja_agua_viva.png")
	s.hframes = 2
	s.position = base + Vector2(0, -14)
	s.z_index = 4
	s.material = _material_sem_sombra()
	mundo.add_child(s)
	var luz := PointLight2D.new()
	luz.color = Color(1.0, 0.45, 0.75)
	luz.texture = _luz_tex
	luz.texture_scale = 1.2
	luz.energy = randf_range(0.1, 0.3)
	s.add_child(luz)
	var pulso := create_tween().set_loops()
	pulso.tween_property(luz, "energy", 0.7, 1.6).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(luz, "energy", 0.1, 1.6).set_trans(Tween.TRANS_SINE)
	_animais.append({"nodo": s, "x0": base.x - 30.0, "x1": base.x + 30.0, "base_y": base.y - 14.0,
		"vel": 4.0 + randf() * 3.0, "dir": 1.0 if randf() < 0.5 else -1.0, "t": randf() * 6.0,
		"quadros": 2, "vertical": false, "luz": luz, "pulso": pulso})


## A enguia elétrica solta uma descarga: um clarão azulado e três raios finos em volta do corpo.
func _descarga(n: Sprite2D) -> void:
	var clarao := PointLight2D.new()
	clarao.color = Color(0.5, 0.85, 1.0)
	clarao.texture = _luz_tex
	clarao.texture_scale = 0.9
	clarao.energy = 0.0
	n.add_child(clarao)
	var lum := create_tween()
	lum.tween_property(clarao, "energy", 1.6, 0.05)
	lum.tween_property(clarao, "energy", 0.0, 0.3)
	lum.tween_callback(clarao.queue_free)
	for k in 3:
		var raio := Line2D.new()
		raio.width = 1.0
		raio.default_color = Color(0.75, 0.95, 1.0, 1.0)
		var x := randf_range(-10.0, 10.0)
		var y := randf_range(-6.0, 0.0)
		raio.add_point(Vector2(x, y))
		for j in 3:
			x += randf_range(-4.0, 4.0)
			y += randf_range(-3.0, 3.0)
			raio.add_point(Vector2(x, y))
		n.add_child(raio)
		var fim := create_tween()
		fim.tween_interval(0.12)
		fim.tween_callback(raio.queue_free)


## O teto de corais fica transparente quando Adé passa por baixo, como as copas da mata.
func _atualizar_tetos(delta: float) -> void:
	if lugar_atual != "iemanja_camara":
		return
	var p := jogador.global_position
	for t in _tetos:
		var s: Sprite2D = t["s"]
		var perto := absf(p.x - s.position.x) < 26.0 and absf(p.y - s.position.y) < 22.0
		s.modulate.a = lerpf(s.modulate.a, 0.45 if perto else 1.0, minf(1.0, 8.0 * delta))


func _mover_animais(delta: float) -> void:
	if lugar_atual not in ["iemanja_fundo", "iemanja_camara"] or _altar == null:
		return
	var centro := _altar.position + Vector2(0, -8)
	for a in _animais:
		if a.get("sumindo", false):
			continue
		var n: Sprite2D = a["nodo"]
		a["t"] += delta
		if a["vertical"]:
			# o cavalo-marinho sobe e desce no mesmo lugar
			n.position.y = a["base_y"] + sin(a["t"] * 1.4) * 10.0
			n.flip_h = false
		else:
			n.position.x += a["vel"] * a["dir"] * delta
			n.position.y = a["base_y"] + sin(a["t"] * 2.0) * 5.0
			if n.position.x > a["x1"] or n.position.x < a["x0"]:
				a["dir"] = -a["dir"]
			n.flip_h = a["dir"] < 0.0
		# se chega perto do altar, o bicho volta (ou se afasta, no caso do cavalo)
		if n.position.distance_to(centro) < 30.0:
			if a["vertical"]:
				n.position.x = centro.x + (34.0 if n.position.x >= centro.x else -34.0)
			else:
				a["dir"] = -a["dir"]
				n.position.x = centro.x + (-30.0 if n.position.x < centro.x else 30.0)
		n.frame = int(a["t"] * 3.0) % a["quadros"]
		if a.get("eletrica", false):
			a["choque"] -= delta
			if a["choque"] <= 0.0:
				_descarga(n)
				a["choque"] = randf_range(2.5, 4.5)


## Gotas que caem da ponta de uma estalactite, de vez em quando.
func _criar_gotejo(ponta: Vector2) -> void:
	var g := CPUParticles2D.new()
	g.position = ponta
	g.amount = 2
	g.lifetime = 2.2
	g.preprocess = 2.2
	g.direction = Vector2(0, 1)
	g.spread = 0.0
	g.gravity = Vector2(0, 45)
	g.initial_velocity_min = 0.0
	g.initial_velocity_max = 2.0
	g.scale_amount_min = 1.0
	g.scale_amount_max = 1.0
	g.color = Color(0.7, 0.95, 1.0, 0.85)
	g.z_index = 5
	g.material = _material_sem_sombra()
	mundo.add_child(g)


func _criar_peixe(base: Vector2) -> void:
	var peixe := Sprite2D.new()
	peixe.texture = preload("res://arte/iemanja_peixe.png")
	peixe.hframes = 2
	peixe.position = base
	peixe.z_index = 4
	peixe.material = _material_sem_sombra()
	mundo.add_child(peixe)
	# a lanterna na cabeça: luz amarelada que acende e apaga, iluminando o caminho
	var luz_p := PointLight2D.new()
	luz_p.color = Color(1.0, 0.92, 0.55)
	luz_p.energy = 0.0
	luz_p.texture_scale = 0.5                  # luz pequena, só clareia bem perto do peixe
	luz_p.texture = _luz_tex
	luz_p.position = Vector2(3, -7)            # a luz sai da pontinha da isca, em cima da cabeça
	peixe.add_child(luz_p)
	_peixes.append({"nodo": peixe, "luz": luz_p, "x0": base.x - 40.0, "x1": base.x + 40.0, "vel": 14.0 + randf() * 10.0, "dir": 1.0, "t": randf() * 6.0, "fase": randf() * 5.0})


func _mover_peixes(delta: float) -> void:
	if lugar_atual not in ["iemanja_fundo", "iemanja_camara"]:
		return
	for f in _peixes:
		var n: Sprite2D = f["nodo"]
		f["t"] = f.get("t", 0.0) + delta
		n.position.x += f["vel"] * f["dir"] * delta
		# movimento ondulatório vertical suave
		n.position.y += sin(f["t"] * 2.5) * 8.0 * delta
		if n.position.x > f["x1"] or n.position.x < f["x0"]:
			f["dir"] = -f["dir"]
		n.flip_h = f["dir"] < 0.0
		# anima frames da cauda (batida lenta)
		n.frame = int(f["t"] * 4.0) % 2
		# a lanterna acende e apaga (fica acesa cerca de 3 s em cada ciclo de 5 s)
		var luz: PointLight2D = f["luz"]
		var acesa := fposmod(f["t"] * 0.6 + f["fase"], 5.0) < 3.0
		luz.energy = lerpf(luz.energy, 2.2 if acesa else 0.0, minf(1.0, 5.0 * delta))
		luz.position = Vector2(3.0 * f["dir"], -7.0)


func _nado_livre(pos: Vector2) -> bool:
	# Adé tem corpo: os quatro cantos do corpo precisam estar na trilha (sem encostar nos corais)
	for d in [Vector2(-4, -8), Vector2(4, -8), Vector2(-4, 2), Vector2(4, 2)]:
		if not _perola_pega and _perola != null and (pos + d).distance_to(_perola.global_position) < 44.0:
			continue                              # a pérola fica numa pedra: perto dela, Adé pode chegar
		var l := _letra_em(pos + d)
		if l == "s" and not _perola_pega:
			if not _aviso_saida:
				_aviso_saida = true
				_falar("sem_perola")
			return false
		if not (l == "w" or l == "s" or l == "Z"):   # Z é a casa da pérola: Adé pode chegar nela
			return false
	return true


var _altar: Area2D
var _luz_altar: PointLight2D
var _pulso_altar: Tween
var _perola: Sprite2D
var _perola_luz: PointLight2D
var _perola_pega := false
var _aviso_saida := false

## A pérola ilumina o caminho quando Adé chega perto; ao tocar nela, Adé a guarda.
func _atualizar_perola(delta: float, p: Vector2) -> void:
	if _perola == null or _perola_pega:
		return
	var d := p.distance_to(_perola.global_position)
	# a pérola pisca: mais forte quando Adé está perto, um brilho fraco de longe
	var pisca := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)
	var perto := d < 80.0
	var alvo := (1.2 + 0.8 * pisca) if perto else (0.25 + 0.2 * pisca)
	_perola_luz.energy = lerpf(_perola_luz.energy, alvo, minf(1.0, 6.0 * delta))
	_perola_luz.texture_scale = 1.4 + 0.4 * pisca
	_perola.modulate = Color(1.0, 1.0, 1.0, (0.55 + 0.45 * pisca) if perto else (0.35 + 0.25 * pisca))
	if d < 22.0:
		_pegar_perola()


## Apertar "interagir" perto da pérola também a pega (além de encostar nela).
func _input(ev: InputEvent) -> void:
	if not ev.is_action_pressed("interagir"):
		return
	if _perola_pega or _perola == null or not is_instance_valid(_perola) or $Dialogo.ativo:
		return
	if lugar_atual != "iemanja_fundo" or not _mergulhando:
		return
	if jogador.global_position.distance_to(_perola.global_position) < 40.0:
		get_viewport().set_input_as_handled()
		_pegar_perola()


func _pegar_perola() -> void:
	_perola_pega = true
	_iem["perola"] = true
	Jogo.set_meta("iemanja_perola", true)
	_perola.visible = false
	_perola_luz.energy = 0.0
	_acender_slot("perola", "")
	_pegar_item("perola", _perola.global_position)
	_falar("perola_achada")


func _sem_ar() -> void:
	jogador.congelar(true)
	_barra_ar.visible = false
	_voltando = true
	axe -= 1                                  # faltar ar custa um búzio de axé
	_atualizar_axe()
	await _falar("sem_ar")
	if axe <= 0:
		_sem_axe()
		return
	await _mergulhar()



## A passagem de bolhas leva Adé até a câmara de Aiocá: lá não há timer de ar.
func _entrar_camara() -> void:
	_voltando = true
	jogador.congelar(true)
	_barra_ar.visible = false
	await _falar("camara_chegada")
	teleportar("iemanja_camara", CAMARA_ORIGEM + Vector2(10 * TILE, 10 * TILE))
	_clarear_camara(false)
	_ar = AR_MAX
	_voltando = false
	jogador.congelar(false)


func _aceita_arriar(id: String, alvo: String) -> bool:
	if alvo != "altar_iem" or not ALTAR_ITENS.has(id) or Jogo.has_meta("iemanja_arriou_" + ALTAR_ITENS[id]):
		return false
	if not Jogo.has_meta("iemanja_altar_viu"):
		return false      # só arria depois de olhar (falar com) o altar
	if id == "perola":
		# a pérola é a última: só depois das flores e da alfazema
		return Jogo.has_meta("iemanja_arriou_alfazema") and Jogo.has_meta("iemanja_arriou_flores")
	return true


## Cada item vai para o seu lugar no altar; a pérola, no centro, acende a câmara.
func _ao_arriar(id: String, _alvo: String) -> void:
	Jogo.set_meta("iemanja_arriou_" + ALTAR_ITENS[id], true)
	_pos_oferenda(id, true)
	_clarear_camara(true)
	if id == "perola":
		_acender_camara()


## Adé chega ao altar e fala do que falta arriar (ou que a oferenda está pronta).
func _na_altar() -> void:
	Jogo.set_meta("iemanja_altar_viu", true)
	var nomes := {"alfazema": "a alfazema", "flores_iemanja": "as flores brancas", "perola": "a pérola"}
	var falta := []
	for bid in ALTAR_ITENS:
		if not Jogo.has_meta("iemanja_arriou_" + ALTAR_ITENS[bid]):
			falta.append(nomes[bid])
	var chave := "altar_vazio"
	if falta.is_empty():
		chave = "altar_pronto"
	elif falta.size() < ALTAR_ITENS.size():
		chave = "altar_parcial"
	var linhas: Array = _dados[chave].duplicate(true)
	var txt := " e ".join(falta)
	for l in linhas:
		l["pt"] = l["pt"].replace("{falta}", txt)
	await _falar_linhas(linhas)


## Antes de olhar o altar, Adé não arria nada: ela ainda não sabe se é ali.
func _recusa(id: String, alvo: Dictionary) -> void:
	if alvo.get("id", "") == "altar_iem" and not Jogo.has_meta("iemanja_altar_viu"):
		await _falar_linhas(_dados["altar_nao_visto"].duplicate(true))
		return
	await super._recusa(id, alvo)


func _pos_oferenda(bid: String, animar: bool) -> void:
	var sp := Sprite2D.new()
	sp.texture = Jogo.bornal.icone(bid)
	sp.position = _altar.position + ALTAR_POS[bid]
	sp.z_index = 1
	mundo.add_child(sp)
	if animar:
		sp.modulate.a = 0.0
		create_tween().tween_property(sp, "modulate:a", 1.0, 0.25)
		Jogo.tocar_som("buzio", -6.0)


## Cada oferenda no altar clareia um pouco a câmara; com a última (a pérola), ela fica toda clara.
func _clarear_camara(animar: bool) -> void:
	var n := 0
	for bid in ALTAR_ITENS:
		if Jogo.has_meta("iemanja_arriou_" + ALTAR_ITENS[bid]):
			n += 1
	# só a pérola (a última) clareia a câmara; as duas primeiras deixam tudo escuro
	var peso: float = [0.0, 0.0, 0.0, 1.0][n]
	var alvo := COR_FUNDO.lerp(COR_CAMARA_CLARA, peso)
	if animar:
		create_tween().tween_property(_noite, "color", alvo, 1.2)
	else:
		_noite.color = alvo


## Com a pérola no altar, os bichos e as águas-vivas somem aos poucos (3 segundos).
func _sumir_bichos() -> void:
	for a in _animais:
		a["sumindo"] = true
		var n: Sprite2D = a["nodo"]
		if a.has("pulso"):
			a["pulso"].kill()
		var t := create_tween().set_parallel(true)
		t.tween_property(n, "modulate:a", 0.0, 3.0)
		if a.has("luz"):
			t.tween_property(a["luz"], "energy", 0.0, 3.0)
		t.chain().tween_callback(n.hide)


## A câmara acende e três ondulações saem do altar. Sem diálogo por enquanto: a conversa com Iemanjá vem depois.
func _acender_camara() -> void:
	Jogo.set_meta("iemanja_oferenda", true)
	_sumir_bichos()
	Jogo.tocar_som("claridade", -4.0)
	if _pulso_altar:
		_pulso_altar.kill()
	await get_tree().create_timer(0.5).timeout
	var t := create_tween()
	t.tween_property(_luz_altar, "energy", 2.4, 1.4)
	t.parallel().tween_property(_luz_altar, "texture_scale", 4.0, 1.4)
	for i in 3:
		_ondulacao(_altar.position + Vector2(0, -18), i * 0.45)
	_spawnar_peixes_camara()
	_aparecer_iemanja()


## Iemanjá surge em forma de figura sobre o altar, em brilho suave, depois que a câmara irradia.
func _aparecer_iemanja() -> void:
	await get_tree().create_timer(1.6).timeout
	var ieman := Sprite2D.new()
	ieman.texture = preload("res://arte/iemanja_figura.png")
	ieman.centered = false
	ieman.position = _altar.position + Vector2(-12, -58)
	ieman.z_index = 6
	ieman.modulate.a = 0.0
	ieman.material = _material_sem_sombra()
	mundo.add_child(ieman)
	var luz := PointLight2D.new()
	luz.color = Color(0.7, 0.95, 1.0)
	luz.energy = 0.0
	luz.texture = _luz_tex
	luz.texture_scale = 2.2
	luz.position = Vector2(12, 22)
	ieman.add_child(luz)
	var t := create_tween().set_parallel(true)
	t.tween_property(ieman, "modulate:a", 1.0, 2.5)
	t.tween_property(luz, "energy", 1.0, 2.5)
	await t.finished
	await _falar("iemanja_conversa")
	# um sinal "terminou" de uma caixa anterior pode chegar antes: espera a conversa de fato acabar
	while $Dialogo.ativo:
		await $Dialogo.terminou
	# Iemanjá se despede: a figura some aos poucos
	var sumir := create_tween().set_parallel(true)
	sumir.tween_property(ieman, "modulate:a", 0.0, 1.2)
	sumir.tween_property(luz, "energy", 0.0, 1.2)
	await sumir.finished
	ieman.queue_free()
	# Iemanjá entrega a guia azul (para lavar no terreiro) e o abebé, com a cena de destaque do troféu
	Jogo.set_meta("iemanja_guia", true)
	_pegar_item("guia")
	await _ganhar_trofeu_iemanja()
	_abrir_saida_camara()



## Quando a pérola irradia a câmara, poucos peixes normais aparecem nadando.
func _spawnar_peixes_camara() -> void:
	var tex: Texture2D = preload("res://arte/iemanja_peixe_normal.png")
	var cores_corpo := [Color(1.0, 0.2, 0.2), Color(1.0, 0.5, 0.05), Color(1.0, 0.92, 0.05), Color(0.15, 1.0, 0.3), Color(0.05, 0.95, 1.0), Color(0.2, 0.4, 1.0), Color(1.0, 0.15, 0.85)]
	var cores_luz := [Color(1.0, 0.2, 0.2), Color(1.0, 0.5, 0.05), Color(1.0, 0.92, 0.05), Color(0.15, 1.0, 0.3), Color(0.05, 0.95, 1.0), Color(0.2, 0.4, 1.0), Color(1.0, 0.15, 0.85)]
	var origem := CAMARA_ORIGEM
	for i in 10:
		await get_tree().create_timer(i * 0.35 + randf() * 0.2).timeout
		var idx := randi() % cores_corpo.size()
		var cor: Color = cores_corpo[idx]
		var p := Sprite2D.new()
		p.texture = tex
		p.hframes = 2
		p.position = Vector2(origem.x + randf_range(4 * TILE, 16 * TILE), origem.y + randf_range(3 * TILE, 11 * TILE))
		p.z_index = 4
		p.modulate = Color(cor.r, cor.g, cor.b, 0.0)
		p.material = _material_sem_sombra()
		add_child(p)
		var luz := PointLight2D.new()
		luz.color = cores_luz[idx]
		luz.energy = 0.0
		luz.texture = _luz_tex
		luz.texture_scale = 0.4
		luz.position = Vector2(3, -5)
		p.add_child(luz)
		create_tween().tween_property(p, "modulate:a", 1.0, 0.8)
		var vel := 16.0 + randf() * 12.0
		var dir := 1.0 if randf() > 0.5 else -1.0
		_peixes.append({
			"nodo": p, "luz": luz,
			"x0": origem.x + 3.5 * TILE, "x1": origem.x + 16.5 * TILE,
			"vel": vel, "dir": dir,
			"t": randf() * 6.0, "fase": randf() * 5.0,
			"camara": true
		})


## O abebé de Iemanjá: como o ofá de Oxóssi, o ícone cresce no inventário, a moldura brilha e vem a cena de destaque.
func _ganhar_trofeu_iemanja() -> void:
	_comemorar_mundo()
	Jogo.trofeus["iemanja"] = "Abebé de Iemanjá"
	_pegar_item("abebe")
	_acender_slot("abebe", "")
	_moldura_trofeu.modulate = Color(1.0, 0.85, 0.35)
	var brilho := create_tween().set_loops()
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.95, 0.6), 0.6)
	brilho.tween_property(_moldura_trofeu, "modulate", Color(1.0, 0.78, 0.3), 0.6)
	var ic := AtlasTexture.new()
	ic.atlas = TEX_ITENS_IEM
	ic.region = Rect2(3 * 12, 0, 12, 12)
	await _mostrar_grande(ic, 4.0, "Abebé de Iemanjá!", "Presente de Iemanjá. Leve para o terreiro da Vó.", true)


## Uma bolha de ar, no fundo da câmara, leva Adé de volta ao Ọ̀run quando ele entra nela.
func _abrir_saida_camara() -> void:
	var pos := CAMARA_ORIGEM + Vector2(10 * TILE, 12 * TILE + TILE / 2.0)
	var buraco := Sprite2D.new()
	buraco.texture = preload("res://arte/iemanja_buraco.png")
	buraco.position = pos
	buraco.z_index = -3
	buraco.material = _material_sem_sombra()
	mundo.add_child(buraco)
	var bolhas := _criar_emissor_bolhas(10, 2.2, 12.0)
	bolhas.position = pos
	mundo.add_child(bolhas)
	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2        # o jogador (mesma máscara das saídas das outras fases)
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 16)
	forma.shape = r
	area.add_child(forma)
	mundo.add_child(area)
	area.body_entered.connect(_sair_camara)
	_mostrar_aviso("Uma bolha de ar sobe deste buraco. Ela leva Adé de volta ao Ọ̀run.")


func _sair_camara(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador") and estado != "saindo":
		voltar_ao_mapa()


func _ondulacao(pos: Vector2, atraso: float) -> void:
	await get_tree().create_timer(atraso).timeout
	var anel := Line2D.new()
	anel.width = 1.0
	anel.default_color = Color(0.7, 0.95, 1.0, 0.9)
	for k in 25:
		var a := TAU * k / 24.0
		anel.add_point(Vector2(cos(a), sin(a)) * 6.0)
	anel.position = pos
	anel.z_index = 3
	mundo.add_child(anel)
	var t := create_tween().set_parallel(true)
	t.tween_property(anel, "scale", Vector2(7, 7), 1.8)
	t.tween_property(anel, "modulate:a", 0.0, 1.8)
	t.chain().tween_callback(anel.queue_free)

func _chegou_fundo() -> void:
	jogador.congelar(true)
	jogador.set_physics_process(true)       # sai da água: devolve a física normal
	_barra_ar.visible = false
	_voltando = true
	await _falar("fundo")
	voltar_ao_mapa()


func _colher_flores() -> void:
	if _iem.has("flores") or $Dialogo.ativo:
		return
	_vel = Vector2.ZERO
	await _falar("flores")
	jogador.congelar(true)
	_flores.frame = 1
	Jogo.set_meta("iemanja_flores", true)
	await _falar("continua")
	await _mergulhar()


func _ao_evento(nome: String) -> void:
	match nome:
		"pegar_flores":
			_iem["flores"] = true
			_acender_slot("flores", "")
			_pegar_item("flores_iemanja", _flores.global_position if _flores else Vector2(-1, -1))
		"pegar_remo":
			_iem["remo"] = true
			Jogo.set_meta("iemanja_remo", true)
			_pegar_item("remo", _remo.global_position + Vector2(0, -6) if _remo else Vector2(-1, -1))
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
	if lugar_atual == "iemanja_camara":
		return "iemanja_camara"
	return "iemanja_fundo" if _mergulhando else "iemanja"


func _pode_guardar() -> bool:
	return estado != "saindo" and not _navegando


## Na gruta, a poça do meio é funda: a primeira pedra só afunda; com a segunda por cima, vira caminho.
func _ao_afundar_pedra(p: Dictionary) -> void:
	var abaixo: Vector2i = p["celula"] + Vector2i(0, 1)
	var funda := _letra(_mapas[p["lugar"]], abaixo.x, abaixo.y) == "~" and not _pontes.has(_chave(p["lugar"], abaixo))
	if funda:
		if not _iem.has("poca_funda"):
			_iem["poca_funda"] = true
			await _falar("pedra_funda")
	elif not _iem.has("ponte"):
		_iem["ponte"] = true
		await _falar("pedra_ponte")


# ------------------------------------------------------------------ a tartaruga velha

## Longe de Adé, ela passeia devagar pela areia molhada; quando ele chega perto, ela para, vira para ele,
## respira e pisca. Se ele vem correndo para cima dela, ela se esconde no casco um pouquinho.
func _mover_tartaruga(delta: float) -> void:
	if _tartaruga.is_empty():
		return
	var tt: Area2D = _tartaruga["no"]
	var s: Sprite2D = tt.sprite
	var dist := tt.global_position.distance_to(jogador.global_position)
	if _tartaruga["escondida"] > 0.0:
		_tartaruga["escondida"] -= delta
		s.frame = 5
		return
	var chegando: float = (_tartaruga.get("dist", dist) - dist) / maxf(delta, 0.001)
	_tartaruga["dist"] = dist
	if dist < 26.0 and chegando > 35.0 and jogador.pode_mover:
		_tartaruga["escondida"] = 1.6
		som_perto("caranguejo", tt.global_position, -14.0)
		if not _iem.has("susto_tartaruga") and not $Dialogo.ativo:
			_iem["susto_tartaruga"] = true
			_falar_depois.call_deferred("tartaruga_susto")
		return
	var em_conversa: bool = $Dialogo.ativo
	if dist < 56.0 or em_conversa:
		# parada, olhando para Adé: respira devagar e pisca de vez em quando
		tt.olhar_para_jogador = true
		_tartaruga["piscar"] -= delta
		if _tartaruga["piscar"] < 0.0:
			s.frame = 2
			if _tartaruga["piscar"] < -0.16:
				_tartaruga["piscar"] = randf_range(1.8, 3.6)
		else:
			s.frame = int(_tempo * 1.2) % 2
		return
	tt.olhar_para_jogador = false
	if _tartaruga["espera"] > 0.0:
		_tartaruga["espera"] -= delta
		s.frame = int(_tempo * 1.2) % 2
		return
	var alvo: float = _tartaruga["alvo"]
	var dx := alvo - tt.global_position.x
	if absf(dx) < 1.0:
		# chegou: descansa um pouco e escolhe o próximo ponto, sempre perto de casa
		_tartaruga["espera"] = randf_range(1.5, 3.5)
		_tartaruga["alvo"] = _tartaruga["casa"] + randf_range(-28.0, 28.0)
		return
	tt.global_position.x += signf(dx) * minf(absf(dx), 7.0 * delta)
	s.flip_h = dx < 0.0
	s.frame = 3 + int(_tempo * 3.0) % 2


## A passagem para a gruta do costão fica escondida entre as pedras: só depois da dica da tartaruga
## Adé sabe que dá para passar por ali.
func _ao_pisar_porta(corpo: Node2D, numero: String, lugar: String) -> void:
	if lugar == "iemanja_praia" and numero == "1" and corpo.is_in_group("jogador") and jogador.pode_mover \
			and not _falou_tartaruga and not _iem.has("remo"):
		jogador.congelar(true)
		jogador.global_position += Vector2(-14, 0)
		await _falar("costao_fechado")
		return
	await super._ao_pisar_porta(corpo, numero, lugar)
