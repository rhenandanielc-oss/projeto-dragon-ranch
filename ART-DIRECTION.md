# ART-DIRECTION.md
## Direção de arte — Jogo Roblox de Dragões
**Versão:** 0.1  
**Status:** Documento inicial de direção visual  
**Documento relacionado:** `GAME-DESIGN.md`

---

## 1. Objetivo

Definir uma identidade visual coerente para o jogo, para que o mundo, os dragões, as dungeons, os efeitos mágicos e a interface pareçam pertencer ao mesmo universo.

A prioridade é criar um mundo de fantasia vibrante e memorável, com paisagens que incentivem a exploração, dragões visualmente marcantes e magia colorida, mantendo o desempenho adequado para Roblox e diferentes dispositivos.

## 2. Legenda de decisões

- **APROVADO:** escolha expressamente definida pelo usuário.
- **PROPOSTA:** recomendação inicial que ainda pode ser alterada.
- **PENDENTE:** precisa de uma decisão futura.
- **FUTURO:** não faz parte obrigatória da primeira versão.

Não tratar propostas como decisões definitivas. Não começar a implementação visual completa antes de resolver as decisões essenciais que afetem os modelos, a câmera, o desempenho ou a estrutura do mundo.

## 3. Identidade visual do mundo

### 3.1 Paleta e atmosfera

- **APROVADO:** cores vibrantes.
- **APROVADO:** florestas verdes e cheias de vida.
- **APROVADO:** magia colorida.
- **APROVADO:** muitas paisagens diferentes.
- **APROVADO:** grandes montanhas e vistas panorâmicas.
- **PROPOSTA:** fantasia estilizada com acabamento visual caprichado — não totalmente realista, mas também não excessivamente infantil.
- **PROPOSTA:** combinar verdes naturais, azuis de rios e lagos, tons terrosos e pontos de cor mágica intensa.
- **PROPOSTA:** usar luz, neblina e contraste para criar profundidade sem esconder os caminhos importantes.

As cores mágicas devem destacar locais, habilidades e objetos importantes. Não usar brilho intenso em tudo: áreas comuns precisam de descanso visual para que cristais, runas, dragões e feitiços realmente chamem a atenção.

### 3.2 Paisagens e exploração

O mapa inicial deve ser uma região expansível, mas conter variedade visual suficiente para que explorar não pareça repetitivo.

**Elementos desejados:**
- Florestas densas com árvores de diferentes tamanhos, vegetação, flores e clareiras.
- Rios, lagos, quedas-d'água e pequenas praias ou margens.
- Campos abertos e prados coloridos.
- Grandes montanhas, picos altos, vales e penhascos.
- Mirantes naturais de onde seja possível apreciar a paisagem e reconhecer pontos do mapa.
- Cavernas, ruínas, cristais e áreas com sinais de magia.
- Caminhos, pontes, passagens e marcos visuais que ajudem o jogador a se orientar.
- Locais visualmente interessantes vistos de longe, para incentivar o jogador a chegar até eles.

**Regra de composição:** criar vistas com primeiro plano, plano intermediário e fundo. Por exemplo, vegetação ou rochas na frente, um vale ou floresta no meio e montanhas ao fundo. Evitar que todas as áreas sejam planas ou tenham a mesma silhueta.

### 3.3 Montanhas e vistas panorâmicas

As montanhas devem ser uma das características mais reconhecíveis do mundo.

**Diretrizes:**
- Usar silhuetas variadas: picos pontudos, paredes rochosas, montanhas cobertas de vegetação e áreas com neve ou névoa, se fizerem sentido para o bioma.
- Criar vales, cachoeiras e caminhos que conduzam o olhar.
- Incluir pontos de observação acessíveis a pé ou, mais tarde, pelo voo desbloqueado por missão.
- Garantir que os locais importantes sejam visualmente legíveis à distância.
- Evitar exagerar na geometria e na vegetação a ponto de prejudicar o desempenho.

O voo é uma recompensa de progressão; as paisagens devem ser especialmente interessantes vistas de cima, sem tornar o voo obrigatório para navegar em áreas iniciais.

## 4. Magia e efeitos visuais

### 4.1 Linguagem mágica

- **APROVADO:** magia colorida e visualmente marcante.
- **PROPOSTA:** combinar partículas, brilhos controlados, runas, cristais, rastros e pulsos de energia.
- **PROPOSTA:** atribuir uma identidade visual clara a cada elemento e espécie de dragão.
- **PROPOSTA:** usar cores e formas consistentes para comunicar perigo, cura, defesa, interação e recompensa.

Exemplos de paletas possíveis — ainda não definitivas:
- Fogo: vermelho, laranja e dourado.
- Gelo: azul-claro, branco e ciano.
- Natureza: verde, turquesa e dourado.
- Magia arcana: violeta, azul e rosa.

As cinco espécies e seus elementos foram aprovados em 12/10/2026 (ver `GAME-DESIGN.md` §4.2): Fogo, Eletricidade, Vento, Terra, Água e Chuva. As paletas de Gelo, Natureza e Magia arcana acima eram exemplos e não fazem parte dos elementos da V1; as paletas dos elementos aprovados ainda precisam ser definidas.

### 4.2 Legibilidade durante o combate

- Os efeitos precisam ser fáceis de distinguir durante o combate em tempo real.
- Evitar cobrir o personagem, o dragão inimigo ou os indicadores de vida com partículas.
- Usar impactos breves e claros para acertos, bloqueios, cura e ativação de habilidades.
- Oferecer uma alternativa visual mais leve para dispositivos com menor desempenho, se necessário.
- Efeitos de habilidades devem parecer poderosos sem dificultar a leitura da batalha.

## 5. Direção visual dos dragões

### 5.1 Diretriz geral

**PROPOSTA:** dragões de fantasia estilizados e detalhados, com anatomia expressiva, silhuetas reconhecíveis e animações que transmitam personalidade. Eles podem ter mais detalhes do que os elementos comuns do cenário, pois são o foco emocional e de progressão do jogador.

Cada espécie deve ser identificável pela silhueta, cabeça, chifres, asas, cauda, postura, paleta e efeitos — não apenas pela cor.

### 5.2 Seis fases de crescimento

O jogo mantém as seis fases aprovadas no documento principal:

1. Ovo
2. Bebê
3. Jovem
4. Pré-adulto
5. Adulto
6. Ancião

A aparência deve mudar de forma progressiva em cada fase:
- **Ovo:** forma, padrão e brilho próprios da espécie.
- **Bebê:** proporções pequenas, cabeça e olhos expressivos; movimentos simples.
- **Jovem:** corpo mais alongado, asas e chifres mais definidos.
- **Pré-adulto:** proporções próximas das adultas, mas com diferenças visíveis.
- **Adulto:** silhueta completa e presença visual forte.
- **Ancião:** sinais visuais de experiência, como padrões, marcas, chifres ou detalhes únicos, sem depender apenas de aumentar o tamanho.

Esses exemplos são propostas de linguagem visual; os modelos finais e as proporções precisam ser testados no Roblox Studio. As fases não devem parecer apenas o mesmo modelo redimensionado.

### 5.3 Animação e personalidade

**PROPOSTA:**
- Respiração e movimentos sutis enquanto o dragão está parado.
- Reações diferentes ao jogador, alimentação e interação.
- Animações distintas para andar, correr, atacar, receber dano, descansar e voar.
- Transições suaves entre animações para evitar movimentos bruscos.
- Efeitos de voo que reforcem a espécie, sem deixar um rastro permanente exagerado.

## 6. Fazenda

A fazenda deve transmitir aconchego e progresso: um lugar que o jogador reconhece como seu e deseja personalizar.

**PROPOSTA:**
- Materiais naturais, madeira, pedra, telhados coloridos e vegetação.
- Cercados, ninhos, áreas de alimentação e água visualmente fáceis de reconhecer.
- Caminhos e espaços organizados para facilitar a circulação.
- Elementos decorativos que não bloqueiem a câmera em terceira pessoa.
- Melhorias de instalações que sejam visíveis e comuniquem avanço.
- Paleta coerente com a região, mantendo os dragões em destaque.

Não encher a fazenda de objetos pequenos sem função. A decoração deve manter clareza, espaço de circulação e bom desempenho.

## 7. Mundo aberto e dungeons

### 7.1 Mundo aberto

A região inicial deve ter pontos de referência fortes, caminhos legíveis e paisagens que pareçam conectadas.

**PROPOSTA:**
- Usar diferenças de vegetação, rochas, iluminação e cor para distinguir subáreas.
- Criar silhuetas reconhecíveis para montanhas, árvores especiais, ruínas e construções.
- Posicionar locais de interesse de forma que possam ser avistados à distância quando adequado.
- Evitar repetir o mesmo conjunto de árvores, rochas e estruturas em todas as áreas.

### 7.2 Entradas físicas das dungeons

**APROVADO no design do jogo:** dungeons com entradas físicas no mundo aberto, portões grandes e um círculo no chão para reunir o grupo e interagir; cada grupo entra em sua própria instância.

**Direção visual proposta:**
- Portões grandes, antigos e visualmente distintos das construções comuns.
- Runas, cristais ou energia para comunicar que a entrada é mágica.
- Círculo de grupo fácil de identificar, sem ocupar desnecessariamente uma área enorme.
- Sinais visuais claros para indicar quando a entrada pode ser usada.
- Cada dungeon deve ter uma identidade própria, ligada ao seu tema e aos desafios encontrados.

A decoração não deve esconder o ponto de interação nem tornar confuso onde o grupo precisa ficar.

## 8. Interface (UI)

**PROPOSTA:** interface estilizada, legível e coerente com o universo de fantasia, sem imitar excessivamente uma interface medieval complexa.

A interface deve incluir, conforme os sistemas definidos no `GAME-DESIGN.md`:
- Vida e recursos relevantes para combate.
- Estado do dragão ativo e acesso aos outros dragões.
- Necessidades de cuidado, como alimentação e água, quando relevantes.
- Inventário, materiais, equipamentos e poções.
- Missões e objetivos.
- Indicadores de interação com objetos, NPCs e entradas de dungeon.
- Moeda e recompensas.

**Regras:**
- Priorizar legibilidade em telas pequenas.
- Não depender apenas de cor para comunicar estados.
- Usar ícones consistentes e textos curtos.
- Não cobrir a visão durante o combate ou o voo.
- Manter botões de toque confortáveis se houver suporte a dispositivos móveis.
- Testar a interface com a câmera em terceira pessoa.

## 9. Câmera, composição e leitura visual

**APROVADO no design do jogo:** câmera em terceira pessoa.

**Diretrizes propostas:**
- Manter o personagem e o dragão ativo visíveis em situações normais.
- Evitar vegetação, paredes e efeitos que ocultem o jogador por muito tempo.
- Testar áreas estreitas, interiores de dungeon, combates e mirantes.
- Usar a composição da paisagem para destacar destinos sem retirar o controle do jogador.
- Garantir que os dragões continuem reconhecíveis em diferentes distâncias.

## 10. Desempenho e otimização para Roblox

A qualidade visual deve ser alcançada com escolhas eficientes, não apenas com grande quantidade de polígonos e efeitos.

- Usar modelos e materiais com complexidade adequada ao dispositivo-alvo.
- Limitar partículas simultâneas em batalhas com vários jogadores e dragões.
- Evitar excesso de luzes dinâmicas, transparências e efeitos sobrepostos.
- Reutilizar recursos de forma inteligente sem tornar o cenário repetitivo.
- Testar a região com vários jogadores e dragões ativos.
- Definir níveis de detalhe e distância de renderização conforme necessário.
- Não presumir que um modelo ou efeito complexo terá bom desempenho antes de testá-lo no Roblox Studio.

## 11. Referências visuais e prototipagem

As referências devem orientar o estilo, mas não ser copiadas diretamente.

Antes de produzir o mapa inteiro, recomenda-se criar protótipos pequenos no Roblox Studio:
1. Uma clareira de floresta com vegetação e luz.
2. Um mirante com montanhas, vale e cachoeira.
3. Uma área mágica com cristais e efeitos coloridos.
4. Um portão de dungeon com círculo de grupo.
5. Um dragão em pelo menos duas fases de crescimento.
6. Uma tela de interface vista em computador e celular, se ambos forem suportados.

Avaliar consistência visual, leitura, desempenho e facilidade de implementação antes de expandir o conteúdo.

## 12. Decisões pendentes

- **PENDENTE:** confirmar oficialmente o estilo visual geral: fantasia estilizada premium, cartoon detalhado, low-poly ou semirrealista.
- **PENDENTE:** aprovar silhuetas e cores das cinco espécies (nomes e elementos já aprovados).
- **PENDENTE:** definir tema e subáreas da primeira região.
- **PENDENTE:** definir os dispositivos suportados na V1.
- **PENDENTE:** definir a quantidade de detalhe que o desempenho permite após prototipagem.
- **PENDENTE:** escolher referências visuais específicas para dragões, cenário, UI e efeitos.

## 13. Instruções para implementação com assistente de programação

Ao usar este documento com `GAME-DESIGN.md`:
- Tratar itens marcados **APROVADO** como requisitos.
- Tratar itens marcados **PROPOSTA** como sugestões que precisam de confirmação quando forem decisões importantes.
- Não inventar espécies, sistemas ou requisitos como se já tivessem sido aprovados.
- Não começar a implementação completa antes de resolver decisões pendentes que bloqueiem o trabalho.
- Propor protótipos pequenos e testáveis antes de construir grandes áreas.
- Separar modelos, animações, efeitos, interface e configuração sempre que isso facilitar manutenção.
- Priorizar clareza visual, consistência artística e desempenho em Roblox.
- Não prometer modelos 3D, animações ou efeitos profissionais apenas com prompts textuais; verificar quais recursos e ferramentas estão realmente disponíveis.

## 13.1 Recursos gerados por IA (12/10/2026)

O cenário do Hub e das fazendas usa modelos gerados por IA no Roblox
Studio, guardados em `ServerStorage.WorldAssets`: carvalho, pinheiro,
árvore folhosa, cerejeira, arbusto, ninho, arco de entrada, celeiro,
lanterna, chafariz com estátua de dragão, barraca de mercado e quadro de
missões. Os construtores (`tools/studio/*.luau`) clonam esses modelos.
Estilo: fantasia estilizada com detalhe, cores vibrantes, florestas verdes
e cerejeiras — coerente com §3.

## 14. Histórico de versões

- **0.1:** documento inicial; incorporadas as preferências aprovadas de cores vibrantes, florestas verdes, magia colorida, paisagens variadas e grandes montanhas com vistas panorâmicas.
- **0.2 (12/10/2026):** referências às espécies atualizadas para as cinco espécies aprovadas.
