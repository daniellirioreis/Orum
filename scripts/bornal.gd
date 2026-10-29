extends CanvasLayer
## O Àpò de Adé: a sacola com as coisas que ele carrega para USAR, DAR ou ARRIAR.
## Fica dentro do Jogo (vai junto de uma cena para outra e é guardado no jogo salvo).
##
## Três bolsos:
##   ferramenta → Adé usa no lugar certo (o remo na jangada, a lâmina de bambu na taboa...).
##                Uma ferramenta pode ficar "na mão" (equipada): o botão de atirar usa ela (o ofá).
##   entrega    → Adé dá para alguém (o coco para a Tia Dora, o manjar para a Vó...).
##   oferenda   → Adé arria no lugar sagrado, uma coisa de cada vez (gààrí, epó, oti e luma na tronqueira...).
##
## Tab / I (ou Select no controle) abre o Àpò. A cena diz o que dá para fazer com cada item ali onde
## Adé está (veja terreiro.gd: _acoes_do_bornal e _fazer_no_bornal).
##
## Na mesma tela, a outra página é a caderneta Ìwé Adé: as palavras em iorubá que Adé vai aprendendo.
## Esquerda / direita trocam de página.

signal mudou

const TEX_SLOT := preload("res://arte/hud_slot.png")
const COR_TITULO := Color(1.0, 0.86, 0.45)
const COR_TEXTO := Color(1.0, 0.97, 0.9)
const COR_APAGADA := Color(0.62, 0.66, 0.82)
const COR_AVISO := Color(0.95, 0.74, 0.32)
const BOLSOS := [["ferramenta", "Ferramentas"], ["entrega", "Entregas"], ["oferenda", "Oferenda"]]

## As palavras da caderneta: só o iorubá que aparece no jogo.
## "onde" é a fase em que Adé ouviu a palavra. "duvida": true = ainda não confirmada com o terreiro.
const CADERNETA := [
	{"palavra": "Laroyê", "pron": "la-rô-iê", "sig": "Saudação a Exu. Pede licença no caminho.", "onde": "Encruzilhada", "duvida": false},
	{"palavra": "Èṣù", "pron": "é-xu", "sig": "Exu, o mensageiro que abre os caminhos.", "onde": "Encruzilhada", "duvida": false},
	{"palavra": "Ọ̀run", "pron": "ô-run", "sig": "O céu, o mundo dos orixás.", "onde": "Encruzilhada", "duvida": false},
	{"palavra": "Yemọja", "pron": "iê-mô-dja", "sig": "Iemanjá, a mãe das águas.", "onde": "Encruzilhada", "duvida": false},
	{"palavra": "Nàná Bùrúkù", "pron": "na-na bu-ru-cu", "sig": "Nanã, dona das lagoas, da lama e do barro.", "onde": "Encruzilhada", "duvida": false},
	{"palavra": "Gààrí", "pron": "ga-á-ri", "sig": "Farinha de mandioca torrada.", "onde": "Terreiro da Vó", "duvida": false},
	{"palavra": "Epó", "pron": "é-pó", "sig": "Azeite de dendê, vermelho e cheiroso.", "onde": "Terreiro da Vó", "duvida": false},
	{"palavra": "Oti", "pron": "ô-ti", "sig": "A bebida que se oferece a Exu.", "onde": "Terreiro da Vó", "duvida": false},
	{"palavra": "Ofá", "pron": "ô-fá", "sig": "O arco do caçador.", "onde": "Mata de Oxóssi", "duvida": false},
	{"palavra": "Ọfà kan ṣoṣo", "pron": "ô-fá kan xô-xô", "sig": "Uma flecha só: é tudo de que o caçador precisa.", "onde": "Mata de Oxóssi", "duvida": false},
	{"palavra": "Ọ̀ṣọ́ọ̀sì", "pron": "ô-xô-ô-xi", "sig": "Oxóssi, o caçador e senhor da mata.", "onde": "Mata de Oxóssi", "duvida": false},
	{"palavra": "Okê arô", "pron": "ô-quê a-rô", "sig": "Saudação a Oxóssi.", "onde": "Mata de Oxóssi", "duvida": false},
	{"palavra": "Ó dára, ọmọ mi", "pron": "ó dá-ra, ô-mô mi", "sig": "Muito bem, meu filho.", "onde": "Mata de Oxóssi", "duvida": false},
	{"palavra": "Ọ̀bẹ", "pron": "ô-bê", "sig": "Faca.", "onde": "Mata de Nanã", "duvida": false},
	{"palavra": "Sálùbá", "pron": "sa-lu-bá", "sig": "Saudação a Nanã.", "onde": "Mata de Nanã", "duvida": false},
	{"palavra": "Odoyá", "pron": "ô-dô-iá", "sig": "Saudação a Iemanjá.", "onde": "Mar de Iemanjá", "duvida": false},
	{"palavra": "Aiocá", "pron": "ai-ô-ká", "sig": "O palácio de Iemanjá, no fundo do mar.", "onde": "Mar de Iemanjá", "duvida": false},
	{"palavra": "àbẹ́là", "pron": "a-bê-lá", "sig": "Vela.", "onde": "Terreiro da Vó", "duvida": true},
	{"palavra": "ṣúgà", "pron": "xú-gá", "sig": "Açúcar.", "onde": "Terreiro da Vó", "duvida": true},
	{"palavra": "igi ìdáná", "pron": "i-gi i-dá-ná", "sig": "Lenha: pau para o fogo.", "onde": "Terreiro da Vó", "duvida": true},
	{"palavra": "lófínńdà", "pron": "ló-fín-ndá", "sig": "Alfazema, o perfume roxo.", "onde": "Mar de Iemanjá", "duvida": true},
	{"palavra": "àlùkò", "pron": "a-lu-kô", "sig": "Flor lilás, do mangue.", "onde": "Mata de Nanã", "duvida": true},
]

## id → nome, bolso, frase, ícone [folha, quadro de 12x12], fase (de onde o item é)
const ITENS := {
	# a oferenda a Exu, no terreiro da Vó
	"efum": {"nome": "Gààrí", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 0],
		"desc": "Farinha de mandioca, que a Tia Dora preparou para a oferenda de Exu."},
	"epo": {"nome": "Epó", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 1],
		"desc": "Azeite de dendê, vermelho e cheiroso. Exu gosta."},
	"oti": {"nome": "Oti", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 2],
		"desc": "A bebida que o Ogã Bené guardava para Exu."},
	"luna": {"nome": "Luma", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/itens.png", 3],
		"desc": "Uma vela para iluminar o caminho de Exu."},
	"pade": {"nome": "Padê", "tipo": "oferenda", "fase": "exu", "icone": ["res://arte/pade_itens.png", 0],
		"desc": "O padê mexido no alguidar, até ficar amarelo escuro. Vai na tronqueira, junto com a vela."},
	"lenha": {"nome": "Lenha", "tipo": "entrega", "fase": "exu", "icone": ["res://arte/itens.png", 4],
		"desc": "Um feixe de lenha seca para o fogão da Tia Dora."},
	# a mata de Oxóssi
	"ofa": {"curta": "Já está na mão de Adé. Atire com {atirar}.", "nome": "Ofá", "tipo": "ferramenta", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 3],
		"desc": "O arco do caçador, com uma flecha só. Na mão, atira com {atirar}.", "equipa": true},
	"milho": {"nome": "Milho", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 0],
		"desc": "Uma espiga do milharal. Vai na oferenda para Exu, como a mãe do caçador fez."},
	"coco_mata": {"nome": "Coco", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 1],
		"desc": "Um coco que caiu debaixo do coqueiro da mata."},
	"mel": {"nome": "Mel", "tipo": "oferenda", "fase": "oxossi", "icone": ["res://arte/ox_itens.png", 2],
		"desc": "Um favo de mel da colmeia. Docinho."},
	# a terra de Nanã
	"faca": {"curta": "Um ọ̀bẹ de ferro velho. Será que corta a taboa?", "nome": "Ọ̀bẹ de ferro", "tipo": "ferramenta", "fase": "nana", "icone": ["res://arte/bornal_itens.png", 4],
		"desc": "Um ọ̀bẹ (faca, em iorubá) de ferro velho, achado num toco."},
	"lamina": {"curta": "Bambu afiado: na terra de Nanã, corta melhor que o ferro.", "nome": "Lâmina de bambu", "tipo": "ferramenta", "fase": "nana", "icone": ["res://arte/nana_itens.png", 1],
		"desc": "Uma lasca afiada de bambu rachado. Na terra de Nanã, corta melhor que o ferro."},
	"pote_rachado": {"nome": "Pote rachado", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote de barro da velhinha. Está rachado: assim não segura água."},
	"pote": {"nome": "Pote de barro", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote da velhinha, consertado com o barro da lagoa. Está vazio."},
	"pote_cheio": {"nome": "Pote com água da chuva", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 0],
		"desc": "O pote cheio de água da chuva, para a oferenda de Nanã."},
	"flores_nana": {"nome": "Flores lilás", "tipo": "oferenda", "fase": "nana", "icone": ["res://arte/nana_itens.png", 2],
		"desc": "Flores lilás da ilhota do mangue, para Nanã."},
	# o mar de Iemanjá (e o manjar no terreiro)
	"remo": {"curta": "Agora a jangada pode ir para o mar.", "nome": "Remo", "tipo": "ferramenta", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 0],
		"desc": "O remo da jangada, que o mar tinha deixado na gruta do costão."},
	"coco": {"nome": "Coco", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/ox_itens.png", 1],
		"desc": "Um coco maduro do coqueiro do quintal, para o manjar da Tia Dora."},
	"leite": {"nome": "Leite", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 1],
		"desc": "Uma garrafa de leite fresquinho, para o manjar."},
	"acucar": {"nome": "Açúcar", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 2],
		"desc": "Uma tigelinha de açúcar, para o manjar."},
	"manjar": {"nome": "Manjar branco", "tipo": "entrega", "fase": "iemanja", "icone": ["res://arte/bornal_itens.png", 3],
		"desc": "O manjar que Adé e a Tia Dora fizeram. A comida que Iemanjá mais gosta."},
	"alfazema": {"nome": "Perfume de alfazema", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 1],
		"desc": "O vidrinho roxo da Vó. Ela usa no banho e para lavar as guias. Iemanjá gosta de se sentir cheirosa."},
	"flores_iemanja": {"nome": "Flores brancas", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 0],
		"desc": "As flores brancas da pedra no meio do mar, acesas pela lua."},
	"perola": {"nome": "Pérola", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 2],
		"desc": "Uma pérola do fundo do mar."},
	"espelho": {"nome": "Espelho", "tipo": "oferenda", "fase": "iemanja", "icone": ["res://arte/iemanja_itens.png", 3],
		"desc": "Iemanjá gosta de se ver bonita."},
}

var itens: Array = []          # ids, na ordem em que Adé pegou
var aprendidas: Array = []     # palavras da caderneta que Adé já ouviu nos diálogos
var _aviso: Label

# --- o diário de Adé (as falas que ele já ouviu, como num livro)
var historia: Array = []       # {"capitulo", "quem", "yo", "pt"}, na ordem em que Adé ouviu
var _vistas := {}              # as falas já guardadas (para não repetir a mesma)
var _livro_i := 0
var _livro: Control
var _livro_scroll: ScrollContainer
var _rolagem_acum := 0.0
var _livro_texto: RichTextLabel
var _livro_cap: Label
var _livro_nar: Label
var _livro_quem: Label
var _livro_yo: Label
var _livro_pt: Label
var _livro_contador: Label
var _aba_diario: Label
var _aviso_t := 0.0
var equipado := ""             # a ferramenta "na mão"
var aberto := false

# --- tela do Àpò
var _raiz: Control
var _apo: Control              # a página do Àpò (os itens)
var _cad: Control              # a página da caderneta
var _pagina := 0               # 0 = o Àpò, 1 = a caderneta
var _aba_apo: Label
var _aba_cad: Label
var _dica_tela: Label
var _lista: Array = []         # os ids, na ordem da lista
var _linha := 0                # o item escolhido
var _topo := 0                 # o primeiro item que aparece (a lista rola quando tem muita coisa)
var _linhas_ui: Array = []     # [fundo, ícone, nome] de cada linha visível
var _cursor: ColorRect
const LINHAS_VISIVEIS := 6
const ALTURA_LINHA := 15.0
const TOPO_LISTA := 38.0
var _nome: Label
var _desc: Label
var _escolha = null

# --- a caderneta
var _cad_i := 0                # a palavra escolhida na caderneta
var _cad_topo := 0             # a primeira palavra da coluna da esquerda (rola como o Àpò)
var _cad_cursor: ColorRect
var _cad_linhas_ui: Array = [] # o nome de cada palavra visível na coluna da esquerda
var _cad_contador: Label
var _cad_palavra: Label
var _cad_pron: Label
var _cad_sig: Label
var _cad_onde: Label
var _cad_aviso: Label

# --- a barra pequena do Àpò no canto da tela (o item na mão e quantos itens tem)
var _hud: CanvasLayer
var _hud_slot: TextureRect
var _hud_mao: TextureRect
var _hud_bolsa: TextureRect
var _hud_conta: Label
var _hud_tecla: Label


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_hud()
	mostrar_hud(false)
	Jogo.dispositivo_mudou.connect(_atualizar_hud)     # troca o nome da tecla (Tab / Select / Create / −)


# ------------------------------------------------------------------ os itens

## Guarda uma fala no diário (uma vez só, mesmo que a cena se repita).
func registrar_fala(linha: Dictionary) -> void:
	var quem := str(linha.get("quem", ""))
	var pt := str(linha.get("pt", ""))
	if pt == "" and str(linha.get("yo", "")) == "":
		return
	var chave := quem + "|" + pt
	if _vistas.has(chave):
		return
	_vistas[chave] = true
	historia.append({"capitulo": Jogo.nome_do_local_atual(), "narracao": str(linha.get("narracao", "")), "quem": quem, "yo": str(linha.get("yo", "")), "pt": pt})


## Marca como aprendidas as palavras da caderneta que aparecem no texto de um diálogo.
func aprender_do_texto(texto: String) -> void:
	var t := texto.to_lower()
	for e in CADERNETA:
		var p: String = e["palavra"]
		if not p in aprendidas and t.contains(p.to_lower()):
			aprendidas.append(p)
			_avisar_palavra(p)


## Um aviso pequeno no alto da tela quando Adé aprende uma palavra nova.
func _avisar_palavra(p: String) -> void:
	if _aviso == null:
		var camada := CanvasLayer.new()
		camada.layer = 70
		add_child(camada)
		_aviso = _rotulo("", 8, COR_TITULO)
		_aviso.position = Vector2(0, 26)
		_aviso.size = Vector2(Jogo.TELA.x, 12)
		_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_aviso.visible = false
		camada.add_child(_aviso)
	_aviso.text = "Nova palavra na caderneta: %s" % p
	_aviso.visible = true
	_aviso_t = 2.5


func _process(delta: float) -> void:
	if _aviso_t > 0.0:
		_aviso_t -= delta
		if _aviso_t <= 0.0:
			_aviso.visible = false
	# no diário, segurar cima/baixo rola mais rápido (o toque único continua em _input)
	if aberto and _raiz and _raiz.visible and _escolha == null and not Jogo.menu.aberto and _pagina == 2:
		var segurando := (1.0 if Input.is_action_pressed("baixo") else 0.0) - (1.0 if Input.is_action_pressed("cima") else 0.0)
		if segurando != 0.0:
			_rolagem_acum += segurando * 260.0 * delta
			var inteiro := int(_rolagem_acum)
			_livro_scroll.scroll_vertical += inteiro
			_rolagem_acum -= inteiro


## As palavras que Adé já aprendeu (só essas aparecem na caderneta).
func _caderneta() -> Array:
	var r := []
	for e in CADERNETA:
		if e["palavra"] in aprendidas:
			r.append(e)
	return r


func _existe_na_caderneta(p: String) -> bool:
	for e in CADERNETA:
		if e["palavra"] == p:
			return true
	return false


func tem(id: String) -> bool:
	return id in itens


func icone(id: String) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(ITENS[id]["icone"][0])
	a.region = Rect2(ITENS[id]["icone"][1] * 12, 0, 12, 12)
	return a


## Põe um item no Àpò (se veio de um lugar da tela, o ícone voa de lá até o Àpò).
func pegar(id: String, de_onde := Vector2(-1, -1)) -> void:
	if not ITENS.has(id):
		push_warning("Àpò: item desconhecido " + id)
		return
	if not tem(id):
		itens.append(id)
	if ITENS[id]["tipo"] == "ferramenta" and ITENS[id].get("equipa", false) and equipado == "":
		equipado = id
	_atualizar_hud()
	if de_onde.x >= 0:
		_voar(icone(id), de_onde, _hud_bolsa.position + Vector2(6, 6))
	_pular(_hud_bolsa)
	mudou.emit()


## Tira um item do Àpò (dado, arriado ou usado). Se for para um lugar da tela, o ícone voa até lá.
func tirar(id: String, para_onde := Vector2(-1, -1)) -> void:
	itens.erase(id)
	if equipado == id:
		equipado = ""
	_atualizar_hud()
	if para_onde.x >= 0:
		_voar(icone(id), _hud_bolsa.position + Vector2(6, 6), para_onde)
	mudou.emit()


## Troca um item por outro no mesmo lugar (o pote rachado vira o pote consertado...).
func trocar(id_velho: String, id_novo: String) -> void:
	var i := itens.find(id_velho)
	if i < 0:
		pegar(id_novo)
		return
	itens[i] = id_novo
	if equipado == id_velho:
		equipado = id_novo
	_atualizar_hud()
	_pular(_hud_bolsa)
	mudou.emit()


func equipar(id: String) -> void:
	equipado = id if equipado != id else ""
	_atualizar_hud()
	mudou.emit()


## Começando uma fase do zero: tira do Àpò o que era dessa fase (menos o que a fase guarda entre visitas).
func comecar_fase(fase: String, menos: Array = []) -> void:
	for id in itens.duplicate():
		if ITENS[id]["fase"] == fase and not id in menos:
			itens.erase(id)
	if equipado != "" and not equipado in itens:
		equipado = ""
	_atualizar_hud()
	mudou.emit()


func esvaziar() -> void:
	itens.clear()
	aprendidas.clear()
	historia.clear()
	_vistas.clear()
	equipado = ""
	_atualizar_hud()


func para_salvar() -> Dictionary:
	return {"itens": itens.duplicate(), "equipado": equipado, "aprendidas": aprendidas.duplicate(), "historia": historia.duplicate(true)}


func carregar(d: Dictionary) -> void:
	historia = d.get("historia", []).duplicate(true)
	_vistas.clear()
	for f in historia:
		_vistas[f["quem"] + "|" + f["pt"]] = true
	aprendidas = []
	for p in d.get("aprendidas", []):
		if _existe_na_caderneta(p):
			aprendidas.append(p)
	itens = []
	for id in d.get("itens", []):
		if ITENS.has(id):
			itens.append(id)
	equipado = d.get("equipado", "")
	if not equipado in itens:
		equipado = ""
	_atualizar_hud()


# ------------------------------------------------------------------ a barra pequena (HUD)

func mostrar_hud(sim: bool) -> void:
	_hud.visible = sim
	_atualizar_hud()


func _montar_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	var tela := Vector2(Jogo.TELA)
	_hud_slot = TextureRect.new()
	_hud_slot.texture = TEX_SLOT
	_hud_slot.position = Vector2(tela.x - 124, 4)       # na mão: ao lado do Àpò, na frente do axé
	_hud.add_child(_hud_slot)
	_hud_mao = TextureRect.new()
	_hud_mao.position = _hud_slot.position + Vector2(3, 3)
	_hud_mao.pivot_offset = Vector2(6, 6)
	_hud.add_child(_hud_mao)
	_hud_bolsa = TextureRect.new()
	var a := AtlasTexture.new()
	a.atlas = load("res://arte/bornal_itens.png")
	a.region = Rect2(5 * 12, 0, 12, 12)
	_hud_bolsa.texture = a
	_hud_bolsa.position = Vector2(tela.x - 102, 5)
	_hud_bolsa.pivot_offset = Vector2(6, 6)
	_hud.add_child(_hud_bolsa)
	_hud_conta = _rotulo("", 7, COR_TEXTO)
	_hud_conta.position = Vector2(tela.x - 91, 9)
	_hud.add_child(_hud_conta)
	_hud_tecla = _rotulo("", 6, COR_APAGADA)
	_hud_tecla.position = Vector2(tela.x - 109, 17)
	_hud_tecla.size = Vector2(26, 8)
	_hud_tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_hud_tecla)


func _atualizar_hud() -> void:
	if not _hud:
		return
	var vazio := itens.is_empty()
	_hud_bolsa.visible = true            # o Àpò fica sempre na tela, mesmo vazio
	_hud_bolsa.modulate = Color(1, 1, 1, 0.6 if vazio else 1.0)
	_hud_conta.visible = not vazio
	_hud_tecla.visible = true
	_hud_conta.text = str(itens.size())
	_hud_tecla.text = Jogo.botao("bornal").split(" ou ")[0]
	_hud_slot.visible = equipado != ""
	_hud_mao.visible = equipado != ""
	if equipado != "":
		_hud_mao.texture = icone(equipado)


## A ferramenta na mão fica meio apagada enquanto não dá para usar (a flecha do ofá voando...).
func mao_apagada(sim: bool) -> void:
	_hud_mao.modulate = Color(1, 1, 1, 0.45 if sim else 1.0)


func _pular(n: Control) -> void:
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(1.5, 1.5), 0.1)
	t.tween_property(n, "scale", Vector2.ONE, 0.16)


func _voar(tex: Texture2D, de: Vector2, para: Vector2) -> void:
	var r := TextureRect.new()
	r.texture = tex
	r.position = de - Vector2(6, 6)
	r.pivot_offset = Vector2(6, 6)
	_hud.add_child(r)
	var meio := (de + para) / 2.0 + Vector2(0, -24)
	var t := create_tween()
	t.tween_method(_voar_passo.bind(r, de, meio, para), 0.0, 1.0, 0.45)
	t.parallel().tween_property(r, "scale", Vector2(1.4, 1.4), 0.2)
	t.tween_property(r, "scale", Vector2(0.6, 0.6), 0.1)
	t.tween_callback(r.queue_free)


func _voar_passo(u: float, r: TextureRect, de: Vector2, meio: Vector2, para: Vector2) -> void:
	r.position = de.lerp(meio, u).lerp(meio.lerp(para, u), u) - Vector2(6, 6)


# ------------------------------------------------------------------ a tela do Àpò

## Abre o Àpò. "acoes" é uma função da cena: recebe o id e devolve [[rótulo, ação], ...] — o que dá
## para fazer com o item ali (Dar, Arriar, Usar, Equipar...). Devolve {"id", "acao"}, ou {} se Adé fechou.
func abrir(acoes: Callable) -> Dictionary:
	aberto = true
	get_tree().paused = true
	Jogo.tocar_som("pegar_item", -12.0)
	_montar_tela()
	var resposta := {}
	while true:
		_escolha = null
		while _escolha == null:
			await get_tree().process_frame
		if _escolha is String and _escolha == "fechar":
			break
		var id: String = _escolha
		var opcoes: Array = acoes.call(id)
		var rotulos := []
		for o in opcoes:
			rotulos.append(o[0])
		rotulos.append("Voltar")
		_raiz.visible = false
		var r: Dictionary = await Jogo.menu.escolher(ITENS[id]["nome"], rotulos)
		_raiz.visible = true
		if r["acao"] == "ok" and r["i"] < opcoes.size():
			resposta = {"id": id, "acao": opcoes[r["i"]][1]}
			break
	_raiz.queue_free()
	_raiz = null
	get_tree().paused = false
	await get_tree().process_frame
	aberto = false
	return resposta


func _montar_tela() -> void:
	var tela := Vector2(Jogo.TELA)
	_raiz = Control.new()
	_raiz.size = tela
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.45)
	fundo.size = tela
	_raiz.add_child(fundo)
	var painel := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.08, 0.3, 0.97)
	estilo.border_color = Color(0.95, 0.95, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = Vector2(16, 14)
	painel.size = Vector2(tela.x - 32, tela.y - 28)
	_raiz.add_child(painel)

	# as abas: o Àpò e a caderneta
	var bolsa := TextureRect.new()
	var a := AtlasTexture.new()
	a.atlas = load("res://arte/bornal_itens.png")
	a.region = Rect2(5 * 12, 0, 12, 12)
	bolsa.texture = a
	bolsa.position = Vector2(28, 20)
	_raiz.add_child(bolsa)
	_aba_apo = _rotulo("Àpò de Adé", 9, COR_TITULO)
	_aba_apo.position = Vector2(46, 19)
	_raiz.add_child(_aba_apo)
	var caderneta := TextureRect.new()
	var c := AtlasTexture.new()
	c.atlas = load("res://arte/bornal_itens.png")
	c.region = Rect2(6 * 12, 0, 12, 12)
	caderneta.texture = c
	caderneta.position = Vector2(116, 20)
	_raiz.add_child(caderneta)
	_aba_cad = _rotulo("Ìwé Adé", 8, COR_APAGADA)
	_aba_cad.position = Vector2(130, 19)
	_raiz.add_child(_aba_cad)
	_aba_diario = _rotulo("Ìrántí", 8, COR_APAGADA)
	_aba_diario.position = Vector2(192, 19)
	_raiz.add_child(_aba_diario)

	_apo = Control.new()
	_apo.size = tela
	_raiz.add_child(_apo)
	_montar_apo(tela)
	_montar_cad(tela)
	_montar_livro(tela)

	_dica_tela = _rotulo("", 7, COR_APAGADA)
	_dica_tela.position = Vector2(16, tela.y - 26)
	_dica_tela.size = Vector2(tela.x - 32, 10)
	_dica_tela.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raiz.add_child(_dica_tela)

	_pagina = 0
	_livro_i = 0
	_linha = 0
	_topo = 0
	_cad_i = 0
	_cad_topo = 0
	_mostrar_pagina()


func _montar_apo(tela: Vector2) -> void:
	# a lista: ícone pequeno na frente do nome (as ferramentas primeiro, depois o resto, na ordem em que Adé pegou)
	_lista.clear()
	for b in BOLSOS:
		for id in itens:
			if ITENS[id]["tipo"] == b[0]:
				_lista.append(id)
	_cursor = ColorRect.new()
	_cursor.color = Color(1.0, 0.85, 0.3, 0.22)
	_cursor.size = Vector2(tela.x - 56, ALTURA_LINHA)
	_apo.add_child(_cursor)
	_linhas_ui.clear()
	for i in LINHAS_VISIVEIS:
		var y := TOPO_LISTA + i * ALTURA_LINHA
		var ic := TextureRect.new()
		ic.position = Vector2(32, y + 1.5)
		_apo.add_child(ic)
		var nome := _rotulo("", 8, COR_TEXTO)
		nome.position = Vector2(48, y + 1)
		_apo.add_child(nome)
		_linhas_ui.append([ic, nome])
	var seta_cima := _rotulo("▲", 6, COR_APAGADA)
	seta_cima.name = "SetaCima"
	seta_cima.position = Vector2(tela.x - 34, TOPO_LISTA - 2)
	_apo.add_child(seta_cima)
	var seta_baixo := _rotulo("▼", 6, COR_APAGADA)
	seta_baixo.name = "SetaBaixo"
	seta_baixo.position = Vector2(tela.x - 34, TOPO_LISTA + (LINHAS_VISIVEIS - 1) * ALTURA_LINHA + 4)
	_apo.add_child(seta_baixo)

	var sep := ColorRect.new()
	sep.color = Color(0.95, 0.95, 1.0, 0.35)
	sep.position = Vector2(24, 132)
	sep.size = Vector2(tela.x - 48, 1)
	_apo.add_child(sep)
	_nome = _rotulo("", 9, COR_TITULO)
	_nome.position = Vector2(26, 137)
	_apo.add_child(_nome)
	_desc = _rotulo("", 8, COR_TEXTO)
	_desc.position = Vector2(26, 151)
	_desc.size = Vector2(tela.x - 52, 36)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apo.add_child(_desc)


func _montar_cad(tela: Vector2) -> void:
	_cad = Control.new()
	_cad.size = tela
	_raiz.add_child(_cad)
	_cad_topo = 0

	# coluna da esquerda: as palavras (rolam como no Àpò)
	_cad_cursor = ColorRect.new()
	_cad_cursor.color = Color(1.0, 0.85, 0.3, 0.22)
	_cad_cursor.size = Vector2(84, ALTURA_LINHA)
	_cad.add_child(_cad_cursor)
	_cad_linhas_ui.clear()
	for i in LINHAS_VISIVEIS:
		var nome := _rotulo("", 7, COR_TEXTO)
		nome.position = Vector2(30, TOPO_LISTA + i * ALTURA_LINHA + 1)
		_cad.add_child(nome)
		_cad_linhas_ui.append(nome)

	# a linha que separa as duas colunas
	var vsep := ColorRect.new()
	vsep.color = Color(0.95, 0.95, 1.0, 0.35)
	vsep.position = Vector2(116, TOPO_LISTA - 2)
	vsep.size = Vector2(1, LINHAS_VISIVEIS * ALTURA_LINHA + 4)
	_cad.add_child(vsep)

	# coluna da direita: a tradução da palavra escolhida
	_cad_palavra = _rotulo("", 8, COR_TITULO)
	_cad_palavra.position = Vector2(124, TOPO_LISTA)
	_cad_palavra.size = Vector2(tela.x - 140, 14)
	_cad.add_child(_cad_palavra)
	_cad_pron = _rotulo("", 6, COR_APAGADA)
	_cad_pron.position = Vector2(124, TOPO_LISTA + 18)
	_cad_pron.size = Vector2(tela.x - 140, 10)
	_cad.add_child(_cad_pron)
	_cad_sig = _rotulo("", 7, COR_TEXTO)
	_cad_sig.position = Vector2(124, TOPO_LISTA + 32)
	_cad_sig.size = Vector2(tela.x - 140, 56)
	_cad_sig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cad.add_child(_cad_sig)

	var sep := ColorRect.new()
	sep.color = Color(0.95, 0.95, 1.0, 0.35)
	sep.position = Vector2(24, 132)
	sep.size = Vector2(tela.x - 48, 1)
	_cad.add_child(sep)
	_cad_onde = _rotulo("", 7, COR_TEXTO)
	_cad_onde.position = Vector2(26, 137)
	_cad_onde.size = Vector2(tela.x - 130, 10)
	_cad.add_child(_cad_onde)
	_cad_contador = _rotulo("", 7, COR_APAGADA)
	_cad_contador.position = Vector2(tela.x - 104, 137)
	_cad_contador.size = Vector2(78, 10)
	_cad_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cad.add_child(_cad_contador)
	_cad_aviso = _rotulo("", 7, COR_AVISO)
	_cad_aviso.position = Vector2(26, 151)
	_cad_aviso.size = Vector2(tela.x - 52, 30)
	_cad_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cad.add_child(_cad_aviso)


func _trocar_pagina(passo: int) -> void:
	_pagina = (_pagina + passo + 3) % 3
	Jogo.tocar_som("texto", -10.0)
	_mostrar_pagina()


func _mostrar_pagina() -> void:
	_apo.visible = _pagina == 0
	_cad.visible = _pagina == 1
	_livro.visible = _pagina == 2
	_aba_apo.add_theme_color_override("font_color", COR_TITULO if _pagina == 0 else COR_APAGADA)
	_aba_cad.add_theme_color_override("font_color", COR_TITULO if _pagina == 1 else COR_APAGADA)
	_aba_diario.add_theme_color_override("font_color", COR_TITULO if _pagina == 2 else COR_APAGADA)
	if _pagina == 0:
		_dica_tela.text = Jogo.texto("{interagir}: escolher  ·  ←→ caderneta  ·  %s: fechar" % Jogo.botao("bornal"))
		_mostrar_cursor()
	elif _pagina == 1:
		_dica_tela.text = "cima/baixo: palavra  ·  ←→ trocar  ·  %s: fechar" % Jogo.botao("bornal")
		_mostrar_cad()
	else:
		_dica_tela.text = "cima/baixo: rolar  ·  ←→ trocar  ·  %s: fechar" % Jogo.botao("bornal")
		_mostrar_livro()


## A página do diário: uma fala por página, como num livro.
## Em cima, o lugar (capítulo) e uma frase de narração (se o diálogo tiver); depois quem fala, em cor
## própria, e a fala em itálico.
const COR_FALANTE := [
	["Benedita", Color(1.0, 0.8, 0.3)],
	["Adé", Color(0.6, 0.85, 1.0)],
	["Tia", Color(1.0, 0.6, 0.75)],
	["Èṣù", Color(1.0, 0.5, 0.4)],
	["Exu", Color(1.0, 0.5, 0.4)],
	["Iemanjá", Color(0.5, 0.85, 1.0)],
	["Yemọja", Color(0.5, 0.85, 1.0)],
	["Nanã", Color(0.8, 0.65, 1.0)],
	["Nàná", Color(0.8, 0.65, 1.0)],
	["Bené", Color(0.95, 0.7, 0.45)],
	["Ọ̀ṣọ́ọ̀sì", Color(0.55, 0.92, 0.55)],
	["Tartaruga", Color(0.75, 0.85, 0.45)],
]
var _fonte_italica: Font


func _montar_livro(tela: Vector2) -> void:
	_livro = Control.new()
	_livro.size = tela
	_raiz.add_child(_livro)
	# o diário é uma lista que rola: Adé lê descendo, sem virar página
	_livro_scroll = ScrollContainer.new()
	_livro_scroll.position = Vector2(24, TOPO_LISTA - 2)
	_livro_scroll.size = Vector2(tela.x - 48, 92)
	_livro_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_livro.add_child(_livro_scroll)
	_livro_texto = RichTextLabel.new()
	_livro_texto.bbcode_enabled = true
	_livro_texto.fit_content = true
	_livro_texto.scroll_active = false
	_livro_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_livro_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_livro_texto.add_theme_font_size_override("normal_font_size", 6)
	_livro_texto.add_theme_color_override("default_color", COR_TEXTO)
	_livro_scroll.add_child(_livro_texto)
	var sep := ColorRect.new()
	sep.color = Color(0.95, 0.95, 1.0, 0.35)
	sep.position = Vector2(24, 132)
	sep.size = Vector2(tela.x - 48, 1)
	_livro.add_child(sep)
	_livro_contador = _rotulo("", 7, COR_APAGADA)
	_livro_contador.position = Vector2(tela.x - 104, 137)
	_livro_contador.size = Vector2(78, 10)
	_livro_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_livro.add_child(_livro_contador)


## Fonte "inclinada" (itálico sintético): a Noto Sans não tem itálico no projeto.
func _fonte_italica_() -> Font:
	if _fonte_italica == null:
		var fv := FontVariation.new()
		fv.base_font = preload("res://fontes/NotoSans-Regular.ttf")
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.25, 1), Vector2.ZERO)
		_fonte_italica = fv
	return _fonte_italica


## Cores de quem não está na lista: sempre uma cor viva, sempre a mesma para o mesmo nome.
const CORES_EXTRAS := [
	Color(0.95, 0.6, 0.4), Color(0.6, 0.95, 0.8), Color(0.95, 0.85, 0.5), Color(0.7, 0.7, 1.0),
	Color(0.9, 0.55, 0.85), Color(0.55, 0.9, 0.55), Color(1.0, 0.75, 0.6), Color(0.6, 0.85, 0.95),
]


func _cor_do_falante(quem: String) -> Color:
	for par in COR_FALANTE:
		if quem.contains(par[0]):
			return par[1]
	if quem == "":
		return COR_TEXTO
	var soma := 0
	for c in quem:
		soma += c.unicode_at(0)
	return CORES_EXTRAS[soma % CORES_EXTRAS.size()]


func _mostrar_livro() -> void:
	var n := historia.size()
	if n == 0:
		_livro_texto.text = "[color=#c0c6e6]Adé ainda não ouviu nada. As conversas que ele tiver aparecem aqui, como num diário.[/color]"
		_livro_contador.text = "0 falas"
		return
	var partes := []
	var capitulo_atual := ""
	for f in historia:
		if f["capitulo"] != capitulo_atual:
			capitulo_atual = f["capitulo"]
			partes.append("[color=#ffd873]%s[/color]" % capitulo_atual)
		if str(f.get("narracao", "")) != "":
			partes.append("[color=#8e96c0]%s[/color]" % f["narracao"])
		partes.append("[color=#%s]%s[/color]: %s" % [_cor_do_falante(f["quem"]).to_html(false), f["quem"], f["pt"]])
		if f["yo"] != "":
			partes.append("[color=#ffb35c]%s[/color]" % f["yo"])
		partes.append("")
	_livro_texto.text = "\n".join(partes)
	_livro_contador.text = "%d falas" % n


func _mostrar_cad() -> void:
	var n := _caderneta().size()
	if n == 0:
		_cad_cursor.visible = false
		for l in _cad_linhas_ui:
			l.text = ""
		_cad_palavra.text = "Nenhuma palavra ainda."
		_cad_pron.text = ""
		_cad_sig.text = "Adé vai aprendendo as palavras em iorubá conversando com as pessoas."
		_cad_onde.text = ""
		_cad_contador.text = "0 de 0"
		_cad_aviso.text = ""
		return
	_cad_cursor.visible = true
	_cad_i = clampi(_cad_i, 0, n - 1)
	# rola a coluna das palavras para a escolhida aparecer
	if _cad_i < _cad_topo:
		_cad_topo = _cad_i
	elif _cad_i >= _cad_topo + LINHAS_VISIVEIS:
		_cad_topo = _cad_i - LINHAS_VISIVEIS + 1
	for i in LINHAS_VISIVEIS:
		var k := _cad_topo + i
		var l: Label = _cad_linhas_ui[i]
		if k < n:
			l.text = _caderneta()[k]["palavra"]
			l.add_theme_color_override("font_color", COR_TITULO if k == _cad_i else COR_TEXTO)
		else:
			l.text = ""
	_cad_cursor.position = Vector2(28, TOPO_LISTA + (_cad_i - _cad_topo) * ALTURA_LINHA)
	# a coluna da direita: a tradução da palavra escolhida
	var e: Dictionary = _caderneta()[_cad_i]
	_cad_palavra.text = e["palavra"]
	_cad_pron.text = "pronúncia: " + e["pron"]
	_cad_sig.text = e["sig"]
	_cad_onde.text = "Onde aprendeu: " + e["onde"]
	_cad_contador.text = "%d de %d" % [_cad_i + 1, n]
	_cad_aviso.text = "Ainda não confirmada: conferir no terreiro." if e["duvida"] else ""


func _mostrar_cursor() -> void:
	if _lista.is_empty():
		_cursor.visible = false
		for l in _linhas_ui:
			l[0].texture = null
			l[1].text = ""
		_linhas_ui[0][1].text = "O Àpò está vazio."
		_linhas_ui[0][1].add_theme_color_override("font_color", COR_APAGADA)
		_nome.text = ""
		_desc.text = ""
		_apo.get_node("SetaCima").visible = false
		_apo.get_node("SetaBaixo").visible = false
		return
	_linha = clampi(_linha, 0, _lista.size() - 1)
	# rola a lista para o item escolhido aparecer
	if _linha < _topo:
		_topo = _linha
	elif _linha >= _topo + LINHAS_VISIVEIS:
		_topo = _linha - LINHAS_VISIVEIS + 1
	for i in LINHAS_VISIVEIS:
		var k := _topo + i
		var ic: TextureRect = _linhas_ui[i][0]
		var nome: Label = _linhas_ui[i][1]
		if k < _lista.size():
			var id: String = _lista[k]
			ic.texture = icone(id)
			nome.text = ITENS[id]["nome"] + ("   · na mão" if id == equipado else "")
			nome.add_theme_color_override("font_color", COR_TITULO if k == _linha else COR_TEXTO)
		else:
			ic.texture = null
			nome.text = ""
	_cursor.visible = true
	_cursor.position = Vector2(28, TOPO_LISTA + (_linha - _topo) * ALTURA_LINHA)
	_apo.get_node("SetaCima").visible = _topo > 0
	_apo.get_node("SetaBaixo").visible = _topo + LINHAS_VISIVEIS < _lista.size()
	var id_esc: String = _lista[_linha]
	_nome.text = ITENS[id_esc]["nome"] + ("  (na mão)" if id_esc == equipado else "")
	_desc.text = Jogo.texto(ITENS[id_esc]["desc"])


func _input(ev: InputEvent) -> void:
	if not aberto or not _raiz or not _raiz.visible or _escolha != null or Jogo.menu.aberto:
		return
	if ev.is_action_pressed("bornal") or ev.is_action_pressed("cancelar") or ev.is_action_pressed("sair"):
		_escolha = "fechar"
		Jogo.tocar_som("texto", -10.0)
	elif ev.is_action_pressed("esquerda") or ev.is_action_pressed("direita"):
		_trocar_pagina(-1 if ev.is_action_pressed("esquerda") else 1)
	elif ev.is_action_pressed("cima") or ev.is_action_pressed("baixo"):
		var passo := -1 if ev.is_action_pressed("cima") else 1
		if _pagina == 0:
			if not _lista.is_empty():
				_linha = (_linha + passo + _lista.size()) % _lista.size()
				Jogo.tocar_som("texto", -12.0)
				_mostrar_cursor()
		elif _pagina == 1:
			if not _caderneta().is_empty():
				_cad_i = (_cad_i + passo + _caderneta().size()) % _caderneta().size()
				Jogo.tocar_som("texto", -12.0)
				_mostrar_cad()
		else:
			_livro_scroll.scroll_vertical += passo * 14
	elif ev.is_action_pressed("interagir"):
		if _pagina == 0 and not _lista.is_empty():
			Jogo.tocar_som("buzio", -10.0)
			_escolha = _lista[_linha]
	else:
		return
	get_viewport().set_input_as_handled()


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 2)
	return l
