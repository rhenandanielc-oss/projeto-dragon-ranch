# GAME-DESIGN.md

## Documento de Design do Jogo --- V1

**Projeto:** Jogo de criação e aventura com dragões no Roblox\
**Nome provisório:** Dragon Ranch\
**Versão do documento:** 0.2\
**Status:** Design em consolidação --- não iniciar programação até
revisar os bloqueios essenciais\
**Idioma:** Português (Brasil)

------------------------------------------------------------------------

## 1. Como usar este documento

Este arquivo é a referência central para o design da primeira versão
(V1).

### Níveis de decisão

-   **APROVADO:** escolha explicitamente confirmada pelo responsável
    pelo projeto. Deve ser preservada, salvo aprovação explícita de uma
    alteração.
-   **PROPOSTA:** sugestão de design que ainda precisa de aprovação.
-   **PENDENTE:** decisão essencial ainda não definida.
-   **FUTURO:** ideia reservada para atualizações posteriores à V1.

O Claude deve: 1. Consultar este documento antes de propor ou
implementar alterações. 2. Não substituir decisões aprovadas por
preferências próprias. 3. Não iniciar a programação enquanto os
bloqueios essenciais da seção 15 não forem resolvidos ou explicitamente
adiados pelo responsável. 4. Quando uma decisão mudar, propor a
alteração, aguardar aprovação e atualizar este documento e o histórico
de mudanças. 5. Distinguir fatos aprovados de sugestões; não apresentar
propostas como se já tivessem sido aprovadas. 6. Não adicionar sistemas
grandes à V1 sem aprovação. 7. Não apagar nem reescrever regras
aprovadas silenciosamente.

------------------------------------------------------------------------

## 2. Visão geral

O jogo é uma experiência multiplayer 3D no Roblox, voltada a um público
amplo, em que os jogadores criam dragões em uma fazenda, acompanham seu
crescimento, exploram um mundo aberto, concluem missões, entram em
dungeons e combatem em tempo real.

A progressão central é a jornada de um dragão desde o ovo até a fase de
ancião. O jogador precisa cuidar dele, treiná-lo, conquistar o
desbloqueio do voo e obter equipamentos e recursos por exploração.

### Pilares principais

1.  **Criação e vínculo:** cuidar, criar e desenvolver vários dragões.
2.  **Progressão de longo prazo:** seis estágios de vida, habilidades e
    evolução por requisitos.
3.  **Exploração:** mundo aberto com pontos de interesse e dungeons
    físicas.
4.  **Combate em tempo real:** jogador e dragão lutam juntos, sem
    sistema de turnos.
5.  **Recompensas e risco:** coleta, equipamentos, poções, moedas e loot
    limitado.
6.  **Expansibilidade:** sistemas planejados para receber espécies,
    regiões e atividades futuras.

### Público e plataforma

-   **Plataforma:** Roblox.
-   **Apresentação:** jogo 3D em terceira pessoa.
-   **Modo:** multiplayer.
-   **Público-alvo:** geral, com linguagem visual e regras acessíveis.
-   **Mundo inicial:** uma região inicial expansível.

------------------------------------------------------------------------

## 3. Decisões de design aprovadas

As seguintes decisões foram confirmadas e devem ser tratadas como a base
vigente da V1:

  -----------------------------------------------------------------------
  Área                                Decisão aprovada
  ----------------------------------- -----------------------------------
  Plataforma                          Roblox

  Câmera                              Terceira pessoa

  Combate                             Misto: o personagem usa armas e
                                      habilidades simples; o dragão usa
                                      seus próprios ataques e poderes

  Coleção de dragões                  O jogador pode ter vários dragões,
                                      mas apenas um fica ativo e
                                      acompanha o jogador por vez

  Crescimento                         Seis estágios: ovo, bebê, jovem,
                                      pré-adulto, adulto e ancião

  Ritmo de crescimento                Sem obrigação de permanecer offline
                                      ou aguardar longos períodos
                                      offline; progressão configurada
                                      para não ser excessivamente rápida

  Voo                                 Desbloqueado por uma missão que
                                      envolve obter um item especial,
                                      como uma poção. A poção pode ser
                                      usada a partir do estágio Jovem.
                                      A missão é feita uma vez por
                                      dragão

  Dungeons                            Entradas físicas no mundo aberto;
                                      podem ser descobertas por
                                      exploração ou por missões

  Grupos em dungeons                  Jogadores podem se agrupar na
                                      entrada e iniciar uma expedição;
                                      cada grupo recebe sua própria
                                      instância

  Fazenda                             Área própria para alojar e cuidar
                                      dos dragões, com instalações
                                      funcionais

  Necessidades                        Comida e água são parte do cuidado;
                                      não há morte permanente por
                                      negligência

  Poções                              Incluem poções de batalha para
                                      efeitos temporários

  Espécies iniciais                   Cinco espécies: Wyvern, Dragão
                                      Ocidental, Amphiptere, Wyrm e
                                      Dragão Asiático (alterado de três
                                      para cinco em 12/10/2026)

  Elementos por espécie               Wyvern: Fogo/Eletricidade;
                                      Dragão Ocidental: Fogo;
                                      Amphiptere: Vento/Fogo;
                                      Wyrm: Terra/Água;
                                      Dragão Asiático: Água/Chuva

  Estágio mínimo para voar            Jovem (nessa fase o dragão já é
                                      bem maior que o jogador)

  Missão de voo                       Uma vez por dragão

  Armas iniciais                      Espada e arco disponíveis desde o
                                      início

  Dispositivos                        PC e celular desde o início

  PvP                                 Combate no mundo aberto, com
                                      proteção inicial para novos
                                      jogadores e proteção para fazendas

  Loot PvP                            Varia conforme a zona; é sempre
                                      limitado

  Proteção de progresso               Dragões permanentes, estágios,
                                      níveis e progresso essencial não
                                      podem ser roubados nem perdidos em
                                      derrota PvP

  Combate humano                      Espada, arco e habilidades simples

  Mundo inicial                       Uma região completa, planejada para
                                      expansão

  Economia                            Moedas, coleta e venda de materiais

  Ideias futuras                      Cruzamento, ovos misteriosos,
                                      guildas, eventos e outras expansões
                                      não fazem parte do escopo inicial
                                      sem nova aprovação
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 4. Dragões

### 4.1 Quantidade e estado ativo

-   O jogador pode possuir vários dragões.
-   Apenas um dragão pode estar ativo e acompanhá-lo por vez.
-   Os outros dragões ficam na fazenda ou em espaços de alojamento
    definidos pelo jogo.
-   A troca do dragão ativo deve ocorrer por uma interface clara e sob
    regras a definir.
-   A V1 deve ser projetada para permitir adicionar novas espécies e
    variações futuramente.

### 4.2 Espécies iniciais, elementos, nomes e raridades

**APROVADO (12/10/2026):** a V1 começa com cinco espécies, cada uma com seus elementos. Novas espécies poderão ser adicionadas em atualizações.

| Espécie | Elementos |
|---|---|
| Wyvern | Fogo / Eletricidade |
| Dragão Ocidental | Fogo |
| Amphiptere | Vento / Fogo |
| Wyrm | Terra / Água |
| Dragão Asiático | Água / Chuva |

Elementos presentes na V1: Fogo, Eletricidade, Vento, Terra, Água e Chuva. A lista candidata anterior (Fogo, Água, Natureza, Gelo e Raio) foi substituída.

**APROVADO (12/10/2026) — elementos:** a V1 tem **seis** elementos distintos.
- **Água:** controla massas de água, como mar e rios.
- **Chuva:** controla fenômenos de tempestade — chuva, tempestades e raios.
- **Fogo**, **Eletricidade**, **Vento** e **Terra**: efeitos a detalhar.

**APROVADO (12/10/2026) — Chuva × Eletricidade:**
- **Eletricidade:** rápida e direta — choques, correntes, impulsos, ataques em alvo único ou em linha.
- **Chuva:** em área e mais lenta — nuvens de tempestade, raios que caem numa região, chuva que atrapalha os inimigos.

**APROVADO (12/10/2026) — elementos duplos:** espécies com dois elementos têm três grupos de poderes: poderes que combinam os dois elementos, poderes só do primeiro e poderes só do segundo. Exemplo: o Wyvern tem poderes de Fogo + Eletricidade juntos, poderes só de Fogo e poderes só de Eletricidade.

**APROVADO (12/10/2026) — locomoção especial:**
- **Wyrm:** não voa. Em compensação, é muito rápido em terra, bem mais rápido em solo do que as espécies que voam.
- **Dragão Asiático:** voa sem asas, ondulando o corpo de um lado para o outro.

**PROPOSTAS SELECIONADAS PARA AVALIAÇÃO — ainda não tratadas como decisões finais:**
- **Raridades:** sete níveis, incluindo uma raridade secreta acima de Mítico. Nomes candidatos: Comum, Incomum, Raro, Épico, Lendário, Mítico e Secreto. Os nomes e a ordem final ainda precisam de confirmação.
- **Nomes:** cada dragão terá o nome oficial da espécie e poderá receber um nome personalizado pelo jogador.
- **Função da raridade:** afetará principalmente a dificuldade de obtenção, a aparência e os efeitos visuais. Não deve, por si só, tornar um dragão significativamente mais forte em combate.

**PENDENTE:** aparências, habilidades e atributos específicos de cada uma das cinco espécies.

**PROPOSTA:** as cinco espécies iniciais devem ter funções de combate distintas — por exemplo, dano direto, mobilidade/velocidade, defesa/controle, área e suporte —, mas essa distribuição ainda precisa ser aprovada.

As espécies não devem ser apenas recolorações: cada uma deve ter diferenças visuais e de gameplay compreensíveis e balanceáveis. Não considerar a lista de raridades como definitiva até confirmação.

### 4.3 Identificação e raridade dos dragões

**PROPOSTA SELECIONADA PARA AVALIAÇÃO:** ficha de cada dragão com quatro características centrais:
- **Nome oficial:** nome da espécie.
- **Nome personalizado:** nome que o jogador pode dar ao indivíduo.
- **Espécie:** determina anatomia, aparência-base e identidade natural.
- **Elemento:** determina a identidade elemental e orienta os efeitos e habilidades.
- **Raridade:** indica principalmente a dificuldade de obtenção e a apresentação visual.

A proposta atual prevê sete níveis de raridade, com um nível secreto acima de Mítico. A sequência candidata é Comum → Incomum → Raro → Épico → Lendário → Mítico → Secreto; nomes, ordem e distribuição de obtenção continuam pendentes de aprovação final.

**Regra de balanceamento proposta:** raridade deve priorizar exclusividade visual e dificuldade de obtenção, não ser uma garantia automática de superioridade em combate. O equilíbrio deve depender também de estágio, atributos, habilidades e decisões do jogador.

### 4.4 Atributos

**PROPOSTA:** usar um conjunto inicial enxuto: - Vida; - Energia ou
vigor; - Força de ataque; - Defesa; - Velocidade de movimento; -
Controle de voo, quando desbloqueado.

Os nomes finais, fórmulas, limites e diferenças entre espécies ainda
precisam ser definidos.

### 4.5 Personalidade e vínculo

**PROPOSTA:** o cuidado e o treinamento podem melhorar a resposta do
dragão a comandos, desbloquear interações e fortalecer o vínculo. Isso
não deve substituir os requisitos principais de crescimento.

### 4.6 Morte e perda

-   Não existe morte permanente do dragão por falta de alimento ou água.
-   A derrota PvP não permite roubar um dragão.
-   O dragão não perde permanentemente seus estágios, níveis ou
    progresso essencial.
-   Consequências de combate devem ser temporárias ou limitadas a itens
    expressamente classificados como saqueáveis.

------------------------------------------------------------------------

## 5. Crescimento em seis estágios

O crescimento é uma mecânica central e deve ser perceptível tanto
visualmente quanto em gameplay.

  -----------------------------------------------------------------------
  Estágio                             Papel geral
  ----------------------------------- -----------------------------------
  Ovo                                 Incubação e preparação para o
                                      nascimento

  Bebê                                Cuidados básicos e primeiras
                                      interações

  Jovem                               Introdução ao treinamento e às
                                      habilidades; já é bem maior que o
                                      jogador e pode receber a poção de
                                      voo após cumprir a missão

  Pré-adulto                          Preparação para desafios avançados
                                      e progressão rumo à maturidade

  Adulto                              Maturidade e identidade completa
                                      da espécie

  Ancião                              Estágio avançado, reservado a
                                      jogadores que investiram tempo e
                                      cumpriram requisitos
  -----------------------------------------------------------------------

### 5.1 Regras de crescimento

-   O crescimento não deve ser rápido demais.
-   O sistema não deve exigir que o jogador fique offline esperando um
    temporizador terminar.
-   A progressão pode combinar tempo de jogo, cuidados, treinamento,
    missões e requisitos específicos.
-   Os requisitos de cada transição devem ser configuráveis.
-   O jogo deve explicar ao jogador o que falta para o próximo estágio.
-   A progressão deve ser salva entre sessões.
-   Não haverá regressão permanente de estágio por negligência.
-   Comida e água mantêm o dragão saudável e funcional, mas não devem
    acelerar o crescimento de forma desproporcional.

### 5.2 Sistema de pontos de crescimento

**APROVADO (12/10/2026):** o dragão cresce juntando **pontos de
crescimento** ao fazer atividades com o jogador. O crescimento deve ser
**demorado**.

Fontes de pontos:
- **Cuidados** (comer, beber, carinho): poucos pontos, com limite diário.
- **Treino na fazenda:** pontos médios.
- **Combate, exploração e missões com o dragão ativo:** maior fonte.
- **Dragões na fazenda** (não ativos) ganham um pouco com cuidados e
  treino.

Fome e sede: dragão bem cuidado ganha pontos no ritmo normal; com fome
ou sede, ganha metade. Nunca regride nem morre.

**APROVADO (12/10/2026):** a passagem de estágio depende **somente dos
pontos**. Não há cronômetro nem marcos obrigatórios: ao atingir a
pontuação necessária, o dragão cresce.

**Calibração provisória (configurável, a ajustar em testes).** As horas
abaixo não são tempo de espera; são apenas uma estimativa de quanto jogo
ativo leva para juntar os pontos de cada estágio. Uma sessão ≈ 30–45 min:

| Passagem | Sessões nessa fase | Total acumulado aprox. |
|---|---|---|
| Ovo → Bebê | ~1 (≈30 min) | 0,5 h |
| Bebê → Jovem | ~5 | 3–4 h |
| Jovem → Pré-adulto | ~15 | 12–14 h |
| Pré-adulto → Adulto | ~30 | 30–35 h |
| Adulto → Ancião | ~80+ | 85 h ou mais |

Como o voo é liberado no estágio Jovem, o primeiro voo acontece por volta
de 3–4 horas de jogo com aquele dragão.

**REJEITADO (12/10/2026):** marcos obrigatórios por estágio. Missões,
dungeons e a missão de voo dão pontos, mas não são exigidas para crescer.
A missão de voo continua sendo o que libera o voo (seção 7).

Recomendação de teste: definir metas de progressão em sessões de jogo, e
não apenas em horas de calendário. Ajustar depois de testes com
jogadores.

------------------------------------------------------------------------

## 6. Fazenda e cuidados

A fazenda é a base do jogador e o lugar onde ele organiza seus dragões e
recursos.

### 6.1 Funções previstas

-   Alojamento para dragões;
-   Ninhos ou espaço de incubação;
-   Comedouros;
-   Bebedouros;
-   Área de treinamento;
-   Jardim ou área de cultivo de ingredientes;
-   Oficina para criação ou melhoria de equipamentos, se aprovada no
    escopo detalhado;
-   Espaços para expansão e personalização.

### 6.2 Comida e água

-   O jogador precisa obter comida e água para cuidar dos dragões.
-   A alimentação comum sustenta o cuidado básico.
-   Alimentos especiais podem oferecer benefícios temporários, se
    balanceados.
-   A falta de cuidado não pode causar morte permanente nem apagar
    progresso.
-   Não deve existir punição severa por o jogador ficar offline.

### 6.3 Limites a definir

**PENDENTE:** tamanho inicial da fazenda, número inicial de espaços para
dragões, método de obtenção de água e comida e quais instalações estarão
disponíveis desde o início.

------------------------------------------------------------------------

## 7. Voo e missão de desbloqueio

O voo deve ser uma conquista marcante, não uma habilidade liberada
imediatamente.

### 7.1 Fluxo geral aprovado

1.  O jogador recebe uma missão relacionada ao primeiro voo.
2.  A missão orienta o jogador a explorar o mundo e encontrar uma
    dungeon.
3.  Dentro da dungeon, o jogador supera obstáculos e desafios.
4.  O jogador obtém uma poção ou item especial necessário para o voo.
5.  O jogador retorna e utiliza o item conforme a missão.
6.  O dragão cumpre os requisitos de idade e desbloqueia o voo.
7.  O jogador recebe uma introdução aos controles de voo.

### 7.2 Regras

-   O voo é desbloqueado por missão.
-   A obtenção do item não deve, sozinha, ignorar os requisitos de idade
    definidos para o dragão.
-   A habilidade deve funcionar no mundo aberto e ser adequada à câmera
    em terceira pessoa.
-   O sistema deve prever futuras manobras e habilidades aéreas sem
    exigir que todas sejam implementadas na V1.

**APROVADO (12/10/2026):** o estágio mínimo para voar é **Jovem**. A
missão de voo é feita **uma vez por dragão**: cada dragão precisa receber
sua própria poção.

**APROVADO (12/10/2026):** o Wyrm não voa (ver seção 4.2).

**APROVADO (12/10/2026):** o Wyrm tem uma missão de marco própria, no
mesmo estágio (Jovem) e com a mesma estrutura (dungeon + item especial),
que desbloqueia a habilidade de **entrar na terra** (escavar e se
deslocar por baixo do solo). Também é feita uma vez por dragão.

**PENDENTE:** controles de voo e de escavação (PC e celular), limites e
se haverá custo de energia.

------------------------------------------------------------------------

## 8. Mundo aberto

A V1 terá uma região inicial expansível.

### 8.1 Componentes esperados

-   Fazenda do jogador;
-   Área inicial segura;
-   NPCs que oferecem missões;
-   Rotas de exploração;
-   Recursos coletáveis;
-   Entradas de dungeons visíveis no cenário;
-   Áreas de risco progressivo;
-   Espaços para encontros e PvP;
-   Caminhos e áreas acessíveis após desbloquear o voo.

### 8.2 Descoberta

O jogador pode: - Seguir uma missão até uma dungeon; - Encontrar uma
entrada enquanto explora; - Descobrir recursos e locais sem que uma
missão os marque primeiro.

**PROPOSTA:** dar pistas visuais e ambientais para que locais secretos
possam ser descobertos sem depender apenas de marcadores de interface.

### 8.3 Terras de Escamarra (APROVADO 12/10/2026)

- **Nome da região inicial:** Terras de Escamarra.
- **Tamanho:** ~8.000 × 8.000 studs, com StreamingEnabled (carregamento
  por proximidade, necessário para celular).
- **Servidor:** até 8 jogadores; cada um com terreno de fazenda próprio.

| Área | Posição | Zona |
|---|---|---|
| Vila inicial (mercador, NPCs, ponto de partida) | Centro-sul | Protegida |
| Fazendas (8 terrenos) | Ao lado da vila | Protegida |
| Prados e bosques | Em volta da vila | Comum |
| Floresta densa e rio principal | Oeste | Comum |
| Grande lago e cachoeiras | Leste | Comum |
| Cordilheira com mirantes | Norte | Comum |
| Vale dos Cristais | Extremo leste, atrás de penhascos | Perigosa |
| Cânion vulcânico | Extremo oeste, após a floresta | Perigosa |
| Portão da dungeon | Vale escondido na cordilheira norte, atrás de uma cachoeira | Comum |

**Descoberta da dungeon:** sem marcador de interface, mesmo com a missão
ativa; a missão dá apenas uma pista vaga; ruínas com runas apontam a
direção; dos mirantes é possível ver um brilho mágico no vale.

As zonas perigosas ficam longe da vila, atrás de obstáculos naturais.
O terreno atual do place (~2.000 × 2.000) pode ser reaproveitado como
parte da área central.

------------------------------------------------------------------------

## 9. Dungeons físicas com instâncias por grupo

### 9.1 Entrada no mundo

As dungeons são construções ou locais físicos no mundo aberto. Exemplo:
um portão enorme em uma montanha, com um círculo mágico no chão.

Na entrada, o jogador poderá interagir com um ponto de acesso para: -
Consultar informações da dungeon; - Ver requisitos e dificuldade; -
Formar ou confirmar um grupo; - Iniciar a expedição.

A interface e o fluxo final de agrupamento ainda precisam ser
detalhados.

### 9.2 Instância

-   A entrada permanece visível no mapa aberto.
-   Cada grupo recebe uma instância separada da dungeon.
-   Jogadores que não pertencem ao grupo não devem interferir na
    instância.
-   A instância deve controlar a conclusão, os inimigos, os chefes e as
    recompensas daquele grupo.
-   A saída deve devolver os jogadores ao mundo aberto em um local
    apropriado.

### 9.3 Conteúdo da V1

**PROPOSTA:** começar com uma dungeon principal, com inimigos comuns,
obstáculos, pelo menos um chefe e uma recompensa vinculada à missão de
voo.

### 9.4 Recompensas

Possíveis recompensas: - Moedas; - Materiais de criação; -
Equipamentos; - Poções; - Ingredientes raros; - Itens de missão.

### 9.5 Regras aprovadas (12/10/2026)

- **Grupo:** de 1 a 4 jogadores, cada um com seu dragão ativo; é possível
  entrar sozinho.
- **Formação:** o primeiro jogador a pisar no círculo do portão vira
  líder; quem pisar no círculo em até 30 segundos entra no grupo; o líder
  inicia (ou a contagem termina) e todos vão para a instância.
- **Desconexão:** o jogador tem 3 minutos para voltar e retomar na mesma
  instância; se não voltar, sai do grupo sem perder o que já tinha.
- **Morte:** quem morre **não volta mais** àquela expedição — é eliminado
  e devolvido ao portão no mundo aberto. Se todos morrerem, a expedição
  falha. Não há perda de itens (dungeon não é zona de PvP).
- **Recompensas:** loot individual, sem disputa no grupo; o item da missão
  de voo (ou de entrar na terra) é dado a todos com a missão ativa.
- **Reentrada:** livre, mas o baú final dá a recompensa completa apenas
  uma vez a cada 20 horas por jogador.

- **Jogador eliminado:** fica com o loot coletado até morrer; **não**
  recebe o baú final, mesmo que o grupo vença, e por isso o limite de 20
  horas dele não é gasto; **não** recebe o item da missão de voo (ou de
  entrar na terra) — precisa concluir a dungeon vivo.

**PENDENTE (balanceamento, não bloqueia):** dificuldade e duração média.

------------------------------------------------------------------------

## 10. Combate em tempo real

### 10.1 Princípio

O combate acontece em tempo real, no próprio mundo do jogo, sem turnos
nem transição para uma tela de batalha separada.

O sistema é misto: - O jogador controla seu personagem em terceira
pessoa. - O personagem usa espada, arco e habilidades simples. - Um
dragão ativo acompanha o jogador e participa do combate com seus ataques
e poderes. - O jogador não controla dois personagens manualmente ao
mesmo tempo; o dragão usa comportamento de companheiro e comandos
simples.

### 10.2 Habilidades iniciais propostas

Estas habilidades são propostas para o primeiro conjunto de combate e
ainda precisam de balanceamento:

-   **Sopro elemental:** ataque principal de alcance, específico da
    espécie;
-   **Investida:** avanço rápido contra um alvo;
-   **Defesa especial:** escudo, proteção ou redução temporária de dano;
-   **Ataque aéreo:** manobra que pode ser adicionada após o sistema
    básico de voo estar estável.

Não é obrigatório que todas as habilidades estejam disponíveis para
todas as espécies. A lista final será aprovada junto com as três
espécies.

### 10.3 Combate humano

**Decisão aprovada:** espada, arco e habilidades simples.

**APROVADO (12/10/2026):** espada e arco estão disponíveis desde o
início.

### 10.5 Controles e regras de combate (APROVADO 12/10/2026)

**Controles (PC / celular):**

| Ação | PC | Celular |
|---|---|---|
| Atacar | Clique esquerdo | Botão de ataque |
| Trocar arma/equipamento | Rolagem do mouse percorre o menu de equipamentos equipados | Botão pequeno que abre o menu de equipamentos equipados |
| Bloquear (espada) / mirar (arco) | Clique direito | Botão segurar |
| Esquiva (rolamento, com recarga) | Q | Botão de esquiva |
| Poções e itens rápidos | Barra de inventário na tela com até 8 itens visíveis; o jogador escolhe a poção e bebe | Mesma barra, por toque |
| Interagir | E | Botão contextual |
| Dragão: atacar o alvo mirado | F | Botão |
| Dragão: voltar para perto | G | Botão |
| Dragão: poderes especiais | Z, X, C | Botões |

**Habilidades do jogador (desde o início):** espada com combo de 3 golpes
e Golpe Giratório; arco com tiro carregado e Flecha Tripla.

**Flechas:** são finitas. Obtidas em baús, fabricadas pelo jogador e
derrubadas por monstros. Empilham até 50 por espaço (provisório).

**Comando do dragão:** segue o jogador e ataca sozinho quem atacar o
jogador; poderes especiais apenas sob comando, com recarga; se derrotado,
recua para descansar e pode ser chamado de novo após 60 segundos. Nunca
morre.

**Montaria:** a partir do estágio Jovem o jogador pode montar no dragão e
controlá-lo diretamente, **em terra ou voando** (voo após a missão).
Montado, o jogador não usa espada e arco; controla os ataques e poderes
do dragão.

**Poderes do dragão por estágio:**
- Ovo e Bebê: não lutam (o Bebê pode acompanhar, sem combater).
- Jovem: ataque básico + 1 poder do primeiro elemento.
- Pré-adulto: + 1 poder do segundo elemento.
- Adulto: + poder combinado dos dois elementos (Dragão Ocidental, de
  elemento único, recebe um terceiro poder de Fogo, mais forte).
- Ancião: versões mais fortes dos poderes.

**PENDENTE (não bloqueia):** onde e como as flechas são fabricadas;
valores de dano, alcance e recargas (balanceamento).

### 10.4 Balanceamento

-   O nível do dragão não deve tornar o resultado completamente
    automático.
-   Posicionamento, esquiva, escolha de habilidade e terreno devem ter
    importância.
-   Equipamentos e poções concedem vantagens limitadas, sem substituir
    habilidade do jogador.
-   Ataques e recompensas precisam ser validados pelo servidor.

------------------------------------------------------------------------

## 11. PvP e proteção

### 11.1 Princípio aprovado

O combate PvP pode acontecer no mundo aberto, com proteção inicial para
novos jogadores e proteção das fazendas.

### 11.2 Proteções necessárias

**PROPOSTA:** - Área inicial segura; - Proteção temporária para
jogadores novos; - Fazendas sem ataques PvP diretos; - Indicação visual
clara de zonas perigosas; - Aviso antes de entrar em uma zona com risco
de loot; - Proteção contra repetidos ataques abusivos ao mesmo jogador.

**APROVADO (12/10/2026):**
- **Proteção de iniciante:** o jogador não pode ser atacado até o seu
  primeiro dragão chegar ao estágio Jovem. Se atacar outro jogador
  antes disso, perde a proteção.
- **Proteção ao renascer:** 2 minutos sem poder ser atacado após perder.
- **Anti-abuso:** quem derrota o mesmo jogador de novo dentro de 30
  minutos não recebe loot dele.
- Aviso na tela ao entrar em cada tipo de zona.

### 11.3 Loot variável por zona

A quantidade e o tipo de loot que pode ser perdido variam conforme a
zona. O risco deve ser comunicado antes do jogador entrar na área.

Categorias sugeridas: - **Zona protegida:** sem saque de PvP; - **Zona
comum:** risco mínimo ou nenhuma perda de inventário; - **Zona
perigosa:** perda limitada de itens elegíveis e recompensas melhores.

**APROVADO (12/10/2026):**
- **Zona protegida** (fazendas, área inicial, vilas): sem PvP.
- **Zona comum** (maior parte do mapa): PvP ativo, sem perda de itens; o
  derrotado apenas renasce.
- **Zona perigosa** (áreas com recursos e baús melhores): PvP com perda
  limitada — o derrotado deixa cair **até 40%** dos materiais coletados
  que estiver carregando.

### 11.4 Itens protegidos

**APROVADO (12/10/2026).** Nunca podem ser roubados ou perdidos como
consequência de derrota PvP: dragões; estágios e pontos de crescimento;
progresso de missões; desbloqueio de voo e de entrar na terra;
equipamentos; moedas; itens de missão; itens permanentes da conta.

### 11.5 Itens saqueáveis

**APROVADO (12/10/2026):** apenas materiais coletados que o jogador
estiver carregando, e somente em zona perigosa (até 40%).

O jogo deve informar quais itens podem ser perdidos e em quais zonas.
Não permitir saques ilimitados nem a remoção de todo o inventário.

------------------------------------------------------------------------

## 12. Inventário, equipamentos e poções

### 12.1 Inventário

O inventário deverá distinguir claramente: - Itens protegidos; -
Materiais; - Alimentos; - Poções; - Equipamentos; - Itens de missão; -
Itens elegíveis para saque, quando aplicável.

**APROVADO (12/10/2026):**
- **Mochila:** 30 espaços iniciais, ampliável com moedas até 60.
- **Empilhamento:** materiais 50, alimentos 20, poções 10, equipamentos 1
  por espaço.
- **Itens de missão:** aba separada, não ocupam espaço.
- **Armazém da fazenda:** 100 espaços, totalmente seguro (fora do PvP).
  Guardar materiais ali evita o risco de perda em zona perigosa.
- Dragões não ocupam espaço no inventário.

### 12.2 Poções de batalha

Poções poderão conceder efeitos temporários, como: - Recuperação de
vida; - Recuperação de energia; - Resistência elemental; - Bônus
temporário de força, velocidade ou defesa.

Esses efeitos são exemplos e devem ser balanceados.

**PROPOSTA:** limitar quantidade de espaços de poções equipadas e
aplicar recarga entre usos para evitar que o combate seja decidido
apenas pela quantidade de consumíveis.

### 12.3 Equipamentos

Equipamentos básicos podem incluir sela, armadura e amuleto, desde que o
escopo da V1 comporte sua implementação.

Equipamentos devem ser legíveis, balanceáveis e preparados para receber
novos itens em atualizações. O cruzamento de espécies e equipamentos
avançados permanecem fora da V1, salvo nova aprovação.

------------------------------------------------------------------------

## 13. Economia

### 13.1 Modelo aprovado

A economia inicial inclui: - Moedas; - Coleta de materiais; - Venda de
materiais.

### 13.2 Fontes de recursos

**PROPOSTA:** - Recompensas de missões; - Recompensas de dungeons; -
Coleta de recursos no mapa; - Venda de materiais obtidos durante a
exploração.

### 13.3 Usos das moedas

**PROPOSTA:** - Comprar alimentos e materiais básicos; - Comprar itens
de cuidado; - Adquirir itens básicos de progressão; - Pagar por
melhorias ou expansões da fazenda, se aprovadas.

### 13.4 Regras de economia

-   Evitar fontes infinitas de moeda sem custos ou limites.
-   Evitar que jogadores experientes possam transferir vantagens
    excessivas a iniciantes.
-   Evitar recompensas de PvP que incentivem atacar repetidamente o
    mesmo jogador.
-   Definir preços e recompensas por configuração, facilitando ajustes
    sem reescrever os sistemas.

**APROVADO (12/10/2026):**
- **Moeda única** na V1 (nome temático a definir).
- **Ganhos:** missões, dungeons e venda de materiais ao mercador.
- **Gastos:** comida, poções, ampliação da mochila e melhorias da fazenda.
- **Controle:** pontos de coleta reaparecem após alguns minutos; o
  mercador paga preço fixo.
- **Comércio entre jogadores:** fora da V1 (evita transferência de
  vantagens, golpes e duplicação de itens). Pode entrar em atualização
  futura.

**PENDENTE (balanceamento, não bloqueia):** preços, valores de
recompensa, custo das ampliações, tempo de reaparecimento da coleta.

------------------------------------------------------------------------

## 14. Conteúdo fora da V1

As seguintes ideias ficam reservadas para atualizações futuras:

-   Ovos misteriosos e espécies raras adicionais;
-   Cruzamento de dragões e herança de características;
-   Sistemas avançados de equipamentos;
-   Guildas;
-   Eventos sazonais;
-   Chefes mundiais;
-   Corridas aéreas;
-   Novas regiões e biomas;
-   Dungeons adicionais e desafios lendários;
-   Novas espécies e habilidades.

Esses sistemas não devem ser implementados na V1 apenas porque aparecem
neste documento. A arquitetura deve facilitar sua adição futura, sem
antecipar trabalho complexo desnecessário.

------------------------------------------------------------------------

## 15. Bloqueios essenciais antes de programar

Estas são as decisões ainda não resolvidas que afetam diretamente a
arquitetura ou o escopo. O responsável pelo projeto deve respondê-las ou
autorizar explicitamente uma decisão provisória antes da implementação.

### B1. Detalhes das cinco espécies iniciais e dos elementos — PARCIALMENTE RESOLVIDO

**Resolvido (12/10/2026):** cinco espécies e seus elementos (ver seção 4.2).

**Resolvido (12/10/2026):** Água e Chuva são distintas (seis elementos);
elementos duplos têm poderes combinados e separados; Wyrm não voa e é
muito rápido em terra; Dragão Asiático voa sem asas, ondulando.

**Resolvido também:** Chuva (área, tempestade) × Eletricidade (rápida,
direta); Wyrm desbloqueia "entrar na terra" no lugar do voo.

**Ainda falta:** identidade visual, função no
combate e habilidades de cada espécie; os sete níveis de raridade e a
regra da raridade secreta.

### B2. Regra exata de crescimento — RESOLVIDO

**Resolvido (12/10/2026):** crescimento somente por pontos, ritmo
demorado, sem marcos obrigatórios; calibração provisória na seção 5.2.

Definir os requisitos de passagem entre os seis estágios: esforço
esperado, missões, treinamento, cuidados e possíveis itens. Não é
necessário definir tempos rígidos offline, pois o jogo não deve exigir
isso.

### B3. Limite de idade para voar — RESOLVIDO

**Resolvido (12/10/2026):** voo a partir do estágio Jovem; missão de voo
uma vez por dragão.

### B4. Escopo do combate da V1 — RESOLVIDO

**Resolvido (12/10/2026):** espada e arco disponíveis desde o começo.

**Resolvido também:** controles, habilidades, comando do dragão,
montaria e poderes por estágio (seção 10.5).

### B5. Regras de PvP e loot — RESOLVIDO

**Resolvido (12/10/2026):** ver seção 11.

Confirmar como a proteção inicial funciona, quais zonas existem, quais
itens são saqueáveis e o limite de perda por derrota.

### B6. Estrutura das dungeons — RESOLVIDO

**Resolvido (12/10/2026):** ver seção 9.5.

Definir tamanho máximo dos grupos, fluxo para formar o grupo na entrada,
comportamento ao desconectar, derrota dentro da dungeon e distribuição
de recompensas.

### B7. Economia e inventário — RESOLVIDO

**Resolvido (12/10/2026):** ver seções 12.1 e 13.4.

Definir a capacidade inicial do inventário, empilhamento de itens,
fontes principais de moedas e se comércio direto entre jogadores entra
na V1.

### B8. Salvamento e propriedade — RESOLVIDO

**Resolvido (12/10/2026):**
- **Dados salvos:** dragões (espécie, elementos, raridade, nomes, estágio,
  pontos, voo/terra desbloqueados), dragão ativo, mochila, armazém,
  moedas, missões, fazenda e proteção de iniciante.
- **Quando:** a cada 2–3 minutos, ao sair e ao fechar o servidor.
- **Trava de sessão:** os dados do jogador ficam travados no servidor em
  que ele está, impedindo duplicação entre servidores.
- **Itens únicos:** cada equipamento tem um código único.
- **Falhas:** novas tentativas; nunca sobrescrever dados bons com dados
  vazios ou corrompidos.
- **Proteção contra exploiters (requisito do responsável):** o servidor é
  a única autoridade sobre moedas, itens, pontos, dano e recompensas; todo
  pedido do cliente (RemoteEvent/RemoteFunction) é validado — tipo dos
  dados, distância, posse do item, tempo de recarga e limite de
  frequência; movimentos e velocidades impossíveis são verificados no
  servidor; o cliente nunca informa quanto ganhou.

Definir os dados persistentes necessários: dragões e seus estágios,
dragão ativo, inventário, moedas, missões, desbloqueio do voo e estado
da fazenda. O sistema precisa lidar com salvamentos falhos e evitar
duplicação de itens.

### B9. Escopo do mapa — RESOLVIDO

**Resolvido (12/10/2026):**
- O mapa deve ser **muito maior** que o terreno atual (~2.000 × 2.000
  studs), já na V1, para haver espaço de exploração; encontrar a dungeon
  e as zonas perigosas não deve ser fácil.
- Até **8 jogadores por servidor**; cada um recebe um **terreno de
  fazenda próprio** ao entrar, salvo entre servidores.

Nome, tamanho e layout: ver seção 8.3.

Definir o tema da região inicial, os pontos principais e o tamanho
aproximado da área jogável. Não é necessário desenhar todo o mapa em
detalhe antes de prototipar.

### B10. Dispositivos de controle — RESOLVIDO

**Resolvido (12/10/2026):** PC e celular desde o início. Console fica
fora da V1.

------------------------------------------------------------------------

## 16. Critérios de conclusão da V1

A V1 só deve ser considerada pronta quando for possível testar o ciclo
principal de ponta a ponta:

1.  O jogador entra e recebe acesso à sua fazenda.
2.  Obtém ou recebe um ovo e começa a cuidar do dragão.
3.  O crescimento e os dados são salvos corretamente.
4.  O jogador coleta recursos, consegue moedas e compra ou produz itens.
5.  Recebe uma missão e encontra uma dungeon física no mundo aberto.
6.  Forma um grupo ou entra sozinho conforme as regras aprovadas.
7.  Completa a dungeon, recebe recompensas e obtém o item da missão de
    voo.
8.  Cumpre os requisitos e desbloqueia o voo.
9.  Combate inimigos em tempo real usando o personagem e o dragão ativo.
10. Testa o PvP, a proteção e o loot conforme as regras definidas.
11. Sai e retorna ao jogo sem perder nem duplicar progresso.
12. Os principais fluxos funcionam em todos os dispositivos escolhidos
    para a V1.

------------------------------------------------------------------------

## 17. Princípios técnicos para orientar o futuro desenvolvimento

Esta seção define princípios, não código nem arquitetura final.

-   O servidor deve validar combate, recompensas, inventário, economia,
    crescimento e resultados de dungeons.
-   O cliente não deve poder conceder moedas, itens ou progresso por
    conta própria.
-   Dados permanentes devem ser salvos com tratamento de falhas e
    limites de chamadas.
-   Sistemas devem ser separados por responsabilidade e usar
    configurações para valores que serão balanceados.
-   Interfaces e controles devem considerar os dispositivos aprovados.
-   O código deve ser desenvolvido em etapas pequenas, com testes entre
    etapas.
-   Não implementar recursos futuros antes de o ciclo principal da V1
    funcionar.
-   Não alterar mecânicas aprovadas sem registrar a mudança e obter
    autorização.
-   Evitar prometer proteção absoluta contra exploits; implementar
    validação no servidor, verificações e testes.

------------------------------------------------------------------------

## 18. Próxima etapa recomendada

**Não começar a programar ainda.**

Primeiro, resolver os bloqueios B1 a B10, priorizando: 1. As cinco
espécies e suas funções; 2. Crescimento e desbloqueio do voo; 3. Regras
de combate e PvP/loot; 4. Fluxo de grupos e instâncias de dungeon; 5.
Salvamento e inventário; 6. Dispositivos suportados.

Depois, criar ou atualizar: - `MASTER-PROMPT.md`: regras de trabalho
para o Claude; - `PROJECT-STATE.md`: decisões, pendências e estado
atual; - `V1-ROADMAP.md`: fases e dependências de implementação; -
`IDEAS-BACKLOG.md`: recursos futuros.

O responsável pelo projeto mantém a decisão final sobre todas as
mecânicas.

------------------------------------------------------------------------

## 19. Histórico de alterações

  -----------------------------------------------------------------------
  Versão                              Alteração
  ----------------------------------- -----------------------------------
  0.1                                 Consolidação inicial da visão do
                                      jogo, decisões aprovadas, mecânicas
                                      da V1, ideias futuras e bloqueios
                                      de design.

  0.2 (12/10/2026)                    Espécies iniciais alteradas de três
                                      para cinco (Wyvern, Dragão
                                      Ocidental, Amphiptere, Wyrm, Dragão
                                      Asiático) com elementos definidos;
                                      voo a partir de Jovem, uma vez por
                                      dragão; espada e arco desde o
                                      início; PC e celular. B3 e B10
                                      resolvidos; B1 e B4 parciais.

  0.2.1 (12/10/2026)                  Seis elementos (Água e Chuva
                                      distintas); regra de poderes dos
                                      elementos duplos; Wyrm não voa e é
                                      muito rápido em terra; Dragão
                                      Asiático voa ondulando, sem asas.

  0.2.2 (12/10/2026)                  Chuva × Eletricidade diferenciadas;
                                      Wyrm desbloqueia "entrar na terra"
                                      por missão de marco no estágio
                                      Jovem.

  0.2.3 (12/10/2026)                  Crescimento por pontos, ritmo
                                      demorado com valores provisórios;
                                      marcos por estágio em proposta.

  0.2.4 (12/10/2026)                  Crescimento somente por pontos;
                                      marcos obrigatórios rejeitados. B2
                                      resolvido.

  0.2.5 (12/10/2026)                  PvP: três zonas, perda de até 40%
                                      dos materiais em zona perigosa,
                                      proteção de iniciante até o
                                      primeiro dragão virar Jovem,
                                      anti-abuso. B5 resolvido.

  0.2.6 (12/10/2026)                  Dungeons: grupos de 1 a 4, formação
                                      no círculo, morte elimina o
                                      jogador da expedição, loot
                                      individual, baú final a cada 20 h.

  0.2.7 (12/10/2026)                  Jogador eliminado mantém o loot,
                                      não recebe baú final nem item de
                                      missão; limite de 20 h não é gasto.
                                      B6 resolvido.

  0.2.8 (12/10/2026)                  Inventário (mochila 30→60, armazém
                                      100), moeda única, sem comércio
                                      entre jogadores na V1. B7 resolvido.

  0.2.9 (12/10/2026)                  Salvamento com trava de sessão e
                                      proteção contra exploiters (B8
                                      resolvido). Mapa muito maior, 8
                                      jogadores por servidor, fazenda
                                      própria por jogador.

  0.2.10 (12/10/2026)                 Mapa "Terras de Escamarra",
                                      ~8.000 × 8.000 studs, layout e
                                      regras de descoberta. B9 resolvido.

  0.2.11 (12/10/2026)                 Controles PC/celular, barra de 8
                                      itens, flechas finitas, comando do
                                      dragão, montaria a partir de Jovem
                                      (terra e voo), poderes por estágio.
                                      B4 resolvido.

  -----------------------------------------------------------------------

**Fim do documento.**
