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

**Fase 0 — Design concluída (12/10/2026).** Todos os bloqueios B1–B10 resolvidos.

~~Fase 0 — Design.~~ Conforme o `GAME-DESIGN.md` (seções 15 e 18), a programação
dos sistemas só começa depois que os bloqueios B1–B10 forem resolvidos ou
explicitamente adiados pelo responsável.

---

## 2. Documentação

| Item | Estado | Observação |
|---|---|---|
| `GAME-DESIGN.md` | ✅ | v0.2 — 5 espécies, voo, armas e dispositivos atualizados |
| `ART-DIRECTION.md` | ✅ | v0.2 |
| `DRAGON-VISUAL-DESIGN.md` | ✅ | v0.2 — 5 fichas com anatomia-base proposta |
| `PROJECT-STATE.md` | ✅ | este arquivo |
| `MASTER-PROMPT.md` | ⬜ | regras de trabalho para o Claude |
| `V1-ROADMAP.md` | ✅ | 11 fases de construção |
| `IDEAS-BACKLOG.md` | ✅ | inclui ovos melhores (futuro) |

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
| B9 | Mapa | ✅ Terras de Escamarra, ~8.000 × 8.000 studs, 8 jogadores, layout aprovado |
| B10 | Dispositivos | ✅ PC e celular |

Outras pendências de arte: estilo final dos dragões (ART §12, DRAGON §14).

---

## 4. O que existe hoje no Roblox Studio

Levantamento feito em 12/10/2026, em modo Edit.

| Área | Conteúdo | Relação com o design |
|---|---|---|
| Terreno | ~2.000 × 2.000 studs com terreno esculpido | Pode servir de base para a região inicial (B9) |
| `Workspace.Foliage` | 26 bordos, 36 pinheiros, 7 arbustos | Aproveitável para florestas |
| `Workspace.Cabins` | Cabin1, Cabin2, StarterCabin | Conteúdo do modelo do Roblox; pode virar referência para a fazenda |
| `Workspace.ConstructionZone` | Casas incompletas, materiais, ponte, placas | Conteúdo do modelo do Roblox; sem função no design |
| `Workspace.Props` / `Billboards` | Cerca, 7 tochas, ponte, 6 placas | Decoração de exemplo |
| `Workspace.Tools` | 6 baús com ferramentas de exemplo (Gravity Coil, Teleport etc.) | **Não fazem parte do design** — remover ou substituir |
| `Lighting` | Atmosphere, Sky, Bloom, DepthOfField, SunRays | Base de iluminação já configurada |
| `ServerScriptService`, `ReplicatedStorage`, `ServerStorage`, `StarterGui` | Vazios | Nenhum sistema implementado |

**Conclusão:** o place é um mapa-modelo com cenário. Nenhum sistema de jogo
(dragões, fazenda, crescimento, combate, dungeons, inventário, economia, save)
foi implementado.

---

## 5. Sistemas da V1 (critérios do GAME-DESIGN §16)

| # | Sistema | Estado | Depende de |
|---|---|---|---|
| 1 | Fazenda do jogador (atribuição e acesso) | ⬜ | B9, B8 |
| 2 | Ovo, cuidados (comida e água) | ⬜ | B1, B2 |
| 3 | Crescimento em 6 estágios + salvamento | ⬜ | B2, B8 |
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
| Clareira de floresta | 🟡 floresta genérica do modelo existe |
| Mirante com montanhas, vale e cachoeira | ⬜ |
| Área mágica com cristais | ⬜ |
| Portão de dungeon com círculo de grupo | ⬜ |
| Dragão em duas fases | ⛔ depende do estilo e da aprovação das silhuetas |
| Interface em PC e celular | ⬜ desbloqueado (B10 resolvido) |

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
