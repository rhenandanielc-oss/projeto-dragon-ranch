# WORLD-DESIGN.md
## Mundo aberto — Terras de Escamarra

**Versão:** 0.1 (PROPOSTA, aguardando aprovação)
**Data:** 12/10/2026
**Base:** `GAME-DESIGN.md` v0.3.2, `ART-DIRECTION.md`, `DRAGON-VISUAL-DESIGN.md`
**Status:** nada aqui está construído. Nenhum item substitui decisões
aprovadas até o responsável confirmar a seção 8 (decisões).

Referência de sensação: a exploração, a escala e a descoberta descritas
pelo responsável (inspiradas em Dystovia). Não foi copiado mapa nem
recurso de outro jogo; os princípios foram aplicados ao nosso universo.

---

## 1. Estrutura geral do mundo

O mundo é um **continente** cercado por mar, com relevo que divide o
território em regiões ligadas por estradas, trilhas e passagens. O Hub
fica no centro-sul (como já aprovado). As 18 fazendas ficam **espalhadas
pelo continente inteiro**, cada uma escondida no próprio bosque, em três
faixas de distância.

| Camada | O que é | Função no jogo |
|---|---|---|
| **Hub — Ilha do Coração** | Vila numa ilha fluvial, no centro-sul, onde o Rio do Lago se divide em dois braços. ~700 × 500 studs de vila; zona protegida ~1.000 × 800 incluindo as pontes | NPCs, comércio, missões, serviços. Ponto de partida das estradas para todas as regiões |
| **Prados Centrais** | Colinas abertas em volta do Hub | Primeiras explorações, coleta fácil, PvP comum (sem perda) |
| **Regiões intermediárias** | Floresta Densa (oeste), Grande Lago (leste), Floresta Encantada (nordeste), encosta sul da Cordilheira (norte), Prados do Sul e Costa (sul), borda do Pântano (sudeste) | Viagens médias, recursos melhores, a maioria das fazendas |
| **Regiões distantes** | Picos Gelados (noroeste), Cânion Vulcânico (oeste), Vale dos Cristais (leste), Planalto das Ruínas (nordeste), coração do Pântano (sudeste) | Zonas perigosas, melhores recompensas, fazendas mais isoladas |
| **Lugares escondidos** | Vale da dungeon (atrás da cachoeira, cordilheira norte — já aprovado), Vale Oculto (por uma caverna), ninhos raros | Descoberta sem marcador; recompensam quem explora |
| **Borda** | Mar e picos intransponíveis | Limite natural do mapa e espaço reservado para expansões |

Preservado do que já foi aprovado: Hub no centro-sul; floresta densa e rio
principal a oeste; grande lago e cachoeiras a leste; cordilheira com
mirantes ao norte; Vale dos Cristais no extremo leste atrás de penhascos
(perigoso); Cânion Vulcânico no extremo oeste (perigoso); portão da
dungeon num vale escondido da cordilheira norte, atrás de uma cachoeira,
sem marcador.

Novo (precisa de aprovação): Picos Gelados, Floresta Encantada, Pântano,
Planalto das Ruínas com cavernas, Costa Sul e Vale Oculto.

---

## 2. Mapa conceitual (visto de cima)

O mapa desenhado está no artifact "Atlas de Escamarra" e em
`docs/world-map-concept.svg`. Resumo das posições (x = leste, y = norte,
em studs; o centro do mapa é 0,0):

```
y +7000 ─────────────────────────────── mar / picos ───────────────────────────────
            PICOS GELADOS (perigoso)      CORDILHEIRA ALTA          VALE OCULTO (#18)
              #14 Geleira        Túnel ✦   ✦ Passo   ▲ dungeon        ✦ caverna
                                  #9 Mirante do Penhasco          PLANALTO DAS RUÍNAS
y +3500 ─────────────────────────────────────────────────────────────── #17 Ruínas
   CÂNION       FLORESTA DENSA        PRADOS CENTRAIS     FLORESTA ENCANTADA
   VULCÂNICO      #7 Cascata            #4 Colinas          #8 Bosque Encantado
  (perigoso)    ✦Árvore-Mãe                                     ▼ cachoeiras
   #15 Termas ✦Ponte da Fenda                                                  │ VALE DOS
y     0 ───────────────#2 Pinheiral ─────────────────── #3 Beira-Lago  GRANDE  ✦ CRISTAIS
     #13 Garganta   ✦Ponte do Rio      ★ HUB (0,-1500)       LAGO #10 Ilha  #16 │ (perigoso)
                 #6 Raízes      #1 Riacho        #5 Moinho                      │penhascos
y -3500 ───────────────────────────────────────────────────────────────────────────
              PRADOS DO SUL                       PÂNTANO (borda comum,
              #12 Costa  ⌂ Farol                   coração perigoso) #11 Brejo
y -7000 ─────────────────────────────── mar ───────────────────────────────────────
      x -8000               x -4000            x 0              x +4000          x +8000
```

Distâncias relativas do Hub (em linha reta): faixa interna ~2.000–2.600
studs; faixa média ~4.100–5.100; faixa externa ~5.200–8.000.

**Barreiras naturais:** Rio Principal (oeste, cruza por ponte ou vau),
braços do Rio do Lago (em volta do Hub), Grande Lago, penhascos do leste
(x ≈ 5.300, só passam pelo Desfiladeiro), Cordilheira (só passa pelo
Passo e pelo Túnel de Gelo), fenda de lava (oeste), pântano alagado
(sudeste).

**Pontos de passagem (estreitamentos):** Ponte do Rio Principal, Ponte da
Fenda, Passo da Cordilheira, Túnel de Gelo, ponte da Ilha do Lago,
Desfiladeiro dos Cristais, passarelas do Pântano. Cada um tem uma rota
alternativa mais longa, para nenhum ser obrigatório.

**Marcos visíveis de longe (para orientação):** Torre do Dragão (Hub),
Árvore-Mãe (oeste), Vulcão (extremo oeste), Pico Branco (noroeste),
Cachoeira Grande (norte do lago), Pilar de Cristal (extremo leste),
Árvore de Luz (Floresta Encantada), Farol da Costa (sul), Cúpula das
Ruínas (nordeste).

---

## 3. As 18 fazendas

Faixa **interna** (1–6): perto do Hub, para jogadores novos. Faixa
**média** (7–13). Faixa **externa** (14–18): mais isoladas, perto de
zonas perigosas e recursos melhores.

Distância = linha reta até o Hub. Tempo a pé usa 16 studs/s (velocidade
padrão do Roblox) e um caminho ~30% mais longo que a linha reta.

| # | Fazenda | Região / bioma | Bosque | Entrada | Isolamento | Distância (a pé) | Pontos de interesse próximos |
|---|---|---|---|---|---|---|---|
| 1 | Riacho | Prados do Sul | Bétulas e carvalhos jovens, cercas vivas, clareiras floridas | Ponte de madeira sobre um riacho | Baixo | ~2.000 (2,7 min) | Hub, Vau do Sul, campos de coleta |
| 2 | Pinheiral | Borda da Floresta Densa | Pinheiros altos em camadas, chão de agulhas, rochas com musgo | Trilha estreita entre dois pinheiros caídos | Médio | ~2.400 (3,3 min) | Ponte do Rio Principal, Árvore-Mãe |
| 3 | Beira-Lago | Margem oeste do Grande Lago | Salgueiros, juncos, pedras lisas | Trilha pela margem e um pequeno píer | Baixo | ~2.500 (3,4 min) | Grande Lago, água e pesca |
| 4 | Colina das Flores | Prados Centrais (norte do Hub) | Cerejeiras e campos de flores em colinas | Arco natural de cerejeiras | Baixo | ~2.200 (3,0 min) | Estrada norte, primeiros mirantes |
| 5 | Moinho | Prados do sudeste | Pomar e faias, sebes altas | Estrada de cascalho entre sebes | Baixo | ~2.400 (3,3 min) | Borda do Pântano, Hub |
| 6 | Raízes Antigas | Sudoeste, borda da floresta | Carvalhos gigantes com raízes expostas | Túnel natural de raízes | Médio | ~2.600 (3,5 min) | Rio do Lago, estrada da Garganta |
| 7 | Cascata do Oeste | Vale do Rio Principal | Floresta úmida, samambaias, musgo, quedas-d'água baixas | Ponte de pedra sobre o rio | Médio | ~4.600 (6,2 min) | Árvore-Mãe, Ponte do Rio |
| 8 | Bosque Encantado | Floresta Encantada | Árvores que brilham, cogumelos gigantes, flores mágicas | Anel de cogumelos que vira trilha | Alto | ~5.100 (6,9 min) | Árvore de Luz, cachoeiras do lago |
| 9 | Mirante do Penhasco | Encosta sul da Cordilheira | Abetos em terraços entre rochas | Trilha em zigue-zague pela encosta | Médio-alto | ~5.000 (6,7 min) | Passo da Cordilheira, vista do mapa, rota para a dungeon |
| 10 | Ilha do Lago | Ilha no Grande Lago | Bosque denso cobrindo a ilha | Ponte longa e estreita (único acesso a pé) | Alto | ~4.200 (5,7 min) | Cachoeira Grande, Desfiladeiro |
| 11 | Brejo | Borda do Pântano | Ciprestes, raízes na água, névoa baixa | Passarelas de madeira | Médio-alto | ~4.100 (5,6 min) | Coração do Pântano (perigoso), ervas raras |
| 12 | Costa | Costa Sul | Pinheiros da costa, dunas com capim | Trilha pela praia, atrás das dunas | Médio | ~5.000 (6,8 min) | Farol, praias, recursos do mar |
| 13 | Garganta Rubra | Entre a floresta e o cânion | Pinheiros-negros entre rochas avermelhadas | Passagem estreita entre paredões | Alto | ~4.900 (6,6 min) | Borda do Cânion Vulcânico (perigoso) |
| 14 | Geleira | Picos Gelados | Pinheiros cobertos de neve, gelo, rochas | Túnel de gelo | Muito alto | ~8.000 (10,9 min) | Pico Branco, cristais de gelo |
| 15 | Fontes Termais | Borda do Cânion Vulcânico | Oásis verde ao redor de fontes quentes, cercado de árvores queimadas | Ponte de pedra sobre fenda de lava | Muito alto | ~5.900 (8,0 min) | Vulcão, Ponte da Fenda |
| 16 | Cristalina | Antes dos penhascos do leste | Pinheiros azulados e pequenos cristais | Desfiladeiro estreito | Alto | ~5.200 (7,0 min) | Desfiladeiro dos Cristais, Vale dos Cristais (perigoso) |
| 17 | Ruínas Antigas | Planalto das Ruínas | Árvores crescendo entre colunas e muros caídos | Escadaria de pedra antiga | Alto | ~7.200 (9,8 min) | Cúpula das Ruínas, cavernas |
| 18 | Vale Oculto | Vale escondido na cordilheira | Bosque antigo, nevoeiro, flores raras | Caverna que atravessa a montanha | Máximo | ~8.000 (10,9 min) | O lugar mais escondido do mapa |

Direções equilibradas: norte 4, 9, 18 · nordeste 8, 17 · leste 3, 10, 16 ·
sudeste 5, 11 · sul 1, 12 · sudoeste 6, 13 · oeste 2, 7, 15 · noroeste 14.

### 3.1 Como cada fazenda se integra à paisagem

- **Tamanho:** área interna cercada de ~200 × 200 studs (hoje são
  130 × 130), com espaço reservado para as ampliações da progressão.
  Cercada por um bosque de 80–150 studs de profundidade. Pegada total
  ~400 × 400 studs, com contorno irregular que segue o relevo.
- **Bosque em camadas:** borda externa de arbustos e árvores baixas;
  faixa intermediária densa de árvores altas (é ela que esconde a
  fazenda); clareiras e trilhas formadas pelo relevo, rochas e água. As
  árvores seguem regras de agrupamento (bosquetes de 3–9 árvores da
  mesma espécie, com espaços entre os grupos), e não espalhamento
  aleatório.
- **Visibilidade:** de fora, enxerga-se a fazenda só em relances entre as
  árvores: um telhado, a fumaça da chaminé, um dragão grande. De perto, a
  trilha de entrada fica legível. Do alto (voo), a fazenda aparece como
  clareira, o que é coerente: o voo é uma recompensa.
- **Identidade por bioma:** cada fazenda tem um "kit" de bioma (madeira,
  pedra, telhado, cerca, vegetação e luz próprios). As construções que o
  jogador desbloqueia são as mesmas em todas as fazendas, mas trocam de
  estilo conforme o kit.

### 3.2 Problema a resolver: a fazenda muda de servidor para servidor

Hoje cada jogador recebe, ao entrar, o primeiro terreno livre do
servidor. Com fazendas em biomas diferentes, a mesma pessoa poderia ter
uma fazenda na neve num servidor e na praia no outro. O progresso salvo
(dragões, construções) continua, mas o lugar muda. Opções na seção 8.

---

## 4. Como o terreno cria encontros sem tornar tudo perigoso

### 4.1 Onde os encontros acontecem

O tráfego não se espalha pelo mapa: concentra-se onde a geografia manda.

- **Estradas e trilhas:** as rotas do Hub para cada região. Quem viaja
  tende a usá-las, então é ali que se cruzam pessoas.
- **Estreitamentos:** pontes, passos, túnel, desfiladeiro e passarelas.
  São os lugares de "dois jogadores numa ponte estreita".
- **Destinos comuns:** pontos de coleta, mirantes, a região da dungeon,
  os ninhos selvagens e as zonas perigosas com recursos melhores.
- **Arredores das fazendas:** a trilha de entrada de cada fazenda passa
  por zona comum. É ali que alguém "observa uma fazenda entre as árvores".

### 4.2 Como a geografia controla a visão

| Terreno | Alcance de visão típico | Efeito |
|---|---|---|
| Floresta densa / pântano / ruínas | 60–120 studs | Movimento entre as árvores, surpresa, emboscada |
| Prados, margens, praia | 300–600 studs | Vê-se quem vem, dá para evitar ou se preparar |
| Mirantes e voo | 1.000+ studs | Ver sinais de atividade e decidir investigar |

**Sinais de atividade** que podem ser vistos ou ouvidos de longe: dragões
voando (quem voa enxerga longe, mas também é visto), efeitos de poderes
e sons de combate (alcance ~200 studs), fumaça de ataques de fogo,
pássaros que levantam voo quando alguém passa e pontos de coleta recém
esvaziados.

### 4.3 O que impede que toda viagem seja perigosa (regras já aprovadas, mantidas)

- Hub e interiores das fazendas: zona protegida.
- Zona comum: PvP sem perda de itens.
- Zona perigosa: só nas regiões distantes, avisada na tela ao entrar.
- Proteção de iniciante até o primeiro dragão virar Jovem.
- 2 minutos de proteção ao renascer; sem loot repetido do mesmo jogador
  por 30 minutos.

**Novidades propostas:**
- **Rotas seguras × atalhos arriscados:** toda região tem uma estrada
  mais longa por zona comum e um atalho mais curto que corta zona
  perigosa. O jogador escolhe o risco.
- **Nenhum estreitamento obrigatório:** cada ponte ou passo tem um
  desvio mais longo, para ninguém ficar preso por um jogador "pedágio".
- **Acampamentos de viagem (4):** pequenas zonas protegidas nas estradas
  principais (Rio, Passo, Lago, Sul), com fogueira. São pontos para
  descansar e trocar de dragão ativo, sem viagem rápida.

### 4.4 Frequência de encontros: estimativa e meta

Meta proposta, para um jogador viajando fora das zonas protegidas:
- **avistar** outro jogador a cada **2–5 minutos**;
- **encontro próximo** (menos de ~80 studs, quando dá para lutar ou
  fugir) a cada **8–15 minutos**.

Estimativa com 18 jogadores, cerca de 45% deles fora das zonas
protegidas (~8 pessoas no mundo aberto), ~85 milhões de studs² de terra
percorrível e ~70% do tempo de viagem gasto em rotas e destinos que
ocupam ~20% da área:
- espalhados de forma uniforme: avistamento a cada ~14 min (o mundo
  pareceria vazio);
- concentrados nas rotas, como planejado: avistamento a cada ~4 min,
  encontro próximo a cada ~12 min, dentro da meta.

É uma conta de ordem de grandeza (modelo de "partículas" com visão média
de 250 studs e velocidade relativa ~30 studs/s), não uma garantia. Os
números reais saem dos testes da seção 5.3.

---

## 5. Escala do mapa

### 5.1 Proposta inicial

- **Manter o tamanho aprovado: ~16.000 × 16.000 studs** de área total,
  centrada na origem.
- **Continente jogável de ~13.000 studs de diâmetro**, com mar e picos
  intransponíveis na borda (servem de limite natural e de espaço para
  expansões).
- **Terra percorrível ~85 milhões de studs²** (descontando lago,
  montanhas altas e penhascos).

### 5.2 Por que esse tamanho

**Tempos de viagem** (caminho ~30% mais longo que a linha reta):

| Trajeto | A pé (16 st/s) | Montado em terra (proposta 45 st/s; Wyrm 65) | Voando (proposta 70 st/s + bônus de raridade) |
|---|---|---|---|
| Faixa interna ↔ Hub | 2,7–3,5 min | ~1–1,3 min | ~0,5 min |
| Faixa média ↔ Hub | 5,6–6,9 min | ~2–2,5 min | ~1–1,2 min |
| Faixa externa ↔ Hub | 7–11 min | ~2,5–3,9 min | ~1,2–1,9 min |
| Travessia do continente | ~18 min | ~6 min | ~3 min |

- O jogador novo, que ainda anda a pé, fica na faixa interna, a ~3 min
  do Hub. As viagens longas acontecem quando ele já pode montar (Jovem,
  ~3–4 h de jogo) e, depois, voar.
- Uma viagem até a região distante leva minutos, não segundos: o mapa
  parece grande, mas a viagem não chega a ser cansativa.

**Comparação com outros tamanhos** (mesma conta de encontros):

| Tamanho total | Avistamento | Encontro próximo | Sensação |
|---|---|---|---|
| 12.000 | ~2 min | ~7 min | Mais combate, mundo menor; viagens curtas demais montado |
| **16.000 (proposta)** | **~4 min** | **~12 min** | **Equilíbrio entre exploração e encontros** |
| 20.000 | ~6 min | ~19 min | Mais vazio; muito mais conteúdo para preencher |

Além disso, até ~±10.000 studs da origem não há problemas de precisão
de física no Roblox, e 16.000 cabe com folga.

### 5.3 Como validar antes de construir tudo

1. **Maquete cinza (greybox):** só relevo, rios, estradas, marcos e
   blocos no lugar das fazendas, sem arte. Cronometrar os trajetos a pé,
   montado e voando. Metas: faixa interna ↔ Hub ≤ 3,5 min a pé; faixa
   externa ↔ Hub ≤ 4 min montado; ninguém se perde por mais de 1 min
   seguindo estradas e marcos.
2. **Simulação com 18 robôs:** NPCs com rotinas de jogador (ir ao Hub,
   coletar, ir à dungeon, explorar, voltar à fazenda) rodando no
   servidor do Studio. Registrar a distância entre todos e contar
   avistamentos (< 250 studs com linha de visão) e encontros (< 80) por
   hora. Comparar com a meta da seção 4.4 e ajustar estradas, visão ou
   escala.
3. **Teste com pessoas:** sessões de 30 min com 8–18 amigos no jogo
   publicado. Medir encontros reais e perguntar: "o mundo pareceu vazio?
   lotado? perigoso demais?".
4. **Teste de desempenho:** a cada região construída, medir no celular e
   num PC fraco (memória, FPS, tempo de carregamento das áreas).

Se os encontros ficarem abaixo da meta, primeiro concentra-se mais o
tráfego (estradas, destinos); só depois se reduz a escala.

---

## 6. Desempenho e expansão

### 6.1 Desempenho

- **StreamingEnabled** com raio-alvo inicial ~1.024 studs e mínimo ~256
  (ajustar nos testes). Cada árvore, rocha ou construção é um modelo
  "atômico" que carrega e descarrega inteiro.
- **Marcos e montanhas visíveis de longe:** relevo em terreno (Terrain) e
  marcos com versão simplificada para distância (LevelOfDetail =
  StreamingMesh), para o horizonte nunca ficar vazio.
- **Poucos modelos, muito reaproveitados:** 8–12 variações de árvore, 4–6
  de rocha, 4–6 de arbusto por bioma, cada uma com 1–2 peças. Folhas sem
  colisão nem consulta; sombra desligada em vegetação pequena.
- **Orçamento:** ~40.000 árvores e rochas no mundo inteiro (o servidor
  guarda tudo; o cliente só carrega o que está perto); meta de no máximo
  ~6.000–8.000 objetos de cenário dentro do raio carregado.
- **Grama e flores pequenas:** pela decoração do terreno do Roblox, em vez
  de peças soltas (hoje as flores são peças individuais; trocar).
- **Luzes:** poucas luzes pontuais, sem sombra; brilho das lanternas por
  material e cor.
- **Terreno:** camada fina (só o necessário abaixo da superfície), para não
  inflar o tamanho do place.

### 6.2 Expansão sem reconstruir o mundo

- **Mundo em blocos de 2.048 × 2.048 studs,** cada região com o seu
  construtor (`tools/studio/regions/*.luau`) versionado no GitHub. Mudar
  uma região não mexe nas outras.
- **Kits de bioma reutilizáveis** (árvores, rochas, construções, cores) em
  `ServerStorage.WorldAssets/<Bioma>`.
- **Bordas reservadas:** ilhas no mar (leste e sul) e terras além da
  cordilheira (norte) ficam como futuras regiões. As estradas já terminam
  em "pontas" (cais, passagem bloqueada por desmoronamento) prontas para
  continuar.
- **Fazendas definidas por dados:** cada fazenda é um ponto no mapa com
  orientação, bioma e kit, o que permite adicionar novas fazendas ou
  mudar uma de lugar sem refazer o código.

---

## 7. Conflitos com decisões aprovadas

| # | Decisão aprovada | O que esta proposta muda |
|---|---|---|
| C1 | `GAME-DESIGN.md` §8.4 (v0.3.2): fazendas em anel ao redor do Hub | Fazendas espalhadas pelo mundo inteiro, em três faixas de distância. O Hub e as fazendas construídos hoje seriam refeitos (os modelos 3D são reaproveitados) |
| C2 | §8.3: tabela de regiões | Mantém todas as regiões aprovadas nas mesmas posições e acrescenta Picos Gelados, Floresta Encantada, Pântano, Planalto das Ruínas, Costa Sul e Vale Oculto |
| C3 | §11 (PvP): três zonas com regras fixas | O pedido de "PvP mais intenso fora da região inicial" pode ser feito só com geografia (sem mudar regras) ou mudando regras; ver decisão D4 |
| C4 | Atribuição de fazenda: primeiro terreno livre do servidor | Com biomas diferentes, a fazenda do jogador mudaria de lugar entre servidores; ver decisão D3 |
| C5 | Fazenda 130 × 130 | Proposta de 200 × 200 internos + bosque |

---

## 8. Decisões para aprovar antes de construir

- **D1 — Estrutura do mundo:** substituir o anel de fazendas pelo mundo
  descrito aqui (Hub no centro-sul, 18 fazendas espalhadas em três
  faixas)?
- **D2 — Escala:** manter 16.000 × 16.000 studs com continente jogável
  de ~13.000 de diâmetro?
- **D3 — Fazenda × servidor** (C4):
  - (a) sempre o primeiro terreno livre (bioma muda entre servidores);
  - (b) jogadores sem dragão Jovem recebem fazendas da faixa interna;
    os demais, qualquer uma;
  - (c) como (b), e o jogador escolhe um bioma favorito, atendido
    quando estiver livre no servidor.
  Recomendação: **(c)**.
- **D4 — PvP "mais intenso"** (C3):
  - (A) manter as regras e intensificar só pela geografia (rotas,
    estreitamentos, visão);
  - (B) como (A) e ampliar a zona perigosa a todas as regiões distantes
    (Picos Gelados, coração do Pântano, interior das Ruínas, além do
    Cânion e do Vale dos Cristais);
  - (C) como (B) e criar perda pequena na zona comum (por exemplo 10%),
    o que altera uma regra aprovada.
  Recomendação: **(B)**.
- **D5 — Bosque das fazendas:** só o interior cercado é protegido e o
  bosque em volta é zona comum (recomendado), ou o bosque também é
  protegido?
- **D6 — "Ilha" inicial:** você mencionou "fora da ilha ou região inicial
  protegida". Proposta: Hub numa ilha fluvial (Ilha do Coração), ligada
  por pontes, dentro do continente. Ou prefere uma ilha separada no mar,
  com travessia (barco ou ponte longa) até o continente?
- **D7 — Viagem rápida:** nenhuma; ou voltar para a própria fazenda com
  tempo de recarga (recomendado: 5 min); ou portais descobertos por
  exploração. Mais viagem rápida = menos encontros.
- **D8 — Mapa na tela:** sem mapa; bússola com direção da sua fazenda e do
  Hub; ou mapa que se revela conforme você explora (recomendado), com
  marcadores só para a sua fazenda, o Hub e os acampamentos. A dungeon
  continua sem marcador (já aprovado).
- **D9 — Velocidades provisórias:** montado em terra 45 studs/s (Wyrm 65),
  voo 70 studs/s mais o bônus de raridade. Ajustáveis nos testes.
- **D10 — Acampamentos de viagem:** criar os 4 pontos protegidos nas
  estradas?
- **D11 — Novos biomas:** aprovar Picos Gelados, Floresta Encantada,
  Pântano, Planalto das Ruínas, Costa Sul e Vale Oculto.
- **D12 — Primeiro passo:** começar pela maquete cinza do continente
  inteiro (só relevo, rios, estradas e marcos) e pelos testes de tempo e
  de encontros, antes de qualquer arte?

---

## 9. Histórico

| Versão | Alteração |
|---|---|
| 0.1 (12/10/2026) | Proposta inicial do mundo aberto: estrutura, mapa conceitual, 18 fazendas, encontros, escala, desempenho, conflitos e decisões |
