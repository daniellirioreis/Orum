extends Node2D
## O mapa dos caminhos: depois que Exu abre os caminhos, Adé sai da encruzilhada e escolhe
## para qual campo de orixá ele vai — andando pelo mapa, de ponto em ponto, como nos mapas-múndi
## dos jogos de 16 bits.
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
const TRILHA_BORDA := Color(0.3, 0.19, 0.1)
const TRILHA_TERRA := Color(0.78, 0.6, 0.36)
const TRILHA_CLARA := Color(0.89, 0.74, 0.5)
const TRILHA_CISCO := Color(0.6, 0.43, 0.24)
const TRILHA_PEDRINHA := Color(0.96, 0.9, 0.76)
const TUFO := Color(0.2, 0.48, 0.22)
const MADEIRA := Color(0.56, 0.35, 0.17)
const MADEIRA_CLARA := Color(0.72, 0.5, 0.27)

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
var _texturas: Array = []
var _ade: Sprite2D
var _nome: Label
var _saudacao: Label
var _descricao: Label
var _icone: TextureRect
var _caixa: PanelContainer
var _texto_caixa: Label
var _seta_caixa: Label


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

	var mapa: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_MAPA))
	for id in mapa["nos"]:
		NOS[id] = Vector2(mapa["nos"][id][0], mapa["nos"][id][1])
	for c in mapa["caminhos"]:
		var pts := PackedVector2Array()
		for p in c["pontos"]:
			pts.append(Vector2(p[0], p[1]))
		var ponte := {}
		for i in c["ponte"]:
			ponte[int(i)] = true
		_caminhos.append({"a": c["a"], "b": c["b"], "pontos": pts, "ponte": ponte, "aberto": 0.0})
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
	_ade.position = NOS["orita"]
	var sombra := Sprite2D.new()
	sombra.texture = preload("res://arte/sombra.png")
	sombra.scale = Vector2(0.75, 0.75)
	sombra.show_behind_parent = true
	_ade.add_child(sombra)
	add_child(_ade)

	_criar_interface()
	Jogo.tocar_musica()
	if Jogo.has_meta("mapa_aberto"):
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
	if not ev.is_action_pressed("interagir"):
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
		["res://arte/mundo_nuvem.png", Vector2(96, 40), 7.0, 0.35],
		["res://arte/mundo_nuvem_p.png", Vector2(162, 41), 6.0, 0.42],
		["res://arte/mundo_nuvem_p.png", Vector2(130, 34), 9.0, 0.28],
		["res://arte/mundo_tempestade.png", Vector2(198, 40), 4.0, 0.9],
		["res://arte/mundo_tempestade.png", Vector2(243, 43), 3.0, 1.1],
		["res://arte/mundo_tempestade.png", Vector2(224, 34), 5.0, 0.8],
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
	var andado := 0.0
	for i in range(1, pts.size()):
		var de := pts[i - 1]
		var para := pts[i]
		var passo := de.distance_to(para)
		var t := 0.0
		while t < passo:
			var dt := get_process_delta_time()
			t += VELOCIDADE * dt
			andado += VELOCIDADE * dt
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


# ------------------------------------------------------------------ abertura dos caminhos

func _abrir_caminhos() -> void:
	_nome.text = "Oríta Mẹ́ta"
	_saudacao.text = "Laroyê!"
	_descricao.text = "Exu abriu os caminhos..."
	await get_tree().create_timer(0.8).timeout
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
	await get_tree().create_timer(0.4).timeout
	_abrir_caixa("Os caminhos estão abertos! Cada um leva ao campo de um orixá.\nAnde com as setas e escolha por onde começar.")
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
			lista.append((pts.size() - 1 - k) if c.get("inverso", false) else k)
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
	for id in fins:
		_trilhas.draw_circle(NOS[id], 8.5, TRILHA_BORDA)
	for camada in 4:
		if camada == 1:
			for id in fins:
				_trilhas.draw_circle(NOS[id], 7.5, TRILHA_TERRA)
		if camada == 2:
			for id in fins:
				_trilhas.draw_circle(NOS[id] + Vector2(-0.5, -1), 5.0, TRILHA_CLARA)
		for v in visiveis:
			var c: Dictionary = v[0]
			var pts: PackedVector2Array = c["pontos"]
			for i: int in v[1]:
				var p := pts[i].round()
				var antes := pts[maxi(0, i - 1)]
				var depois := pts[mini(pts.size() - 1, i + 1)]
				var normal := (depois - antes).normalized().orthogonal()
				var ponte: bool = c["ponte"].has(i)
				var largura := 3.5 + 0.5 * sin(i * 0.37 + pts[0].x)
				match camada:
					0:
						_trilhas.draw_circle(p, largura + 1.5, TRILHA_BORDA)
					1:
						_trilhas.draw_circle(p, largura + 0.5, MADEIRA if ponte else TRILHA_TERRA)
					2:
						if ponte:
							if i % 3 == 0:     # vão entre as tábuas
								for k in range(-4, 5):
									_trilhas.draw_rect(Rect2((p + normal * k).round(), Vector2.ONE), TRILHA_BORDA)
							else:
								_trilhas.draw_rect(Rect2((p + normal * -2).round(), Vector2(1, 1)), MADEIRA_CLARA)
						else:
							_trilhas.draw_circle(p + Vector2(-0.5, -0.8), largura - 1.5, TRILHA_CLARA)
					3:
						if ponte:
							for lado in [-5, 5]:   # corrimão
								_trilhas.draw_rect(Rect2((p + normal * lado).round(), Vector2.ONE), Color(0.25, 0.14, 0.06))
							continue
						var h: int = (i * 73 + int(pts[0].x) * 31) % 17
						if h == 0 or h == 7:
							_trilhas.draw_rect(Rect2((p + normal * (h % 3 - 1) * 1.5).round(), Vector2.ONE), TRILHA_CISCO)
						elif h == 3:
							_trilhas.draw_rect(Rect2((p + normal * 1.5).round(), Vector2.ONE), TRILHA_PEDRINHA)
						if i % 9 == 4:     # tufo de capim na beirada
							var lado := 1.0 if (i / 9) % 2 == 0 else -1.0
							var t := (p + normal * lado * (largura + 2.0)).round()
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


func _mostrar_no(id: String) -> void:
	if id == "orita":
		_nome.text = "Oríta Mẹ́ta · a encruzilhada"
		_saudacao.text = "Laroyê!"
		_descricao.text = "Todo caminho começa e termina aqui."
		_icone.texture = null
		return
	var c: Dictionary = _campos[id]
	_nome.text = "%s · %s" % [c["nome"], c["yo"]]
	_saudacao.text = c["saudacao"]
	_descricao.text = c["campo"]
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://arte/mapa_icones.png")
	atlas.region = Rect2(ORDEM_ICONES.find(id) * 16, 0, 16, 16)
	_icone.texture = atlas
	_icone.position = Vector2(8, 9)


func _esconder_no() -> void:
	_nome.text = ""
	_saudacao.text = ""
	_descricao.text = ""
	_icone.texture = null


func _entrar() -> void:
	if _no_atual == "orita":
		_abrir_caixa("Exu: \"A escolha é sua, minha criança. Ande até um campo e entre.\"")
		return
	var c: Dictionary = _campos[_no_atual]
	Jogo.tocar_som("caminho", -10.0)
	_abrir_caixa("%s %s\nO caminho até o campo de %s ainda está se abrindo... Em breve!" % [c["saudacao"], c["nome"], c["nome"]])


func _abrir_caixa(texto: String) -> void:
	_ocupado = true
	_texto_caixa.text = texto
	_caixa.visible = true
	_caixa.position.y = 160.0 if NOS[_no_atual].y < 140.0 else 36.0
	_seta_caixa.position = _caixa.position + Vector2(220, 40)
	_seta_caixa.visible = true
	Jogo.tocar_som("texto", -14.0)


func _fechar_caixa() -> void:
	_caixa.visible = false
	_seta_caixa.visible = false
	await get_tree().create_timer(0.15).timeout
	_ocupado = false
