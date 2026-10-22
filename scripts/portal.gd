extends Area2D
## Saída da fase: o caminho de Ògún (portal de ferro com màrìwò, a franja de palmeira).

const PROXIMA_CENA := "res://cenas/fim.tscn"

var _usado := false


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	if _usado or not corpo.is_in_group("jogador"):
		return
	_usado = true
	corpo.congelar(true)
	Jogo.mudar_cena(PROXIMA_CENA)
