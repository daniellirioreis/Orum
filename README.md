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

| Ação | Teclado | Controle |
|---|---|---|
| Andar (terreiro, visto de cima) | W A S D ou setas | Direcional ou analógico |
| Andar (fases de plataforma) | A / D ou setas | Direcional ou analógico |
| Pular | Espaço, W, ↑ ou Z | A |
| Falar / avançar diálogo | E, Enter ou X | X ou B |
| Voltar ao título | Esc | Start |
| Tela cheia | F11 | |

## O que tem nesta versão

**No terreiro (visão de cima)**
- Abertura com o sonho: sete silhuetas de orixás, cada uma com sua cor.
- A casa com barracão (congá, atabaques, esteira), cozinha, despensa e o quintal com horta, árvores,
  a tronqueira e a porteira.
- As pessoas da casa: a Vó (mãe de santo), a Tia Dora (cozinha), o Ogã Bené (atabaques) e a Lia (cambone).
- Onde está cada oferenda:
  - **Efum**: com a Tia Dora, na cozinha. Antes, ela pede lenha do quintal.
  - **Epó**: escondido na despensa. É preciso procurar nos caixotes e sacos.
  - **Oti**: com o Ogã Bené. Mini-jogo: ele toca uma sequência nos atabaques e Adé repete (← ↑ →).
  - **Luma**: com a Lia, no congá. Ela só entrega depois das outras três.
- O ritual: as oferendas diante da tronqueira, a Vó saúda ("Meu pai, abençoe!") e Exu chega.
- Noite de verdade: lampiões, velas do congá e fogão iluminam; vaga-lumes no quintal, fumaça na chaminé,
  galinhas andando e um gato dormindo. A cor da noite fica em `COR_NOITE`, no topo de `scripts/terreiro.gd`.

**Na encruzilhada**
- Adé, a personagem jogável, com corrida, pulo de altura variável, "coyote time" e renascimento ao cair.
- 10 búzios (owó ẹyọ) espalhados pelo caminho.
- Exu na encruzilhada, com diálogo em iorubá e legenda em português, contando o itan do gorro de duas cores.
- O mato fechado que se abre depois da conversa, e a saída pelo caminho de Ogum (portal de ferro com màrìwò).
- Fundo em camadas com pôr do sol e baobás, música de agogô e atabaque, efeitos sonoros.

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
| `W` `f` `o` `u` | varal, flores, pedras, poste com lampião |
| `g` `z` | galinha e gato |
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
