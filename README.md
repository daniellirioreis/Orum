# Ọ̀run — Histórias dos Orixás (protótipo)

Jogo de plataforma 2D em pixel art com os itans dos orixás.
Esta versão tem o **Prólogo** completo, em duas partes:

1. **Ilé — O Terreiro da Vó** (visão de cima, estilo RPG). Adé sonha com os orixás e acorda no
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

O terreiro usa dois arquivos de texto do mesmo tamanho, um em cima do outro:

`fases/terreiro.txt` (chão e paredes):

| Caractere | O que é |
|---|---|
| `#` | parede da casa (com 2 blocos de altura, a parede mostra a frente alta) |
| `j` | parede com janela |
| `M` | muro do quintal |
| `.` `:` | piso vermelho do barracão (liso / com marcas de uso) |
| `c` | ladrilho da cozinha |
| `d` | tábuas da despensa |
| `,` `;` `*` | grama (lisa / com tufos / com flores) |
| `_` `=` | caminho de terra (liso / com pedrinhas) |
| `t` | terra batida (em volta da horta) |

`fases/terreiro_objetos.txt` (coisas e pessoas; `.` = nada):

| Caractere | O que é |
|---|---|
| `P` | onde Adé acorda |
| `V` `D` `G` `N` | Vó, Tia Dora, Ogã Bené, Lia (cambone) |
| `C` `A` `E` `r` | congá, atabaques, esteira, tapete |
| `Z` `B` | cerquinha (separa a gira da assistência) e banco |
| `l` `+` `b` | lampião de parede, luz de teto (invisível), varal de bandeirinhas |
| `p` | vaso com planta |
| `F` `m` `O` | fogão a lenha, mesa, pote de barro |
| `h` `i` `n` | filtro de barro, pilão, prateleira de panelas (na parede) |
| `Q` `U` | prateleira e barril da despensa |
| `K` `S` | caixote e saco da despensa (dá para procurar neles) |
| `k` | o caixote onde está o Epó |
| `L` `H` | lenha, horta |
| `R` `Y` `J` | árvore, dendezeiro, bananeira |
| `W` `f` `o` `u` | varal de roupa, flores, pedras, poste com lampião |
| `g` `z` | galinha (anda sozinha) e gato dormindo |
| `T` `X` | tronqueira e porteira |
| `v` `e` | onde a Vó espera na tronqueira e onde Exu aparece |

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
