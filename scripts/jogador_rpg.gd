extends CharacterBody2D
## Adé visto de cima (estilo RPG): anda nas quatro direções.
## Folha arte/ade_snes.png: 0-2 de frente, 3-5 de costas, 6-8 de lado (parado, passo, passo).

const VELOCIDADE := 72.0

const ANIMACOES := {
	"frente": {"parado": [0], "andando": [1, 0, 2, 0], "fps": 9.0},
	"costas": {"parado": [3], "andando": [4, 3, 5, 3], "fps": 9.0},
	"lado": {"parado": [6], "andando": [7, 6, 8, 6], "fps": 9.0},
}

var pode_mover := true
var limite_queda := 100000.0   # não usado aqui; existe para ser igual ao jogador de plataforma
var direcao_olhar := "frente"
var _tempo_anim := 0.0

@onready var sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if pode_mover:
		entrada = Vector2(Input.get_axis("esquerda", "direita"), Input.get_axis("cima", "baixo"))
		if entrada.length() > 1.0:
			entrada = entrada.normalized()
	velocity = entrada * VELOCIDADE
	move_and_slide()

	if entrada != Vector2.ZERO:
		if absf(entrada.x) > absf(entrada.y):
			direcao_olhar = "lado"
			sprite.flip_h = entrada.x < 0.0
		else:
			direcao_olhar = "frente" if entrada.y > 0.0 else "costas"
			sprite.flip_h = false
	_animar(delta, entrada != Vector2.ZERO)


func _animar(delta: float, andando: bool) -> void:
	_tempo_anim += delta
	var anim: Dictionary = ANIMACOES[direcao_olhar]
	if andando:
		var quadros: Array = anim["andando"]
		sprite.frame = quadros[int(_tempo_anim * anim["fps"]) % quadros.size()]
	else:
		sprite.frame = anim["parado"][0]


## Olha para um ponto (usado nas conversas).
func olhar_para(ponto: Vector2) -> void:
	var d := ponto - global_position
	if absf(d.x) > absf(d.y):
		direcao_olhar = "lado"
		sprite.flip_h = d.x < 0.0
	else:
		direcao_olhar = "frente" if d.y > 0.0 else "costas"
		sprite.flip_h = false


## Para a personagem (usado durante os diálogos e as cenas).
func congelar(valor: bool) -> void:
	pode_mover = not valor
	if valor:
		velocity = Vector2.ZERO
