# PROJECT-STATE.md
## Estado atual do projeto Dragon Ranch

**Última atualização:** 12/10/2026
**Documentos de referência:** `GAME-DESIGN.md`, `ART-DIRECTION.md`, `DRAGON-VISUAL-DESIGN.md`
**Place no Studio:** "Rancho do Dragão" (placeId 14594299983)

Este arquivo registra o que já foi feito, o que falta e o que está bloqueado.
Deve ser atualizado a cada etapa concluída.

Legenda: ✅ feito · 🟡 parcial · ⬜ não feito · ⛔ bloqueado por decisão pendente

---

## 1. Fase atual

**Mapa do mundo aberto construído (12/10/2026)** conforme `WORLD-DESIGN.md` v0.2:
terreno de 16.000 × 16.000 studs, Hub na ilha fluvial, 18 fazendas espalhadas com
bosques, florestas, pontes, acampamentos, waypoints, marcos, Castelo dos Dragões e
ilhas flutuantes. Passe de gráficos feito (12/10/2026): vegetação rebalanceada no estilo pedido
(manchas de floresta alta com clareiras, campos abertos com árvores soltas),
árvores e plantas realistas (PBR), rochas de terreno, grama alta, luz e névoa
novas, acampamentos em escala de dragão e ferramenta de qualidade no jogo
(Baixo/Médio/Alto/Ultra). Próximo: Fase 3 — Dragão companheiro (ver `V1-ROADMAP.md`).

Fase 2 — Fazenda e ovos concluída (12/10/2026).

Fase 1 — Fundação concluída (12/10/2026).

Fase 0 — Design concluída (12/10/2026): todos os bloqueios B1–B10 resolvidos.

~~Fase 0 — Design.~~ Conforme o `GAME-DESIGN.md` (seções 15 e 18), a programação
dos sistemas só começa depois que os bloqueios B1–B10 forem resolvidos ou
explicitamente adiados pelo responsável.

---

## 2. Documentação

| Item | Estado | Observação |
|---|---|---|
| `GAME-DESIGN.md` | ✅ | v0.4 — mundo aberto aprovado (§8.3) |
| `ART-DIRECTION.md` | ✅ | v0.2 |
| `DRAGON-VISUAL-DESIGN.md` | ✅ | v0.2 — 5 fichas com anatomia-base proposta |
| `PROJECT-STATE.md` | ✅ | este arquivo |
| `MASTER-PROMPT.md` | ⬜ | regras de trabalho para o Claude |
| `V1-ROADMAP.md` | ✅ | 11 fases de construção |
| `IDEAS-BACKLOG.md` | ✅ | inclui ovos melhores (futuro) |
| `WORLD-DESIGN.md` | ✅ v0.2 | mundo aberto aprovado (D1–D12 respondidas); artifact "Atlas de Escamarra" |

---

## 3. Bloqueios essenciais (GAME-DESIGN §15)

| Código | Decisão | Estado |
|---|---|---|
| B1 | Espécies e elementos | ✅ 5 espécies, 6 elementos, papéis, raridades (mudam muito o dragão), ovos |
| B2 | Crescimento | ✅ somente por pontos, ritmo demorado, sem marcos obrigatórios |
| B3 | Voo | ✅ a partir de Jovem; missão uma vez por dragão |
| B4 | Combate | ✅ controles, flechas finitas, comando do dragão, montaria a partir de Jovem, poderes por estágio |
| B5 | PvP | ✅ 3 zonas; até 40% dos materiais em zona perigosa; proteção de iniciante; anti-abuso |
| B6 | Dungeons | ✅ grupo 1–4; morte elimina (mantém loot, sem baú final nem item de missão); baú a cada 20 h |
| B7 | Inventário e economia | ✅ mochila 30→60; armazém 100; moeda única; sem comércio entre jogadores |
| B8 | Salvamento | ✅ trava de sessão, autosave, itens com código único, servidor autoritativo contra exploiters |
| B9 | Mapa | ✅ Terras de Escamarra, ~16.000 × 16.000 studs, 18 jogadores, layout aprovado |
| B10 | Dispositivos | ✅ PC e celular |

Outras pendências de arte: estilo final dos dragões (ART §12, DRAGON §14).

---

## 4. O que existe hoje no Roblox Studio

Atualizado em 12/10/2026, depois da construção do mundo aberto.

| Área | Conteúdo |
|---|---|
| Terreno | Continente de ~14.000 studs num mundo de 16.000 × 16.000, gerado por `ServerStorage.WorldGen` (relevo por região, rios com nível de água, Grande Lago, pântano, mar, vulcão, rochedo do castelo, picos nevados, cânions de lava) |
| `Workspace.Hub` | Ilha do Coração: praça, chafariz, Torre do Dragão (marco), 4 NPCs, mesa do cartógrafo (mapa e escolha de fazenda), ~70 casas, barracas, lanternas |
| `Workspace.Farms` | 18 fazendas (Plot01–18) com posição, bioma e faixa como atributos; cerca, arco com placa, ninho, celeiro, cochos, 8 lugares de dragão |
| `Workspace.World.Groves` | Bosque irregular em volta de cada fazenda (~8.800 árvores e arbustos), com corredor de entrada voltado para a estrada |
| `Workspace.World.Forest` | Vegetação por região em blocos de 1.024 studs: ~17.000 árvores (pinheiros-ponderosa, carvalhos, cerejeiras), ~17.000 detalhes (samambaias, arbustos, flores) numa pasta `Detail` que a ferramenta de qualidade esconde, e rochas feitas de terreno |
| `Workspace.World.Bridges` | 19 pontes onde as estradas cruzam água (inclui a ponte longa da Ilha do Lago) |
| `Workspace.World.Camps` | 7 acampamentos **para dragões**: lagoa-bebedouro com borda de rochas, 2 cochos de pedra com carne, varal alto de carne, abrigo alto aberto, ninhos de palha grandes, poleiros (rochas grandes e árvore morta) e braseiro |
| `Workspace.World.Waypoints` | 8 obeliscos rúnicos |
| `Workspace.World.Landmarks` | Castelo dos Dragões, Farol, Cúpula das Ruínas, Árvore-Mãe, Árvore de Luz, Pilar de Cristal, portão da dungeon com cachoeira |
| `Workspace.World.SkyIslands` | 9 ilhas flutuantes (terreno) com árvores frutíferas, arbustos de frutas, varal de carne, lagoa e queda-d'água |
| `ServerStorage.WorldAssets` | Árvores e plantas realistas da Creator Store (gratuitas, sem scripts: Pond1–6, RealOak1–6, Sakura, Fern) e modelos 3D gerados por IA (árvores, pinheiro nevado, árvore morta, cogumelo, arbusto de frutas, rocha, cristais, casa, castelo, farol, ruínas, obelisco, acampamento, celeiro, ninho, etc.) |
| `ServerStorage.OldWorld` | Cenário antigo (anel de fazendas e mapa-modelo), guardado só como reserva; pode ser apagado |
| `Lighting` | Future, Atmosphere ajustada para ver longe, nuvens, bloom, raios de sol, correção de cor |

## 5. Sistemas da V1 (critérios do GAME-DESIGN §16)

| # | Sistema | Estado | Depende de |
|---|---|---|---|
| 1 | Fazenda do jogador (atribuição e acesso) | ✅ novatos perto do Hub; bioma à escolha com dragão Jovem | B9, B8 |
| 2 | Ovo, cuidados (comida e água) | ✅ | B1, B2 |
| 3 | Crescimento em 6 estágios + salvamento | 🟡 crescimento ✅; salvamento real a testar com API ativada | B2, B8 |
| 4 | Coleta, moedas, compra/venda | ⬜ | B7 |
| 5 | Missões e NPCs | ⬜ | B3, B9 |
| 6 | Entrada física da dungeon + grupo | ⬜ | B6 |
| 7 | Instância da dungeon, inimigos, chefe, recompensas | ⬜ | B6, B4 |
| 8 | Missão e desbloqueio do voo | ⬜ | B3 |
| 9 | Combate em tempo real (jogador + dragão) | ⬜ | B4, B1 |
| 10 | PvP, proteção e loot por zona | ⬜ | B5 |
| 11 | Salvamento sem perda nem duplicação | ⬜ | B8 |
| 12 | Suporte aos dispositivos escolhidos | ⬜ | B10 |

## 6. Protótipos de arte recomendados (ART-DIRECTION §11)

| Protótipo | Estado |
|---|---|
| Clareira de floresta | ✅ fazendas em clareiras com bosque |
| Mirante com montanhas, vale e cachoeira | 🟡 relevo pronto; cachoeiras ainda simples |
| Área mágica com cristais | 🟡 Vale dos Cristais e Pilar de Cristal |
| Portão de dungeon com círculo de grupo | 🟡 portão e cachoeira; falta o círculo de grupo |
| Hub Central, fazendas e bosques | ✅ 12/10/2026 |
| Dragão em duas fases | ✅ 5 espécies com ovo, bebê e adulto gerados (aguardando aprovação do responsável) |
| Interface em PC e celular | 🟡 primeiras telas prontas; testar no celular |

---

## 8. Código implementado

O código fica em `src/` (espelho exato do Studio). Pastas gerenciadas:
`ReplicatedStorage.Shared`, `ServerScriptService.Server`,
`StarterPlayer.StarterPlayerScripts.Client`.

| Módulo | Função | Estado |
|---|---|---|
| `Shared/Config/*` | Espécies, elementos, raridades, crescimento, inventário, itens, regras (valores ajustáveis) | ✅ |
| `Shared/Net/NetDefs` | Lista única de remotes com esquemas de validação | ✅ |
| `Shared/Net/NetClient` | Acesso do cliente aos remotes | ✅ |
| `Server/Services/NetService` | Rede protegida: limite de frequência, validação de argumentos, infrações e expulsão | ✅ testado |
| `Server/Data/DataService` | Salvamento com trava de sessão, autosave, BindToClose, novas tentativas | ✅ testado (memória) |
| `Server/Data/ProfileTemplate` | Formato do perfil + reconciliação | ✅ |
| `Server/Services/FarmService` | 18 terrenos, atribuição ao entrar, placa com nome, nascer na própria fazenda | ✅ testado |
| `Server/Services/InventoryService` | Núcleo da mochila (adicionar, remover, contar, empilhar) | ✅ |
| `Server/Dragons/DragonService` | Ovo inicial, incubação, cuidados, treino, pontos, estágios, nome filtrado, dragão ativo, ampliar espaços | ✅ testado |
| `Server/Dragons/DragonModels` | Usa os modelos realistas gerados (ServerStorage.DragonAssets); peças simples só como reserva | ✅ testado |
| `Server/Services/NPCService` + `Client/UI/Dialog` | 4 NPCs no Hub com conversa | ✅ testado |
| `Shared/Config/NPCs` | Nomes e falas dos NPCs | ✅ |
| `Client/UI/*` | Escolha do ovo, painel de dragões, barra de moedas/itens, avisos (PC e celular) | ✅ testado |
| `tools/studio/build_farms.luau` | (antigo) grade de 18 fazendas — substituído por build_hub | — |
| `tools/studio/build_hub.luau` | (antigo) Hub com fazendas em anel — substituído pelo WorldBuilder | — |
| `ServerStorage/WorldGen/WorldData` | Dados do mundo: regiões, rios, estradas, fazendas, acampamentos, waypoints, ilhas | ✅ |
| `ServerStorage/WorldGen/WorldGen` | Gerador de relevo e materiais (roda no Studio e no Luau de linha de comando) | ✅ |
| `ServerStorage/WorldGen/TerrainWriter` | Escreve o terreno em blocos de 256 studs, em segundo plano (~1 min o mapa todo) | ✅ |
| `ServerStorage/WorldGen/WorldBuilder` | Constrói Hub, pontes, fazendas, bosques, acampamentos, waypoints, marcos, ilhas, florestas e luz | ✅ |
| `Shared/Config/Biomes` + `Client/UI/FarmChooser` | Escolha do bioma da fazenda na mesa do cartógrafo (validada no servidor) | ✅ |
| `Client/UI/Compass` | Bússola com direção e distância da fazenda e do Hub | ✅ testado |
| `Shared/Config/Graphics` + `Client/UI/GraphicsSettings` | Ferramenta de qualidade (Baixo/Médio/Alto/Ultra): sombras, efeitos de tela, névoa, nuvens, detalhes pequenos, partículas e luzes pequenas; salva no perfil; celular começa no Médio | ✅ testado |
| `tools/worldgen/preview.py` | Prévia do relevo em PNG sem abrir o Studio | ✅ |
| `tools/studio/sync_from_github.luau` / `ServerStorage.RepoSync` | Copia o código do GitHub (por commit) para o Studio | ✅ |
| `tools/studio/import_dragon_assets.luau` | Importa dragões gerados por IA para ServerStorage.DragonAssets | ✅ |
| `tools/checksums.py` | Confere se o Studio está idêntico ao repositório | ✅ |

**Testes do mundo aberto (12/10/2026, Play no Studio):**
- Servidor inicia sem erros; jogador novo recebe a fazenda livre mais próxima do Hub (Moinho, ~2.100 studs) e nasce nela. ✅
- Bússola mostra o Hub e a distância. ✅
- Mesa do cartógrafo com o pedido "Ver mapa e fazendas"; 4 NPCs no Hub. ✅

**Testes da Fase 1 (12/10/2026, Play no Studio):**
- Perfil carrega e chega ao cliente (50 moedas, mochila 30). ✅
- Ping com texto, NaN e argumento extra: rejeitados. ✅
- Cliente tentando disparar remote do servidor (ex.: falsificar moedas): rejeitado. ✅
- Rajada de 20 pedidos: só 5 aceitos (limite de frequência). ✅

**Testes da Fase 2 (12/10/2026, Play no Studio, com acelerador de pontos só de teste):**
- Jogador recebe a Fazenda 01, a placa mostra o nome e ele nasce dentro dela. ✅
- Tela de escolha mostra as 5 espécies; escolher cria 1 ovo Comum no ninho e dá 10 carnes e 10 águas. ✅
- Escolher de novo ou mandar espécie inexistente: ignorado/rejeitado. ✅
- Ovo chocou (Ovo → Bebê); carinho e brincadeira deram pontos; Bebê → Jovem. ✅
- Ao virar Jovem, a proteção de iniciante terminou com aviso. ✅
- Alimentar dragão satisfeito é recusado e não gasta item. ✅
- Renomear (com filtro de texto do Roblox) e ampliar fazenda sem moedas (recusado). ✅
- Renomear dragão inexistente, nome de 500 letras e tipo errado: rejeitados. ✅
- Acelerador de pontos de teste funciona **somente no Studio** (atributo `TestPointsMultiplier` em ServerScriptService, ligado só durante o Play).


## 9. Tarefas do responsável (lembrar ao final do projeto)

Coisas que só o dono do jogo pode fazer no Roblox. O Claude deve relembrar
esta lista ao concluir a V1.

| # | Tarefa | Quando | Feito |
|---|---|---|---|
| 1 | Ativar *Game Settings → Security → Enable Studio Access to API Services* (salvamento real nos testes) | Qualquer momento; necessário antes dos testes finais | ⬜ |
| 2 | Definir *Game Settings → Places → Server Size* = 18 | Ao publicar | ⬜ |
| 3 | Publicar o jogo e testar com amigos em servidor real (salvamento entre servidores, trava de sessão) | Fase 11 | ⬜ |
| 4 | Testar no celular de verdade (controles, interface, desempenho) | Fase 11 | ⬜ |
| 5 | Configurar ícone, miniaturas, descrição e classificação de idade (Experience Questionnaire) | Antes de lançar | ⬜ |
| 6 | Conferir o desempenho no celular com o mundo aberto (~50.000 objetos de cenário, StreamingEnabled ligado); se pesar, usar a ferramenta de qualidade do jogo e reduzir a floresta | Fase 11 | ⬜ |
| 7 | **Salvar o place no Studio (File → Save to Roblox / Ctrl+S)** depois de cada sessão de construção: o terreno e o mundo só ficam guardados quando o place é salvo | Sempre | ⬜ |
| 9 | Confirmar que *Terrain → Decoration* (grama alta animada) continua ligado; o script não consegue alterar esse valor | Antes de publicar | ⬜ |
| 10 | Revisar os créditos das árvores da Creator Store (Letaij e outros, modelos gratuitos) se quiser citar os autores na descrição | Antes de lançar | ⬜ |
| 8 | Conferir no Studio, em *Workspace*, `StreamingTargetRadius` (~1024) e `StreamingMinRadius` (~256): o script não consegue alterar esses dois valores | Antes de publicar | ⬜ |

---

## 7. Histórico

| Data | Alteração |
|---|---|
| 12/10/2026 | Criação do arquivo; levantamento do place no Studio |
| 12/10/2026 | B3 e B10 resolvidos; B1 e B4 parciais; espécies passam de 3 para 5 |
| 12/10/2026 | Seis elementos; regra dos elementos duplos; Wyrm terrestre veloz; Dragão Asiático voa ondulando |
| 12/10/2026 | Chuva × Eletricidade; Wyrm desbloqueia entrar na terra |
| 12/10/2026 | Crescimento por pontos, ritmo demorado |
| 12/10/2026 | B2 resolvido: sem marcos obrigatórios |
| 12/10/2026 | B5 resolvido: regras de PvP e loot |
| 12/10/2026 | B6 resolvido: regras de dungeon |
| 12/10/2026 | B7 resolvido: inventário e economia |
| 12/10/2026 | B8 resolvido; B9 parcial |
| 12/10/2026 | B9 resolvido: Terras de Escamarra |
| 12/10/2026 | B4 resolvido: combate e controles |
| 12/10/2026 | Papéis de combate das espécies |
| 12/10/2026 | B1 resolvido: raridades e ovos. Todos os bloqueios resolvidos |
| 12/10/2026 | Criados V1-ROADMAP.md e IDEAS-BACKLOG.md |
| 12/10/2026 | Servidor de 8 para 18 jogadores; mapa dobrado para ~16.000 × 16.000 |
| 12/10/2026 | Fase 1 concluída: fundação (config, rede protegida, salvamento) |
| 12/10/2026 | Fase 2 concluída: 18 fazendas, ovo inicial, crescimento, cuidados, painel |
| 12/10/2026 | Hub Central com 4 NPCs; fazendas em anel separadas por floresta; bosque decorado nas entradas; fazendas decoradas; dragões e cenário com modelos 3D gerados por IA |
| 12/10/2026 | Proposta do mundo aberto (WORLD-DESIGN.md + mapa conceitual); construção do mapa pausada até aprovação |
| 12/10/2026 | Passe de gráficos: vegetação "na medida" (florestas com clareiras e campos abertos), árvores realistas, rochas de terreno, grama alta, luz/névoa novas, acampamentos para dragões, ferramenta de qualidade no jogo |
| 12/10/2026 | Mundo aberto aprovado (D1–D12) e construído: terreno 16k, Hub na ilha fluvial, 18 fazendas espalhadas com bosques, florestas, pontes, acampamentos, waypoints, marcos, castelo, ilhas flutuantes; regra de atribuição de fazenda; bússola |
