extends Area2D
## Item do ritual (Efum, Epó, Oti ou Luna). Só pode ser pego depois que a Vó pede.

signal coletado(id: String)

const QUADROS := {"efum": 0, "epo": 1, "oti": 2, "luna": 3}

@export_enum("efum", "epo", "oti", "luna") var id := "efum"

var ativo := false
var _tempo := 0.0
var _pego := false

@onready var sprite: Sprite2D = $Sprite
@onready var brilho: Sprite2D = $Brilho


func _ready() -> void:
	sprite.frame = QUADROS[id]
	brilho.visible = false
	body_entered.connect(_ao_tocar)


## A Vó pediu: o item começa a brilhar e pode ser pego.
func ativar() -> void:
	ativo = true
	brilho.visible = true
	for corpo in get_overlapping_bodies():
		_ao_tocar(corpo)


func _process(delta: float) -> void:
	if not ativo or _pego:
		return
	_tempo += delta
	sprite.position.y = round(sin(_tempo * 3.0) * 1.5)
	brilho.modulate.a = 0.5 + sin(_tempo * 4.0) * 0.3


func _ao_tocar(corpo: Node2D) -> void:
	if not ativo or _pego or not corpo.is_in_group("jogador"):
		return
	_pego = true
	brilho.visible = false
	Jogo.tocar_som("pegar_item", -4.0)
	coletado.emit(id)
	var t := create_tween().set_parallel()
	t.tween_property(sprite, "position:y", sprite.position.y - 14.0, 0.4)
	t.tween_property(sprite, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(queue_free)
