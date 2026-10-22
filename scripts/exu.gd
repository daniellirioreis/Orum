extends Area2D
## Exu na encruzilhada. Quando Adé chega perto, aparece o balão;
## apertando "interagir" (E / Enter) a conversa começa.

const ARQUIVO_DIALOGO := "res://dialogos/exu.json"

var _jogador_perto := false
var _espera := 0.0
var _tempo := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var balao: Sprite2D = $Balao


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		_jogador_perto = true


func _ao_sair(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		_jogador_perto = false


func _process(delta: float) -> void:
	_tempo += delta
	_espera -= delta
	sprite.frame = int(_tempo * 1.5) % 2
	var dialogo := _dialogo()
	balao.visible = _jogador_perto and not dialogo.ativo
	balao.position.y = -40.0 + round(sin(_tempo * 4.0) * 1.5)
	# Exu olha para Adé
	var jogador := get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador:
		sprite.flip_h = jogador.global_position.x > global_position.x


func _unhandled_input(evento: InputEvent) -> void:
	if not _jogador_perto or _espera > 0.0:
		return
	if evento.is_action_pressed("interagir") and not _dialogo().ativo:
		get_viewport().set_input_as_handled()
		_conversar()


func _conversar() -> void:
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_DIALOGO))
	var linhas: Array = []
	if Jogo.falou_com_exu:
		linhas = dados["depois"].duplicate()
	else:
		linhas = dados["primeira_vez"].duplicate()
	if Jogo.buzios_total > 0 and Jogo.buzios == Jogo.buzios_total:
		linhas.append_array(dados["todos_os_buzios"])
	var dialogo := _dialogo()
	dialogo.iniciar(linhas)
	await dialogo.terminou
	_espera = 0.4


func _dialogo() -> Node:
	return get_tree().get_first_node_in_group("dialogo")
