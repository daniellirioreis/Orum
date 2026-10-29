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
		img.position = Vector2(-64, 8)   # o fundo tem 384 de largura: centraliza na tela de 256
		add_child(img)

	if tipo == "titulo":
		var titulo := _texto("Ọ̀RUN", 34, Color(0.98, 0.82, 0.45), 30)
		titulo.add_theme_font_override("font", preload("res://fontes/NotoSans-SemiBold.ttf"))
		_texto("Ayé àwọn Òrìṣà · O Mundo dos Orixás", 10, Color(1, 0.95, 0.88), 76)
		_personagem("res://arte/ade.png", 16, Vector2(110, 204))
		_personagem("res://arte/exu.png", 24, Vector2(148, 204))
	else:
		_texto("Fim do Prólogo", 22, Color(0.98, 0.82, 0.45), 34)
		_texto("Àṣẹ.", 14, Color(1, 0.95, 0.88), 66)
		_texto("Búzios recolhidos: %d de %d" % [Jogo.buzios, Jogo.buzios_total], 9, Color(1, 0.95, 0.88), 92)
		_texto("Próximo: Ogum, o que abre os caminhos", 8, Color(0.9, 0.85, 0.95), 110)
		_aviso = _texto("Aperte Enter para voltar ao início", 9, Color(1, 1, 1), 140)

	# evita que o mesmo toque que trouxe até aqui pule a tela
	await get_tree().create_timer(0.6).timeout
	_pronto = true
	if tipo == "titulo":
		# o menu já aparece, direto por cima do pôr do sol
		Jogo.menu.estilo_titulo(true, 98.0)
		await _menu_inicial()


func _exit_tree() -> void:
	if tipo == "titulo":
		Jogo.menu.estilo_titulo(false)


func _process(_delta: float) -> void:
	if _aviso:
		_aviso.visible = int(Time.get_ticks_msec() / 500) % 2 == 0


func _unhandled_input(ev: InputEvent) -> void:
	if not _pronto or tipo == "titulo":
		return
	if ev.is_action_pressed("interagir") or ev.is_action_pressed("pular"):
		_pronto = false
		Jogo.mudar_cena("res://cenas/titulo.tscn")


func _texto(texto: String, tamanho: int, cor: Color, y: float) -> Label:
	var r := Label.new()
	r.text = texto
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.position = Vector2(0, y)
	r.size = Vector2(Jogo.TELA.x, tamanho + 8)
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



## Novo jogo, Continuar (um dos três caminhos guardados por Exu), Configurações e Sair.
func _menu_inicial() -> bool:
	var tem_jogo := false
	for i in Jogo.ESPACOS:
		if not Jogo.resumo(i).is_empty():
			tem_jogo = true
	var escolha := 1 if tem_jogo else 0
	while true:
		var r: Dictionary = await Jogo.menu.escolher("", ["Novo jogo", "Continuar", "Configurações", "Sair"],
			escolha, false, [] if tem_jogo else [1])
		if r["acao"] == "cancelar":
			continue
		escolha = r["i"]
		match r["i"]:
			0:
				Jogo.reiniciar()
				Jogo.mudar_cena("res://cenas/terreiro.tscn")
				return true
			1:
				var espaco: int = await Jogo.menu.escolher_caminho("Continuar qual caminho?", true)
				if espaco >= 0:
					Jogo.carregar(espaco)
					return true
			2:
				await Jogo.menu.opcoes()
			3:
				get_tree().quit()
				return true
	return false
