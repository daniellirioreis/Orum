# Ọ̀run — Histórias dos Orixás (protótipo) · versão 16 bits

> **Ramo `estilo-snes`**: visual inspirado nos RPGs de ação do Super Nintendo — tela de 256×224,
> casa vista de fora com telhado, salas por dentro, arte de 16 bits com bordas arredondadas
> entre grama, terra, calçada e água, personagens 16×32, arbustos,
> cercas de estacas de bambu, barrancos com escada, riacho, barra de cima com medidor das oferendas,
> caixa de item, contadores e o AXÉ em búzios, e caixa de diálogo à moda antiga.
> A versão anterior continua no ramo `main`.

Jogo de plataforma 2D em pixel art com os itans dos orixás.
Esta versão tem o **Prólogo** completo, em duas partes:

1. **Ilé — O Terreiro da Vó** (visão de cima, estilo 16 bits). Adé sonha com os orixás e acorda no
   terreiro de Umbanda da avó, que é a mãe de santo da casa. Pede a bênção, conta o sonho e descobre
   que, para encontrar os orixás, primeiro precisa chamar Exu, o mensageiro. Cada oferenda está num
   canto da casa (Efum, Epó, Oti e Luma). Com tudo em mãos, faz o ritual na tronqueira, Exu aparece
   e abre a porteira.
2. **Oríta Mẹ́ta — A Encruzilhada** (plataforma lateral). Exu conta o itan do gorro de duas cores e abre o caminho de Ogum.

## Como abrir

1. Baixe o **Godot 4.3 ou mais novo** (gratuito): https://godotengine.org/download
   Use a versão normal (não precisa da versão .NET/C#).
2. Descompacte esta pasta.
3. Abra o Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta.
4. Aperte **F5** (ou o botão ▶ no canto superior direito) para jogar.

## Controles

| Ação | Teclado | Controle (posição do botão) |
|---|---|---|
| Andar | W A S D ou setas | Direcional ou analógico |
| Falar / confirmar / avançar diálogo | E, Enter ou X | A (Xbox) · ✕ (PlayStation) · botão de baixo |
| Atirar a flecha (mata de Oxóssi) | Espaço, Z ou J | B · ◯ · botão da direita |
| Andar devagar, sem barulho | segurar Shift ou C | segurar L ou R |
| Ver a ilha inteira (mapa) | M, Tab ou Q | Y · △ · botão de cima (ou Select/Back) |
| Pausa | Esc | Start |
| Voltar nos menus | Esc ou Backspace | B · ◯ |
| Pular (fases de plataforma antigas) | Espaço, W, ↑ ou Z | A |
| Tela cheia | F11 | (em Configurações) |

Os controles podem ser trocados em **Configurações → Controles** (no título ou na pausa): escolha a ação e aperte
a nova tecla ou o novo botão do controle. Se outra ação já usava aquela tecla, as duas trocam. "Restaurar o padrão"
volta tudo como era. A escolha fica guardada em `user://controles.cfg`.

Os textos do jogo mostram os botões de quem está jogando: se o último toque foi no controle, aparece "Aperte A";
no teclado, "Aperte E". Nos diálogos e avisos, escreva `{interagir}`, `{atirar}`, `{devagar}`, `{ver_mapa}`, `{pausa}`,
`{andar}`, `{setas}` ou `{confirmar}`, e o jogo troca pelo botão certo (a lista fica em `NOMES_BOTOES`, no `scripts/jogo.gd`).

## O que tem nesta versão

**No terreiro (visão de cima)**
- Abertura com o sonho: nove silhuetas, os orixás que têm mundo no mapa, em sombra com o formato do desenho de cada um
  e a aura e o contorno de luz na cor dele (`arte/sonho_orixas.png`, feito pelo `gerar_sonho_sombras.py`).
- A casa com barracão (congá, atabaques, esteira), cozinha, despensa e o quintal com horta, árvores,
  a tronqueira e a porteira.
- As pessoas da casa: a Vó (mãe de santo), a Tia Dora (cozinha), o Ogã Bené (atabaques) e a Lia (cambone).
- A Vó, o Ogã Bené, a Lia e a Tia Dora têm rotinas: andam entre alguns pontos, param e fazem alguma coisa (a Vó saúda
  o congá e varre, o Ogã afina o atabaque com o malho e depois toca, a Lia varre, a Tia Dora mexe as panelas no fogão e no pilão; na volta de Adé,
  ela colhe na horta, entra pela porta da cozinha, cozinha no fogão e no pilão e volta para a horta). Quando o ponto
  seguinte fica em outro cômodo, a pessoa anda até a porta, some por ela e aparece do outro lado. Antes do ritual cada um fica perto do seu lugar no barracão; quando Adé
  volta de uma viagem, o Ogã fica perto da roda de capoeira, a Lia varre o quintal perto das crianças e a Vó, depois de
  assentar os troféus, cuida do quarto de santo (sem troféu novo, fica pela tronqueira e pela gameleira). Quando Adé
  chega perto, a pessoa para e olha para ele. As rotas ficam em `ROTAS`, no fim do `scripts/terreiro.gd`
  ([lugar, coluna, linha, segundos parado, "saudar" / "varrer" / "tocar"]). Quadros: parado (0-1), saudação (2),
  passos (3-4) e fazendo algo (5-6); depois vêm as poses junto dos objetos (feitas pelo `gerar_personagens.py`):
  a Vó de costas saudando o congá e os assentamentos (7-8), a Lia de costas acendendo a vela do congá (7-8), a Tia
  de costas mexendo a panela no fogão (7-8), socando o pilão (9-10) e agachada colhendo na horta (11-12), e o Ogã
  afinando o atabaque com o próprio tambor (7-8), tocando atrás dos atabaques do barracão (9-10) e afinando ao lado
  deles (11-12). Os objetos respondem: o vapor sobe da panela, o pilão balança, o couro do atabaque vibra, as folhas
  da horta mexem, a vela do congá acende e a vassoura levanta poeira (`_efeito_no_objeto`, no `terreiro.gd`).
- Onde está cada oferenda:
  - **Efum**: com a Tia Dora, na cozinha. Antes, ela pede lenha do quintal.
  - **Epó**: escondido na despensa. É preciso procurar nos caixotes e sacos.
  - **Oti**: com o Ogã Bené. Mini-jogo: ele toca uma sequência nos atabaques e Adé repete (← ↑ →).
  - **Luma**: com a Lia, no congá. Ela só entrega depois das outras três.
- O ritual: as oferendas diante da tronqueira, a Vó saúda ("Meu pai, abençoe!") e Exu chega.
- Noite de verdade: lampiões, velas do congá e fogão iluminam; vaga-lumes no quintal, fumaça na chaminé,
  galinhas andando e um gato dormindo. A cor da noite fica em `COR_NOITE`, no topo de `scripts/terreiro.gd`.

**Na encruzilhada (Oríta Mẹ́ta, visão de cima)** — `cenas/encruzilhada.tscn`, `scripts/encruzilhada.gd`
- Três lugares à noite, cada um com um enigma até chegar a Exu:
  - **Trilha**: empurrar a pedra até o ponto riscado no chão para abrir a cancela de bambu.
  - **Mata**: acender as três lamparinas na ordem certa (leste, oeste e a do meio); a placa dá a dica.
  - **Oríta** (onde os caminhos se encontram): afundar a pedra no riacho para atravessar e olhar a estátua
    dos dois lados. O gorro é vermelho de um lado e preto do outro, como no itã de Exu.
- É noite fechada: quem ilumina são as tochas pelo caminho, as lamparinas e as velas. Adé tem só uma luzinha fraca.
- **Kiumbas**: sombras de olhos vermelhos que vagam pela encruzilhada e perseguem Adé no escuro. Não entram
  na luz das tochas (nem das lamparinas acesas): perto delas, Adé fica protegido. Quando Exu chega, os kiumbas
  e os redemoinhos se desfazem.
- Redemoinhos de poeira andam pelos caminhos. Cada um que pega Adé leva um búzio de **axé** (os 3 búzios
  lá em cima, à direita; `AXE_MAX` no `scripts/terreiro.gd`). Quando o axé acaba, **Exu surge** na fumaça ao lado de
  Adé e oferece trocar os búzios coletados pelo caminho: **5 búzios valem 1 búzio de axé** (`BUZIOS_POR_AXE` no
  `scripts/encruzilhada.gd`); dá para trocar 5, 10 ou 15 de uma vez, conforme o que Adé juntou, e Adé continua dali.
  Sem búzios bastantes, ou se Adé não quiser trocar, é **fim de jogo**: Adé cai, a tela escurece
  e o menu "O axé acabou..." oferece **Voltar ao último caminho guardado** (o último jogo salvo na quartinha de Exu;
  apagado se ainda não há nenhum) ou **Voltar ao título**. Vale para todas as fases com axé.
- Se a pedra ficar presa, ler a placa de novo faz as pedras voltarem para o lugar.
- Exu aparece, abre os caminhos e deixa a escolha com Adé. As estradas do norte, do oeste e do leste
  saem da encruzilhada; qualquer uma leva ao **mapa dos caminhos**.

**O mapa dos caminhos (estilo mapa-múndi dos 16 bits)** — `cenas/mapa_mundo.tscn`, `scripts/mapa_mundo.gd`
- Uma ilha com a encruzilhada no meio e o campo de cada orixá em volta: Oxum (em cima à esquerda: a montanha verde,
  a cachoeira em degraus, a lagoa dourada com o abebé na ilhota, peixinhos, borboletas, ipês com colmeia e o rio de
  ouro, largo e cheio de curvas, que atravessa a mata de Oxóssi, passa entre a encruzilhada e Omolu, corre por
  baixo do mundo de Ogum e deságua no mar de Iemanjá; as trilhas cruzam o rio por pontes), Oxalá (o morro branco e o templo), Iansã (tempestade e raios),
  Oxóssi (a mata), Ogum (a ferraria, o mariwô e o minério), Xangô (a pedreira), Nanã (a lama e o mangue),
  Omolu (embaixo, no meio: terra, palha e pipoca) e Iemanjá (o mar).
- O mapa tem o dobro do tamanho da tela (512x448) e a câmera segue o Adé, como no Super Mario World. Xangô e Oxalá
  ficam no alto, em dois andares de paredão; onde a trilha sobe um paredão aparecem degraus e Adé anda mais devagar.
- Na primeira vez, a câmera se afasta para mostrar a ilha inteira e os caminhos se abrem em ondas a partir da encruzilhada. Adé anda de ponto em ponto com as
  setas (as setinhas piscando mostram para onde dá para ir); a faixa de cima mostra o nome, a saudação e o campo.
- Apertando E num campo, Adé entra na fase daquele orixá (por enquanto, só a de Oxóssi; os outros mostram "Em breve!").
  As fases ficam em `CENAS_DOS_CAMPOS`, no topo de `scripts/mapa_mundo.gd`. Ao voltar, Adé aparece no campo de onde saiu,
  e o troféu ganho aparece com uma ★ na faixa de cima.
- A arte da ilha vem do `gerar_mapa_mundo.py` (`arte/mundo_0.png` a `mundo_3.png`: o mar, o rio e a cachoeira
  mexem entre os quatro quadros; as nuvens são `mundo_nuvem*.png` e `mundo_tempestade.png`, que andam devagar e piscam com raios).
  Os pontos e as trilhas (que fazem curvas e passam por uma ponte no rio de Oxum) ficam em `NOS` e `CAMINHOS`,
  no topo do `gerar_mapa_mundo.py` (no tamanho da tela; o script multiplica por `E = 2`); ele grava `fases/mapa_mundo.json`, que o jogo lê. Para escolher o caminho,
  vale a seta mais parecida com a direção para onde a trilha sai do ponto.
- Os mapas ficam em `fases/enc_trilha.txt`, `fases/enc_mata.txt` e `fases/enc_orita.txt` (+ `_objetos`).
  Letras novas dos objetos: `@` pedra que se empurra, `&` ponto riscado, `!` cancela, `$` lamparina,
  `<` redemoinho que anda de lado, `^` redemoinho que anda para cima e para baixo, `?` placa,
  `S` estátua do gorro (no meio do cruzamento; Exu aparece no lugar dela), `x` lugar reserva de Exu,
  `%` velas vermelha e preta nas quatro esquinas, `y` tocha, `k` kiumba, `>` saída para o mapa dos caminhos. Os textos ficam em `dialogos/encruzilhada.json`.
- A versão antiga da encruzilhada (plataforma) continua em `cenas/jogo.tscn`, mas a porteira agora leva para a nova.

**A Mata de Oxóssi (Igbó Ọ̀ṣọ́ọ̀sì, visão de cima)** — `cenas/mata_oxossi.tscn`, `scripts/mata_oxossi.gd`
- Baseada no itan do caçador de uma flecha só. Quatro lugares, cada um ensina uma coisa do caçador:
  - **O labirinto dos rastros** (observar): três saídas (oeste, norte, leste). O rastro do veado (duas unhas)
    leva à saída certa; o rastro de pássaro engana. São três acertos seguidos; errou, a mata devolve Adé ao começo.
  - **O campo dos veados** (paciência): perto dos veados, quem corre espanta a caça. Segurando Shift/C, Adé anda
    devagar e passa. Se um veado foge, Adé volta para a entrada do campo. No milharal está a **espiga de milho**.
  - **O presente do caçador** (mirar): num toco, Adé acha o **ofá** com uma flecha só. Atirar corta a corda do tronco
    seco, que cai e vira ponte sobre o riacho; acertar a colmeia solta as abelhas, que espantam o javali que guarda o cantinho do coqueiro,
    e cai o **favo de mel**. As cobras fogem quando a flecha passa perto. O **coco** fica no cantinho do coqueiro, atrás do javali (o caminho principal fica sempre livre, na ida e na volta).
    Depois de atirar, é preciso ir buscar a flecha; se ela cai na água, volta sozinha.
  - **A clareira** (o pássaro das Iyami): a sombra no chão mostra onde o pássaro vai mergulhar, e as flechas desviam dele.
    Com milho, coco e mel, Adé faz a oferenda no assentamento de Exu; o pássaro baixa a guarda, Oxóssi chega e,
    com uma flecha só, espanta o pássaro (não mata). O sol se põe, e Adé e Oxóssi conversam sobre o sonho e sobre o que
    Oxóssi guarda: o conhecimento da mata, a paciência e a fartura repartida.
- Os bichos da mata: passarinhos (sabiá, azulão e canário) bicando o chão, que voam quando Adé chega perto e voltam
  depois; bandos de passarinhos atravessando o céu; o pavão, que passeia e abre a cauda quando Adé se aproxima;
  e a onça-pintada, dormindo perto do caminho depois da ponte: se Adé passa correndo perto, ela acorda, ruge e dá o
  bote (leva um búzio de axé); andando devagar, ela continua dormindo. Flecha na onça só acorda a onça.
  Arte em `arte/ox_passarinhos.png`, `ox_pavao.png` e `ox_onca.png` (feita pelo `gerar_bichos_mata.py`);
  nos mapas, `b` passarinhos, `G` pavão e `Q` onça.
- No fim, Oxóssi dá o ofá para Adé: é o **troféu** (fica no último quadradinho do inventário, com moldura dourada,
  e em `Jogo.trofeus`), para levar ao terreiro da Vó. A mata abre a saída do norte, de volta ao mapa.
- Voltando a uma mata já vencida, Adé escolhe logo na entrada entre **Fazer a fase de novo** (do começo, com todos os desafios) e **Voltar ao mapa**. No fim da fase repetida, Oxóssi reconhece Adé, os dois conversam, Adé agradece e eles se abraçam (`arte/ox_abraco.png`, feita pelo `gerar_abraco.py`; falas `oxossi_reencontro` e `oxossi_despedida`); e o menu
  de pausa ganha **Voltar ao mapa** (a cena diz se pode com `pode_voltar_ao_mapa()` e sai com `voltar_ao_mapa()`).
- Mapas: `fases/ox_rastro.txt`, `ox_campo.txt`, `ox_ofa.txt`, `ox_clareira.txt` (+ `_objetos`), gerados pelo `gerar_mapas_oxossi.py`.
  Letras: `W N E` saídas do labirinto, `p` chegada, `v` veado pastando, `V` veado que passeia, `m`/`u` pé de milho
  (sem/com espiga), `O` toco com o ofá, `T` tronco amarrado, `s` cobra, `j` javali, `H` árvore com colmeia, `k` coco,
  `B` pássaro, `X` assentamento de Exu, `x` de onde Oxóssi chega, `>` saída. Textos em `dialogos/mata_oxossi.json`.
- Arte nova: `arte/ox_*.png` (feita pelo `gerar_arte_mata.py`) e o Oxóssi animado em `arte/oxossi_anim.png`.
- **A mata fechada vista de cima**: as copas das árvores altas (`C` no mapa, `arte/ox_copas.png`, 3 formatos) passam
  por cima de tudo, até de Adé, e tapam pedaços da tela; a sombra delas fica no chão (`ox_copa_sombra.png`). Quando
  Adé anda embaixo de uma copa, ela fica meio transparente. Entre as copas, manchas de sol balançam no chão (`Z`,
  `ox_sol.png`) e folhinhas caem girando (`ox_folha.png`). Na clareira não tem copa: o céu abre.
- **A flecha não se perde**: se ela cai num lugar onde Adé não chega (do outro lado do riacho, atrás da moita), um
  passarinho da mata desce, pega a flecha no bico e larga do lado de Adé.
- **O riacho corre**: a água do riacho do ofá (e do riacho da encruzilhada) corre para a direita (shader `SHADER_RIO`) e folhinhas passam boiando.
- Para testar direto, abra `cenas/mata_oxossi.tscn` no Godot e aperte F6.

**A Terra de Nanã (Ilẹ̀ Ẹrẹ̀ Nàná, "a terra da lama de Nanã", visão de cima)** — `cenas/mata_nana.tscn`, `scripts/mata_nana.gd`
- Chove a fase inteira (mais forte na lagoa, com relâmpagos). O ritmo é de quem é mais velho: devagar, olhando.
  Na lama, Adé anda mais devagar (`fator_chao` no `jogador_rpg.gd`). Quatro lugares:
  - **O brejo**: a lama firme e a lama funda são iguaizinhas. Da lama funda sobem bolhas (`arte/nana_bolha.png`, `gerar_bolha.py`),
    sobretudo na beira do caminho firme perto de Adé: crescem devagar, ficam um tempo e só então estouram — elas mostram onde não pisar.
    As **garças** pousam onde dá pé e voam quando Adé chega perto. Pisou na lama funda, a lama puxa Adé (perde um
    búzio de axé) e ele volta para o começo do brejo. Na chegada, uma **velhinha** pede que Adé leve o **pote de barro**
    dela (rachado) até a lagoa: "eu chego lá do meu jeito, devagarinho".
  - **O bambuzal**: o taboal fecha o caminho. A **faca de ferro** do toco não serve: a lama treme, a faca escorrega e
    afunda (na terra de Nanã, ferro não serve para nada). Com a lasca de um bambu rachado, a **lâmina de bambu**, a taboa abre.
    O bambu rachado some do chão quando a lâmina vai para o inventário. No bambuzal pulam **sapos** (`G` no mapa):
    coaxam, a sombra aparece onde vão cair e eles pulam — perto de Adé, pulam em cima dele (leva um búzio de axé);
    é só sair de baixo da sombra. Cada sapo fica perto do seu canto.
  - **O mangue**: a **maré** sobe e desce. Na baixa, dá para passar pelas raízes (e os **caranguejos** saem da lama
    e beliscam); na alta, a água cobre as raízes e leva Adé de volta para o último chão firme. Numa ilhota, as
    **flores lilás**. Do outro lado, a velhinha já está esperando...
  - **A lagoa**: o barro bom fica numa **ilhota no meio da lagoa**. Para chegar lá, Adé atravessa uma fileira de
    **vitórias-régias gigantes** (`W`/`E` no mapa, água `y` sem parede) que andam de um lado para o outro, cada fileira
    num ritmo, e levam Adé junto; as mais escuras (`E`) afundam se ele ficar parado em cima uns 2 segundos (depois
    voltam a boiar). Pisou fora da folha, tchibum: perde um búzio de axé e volta ao último chão firme.
    As folhas grandes têm o mesmo desenho das vitórias-régias pequenas da lagoa (`arte/nana_vitoria_grande.png`).
    Enquanto há algo para fazer na pedra do pote, um balão fica boiando em cima dela.
    O barro é uma **poça de barro mole** na ilhota (`arte/nana_poca_barro.png`, mesma cor da lama), com bolhinhas e um
    balão boiando enquanto o pote está rachado; Adé se abaixa, pega um punhado e a poça fica com a marca das mãos dele.
    Na pedra, a chuva vazaria pela rachadura do pote; Adé conserta o pote com o **barro** da ilhota,
    deixa o pote na pedra até a chuva encher e faz a oferenda (pote com água da chuva e flores lilás) no **lugar de
    Nanã**. A chuva engrossa, a velhinha chega devagar e se revela: era Nanã. Ela fala da lama de onde se moldou o
    primeiro ser humano e para onde todos voltam, da memória e dos mais velhos (os retratos na parede da Vó), e dá
    o **ibiri** a Adé: o troféu. Nanã volta para a lagoa, a chuva acalma e a saída do norte abre.
- Fase repetida: igual à de Oxóssi (escolha na entrada, "Voltar ao mapa" na pausa) e, no fim, o reencontro com Nanã
  e o abraço (`arte/nana_abraco.png`; falas `nana_reencontro` e `nana_despedida`).
- No terreiro, a Vó assenta o ibiri no assentamento lilás de Nanã (falas `conta_nana` e `assenta_nana`).
- Mapas: `fases/nana_brejo.txt`, `nana_bambuzal.txt`, `nana_mangue.txt`, `nana_lagoa.txt` (+ `_objetos`), gerados
  pelo `gerar_mapas_nana.py`. Chão: `m` chão de lama (quase tudo; prende um pouco), `,` só umas ilhas de grama,
  `l` lama firme do brejo, `L` lama funda, `v` água escura, `z` raízes do mangue (maré). Há árvores plantadas dentro da lama.
  Objetos: `V` velhinha, `g` garça, `s` sapo, `K` bambu, `j` bambu rachado, `F` toco com a faca, `T` taboa,
  `k` caranguejo, `X` árvore do mangue, `u` flores lilás, `b` barro, `O` pedra do pote, `N` lugar de Nanã,
  `x` de onde a velhinha chega, `w` vitória-régia, `>` saída. Textos em `dialogos/mata_nana.json`.
- A vegetação é do brejo, do mangue e da lagoa: nas letras das árvores, `R` vira a árvore velha com barba-de-velho
  pendurada (como os cabelos brancos de Nanã), `M` a árvore do mangue (no mangue) ou a árvore velha, `q J Y` o
  buriti; e há `n` aninga, `f`/`i` juncos (com ou sem florzinhas lilás) e `h` aguapé boiando. As bordas usam a
  moita do brejo (`tex_moita` no `scripts/terreiro.gd`). Arte em `arte/nana_buriti.png`, `nana_arvore_velha.png`,
  `nana_aninga.png`, `nana_juncos.png`, `nana_aguape.png` e `nana_moita.png` (`gerar_arte_nana.py`).
- A água escura do brejo, do mangue e da lagoa mexe: faixas de luz passam devagar pela superfície (um shader na
  camada da água, `SHADER_AGUA` no `mata_nana.gd`) e cada pingo de chuva abre um anel na água — na lagoa, com a
  chuva forte da oferenda, são muitos mais.
- O terreno ganhou linhas novas em `arte/terreno_snes.png` (lama, água escura, bolhas, raízes e vitórias-régias,
  feitas pelo `gerar_terreno_nana.py`); cada fase escolhe os seus terrenos em `terrenos` e `agua_chars`
  (`scripts/terreiro.gd`). Arte nova: `arte/nana_*.png` (`gerar_arte_nana.py` e `gerar_nana_pessoas.py`).
- Para testar direto, abra `cenas/mata_nana.tscn` no Godot e aperte F6.
- **Som da chuva**: sempre que chove (no terreiro ou na terra de Nanã), toca o barulho da chuva caindo em laço
  (`sons/chuva.wav`), mais alto lá fora e abafado dentro de casa; na lagoa de Nanã ele engrossa com a chuva.
  Os relâmpagos agora têm trovão (`sons/trovao.wav`). Os dois sons são feitos pelo `gerar_som_chuva.py`.
- **Ọ̀run com cara de terra iorubá**: as trilhas e o largo da encruzilhada são de terra vermelha (laterita; cores
  `TRILHA_*` no `scripts/mapa_mundo.gd` e `LATERITA` no gerador) e, em volta do largo, fica o mercado de Exu
  (Ọlọ́jà, o dono do mercado): barracas com toldo de pano (adire azul-índigo, vermelho e amarelo, verde), cabaças e
  cestos (`mercado()` no `gerar_mapa_mundo.py`).
- **Paisagens do Ọ̀run** (`bioma()` e `paisagens()` no `gerar_mapa_mundo.py`): floresta verde-escura a oeste (Oxum e
  Oxóssi), mata ciliar verde ao longo do rio e da lagoa, savana dourada no meio (acácias, baobás, cupinzeiros e capim)
  e savana seca avermelhada no norte e no leste, com morros de granito. A pedreira de Xangô virou uma serra comprida de pedra vermelha (arenito), em três
  andares, e muitas nuvens passam devagar pelo reino de Oxalá (`_criar_nuvens_de_oxala()` no `scripts/mapa_mundo.gd`).
- **A praia de Iemanjá no Ọ̀run** (`praia_de_iemanja()` no `gerar_mapa_mundo.py`): praia larga com ondas chegando e
  areia molhada, trapiche de madeira com o lugar de Iemanjá na ponta (flores e velas azuis e brancas), barquinhos e
  flores de presente balançando no mar, jangada, peixe pulando, coqueiros, estrelas-do-mar e um farol nas pedras com a
  luz girando. O ponto de Iemanjá fica na areia, no começo do trapiche. Gaivotas (`arte/mundo_gaivota.png`) voam em
  roda sobre o mar (`_criar_gaivotas()` no `scripts/mapa_mundo.gd`).
- **Ọ̀run, o lar dos orixás**: o mapa dos mundos se chama Ọ̀run. Sempre que Adé chega nele, aparece o letreiro
  "Ọ̀run · O lar dos orixás", como na chegada de cada mundo. A fonte padrão do projeto é a Noto Sans
  (`gui/theme/custom_font`), para os acentos do iorubá em cima de maiúsculas (Ọ̀) aparecerem.
- **Nome do cômodo**: ao passar por uma porta do terreiro, uma plaquinha no alto da tela diz onde Adé entrou (Barracão,
  Cozinha, Despensa, Quarto de santo, Quintal). Os nomes ficam em `NOMES_DOS_LUGARES`, no `scripts/terreiro.gd`.
- **Rosto de quem fala**: a caixa de diálogo mostra o retrato (32×32) de quem está falando, numa moldura à esquerda
  (`arte/retratos.png`, feito pelo `gerar_retratos.py`: uma linha por personagem, uma coluna por expressão). Uma fala
  pode pedir a expressão com `"rosto": "feliz"` (ou `"assustado"`, `"rindo"`, `"bravo"`); a gargalhada de Exu já usa o
  rosto rindo. Narração e o Ìtàn ficam sem rosto. A lista de quem tem rosto está em `RETRATOS`, no `scripts/dialogo.gd`.
- **Trilha de cada mundo** (feitas pelo `gerar_musicas.py`, em laço sem emenda): `sons/musica_encruzilhada.wav`
  (Exu: noite, 12/8 com agogô e um baixo com nota "torta"), `musica_oxossi.wav` (galope inspirado no agueré, com
  flauta), `musica_nana.wav` (lenta, inspirada no sató, com coro grave e marimba) e `musica_mapa.wav` (viagem leve).
  O terreiro e a tela de título continuam com `musica.wav`. `Jogo.tocar_musica("nome")` troca de trilha devagar.
- **Efeitos sonoros por ação** (36 sons novos em `sons/`, no estilo SNES, feitos pelo `gerar_sfx.py`):
  - Adé: passos que mudam com o chão (`passo_grama`, `passo_terra`, `passo_lama`, `passo_madeira`; andando devagar não
    faz barulho), `flecha_atira`, `flecha_acerta`, `flecha_mato`, `pegar_item`, `pegar_buzio`, `dano`, `perde_axe`,
    `agua_cai`, `lama_afunda`, `folha_pisa` (vitória-régia).
  - Bichos: `sapo_pulo`, `sapo_coaxa`, `cobra_sibilo` (quando Adé chega perto), `javali_bufo`, `javali_corre`,
    `onca_rosna`, `onca_bote`, `caranguejo`, `colmeia_zumbido`, `colmeia_quebra`, `passaro_grito`, `asas`,
    `veado_foge`, `passarinho_pio`.
  - Encruzilhada: `redemoinho` (o vento do redemoinho mais perto), `kiumba_ve` (o kiumba viu Adé), `kiumba_some`
    (recua na luz ou some quando Exu chega), `tocha_acende`, `pedra_arrasta`; a pedra que cai no riacho faz `agua_cai`.
  - Cenário: `tronco_cai`, `game_over`, `troca_exu`.
  - O passo vem de `som_do_chao(pos)` da cena (o terreiro decide pela letra do mapa; a fase de Nanã põe lama e
    vitória-régia); `som_perto(nome, pos)` toca mais baixo quanto mais longe de Adé.
- **Exu brincalhão**: as falas de Exu zoam Adé de brincadeira, sem perder o ensinamento. Nas maiores zoações ele
  ri: "Há há há!" (gargalhada) ou "Hi hi hi!" (risinho). Quando a fala tem a risada, o `scripts/dialogo.gd` avisa
  (sinal `risada`) e Exu gargalha na tela: olhos fechados, boca aberta, o corpo sacudindo (quadros 2-3 de
  `arte/exu_snes.png`, feitos pelo `gerar_exu_rindo.py`). Ele também chega rindo toda vez que aparece.

**A volta para o terreiro e o quarto de santo**
- No mapa, apertar E na encruzilhada leva Adé de volta para casa. Na primeira vez ele volta a pé pela Oríta Mẹ́ta, fazendo
  o caminho inverso: o cruzamento (Exu está lá e conversa com ele), a mata das lamparinas e a trilha da pedra, até a
  saída do sul (letra `/` em `fases/enc_trilha_objetos.txt`). Os enigmas já estão resolvidos e não há kiumbas: Exu guarda
  o caminho. Daí em diante, o mapa leva direto ao terreiro (o atalho).
- No terreiro, a porteira está aberta e a Vó espera na tronqueira. Adé conta a viagem e entrega os troféus; a Vó leva
  Adé ao **quarto de santo** (porta nova na parede esquerda do barracão, mapa `fases/quarto.txt`), anda até o
  assentamento do orixá, coloca o troféu, acende a vela e saúda o orixá. Depois abençoa Adé.
- O quarto tem um assentamento para cada orixá (Ogum, Oxóssi, Xangô, Iansã, Oxalá no meio, Oxum, Iemanjá, Nanã e Omolu),
  cada um na sua cor (`arte/assentamentos.png`, feita pelo `gerar_assentamentos.py`). Os vazios ficam apagados.
  Exu já tem o dele: a tronqueira. Os troféus entregues ficam em `Jogo.assentados`.
- O quarto tem piso branco (letras `w` e `x` no `fases/quarto.txt`, blocos 41 e 42 do `arte/tiles_snes.png`) e adereços:
  guias penduradas na parede (`j`), trio de quartinhas (`t`), defumador com fumaça (`d`), vasos de flores brancas (`y`),
  velas brancas acesas no chão (`!`), espadas-de-são-jorge, a esteira e um banco. Arte feita pelo `gerar_quarto_santo.py`.
- Na parede, fotos antigas da família de Adé (`u`, `arte/obj_fotos.png`, feita pelo `gerar_fotos_parede.py`): o bisavô,
  a bisavó (moldura oval dourada), a Vó no meio, o avô de chapéu e a Vó moça com a mãe de Adé no colo.
- Depois que as oferendas são arriadas na tronqueira, elas saem do inventário de Adé (as caixinhas somem).
- Saindo pela porteira de novo, Exu leva Adé direto ao mapa, na encruzilhada.
- O tempo no terreiro muda a cada volta de Adé: manhã de sol, fim de tarde, noite (lampiões e velas mais fortes,
  vaga-lumes), nublado (sombras de nuvem passando pelo quintal) ou chuva (gotas, respingos e relâmpagos). Na
  primeira volta com troféu é sempre fim de tarde; depois é sorteado, sem repetir o anterior. Na chuva e à noite
  as crianças e a roda de capoeira não estão, e a Lia, o Ogã e a Tia ficam dentro de casa; a Vó espera Adé dentro do
  barracão, perto do congá (e não na tronqueira). À noite quem ilumina a casa são os lampiões. O tempo fica guardado no
  jogo salvo (`Jogo.tempo_terreiro`); as cores e a força das luzes de cada tempo ficam em `TEMPOS`, no `terreiro.gd`.
- Para um troféu novo: o ícone fica em `ICONE_TROFEU` (no `scripts/terreiro.gd`), e as falas próprias em
  `conta_<id>` (Adé contando a viagem) e `assenta_<id>` (depois de assentar), em `dialogos/terreiro.json`.

**Pausa e jogo salvo (a quartinha de Exu)** — `scripts/menu.gd`, salvar/carregar no `scripts/jogo.gd`
- Esc (ou Start) abre a pausa: Continuar, Configurações (volume da música e dos efeitos, tela cheia), Voltar ao título e
  Sair do jogo (com o aviso "O que Exu não guardou se perde"). Não dá para salvar pelo menu.
- Para salvar, Adé procura a **quartinha de Exu** com a vela vermelha e preta e aperta E: ele bate palmas três vezes,
  a vela acende, Exu surge na fumaça e pergunta se Adé quer que ele guarde o seu caminho. São **três caminhos**
  (espaços de jogo salvo), como nos cartuchos. Ao guardar, o axé enche de novo.
- Onde ficam: no quintal do terreiro (vale depois que Adé volta da primeira viagem), no cruzamento da encruzilhada
  (depois que Exu chega) e na entrada da mata de Oxóssi. Nos arquivos de objetos, a quartinha é a letra `*`.
- O que fica guardado: troféus, assentamentos acesos, búzios, se o mapa já foi aberto e se a volta já foi feita.
  Continuando, Adé aparece no terreiro (ao lado da quartinha), no mapa (na encruzilhada) ou no começo da mata.
- Na tela de título: Novo jogo, Continuar (escolhe um dos três caminhos), Configurações e Sair. As opções aparecem direto por cima do pôr do sol, sem caixa.
- Os arquivos ficam na pasta de dados do Godot (`user://caminho_1.json` a `caminho_3.json`) e as opções em `user://opcoes.cfg`.

**Os orixás (modelos)** — `arte/orixas.png`, feita pelo `gerar_orixas.py`
- Dez quadros de 24x44 (um pouco maiores que o Adé), nesta ordem: Exu, Ogum, Oxóssi, Xangô, Iansã, Oxum,
  Iemanjá, Nanã, Omolu e Oxalá. Quem usa adê tem o rosto coberto pela franja de contas, como na tradição.
- Ainda não aparecem no jogo (menos Oxóssi, animado na fase dele): vão entrar quando cada fase de orixá for feita.

## Estrutura das pastas

```
arte/        sprites e cenário (PNG, edite à vontade)
fontes/      Noto Sans (licença OFL, gratuita), com suporte completo aos acentos do iorubá
sons/        efeitos e música (WAV)
fases/       mapas das fases em texto
dialogos/    falas em JSON (iorubá + português)
cenas/       cenas do Godot (.tscn)
scripts/     código em GDScript, todo comentado em português
             (terreiro.gd, jogador_rpg.gd e toque.gd são do terreiro visto de cima)
```

## Como editar a fase

Abra `fases/prologo.txt` em qualquer editor de texto. Cada caractere é um bloco de 16×16 pixels:

| Caractere | O que é |
|---|---|
| `.` | vazio |
| `#` | terra (vira grama sozinha quando não tem nada em cima) |
| `=` | plataforma de madeira (dá para atravessar por baixo) |
| `B` | mato fechado (some depois de falar com Exu) |
| `,` | capim (só decoração) |
| `o` | búzio |
| `P` | onde Adé começa |
| `E` | Exu |
| `X` | saída da fase |

Medidas úteis para desenhar fases: Adé pula até 3 blocos de altura e atravessa um buraco de até 3 blocos de largura.

## Como editar o terreiro

O terreiro tem quatro lugares, cada um com dois arquivos de texto do mesmo tamanho em `fases/`:
`quintal`, `barracao`, `cozinha` e `despensa` (ex.: `fases/cozinha.txt` e `fases/cozinha_objetos.txt`).

**Portas:** no arquivo de objetos, um número marca uma porta. O mesmo número em dois lugares
liga um ao outro (ex.: `1` no barracão e `1` no quintal). Hoje: `1` barracão ↔ quintal,
`2` barracão ↔ cozinha, `3` cozinha ↔ quintal, `4` cozinha ↔ despensa.

Chão e paredes (`fases/<lugar>.txt`):

| Caractere | O que é |
|---|---|
| `,` `;` `*` | grama (lisa / com tufos / com flores) |
| `=` `r` `o` | calçada de pedras claras, estrada de terra, pedras de pisar |
| `_` `t` | caminho de pedra, terra |
| `a` `e` | canteiro de arbustos, estaca de bambu (cerca) |
| `^` `B` `b` `E` | barranco: beirada, camadas de terra, pé do barranco; escada |
| `~` `\|` | água do riacho, margem |
| `M` | muro do quintal |
| `R` | telhado (as bordas e a cumeeira se ajustam sozinhas) |
| `h` `H` `J` `P` | fachada: parte de cima, parte de baixo, janela, porta |
| `#` `j` | parede de sala (se ajusta sozinha) / parede com janela |
| `.` `:` | piso vermelho (liso / com marcas) |
| `c` `d` | ladrilho da cozinha, tábuas da despensa |
| `+` | vão de porta dentro das salas |

Objetos e pessoas (`fases/<lugar>_objetos.txt`; `.` = nada):

| Caractere | O que é |
|---|---|
| `P` | onde Adé acorda |
| `V` `D` `G` `N` | Vó, Tia Dora, Ogã Bené, Lia (cambone) |
| `C` `A` `E` `r` | congá, atabaques, esteira, tapete |
| `Z` `B` | cerquinha e banco |
| `l` `+` `b` | lampião de parede, luz de teto (invisível), bandeirinhas |
| `p` | vaso com planta |
| `F` `h` `O` `n` `i` | fogão, filtro, pote, panelas (na parede), pilão |
| `m` | mesa (na cozinha) / mato alto (no quintal) |
| `Q` `U` | prateleira e barril da despensa |
| `K` `S` `k` | caixote, saco, caixote onde está o Epó |
| `L` `H` | lenha, horta |
| `R` `Y` `J` `a` | árvore, dendezeiro, bananeira, arbusto |
| `M` `q` `I` | mangueira, coqueiro, gameleira-branca de Iroko (com ojá branco) |
| `W` `f` `o` `u` | varal, flores, pedras, poste com lampião |
| `g` `z` | galinha e gato |
| `w` `s` `x` | crianças na ciranda, crianças no pega-pega, roda de capoeira (com Mestre Tião) |
| `c` | búzio para recolher (no quintal) |
| `T` `X` | tronqueira e porteira |
| `v` `e` | onde a Vó espera e onde Exu aparece |
| `1` a `9` | portas |

## Como trocar a arte (para redesenhar à mão)

A arte foi feita para ser substituída sem mexer no código: é só abrir o PNG no **Pixelorama**
(gratuito) ou no **Aseprite**, redesenhar respeitando o mesmo tamanho e a mesma posição de cada
quadro, e salvar por cima.

| Arquivo | Tamanho | Organização |
|---|---|---|
| `arte/terreno_snes.png` | 256×80 | linha 1: grama (4 variações) · linhas 2–4: terra, calçada e água, **16 peças de borda** cada · linha 5: tufo, flor branca, flor amarela, pedras de pisar, folhas |
| `arte/casa.png` | 256×144 (16×9 blocos) | a casa vista de fora, uma peça só: telhado de quatro águas + fachada. Portas nas colunas 7 e 12, janelas nas colunas 2, 4, 10 e 14 (contando do 0). No mapa, a casa ocupa as letras `R`, `h`, `H`, `J` e `P` |
| `arte/tiles_snes.png` | 16×16 cada | muro, telhado, fachada, pisos e paredes das salas, barranco, escada (ordem em `fases/tiles_snes_indices.txt`) |
| `arte/ade_snes.png` | 9 quadros de 16×32 | de frente (parado, passo, passo), de costas (3), de lado (3, virado para a direita) |
| `arte/vo_snes.png` | 3 quadros de 16×32 | parada, respirando, braços erguidos |
| `arte/tia_snes.png`, `oga_snes.png`, `cambone_snes.png`, `exu_snes.png` | 2 quadros de 16×32 | parado e respirando |
| `arte/arbusto.png` | 2 quadros de 16×18 | normal e com frutinhas |
| `arte/estaca.png`, `arte/obj_arvore.png`, `arte/obj_*.png` | livre | a base do desenho (onde ficam os pés) é a borda de baixo |

**As 16 peças de borda** (terra, calçada, água): cada peça fica no encontro de 4 blocos do mapa.
O número da peça (coluna) diz quais desses 4 blocos são daquele terreno:
cima-esquerda = 1, cima-direita = 2, baixo-esquerda = 4, baixo-direita = 8 (soma).
Ex.: a peça 15 é toda terreno; a peça 8 é só o cantinho de baixo à direita (um canto arredondado).

**Paleta** usada: 5 a 6 tons por material, luz vindo de cima/esquerda, contorno colorido
(uma versão bem escura da cor vizinha, não preto puro).

## Como editar os diálogos

As falas do terreiro estão em `dialogos/terreiro.json` e as da encruzilhada em `dialogos/exu.json`. Cada fala tem `quem` (nome), `yo` (iorubá), `pt` (português) e,
opcionalmente, `evento` (por exemplo, `abrir_caminho`). Se `yo` estiver vazio, a fala aparece
como narração.

**Importante:** as frases em iorubá desta versão são curtas e simples, mas precisam ser revisadas por
alguém fluente antes de qualquer publicação. O iorubá é tonal e os acentos mudam o sentido das palavras.

## Ferramentas gratuitas recomendadas

- **Godot 4**: a engine do jogo.
- **Pixelorama** (https://pixelorama.org) ou **LibreSprite**: para desenhar e animar os sprites.
  As folhas de animação estão em `arte/`: `ade.png` tem 8 quadros de 16×24 e `exu.png` tem 2 quadros de 24×32.
- **LMMS** ou **BeepBox**: para compor músicas.
- **jsfxr** (https://sfxr.me): para criar efeitos sonoros.

## Próximos passos sugeridos

1. Testar e ajustar a sensação do pulo (constantes no topo de `scripts/jogador.gd`).
2. Redesenhar Adé e Exu com mais detalhes no Pixelorama.
3. Capítulo 1: Ògún, com a mecânica de abrir caminho na mata com o ferro.
