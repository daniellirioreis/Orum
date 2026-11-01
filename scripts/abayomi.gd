extends Control
## Fazer a abayomi: a boneca aparece por partes conforme Adé dá cada nó.
## Cada nó é uma seta da sequência. Errou, a boneca desmancha e recomeça.
## Termina quando os cinco nós estiverem dados (sinal "terminou").

signal terminou

const NOS := 5
const SETAS := {"cima": "↑", "baixo": "↓", "esquerda": "←", "direita": "→"}
const PX := 9
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
const COR := {
	"Y": Color(0.96, 0.8, 0.27), "R": Color(0.78, 0.18, 0.23), "B": Color(0.47, 0.76, 0.92),
	"K": Color(0.12, 0.1, 0.11), "P": Color(0.98, 0.78, 0.84),
}

var _sequencia: Array = []
var _pos := 0
var _aviso := ""
var _fonte: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	var nomes := SETAS.keys()
	for i in NOS:
		_sequencia.append(nomes[randi() % nomes.size()])
	_fonte = ThemeDB.fallback_font
	queue_redraw()


## A boneca aparece por partes: a cabeça com o primeiro nó, o lenço com o segundo, e assim por diante.
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.1, 0.92))
	draw_string(_fonte, Vector2(0, 16), "Dê os nós da abayomi", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(1, 0.86, 0.45))

	# a boneca, crescendo conforme os nós
	var origem := Vector2(size.x / 2.0 - 6 * PX, 28)
	for y in BONECA.size():
		if not _linha_visivel(y):
			continue
		var linha: String = BONECA[y]
		for x in linha.length():
			var ch := linha[x]
			if ch == ".":
				continue
			draw_rect(Rect2(origem + Vector2(x * PX, y * PX), Vector2(PX, PX)), COR[ch])

	# a linha de costura com os nós: cada nó dado fica verde
	var y_linha := 160.0
	draw_line(Vector2(36, y_linha), Vector2(size.x - 36, y_linha), Color(0.85, 0.75, 0.55), 2.0)
	for i in NOS:
		var x := 36.0 + i * ((size.x - 72.0) / (NOS - 1))
		var feito := i < _pos
		draw_circle(Vector2(x, y_linha), 6.0, Color(0.5, 0.9, 0.6) if feito else Color(0.3, 0.3, 0.35))

	# a próxima seta a seguir
	if _pos < NOS:
		var atual: String = SETAS[_sequencia[_pos]]
		draw_string(_fonte, Vector2(0, 198), atual, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color(1, 0.86, 0.45))
	draw_string(_fonte, Vector2(0, 218), _aviso, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(0.95, 0.5, 0.5))


func _unhandled_input(ev: InputEvent) -> void:
	for acao in SETAS.keys():
		if not ev.is_action_pressed(acao):
			continue
		get_viewport().set_input_as_handled()
		if acao == _sequencia[_pos]:
			_aviso = ""
			_pos += 1
			if _pos >= NOS:
				queue_redraw()
				terminou.emit()
				queue_free()
				return
		else:
			_pos = 0
			_aviso = "Desmanchou! Tente de novo."
		queue_redraw()
		return
