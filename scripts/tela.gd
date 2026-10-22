extends Control
## Tela simples (título ou fim de capítulo): fundo do pôr do sol, textos e
## "aperte para continuar".

@export_enum("titulo", "fim") var tipo := "titulo"

var _aviso: Label
var _pronto := false


func _ready() -> void:
	Jogo.tocar_musica()
	for nome in ["fundo_ceu", "fundo_montes", "fundo_arvores"]:
		var img := TextureRect.new()
		img.texture = load("res://arte/%s.png" % nome)
		add_child(img)

	if tipo == "titulo":
		var titulo := _texto("Ọ̀RUN", 34, Color(0.98, 0.82, 0.45), 30)
		titulo.add_theme_font_override("font", preload("res://fontes/NotoSans-SemiBold.ttf"))
		_texto("Ìtàn àwọn Òrìṣà · Histórias dos Orixás", 10, Color(1, 0.95, 0.88), 76)
		_personagem("res://arte/ade.png", 16, Vector2(170, 200))
		_personagem("res://arte/exu.png", 24, Vector2(214, 200))
		_aviso = _texto("Aperte Enter ou Espaço", 9, Color(1, 1, 1), 112)
		_texto("Andar: A/D ou setas · Pular: Espaço · Falar: E · Tela cheia: F11", 7, Color(0.85, 0.8, 0.9), 202)
	else:
		_texto("Fim do Prólogo", 22, Color(0.98, 0.82, 0.45), 34)
		_texto("Àṣẹ.", 14, Color(1, 0.95, 0.88), 66)
		_texto("Búzios recolhidos: %d de %d" % [Jogo.buzios, Jogo.buzios_total], 9, Color(1, 0.95, 0.88), 92)
		_texto("Próximo capítulo: Ògún, o que abre os caminhos (em breve)", 8, Color(0.9, 0.85, 0.95), 110)
		_aviso = _texto("Aperte Enter para voltar ao início", 9, Color(1, 1, 1), 136)

	# evita que o mesmo toque que trouxe até aqui pule a tela
	await get_tree().create_timer(0.6).timeout
	_pronto = true


func _process(_delta: float) -> void:
	_aviso.visible = int(Time.get_ticks_msec() / 500) % 2 == 0


func _unhandled_input(ev: InputEvent) -> void:
	if not _pronto:
		return
	if ev.is_action_pressed("interagir") or ev.is_action_pressed("pular"):
		_pronto = false
		if tipo == "titulo":
			Jogo.mudar_cena("res://cenas/terreiro.tscn")
		else:
			Jogo.mudar_cena("res://cenas/titulo.tscn")
	elif ev.is_action_pressed("sair") and tipo == "titulo":
		get_tree().quit()


func _texto(texto: String, tamanho: int, cor: Color, y: float) -> Label:
	var r := Label.new()
	r.text = texto
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.position = Vector2(0, y)
	r.size = Vector2(384, tamanho + 8)
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	r.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.14))
	r.add_theme_constant_override("outline_size", maxi(2, tamanho / 5))
	add_child(r)
	return r


func _personagem(caminho: String, largura: int, pes: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load(caminho)
	s.hframes = s.texture.get_width() / largura
	s.centered = true
	s.offset.y = -s.texture.get_height() / 2.0
	s.position = pes
	add_child(s)
