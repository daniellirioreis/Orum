extends CharacterBody2D
## Adé, a personagem jogável.
## Movimento de plataforma com "coyote time" (pular logo depois de sair da borda)
## e "buffer" de pulo (apertar pular um pouco antes de tocar o chão).

const VELOCIDADE := 110.0
const ACELERACAO := 900.0
const ATRITO := 1200.0
const ACELERACAO_AR := 650.0
const FORCA_PULO := -320.0
const GRAVIDADE := 900.0
const GRAVIDADE_QUEDA := 1300.0   # cai mais rápido do que sobe: pulo mais "firme"
const QUEDA_MAXIMA := 380.0
const TEMPO_COYOTE := 0.1
const TEMPO_BUFFER := 0.12

# quadros da folha arte/ade.png
const ANIMACOES := {
	"parado": {"quadros": [0, 1], "fps": 2.0},
	"correndo": {"quadros": [2, 3, 4, 5], "fps": 10.0},
	"pulando": {"quadros": [6], "fps": 1.0},
	"caindo": {"quadros": [7], "fps": 1.0},
}

var pode_mover := true
var limite_queda := 10000.0        # definido pela fase
var _coyote := 0.0
var _buffer := 0.0
var _animacao := "parado"
var _tempo_anim := 0.0
var _ultimo_chao := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	_ultimo_chao = global_position


func _physics_process(delta: float) -> void:
	var direcao := 0.0
	if pode_mover:
		direcao = Input.get_axis("esquerda", "direita")

	# gravidade
	if not is_on_floor():
		var g := GRAVIDADE if velocity.y < 0.0 else GRAVIDADE_QUEDA
		velocity.y = minf(velocity.y + g * delta, QUEDA_MAXIMA)

	# coyote time e buffer de pulo
	if is_on_floor():
		_coyote = TEMPO_COYOTE
		if _chao_firme():
			_ultimo_chao = global_position
	else:
		_coyote -= delta
	_buffer -= delta
	if pode_mover and Input.is_action_just_pressed("pular"):
		_buffer = TEMPO_BUFFER

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = FORCA_PULO
		_buffer = 0.0
		_coyote = 0.0
		Jogo.tocar_som("pulo", -6.0)

	# soltar o botão no meio do pulo = pulo mais baixo
	if velocity.y < 0.0 and not Input.is_action_pressed("pular"):
		velocity.y *= 0.55

	# movimento horizontal
	var acel := ACELERACAO if is_on_floor() else ACELERACAO_AR
	if direcao != 0.0:
		velocity.x = move_toward(velocity.x, direcao * VELOCIDADE, acel * delta)
		sprite.flip_h = direcao < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, ATRITO * delta)

	move_and_slide()

	if global_position.y > limite_queda:
		_renascer()

	_atualizar_animacao(delta)


## Só guarda o ponto de renascer quando os dois lados dos pés estão sobre chão
## (assim Adé não renasce na beirada do buraco).
func _chao_firme() -> bool:
	var espaco := get_world_2d().direct_space_state
	for dx in [-10.0, 10.0]:
		var consulta := PhysicsPointQueryParameters2D.new()
		consulta.position = global_position + Vector2(dx, 3.0)
		consulta.collision_mask = 1
		if espaco.intersect_point(consulta, 1).is_empty():
			return false
	return true


func _renascer() -> void:
	global_position = _ultimo_chao
	velocity = Vector2.ZERO
	var t := create_tween().set_loops(3)
	t.tween_property(sprite, "modulate:a", 0.2, 0.08)
	t.tween_property(sprite, "modulate:a", 1.0, 0.08)


func _atualizar_animacao(delta: float) -> void:
	var nova := "parado"
	if not is_on_floor():
		nova = "pulando" if velocity.y < 0.0 else "caindo"
	elif absf(velocity.x) > 10.0:
		nova = "correndo"
	if nova != _animacao:
		_animacao = nova
		_tempo_anim = 0.0
	_tempo_anim += delta
	var anim: Dictionary = ANIMACOES[_animacao]
	var quadros: Array = anim["quadros"]
	sprite.frame = quadros[int(_tempo_anim * anim["fps"]) % quadros.size()]


## Para a personagem (usado durante os diálogos).
func congelar(valor: bool) -> void:
	pode_mover = not valor
	if valor:
		velocity.x = 0.0
