extends CharacterBody2D
## Adé visto de cima (estilo RPG): anda nas quatro direções.
## Folha arte/ade_snes.png: 0-2 de frente, 3-5 de costas, 6-8 de lado (parado, passo, passo).

const VELOCIDADE := 72.0
const LENTO := 0.4          # segurando "devagar" (SHIFT / C): passos de caçador, sem barulho

const ANIMACOES := {
	"frente": {"parado": [0], "andando": [1, 0, 2, 0], "fps": 9.0},
	"costas": {"parado": [3], "andando": [4, 3, 5, 3], "fps": 9.0},
	"lado": {"parado": [6], "andando": [7, 6, 8, 6], "fps": 9.0},
}

var pode_mover := true
var limite_queda := 100000.0   # não usado aqui; existe para ser igual ao jogador de plataforma
var direcao_olhar := "frente"
var devagar := false
var fator_chao := 1.0            # lama, areia funda...: a fase diminui (1.0 = chão firme)
var animacao_especial := false   # batendo palmas etc.: quem troca os quadros é a cena
var _tempo_anim := 0.0
var _ultimo_passo := -1

@onready var sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if pode_mover and not Jogo.em_dialogo:
		entrada = Vector2(Input.get_axis("esquerda", "direita"), Input.get_axis("cima", "baixo"))
		if entrada.length() > 1.0:
			entrada = entrada.normalized()
	devagar = pode_mover and not Jogo.em_dialogo and Input.is_action_pressed("devagar")
	velocity = entrada * VELOCIDADE * (LENTO if devagar else 1.0) * fator_chao
	move_and_slide()

	if entrada != Vector2.ZERO:
		if absf(entrada.x) > absf(entrada.y):
			direcao_olhar = "lado"
			sprite.flip_h = entrada.x < 0.0
		else:
			direcao_olhar = "frente" if entrada.y > 0.0 else "costas"
			sprite.flip_h = false
	if not animacao_especial:
		_animar(delta, entrada != Vector2.ZERO)


func _animar(delta: float, andando: bool) -> void:
	_tempo_anim += delta
	var anim: Dictionary = ANIMACOES[direcao_olhar]
	if andando:
		var quadros: Array = anim["andando"]
		var fps: float = anim["fps"] * (0.5 if devagar else 1.0) * (0.7 if fator_chao < 1.0 else 1.0)
		var i := int(_tempo_anim * fps)
		sprite.frame = quadros[i % quadros.size()]
		if i != _ultimo_passo:
			_ultimo_passo = i
			if i % 2 == 0 and not devagar:     # devagar = passos de caçador, sem barulho
				_som_do_passo()
	else:
		sprite.frame = anim["parado"][0]


func _som_do_passo() -> void:
	var cena := get_tree().current_scene
	if cena and cena.has_method("som_do_chao"):
		var som: Array = cena.som_do_chao(global_position)
		if not som.is_empty():
			Jogo.tocar_som(som[0], som[1] + randf_range(-1.5, 1.5))


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


## Para onde Adé está olhando (usado para atirar a flecha).
func direcao() -> Vector2:
	match direcao_olhar:
		"frente":
			return Vector2.DOWN
		"costas":
			return Vector2.UP
	return Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
