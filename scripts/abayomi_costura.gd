extends CanvasLayer
## Dar os nós da abayomi (sem agulha), na caixa de diálogo como os outros mini-jogos:
## a tensão da linha sobe e desce numa barra. Adé aperta "interagir" quando a linha estiver
## bem esticada (na zona verde) para dar o nó. A zona encolhe e a tensão acelera a cada nó.
## A boneca aparece por partes e cada nó fica marcado com um fio. Termina com o sinal "terminou".

signal terminou

const NOS := 5
const PX := 8
const LARGURA := 180.0
const ALTURA := 176.0
## A boneca em pixels (mesmo desenho do ícone): K preto, Y amarelo, R vermelho, B azul, P rosa.
const BONECA := [
	"..YRBBBRY...",
	".YBBKKKBBY..",
	"....KKKK....",
	"...KKKKKK...",
	"KKKBBRBBKKK.",
	"KKBBRRBBPBKK",
	".KBRRPBBRBK.",
	"..BBRPBBPBB.",
	"..BPBBRBBPB.",
	"...BBRBBB...",
	"...KK..KK...",
	"..KKK..KKK..",
]
## Linha (em pixels da boneca) onde cada nó amarra a boneca.
const FIOS := [2, 4, 6, 10, 12]
const COR := {
	"Y": Color(0.96, 0.8, 0.27), "R": Color(0.78, 0.18, 0.23), "B": Color(0.47, 0.76, 0.92),
	"K": Color(0.12, 0.1, 0.11), "P": Color(0.98, 0.78, 0.84),
}
const COR_FIO := Color(0.98, 0.9, 0.6)
const COR_TITULO := Color(1, 0.86, 0.45)
const COR_ERRO := Color(0.95, 0.5, 0.5)

var jogando := false
var _pos := 0
var _marcador := 0.0
var _centro_zona := 0.5     # onde fica a zona verde na barra; muda a cada nó
var _dir := 1.0
var _raiz: Control
var _desenho: Control
var _status: Label
var _aviso: Label
var _dica: Label


func _ready() -> void:
	layer = 9
	_montar()
	_raiz.visible = false


func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.96)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(2)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(38, 26)
	painel.custom_minimum_size = Vector2(LARGURA, ALTURA)
	_raiz.add_child(painel)

	_desenho = Control.new()
	_desenho.position = Vector2(38, 26)
	_desenho.size = Vector2(LARGURA, ALTURA)
	_desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desenho.draw.connect(_desenhar)
	_raiz.add_child(_desenho)

	_status = _rotulo(31, COR_TITULO)
	_aviso = _rotulo(182, COR_ERRO)
	_dica = _rotulo(192, Color(0.8, 0.8, 0.85))


func _rotulo(y: float, cor: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(38, y)
	l.size = Vector2(LARGURA, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", cor)
	_raiz.add_child(l)
	return l


## Joga até Adé dar os cinco nós.
func jogar() -> void:
	_pos = 0
	_marcador = 0.0
	_dir = 1.0
	_centro_zona = randf_range(0.2, 0.8)
	_aviso.text = ""
	_atualizar_status()
	_dica.text = Jogo.texto("{interagir}: dar o nó quando a linha estiver no verde")
	_raiz.visible = true
	jogando = true
	_desenho.queue_redraw()
	await terminou
	_raiz.visible = false


func _atualizar_status() -> void:
	_status.text = "Dê os nós da abayomi · nó %d de %d" % [mini(_pos + 1, NOS), NOS]


func _velocidade() -> float:
	return 0.7 + _pos * 0.2


## Metade da zona verde: começa menor que antes e encolhe a cada nó.
func _meia_zona() -> float:
	return 0.07 - _pos * 0.01


func _process(delta: float) -> void:
	if not jogando:
		return
	_marcador += _dir * _velocidade() * delta
	if _marcador >= 1.0:
		_marcador = 1.0
		_dir = -1.0
	elif _marcador <= 0.0:
		_marcador = 0.0
		_dir = 1.0
	_desenho.queue_redraw()


## A boneca aparece por partes: a cabeça com o primeiro nó, o corpo com o segundo, e assim por diante.
func _linha_visivel(y: int) -> bool:
	if y <= 1:
		return _pos >= 2
	if y <= 3:
		return _pos >= 1
	if y <= 5:
		return _pos >= 3
	if y <= 9:
		return _pos >= 4
	return _pos >= 5


func _desenhar() -> void:
	var origem := Vector2((LARGURA - 12 * PX) / 2.0, 20)
	for y in BONECA.size():
		if not _linha_visivel(y):
			continue
		var linha: String = BONECA[y]
		for x in linha.length():
			var ch := linha[x]
			if ch == ".":
				continue
			_desenho.draw_rect(Rect2(origem + Vector2(x * PX, y * PX), Vector2(PX, PX)), COR[ch])
	# o fio que amarra cada nó dado
	for i in _pos:
		var y: float = origem.y + int(FIOS[i]) * PX - 2.0
		_desenho.draw_rect(Rect2(origem.x - 4, y, 12 * PX + 8, 3), COR_FIO)

	# a barra com a zona verde e a tensão da linha
	var barra := Rect2(12, 126, LARGURA - 24, 10)
	_desenho.draw_rect(barra, Color(0.2, 0.18, 0.22))
	var meia := _meia_zona()
	_desenho.draw_rect(Rect2(barra.position.x + barra.size.x * (_centro_zona - meia), barra.position.y, barra.size.x * meia * 2.0, barra.size.y), Color(0.5, 0.9, 0.6))
	var x_tensao := barra.position.x + barra.size.x * _marcador
	_desenho.draw_circle(Vector2(x_tensao, barra.position.y + barra.size.y / 2.0), 5.0, COR_TITULO)

	# os nós: cada um dado fica verde
	for i in NOS:
		var x := 22.0 + i * ((LARGURA - 44.0) / (NOS - 1))
		_desenho.draw_circle(Vector2(x, 146), 4.0, Color(0.5, 0.9, 0.6) if i < _pos else Color(0.3, 0.3, 0.35))


func _unhandled_input(ev: InputEvent) -> void:
	if not jogando:
		return
	get_viewport().set_input_as_handled()     # não deixa outra coisa reagir enquanto costura
	if not ev.is_action_pressed("interagir"):
		return
	if absf(_marcador - _centro_zona) <= _meia_zona():
		_aviso.text = ""
		_pos += 1
		_centro_zona = randf_range(0.2, 0.8)     # o próximo nó fica em outro lugar da linha
		_atualizar_status()
		if _pos >= NOS:
			jogando = false
			_desenho.queue_redraw()
			terminou.emit()
			return
	else:
		_aviso.text = "Frouxo! A linha escorregou. Tente de novo."
	_desenho.queue_redraw()
