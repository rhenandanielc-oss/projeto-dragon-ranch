# V1-ROADMAP.md
## Plano de construção da V1 — Dragon Ranch / Terras de Escamarra

**Criado em:** 12/10/2026
**Base:** `GAME-DESIGN.md` v0.3 (bloqueios B1–B10 resolvidos)

Cada fase termina com um **teste no Studio** antes de seguir para a próxima.
O andamento é registrado no `PROJECT-STATE.md`.

---

## Princípios de construção

- **Servidor autoritativo:** moedas, itens, pontos, dano e recompensas são
  decididos só no servidor. Todo pedido do cliente é validado (tipo,
  distância, posse, recarga, frequência).
- **Valores em configuração:** preços, pontos, recargas, chances e danos
  ficam em módulos de configuração (`ReplicatedStorage/Config`), fáceis de
  ajustar sem mexer nos sistemas.
- **Um sistema por módulo:** cada sistema tem seu serviço no servidor e seu
  controlador no cliente.
- **Placeholders primeiro:** modelos simples para testar a jogabilidade;
  arte final entra depois que o sistema funciona.
- **PC e celular desde o início:** toda interface e controle nasce com
  versão de toque.
- **Cópia do código no GitHub:** os scripts do Studio são espelhados em
  `src/` neste repositório a cada fase.

### Decisão técnica: instâncias de dungeon

As instâncias de dungeon serão criadas **dentro do próprio servidor** (uma
cópia da dungeon em uma área isolada, fora do mapa, para cada grupo). Com
até 18 jogadores por servidor (no máximo ~5 grupos ao mesmo tempo) isso
continua leve, funciona nos testes do Studio e
evita teleportes entre servidores, que só funcionam no jogo publicado.

---

## Fases

| Fase | Conteúdo | Depende de | Estado |
|---|---|---|---|
| **1. Fundação** | Estrutura de pastas; módulos de configuração; camada de rede com validação; salvamento com trava de sessão e autosave; remoção dos itens de exemplo do mapa | — | ✅ 12/10/2026 |
| **2. Fazenda e ovos** | 18 terrenos de fazenda atribuídos ao entrar; escolha do ovo inicial (5 espécies); ninho e incubação; nascimento; comida e água; pontos de crescimento; troca de estágio; nome personalizado; 3→8 espaços | 1 | ✅ 12/10/2026 |
| **3. Dragão companheiro** | Dragão ativo segue o jogador; troca de dragão ativo; montaria em terra a partir de Jovem; velocidade do Wyrm | 2 | 🟡 código 13/10/2026; testar no Studio |
| **4. Inventário e economia** | Mochila 30→60 com empilhamento; armazém 100; barra de 8 itens; coleta no mapa com reaparecimento; mercador; moedas | 1 | 🟡 código 13/10/2026; testar no Studio |
| **5. Combate** | Espada (combo, Golpe Giratório), arco (tiro carregado, Flecha Tripla), flechas finitas, bloqueio, esquiva; inimigos básicos; comandos do dragão (F, G, Z/X/C); poderes por estágio; poções; dragão recua e volta após 60 s | 3, 4 | 🟡 código 13/10/2026; testar no Studio |
| **6. Mundo** | Terreno ~16.000 × 16.000 das Terras de Escamarra (WORLD-DESIGN v0.2): Hub em ilha fluvial, 18 fazendas espalhadas com bosques, florestas, rios e pontes, lago, cordilheira, Vale dos Cristais, Cânion vulcânico, pântano, ruínas, Coroa do Dragão com castelo, ilhas flutuantes, acampamentos, waypoints; StreamingEnabled; bússola; NPCs e sistema de missões | 1 | 🟡 mapa construído 12/10; ferramenta de qualidade pronta; missões, waypoints e Pedra do Retorno em código 13/10 (testar); túneis e lava 13/10 (reconstruir no Studio) |
| **7. Dungeon** | Portão com círculo de grupo (1–4, 30 s); instância por grupo; inimigos, obstáculos e chefe; morte elimina; desconexão de 3 min; loot individual; baú a cada 20 h | 5, 6 | 🟡 código 13/10/2026; testar no Studio |
| **8. Voo e escavação** | Missão e poção de voo (uma por dragão, a partir de Jovem); voo com asas; voo ondulante do Dragão Asiático; "entrar na terra" do Wyrm | 3, 7 | 🟡 código 13/10/2026; testar no Studio |
| **9. PvP** | Zonas protegida/comum/perigosa com avisos; perda de até 40% dos materiais em zona perigosa; proteção de iniciante; 2 min ao renascer; anti-abuso de 30 min | 5, 6 | 🟡 código 13/10/2026; testar no Studio |
| **10. Ninhos e raridades** | Ninhos selvagens com dragão guardião; ovo de espécie aleatória; chances de raridade; ovos no baú da dungeon e no mercador; efeitos visuais, velocidade de voo e mecânicas extras por raridade; descoberta do Secreto | 5, 6, 8 | 🟡 código 13/10/2026; testar no Studio |
| **11. Fechamento da V1** | Teste completo do ciclo (`GAME-DESIGN.md` §16) em PC e celular; correções; desempenho; revisão contra exploits | todas | ⬜ |

### Arte (em paralelo, a partir da fase 2)

| Item | Estado |
|---|---|
| Modelos placeholder das 5 espécies (silhuetas básicas) | ⬜ |
| Protótipo de uma espécie em duas fases (ART-DIRECTION §11) | ⬜ |
| Portão de dungeon com círculo | ⬜ |
| Ovos das 5 espécies | ⬜ |
| Interface (HUD, inventário, ficha do dragão) em PC e celular | ⬜ |
| Modelos finais das 5 espécies × 6 fases | ⬜ |
| Efeitos de poderes por elemento e por raridade | ⬜ |

---

## Ordem sugerida

1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11.

A fase 6 (mundo) pode começar em paralelo a partir da fase 2, porque não
depende dos sistemas de jogo.
