extends Area2D
## Porteira do terreiro. Fica fechada até Exu abrir; aberta, leva Adé para a encruzilhada.

const PROXIMA_CENA := "res://cenas/jogo.tscn"

var aberta := false
var _usada := false

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func abrir() -> void:
	aberta = true
	sprite.frame = 1
	Jogo.tocar_som("caminho", -2.0)


func _ao_entrar(corpo: Node2D) -> void:
	if not aberta or _usada or not corpo.is_in_group("jogador"):
		return
	_usada = true
	corpo.congelar(true)
	Jogo.mudar_cena(PROXIMA_CENA)


func _physics_process(_delta: float) -> void:
	# se Adé já estiver parado dentro da porteira quando ela abrir
	if aberta and not _usada:
		for corpo in get_overlapping_bodies():
			_ao_entrar(corpo)
