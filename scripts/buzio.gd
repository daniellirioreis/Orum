extends Area2D
## Búzio (owó ẹyọ) para coletar. Flutua, brilha e some ao ser tocado.

var _tempo := 0.0
var _coletado := false

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	_tempo = position.x * 0.05   # cada búzio balança num ritmo diferente
	body_entered.connect(_ao_tocar)


func _process(delta: float) -> void:
	if _coletado:
		return
	_tempo += delta
	sprite.position.y = round(sin(_tempo * 3.0) * 2.0)
	sprite.frame = 1 if fmod(_tempo, 2.0) < 0.15 else 0


func _ao_tocar(corpo: Node2D) -> void:
	if _coletado or not corpo.is_in_group("jogador"):
		return
	_coletado = true
	Jogo.buzios += 1
	Jogo.tocar_som("buzio", -4.0)
	var t := create_tween().set_parallel()
	t.tween_property(sprite, "position:y", sprite.position.y - 12.0, 0.3)
	t.tween_property(sprite, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(queue_free)
