extends CanvasLayer
## Contador de búzios e o letreiro com o nome da fase.

var _contador: Label
var _icone: TextureRect
var _titulo: Label
var _subtitulo: Label


func _ready() -> void:
	layer = 5
	_icone = TextureRect.new()
	var icone := _icone
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://arte/buzio.png")
	atlas.region = Rect2(0, 0, 8, 8)
	icone.texture = atlas
	icone.position = Vector2(8, 8)
	add_child(icone)

	_contador = _rotulo(8, Color(1, 0.96, 0.88))
	_contador.position = Vector2(20, 5)
	add_child(_contador)

	_titulo = _rotulo(16, Color(0.98, 0.84, 0.5))
	_subtitulo = _rotulo(9, Color(1, 0.95, 0.88))
	for r in [_titulo, _subtitulo]:
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.size = Vector2(Jogo.TELA.x, 20)
		r.modulate.a = 0.0
		add_child(r)
	_titulo.position = Vector2(0, 60)
	_subtitulo.position = Vector2(0, 82)


func _process(_delta: float) -> void:
	_contador.text = "%d / %d" % [Jogo.buzios, Jogo.buzios_total]
	# só mostra o contador de búzios nas fases que têm búzios
	_contador.visible = Jogo.buzios_total > 0
	_icone.visible = _contador.visible


func mostrar_titulo(titulo: String, subtitulo: String) -> void:
	_titulo.text = titulo
	_subtitulo.text = subtitulo
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(_titulo, "modulate:a", 1.0, 0.6)
	t.parallel().tween_property(_subtitulo, "modulate:a", 1.0, 0.6)
	t.tween_interval(2.2)
	t.tween_property(_titulo, "modulate:a", 0.0, 0.8)
	t.parallel().tween_property(_subtitulo, "modulate:a", 0.0, 0.8)


func _rotulo(tamanho: int, cor: Color) -> Label:
	var r := Label.new()
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	r.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.12))
	r.add_theme_constant_override("outline_size", 3)
	return r
