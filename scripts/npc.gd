extends Area2D
## Alguém (ou algo) com quem Adé pode interagir: quando ele chega perto, aparece o balão;
## apertando "interagir" (E / Enter), emite o sinal "interagiu". Quem decide o que
## acontece é a cena (por exemplo, scripts/terreiro.gd).

signal interagiu

@export var ativo := true            ## se falso, não mostra balão nem responde
@export var animar := true           ## alterna os quadros 0 e 1 do sprite (respiração)
@export var olhar_para_jogador := true
@export var altura_balao := -40.0

var _perto := false
var _espera := 0.0
var _tempo := 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite")
@onready var balao: Sprite2D = $Balao


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		_perto = true


func _ao_sair(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		_perto = false


func _process(delta: float) -> void:
	_tempo += delta
	_espera -= delta
	var dialogo := get_tree().get_first_node_in_group("dialogo")
	var em_dialogo: bool = dialogo != null and dialogo.ativo
	if em_dialogo:
		_espera = 0.4   # evita reabrir a conversa com o mesmo botão que a fechou
	balao.visible = ativo and _perto and not em_dialogo
	balao.position.y = altura_balao + round(sin(_tempo * 4.0) * 1.5)
	if sprite and animar:
		sprite.frame = int(_tempo * 1.5) % 2
	if sprite and olhar_para_jogador:
		var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
		if jogador:
			sprite.flip_h = jogador.global_position.x < global_position.x


func _unhandled_input(ev: InputEvent) -> void:
	if not ativo or not _perto or _espera > 0.0:
		return
	if ev.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		_espera = 0.4
		interagiu.emit()
