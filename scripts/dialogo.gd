extends CanvasLayer
## Caixa de diálogo: nome de quem fala, a fala em iorubá e a legenda em português.
## Cada linha é um dicionário {"quem", "yo", "pt", "evento" (opcional)}.

signal terminou
signal evento(nome: String)

const LETRAS_POR_SEGUNDO := 45.0

const COR_NOME := Color(0.95, 0.74, 0.32)
const COR_YORUBA := Color(1.0, 0.97, 0.9)
const COR_LEGENDA := Color(0.78, 0.74, 0.82)

var ativo := false
var _linhas: Array = []
var _indice := 0
var _letras := 0.0
var _total := 0
var _som_espera := 0.0

var _painel: PanelContainer
var _nome: Label
var _yoruba: Label
var _legenda: Label
var _seta: Label


func _ready() -> void:
	add_to_group("dialogo")
	layer = 10
	_montar_interface()
	_painel.visible = false
	_seta.visible = false


## Coloca a caixa no alto da tela (quando os personagens estão embaixo) ou embaixo.
func posicionar(no_topo: bool) -> void:
	var y := 26.0 if no_topo else 146.0
	_painel.position.y = y
	_seta.position.y = y + 50.0


func iniciar(linhas: Array) -> void:
	if linhas.is_empty():
		return
	_linhas = linhas
	_indice = 0
	ativo = true
	_painel.visible = true
	_congelar_jogador(true)
	_mostrar_linha()


func _mostrar_linha() -> void:
	var linha: Dictionary = _linhas[_indice]
	_nome.text = linha.get("quem", "")
	_yoruba.text = linha.get("yo", "")
	_yoruba.visible = _yoruba.text != ""
	_legenda.text = linha.get("pt", "")
	# sem iorubá (narração), a legenda vira o texto principal
	_legenda.add_theme_color_override("font_color", COR_LEGENDA if _yoruba.visible else COR_YORUBA)
	_letras = 0.0
	_total = _yoruba.text.length() + _legenda.text.length()
	_atualizar_texto()
	if linha.has("evento"):
		evento.emit(linha["evento"])


func _process(delta: float) -> void:
	if not ativo:
		return
	if _letras < _total:
		_letras += LETRAS_POR_SEGUNDO * delta
		_som_espera -= delta
		if _som_espera <= 0.0:
			Jogo.tocar_som("texto", -14.0)
			_som_espera = 0.07
		_atualizar_texto()
	_seta.visible = _letras >= _total and int(Time.get_ticks_msec() / 400) % 2 == 0


func _atualizar_texto() -> void:
	var n := int(_letras)
	var tam_yo := _yoruba.text.length()
	_yoruba.visible_characters = mini(n, tam_yo)
	_legenda.visible_characters = maxi(n - tam_yo, 0) if _yoruba.visible else n


func _unhandled_input(ev: InputEvent) -> void:
	if not ativo:
		return
	if ev.is_action_pressed("interagir") or ev.is_action_pressed("pular"):
		get_viewport().set_input_as_handled()
		if _letras < _total:
			_letras = _total            # mostra a linha inteira de uma vez
			_atualizar_texto()
		else:
			_indice += 1
			if _indice >= _linhas.size():
				_fechar()
			else:
				_mostrar_linha()


func _fechar() -> void:
	ativo = false
	_painel.visible = false
	_seta.visible = false
	# pequena pausa para o mesmo botão não fazer Adé pular
	await get_tree().create_timer(0.12).timeout
	_congelar_jogador(false)
	terminou.emit()


func _congelar_jogador(valor: bool) -> void:
	var jogador := get_tree().get_first_node_in_group("jogador")
	if jogador:
		jogador.congelar(valor)


func _montar_interface() -> void:
	_painel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.04, 0.1, 0.93)
	estilo.border_color = Color(0.85, 0.62, 0.28)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(2)
	estilo.set_content_margin_all(6)
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.position = Vector2(10, 146)
	_painel.size = Vector2(364, 62)
	_painel.custom_minimum_size = Vector2(364, 62)
	add_child(_painel)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 1)
	_painel.add_child(caixa)

	_nome = _rotulo(8, COR_NOME)
	_yoruba = _rotulo(11, COR_YORUBA)
	_legenda = _rotulo(8, COR_LEGENDA)
	_legenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_legenda.custom_minimum_size.x = 350
	for r in [_nome, _yoruba, _legenda]:
		caixa.add_child(r)

	_seta = _rotulo(9, COR_NOME)
	_seta.text = "»"
	_seta.position = Vector2(362, 196)
	add_child(_seta)


func _rotulo(tamanho: int, cor: Color) -> Label:
	var r := Label.new()
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	return r
