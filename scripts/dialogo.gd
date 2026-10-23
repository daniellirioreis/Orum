extends CanvasLayer
## Caixa de diálogo: nome de quem fala, a fala em iorubá e a legenda em português.
## Cada linha é um dicionário {"quem", "yo", "pt", "evento" (opcional)}.

signal terminou
signal risada(forte: bool)     # a fala tem a risada de Exu
signal evento(nome: String)

const LETRAS_POR_SEGUNDO := 45.0
const ALTURA_TELA := 224.0

const COR_NOME := Color(1.0, 0.86, 0.45)
const COR_YORUBA := Color(1.0, 0.97, 0.9)
const COR_LEGENDA := Color(0.78, 0.82, 0.95)

var ativo := false
var _linhas: Array = []
var _indice := 0
var _letras := 0.0
var _total := 0
var _som_espera := 0.0

var _painel: PanelContainer
var _placa: PanelContainer
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
	var y := 14.0 if no_topo else ALTURA_TELA - 66.0
	_painel.position.y = y
	_placa.position.y = y - 9.0
	_seta.position.y = y + 46.0


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
	_placa.visible = _nome.text != ""
	_yoruba.text = Jogo.texto(linha.get("yo", ""))
	_yoruba.visible = _yoruba.text != ""
	_legenda.text = Jogo.texto(linha.get("pt", ""))
	# sem iorubá (narração), a legenda vira o texto principal
	_legenda.add_theme_color_override("font_color", COR_LEGENDA if _yoruba.visible else COR_YORUBA)
	_letras = 0.0
	_total = _yoruba.text.length() + _legenda.text.length()
	_atualizar_texto()
	_rir(linha.get("yo", "") + " " + linha.get("pt", ""))
	if linha.has("evento"):
		evento.emit(linha["evento"])


## Quando a fala tem a risada de Exu, avisa a cena (Exu gargalha): "Há há há!" é a gargalhada (forte),
## "hi hi hi!" o risinho.
func _rir(texto: String) -> void:
	var t := texto.to_lower()
	if "há há há" in t:
		risada.emit(true)
	elif "hi hi hi" in t:
		risada.emit(false)


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
	_placa.visible = false
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
	var largura := float(Jogo.TELA.x) - 16.0
	_painel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.96)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 7
	estilo.content_margin_bottom = 5
	estilo.shadow_color = Color(0, 0, 0, 0.5)
	estilo.shadow_size = 2
	estilo.shadow_offset = Vector2(1, 2)
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.position = Vector2(8, ALTURA_TELA - 66.0)
	_painel.size = Vector2(largura, 58)
	_painel.custom_minimum_size = Vector2(largura, 58)
	add_child(_painel)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 1)
	_painel.add_child(caixa)
	_yoruba = _rotulo(11, COR_YORUBA)
	_yoruba.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_yoruba.custom_minimum_size.x = largura - 18
	_legenda = _rotulo(8, COR_LEGENDA)
	_legenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_legenda.custom_minimum_size.x = largura - 18
	caixa.add_child(_yoruba)
	caixa.add_child(_legenda)

	# plaquinha com o nome de quem fala, em cima da borda
	_placa = PanelContainer.new()
	var estilo_placa := StyleBoxFlat.new()
	estilo_placa.bg_color = Color(0.5, 0.12, 0.12, 1.0)
	estilo_placa.border_color = Color(0.95, 0.95, 1.0)
	estilo_placa.set_border_width_all(1)
	estilo_placa.set_corner_radius_all(2)
	estilo_placa.content_margin_left = 5
	estilo_placa.content_margin_right = 5
	estilo_placa.content_margin_top = 0
	estilo_placa.content_margin_bottom = 0
	_placa.add_theme_stylebox_override("panel", estilo_placa)
	_placa.position = Vector2(16, ALTURA_TELA - 75.0)
	_placa.z_index = 1
	add_child(_placa)
	_nome = _rotulo(8, COR_NOME)
	_placa.add_child(_nome)
	_placa.visible = false

	_seta = _rotulo(9, COR_NOME)
	_seta.text = "▼"
	_seta.position = Vector2(largura - 6, ALTURA_TELA - 20.0)
	add_child(_seta)


func _rotulo(tamanho: int, cor: Color) -> Label:
	var r := Label.new()
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	return r
