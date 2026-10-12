# DRAGON-VISUAL-DESIGN.md
## Especificação visual dos dragões por fase de crescimento
**Versão:** 0.1  
**Documento relacionado:** `GAME-DESIGN.md` e `ART-DIRECTION.md`  
**Status:** Estrutura visual inicial; detalhes das três espécies ainda precisam ser aprovados.

---

## 1. Objetivo deste documento

Este documento especifica como os dragões devem parecer em cada uma das seis fases de crescimento, servindo de referência para concept art, modelagem 3D, texturas, rigging, animações e implementação no Roblox Studio.

O objetivo é garantir que:
- Cada dragão continue reconhecível como a mesma espécie durante toda a vida.
- Cada fase tenha uma aparência própria, e não seja apenas o mesmo modelo ampliado.
- O crescimento pareça gradual e recompensador.
- Os dragões sejam visualmente marcantes, expressivos e adequados ao estilo de fantasia do jogo.
- Modelos, materiais, animações e efeitos sejam legíveis e otimizados para Roblox.

Este arquivo complementa a direção de arte geral. Não substitui as regras de gameplay do `GAME-DESIGN.md`.

## 2. Legenda de decisões

- **APROVADO:** requisito já definido pelo usuário.
- **PROPOSTA:** recomendação visual inicial ainda sujeita a aprovação.
- **PENDENTE:** precisa ser definido antes de fechar o design final.
- **FUTURO:** pode ser desenvolvido depois da V1.

Não apresentar propostas como decisões aprovadas. O número de espécies iniciais (três) está aprovado; a lista final de elementos, os nomes das espécies e a distribuição de raridades ainda precisam ser confirmados.

## 3. Regras gerais de identidade dos dragões

### 3.1 Estilo

- **APROVADO:** o mundo do jogo terá cores vibrantes, florestas verdes, magia colorida, muitas paisagens e grandes montanhas com vistas panorâmicas.
- **PROPOSTA:** dragões de fantasia estilizados e detalhados, com anatomia expressiva e silhuetas fortes, combinando com o mundo vibrante sem tentar reproduzir animais realistas em todos os detalhes.
- **PENDENTE:** confirmação definitiva do estilo dos próprios dragões.

### 3.2 Identidade de cada espécie

Cada espécie precisa ser identificada mesmo quando aparece apenas como silhueta. Não diferenciar espécies apenas trocando a cor do mesmo modelo.

Para cada espécie, definir:
- Formato e comprimento do corpo.
- Formato da cabeça e do focinho.
- Olhos, sobrancelhas ou placas expressivas.
- Chifres, cristas, espinhos e orelhas, se houver.
- Formato, proporção e estrutura das asas.
- Comprimento e formato da cauda.
- Número e proporção das patas.
- Padrões de escamas, placas, penas ou outras superfícies.
- Cores principais, secundárias e de destaque.
- Efeito mágico ou elemento visual.
- Movimento característico e postura.

### 3.3 Continuidade durante o crescimento

As seis fases devem pertencer claramente à mesma espécie. Ao crescer, o dragão pode ganhar novas proporções e detalhes, mas deve manter os traços que o identificam: cabeça, padrão de cores, formato básico das asas, cauda e marcas características.

**Regra:** não alterar aleatoriamente a paleta, o formato da cabeça ou a anatomia central entre as fases.

### 3.4 Leitura em jogo

- O dragão deve ser reconhecível de perto e à distância.
- A silhueta deve continuar legível em cenários verdes, montanhosos e coloridos.
- As partículas mágicas não devem esconder o corpo.
- Materiais e texturas devem continuar claros sob diferentes condições de iluminação.
- Evitar detalhes tão pequenos que desapareçam durante o jogo.
- Os modelos precisam ser testados com a câmera em terceira pessoa.

---

## 3.5 Identificação, elementos e raridade

### Status das decisões
- **APROVADO:** três espécies na V1, com possibilidade de adicionar outras em atualizações.
- **PROPOSTA SELECIONADA PARA AVALIAÇÃO:** cinco elementos no sistema inicial.
- **PROPOSTA SELECIONADA PARA AVALIAÇÃO:** sete níveis de raridade, incluindo uma raridade secreta acima de Mítico.
- **PROPOSTA SELECIONADA PARA AVALIAÇÃO:** cada indivíduo terá o nome oficial da espécie e um nome personalizado escolhido pelo jogador.
- **PROPOSTA SELECIONADA PARA AVALIAÇÃO:** raridade influenciará principalmente dificuldade de obtenção, aparência e efeitos visuais, não poder de combate garantido.

### Elementos candidatos
A lista abaixo é apenas uma proposta de trabalho, não uma decisão final: **Fogo, Água, Natureza, Gelo e Raio**. A lista precisa ser confirmada antes de associar elementos às três espécies iniciais.

### Raridades candidatas
A sequência de trabalho é **Comum → Incomum → Raro → Épico → Lendário → Mítico → Secreto**. Os nomes, a ordem, as probabilidades e os métodos de obtenção ainda precisam de aprovação. A raridade secreta deve ser descoberta de maneira especial, mas sua regra concreta permanece pendente.

### Regra visual da raridade
- A raridade pode ser comunicada por moldura, ícone, brilho ou efeitos visuais controlados na interface e na apresentação do dragão.
- Não alterar a identidade da espécie apenas para indicar raridade.
- Variantes raras podem ter padrões, detalhes, materiais ou efeitos especiais, desde que a leitura da espécie continue clara.
- Não aplicar brilho intenso permanente a todos os dragões raros; reservar os efeitos mais chamativos para momentos e variantes especiais.
- A raridade não deve, por si só, tornar um dragão visualmente ilegível ou significativamente mais forte em combate.

### Nome oficial e nome personalizado
A interface deverá distinguir o nome da espécie do apelido do indivíduo. Exemplo de apresentação: **[Nome personalizado] — [Nome da espécie]**. O formato exato da interface ainda é uma proposta. O nome personalizado não substitui nem altera a espécie, o elemento ou a raridade.

### Consequência para as fichas das espécies
Cada uma das três fichas deve incluir: nome oficial da espécie, elemento proposto/aprovado, silhueta, cores, traços anatômicos, efeito característico e como esses elementos visuais evoluem nas seis fases. Até a lista final ser aprovada, não atribuir definitivamente um dos cinco elementos candidatos a uma espécie específica.

## 4. Fase 1 — Ovo

### Objetivo visual
O ovo deve despertar curiosidade e permitir que o jogador reconheça a espécie antes da eclosão.

### Forma e proporção
- Silhueta simples e fácil de reconhecer.
- **PROPOSTA:** formato oval com pequenas diferenças entre espécies; evitar que todos os ovos sejam idênticos.
- O tamanho deve ser coerente com o tamanho esperado do dragão adulto, sem exigir uma escala literal exata.

### Superfície e detalhes
- Casca com material próprio, padrões e marcas que indiquem a espécie.
- Pequenas manchas, linhas, placas ou desenhos podem sugerir as escamas e cores do dragão.
- Brilho mágico discreto, se fizer sentido para a espécie.
- Evitar efeitos luminosos intensos permanentes.

### Cor
Cada ovo deve usar as cores associadas à sua espécie. A cor não deve ser a única forma de distingui-los: padrões e silhuetas também precisam ajudar.

### Animação e efeitos
- Movimento de balanço ou tremor em momentos específicos.
- Pequenas rachaduras ou pulsos de luz perto da eclosão, se essa mecânica for usada.
- O efeito de eclosão deve ser legível, breve e otimizado.

### Critérios de aprovação
- É possível distinguir os ovos das três espécies sem depender apenas do nome exibido.
- O ovo é visualmente interessante mesmo parado.
- O padrão do ovo combina com a aparência futura do dragão.

---

## 5. Fase 2 — Bebê

### Objetivo visual
Transmitir descoberta, vulnerabilidade e personalidade, mantendo características claras da espécie.

### Proporções
**PROPOSTA:**
- Cabeça relativamente grande em comparação com o corpo.
- Olhos expressivos.
- Corpo pequeno e compacto.
- Patas curtas ou ainda desproporcionais.
- Asas pequenas, se a espécie tiver asas.
- Cauda curta ou ainda fina.

Essas proporções são uma orientação, não uma regra universal: espécies diferentes podem ter corpos longos, robustos ou leves.

### Cabeça e rosto
- Expressões fáceis de perceber à distância normal de interação.
- Focinho, chifres e cristas já indicam a espécie, mas em tamanho reduzido.
- Evitar dentes, espinhos ou placas que façam o bebê parecer adulto em miniatura.

### Superfície e cor
- Manter a paleta da espécie.
- Padrões de escamas simplificados e maiores, para continuarem visíveis.
- Texturas limpas; evitar excesso de detalhes minúsculos.

### Animações
**PROPOSTA:**
- Passos curtos e movimentos curiosos.
- Olhar ao redor e inclinar a cabeça.
- Reação à aproximação e à alimentação.
- Descanso com postura compacta.
- Pequenas reações ao receber carinho ou interação, caso essas ações existam no jogo.

### Critérios de aprovação
- A fase parece jovem, e não apenas pequena.
- A personalidade é transmitida por postura e movimento.
- O bebê continua identificável como sua espécie.

---

## 6. Fase 3 — Jovem

### Objetivo visual
Mostrar crescimento perceptível, curiosidade e maior capacidade física, sem ainda ter a presença de um adulto.

### Proporções
**PROPOSTA:**
- Tronco e pescoço mais alongados.
- Patas maiores e postura mais firme.
- Cauda mais comprida e funcional para o equilíbrio.
- Asas mais desenvolvidas, quando aplicável.
- Chifres, cristas, espinhos ou placas mais definidos.
- Cabeça ainda relativamente grande, mas menos infantil que na fase bebê.

### Superfície e detalhes
- Padrões da espécie tornam-se mais complexos.
- Escamas e placas podem começar a formar camadas visíveis.
- Marcas de cor podem surgir ou ficar mais evidentes, desde que continuem coerentes com o design aprovado da espécie.

### Animações
**PROPOSTA:**
- Corrida mais rápida e movimentos mais coordenados.
- Alongamento das asas e exercícios de equilíbrio.
- Reações mais confiantes ao ambiente.
- Ataques de treino ou demonstrações de poder, sem conceder habilidades antes de serem desbloqueadas no gameplay.

### Critérios de aprovação
- A diferença em relação ao bebê é clara mesmo sem comparar o tamanho.
- O dragão parece mais coordenado, mas ainda em desenvolvimento.
- Os traços principais da espécie continuam presentes.

---

## 7. Fase 4 — Pré-adulto

### Objetivo visual
Representar a transição entre juventude e maturidade. Deve parecer poderoso em desenvolvimento, mas não totalmente adulto.

### Proporções
**PROPOSTA:**
- Corpo próximo das proporções adultas.
- Ombros, peito, patas e cauda mais robustos ou definidos conforme a espécie.
- Asas próximas do tamanho funcional adulto, se a espécie voar.
- Chifres, cristas, placas e espinhos em fase avançada de crescimento.
- Cabeça com proporções mais maduras.

### Superfície e detalhes
- Escamas, placas e padrões com definição maior.
- Marcas da espécie mais evidentes.
- Pequenas diferenças visuais individuais podem existir, desde que não substituam a identidade central da espécie.

### Animações
**PROPOSTA:**
- Postura mais firme e confiante.
- Movimentos de preparação para combate.
- Abertura completa das asas, quando aplicável.
- Gestos que transmitam força crescente.

### Critérios de aprovação
- Não parece apenas uma versão adulta reduzida.
- Mantém algum sinal visual de crescimento incompleto.
- A passagem para adulto pode ser percebida em proporções, detalhes e animações.

---

## 8. Fase 5 — Adulto

### Objetivo visual
Ser a representação completa e emblemática da espécie: poderoso, reconhecível e visualmente recompensador.

### Proporções
- Anatomia completa e coerente com a espécie.
- Silhueta forte, legível e única.
- Cabeça, tronco, patas, asas e cauda em proporções finais.
- Chifres, cristas, placas ou outros traços característicos no seu desenvolvimento adulto.

### Superfície e materiais
- Maior riqueza de materiais e padrões do que nas fases iniciais, sem depender de microdetalhes.
- Diferenças claras entre partes do corpo quando forem importantes para a leitura.
- Acabamentos compatíveis com a espécie: escamas, placas, membranas de asas ou outras superfícies aprovadas.
- Não usar reflexos ou brilho excessivos em toda a superfície.

### Animações
**PROPOSTA:**
- Ciclo de repouso com respiração e pequenos movimentos.
- Caminhada e corrida com peso perceptível.
- Ataques com antecipação, impacto e recuperação.
- Reações ao dano que não interrompam visualmente toda a batalha.
- Animação de voo e pouso, caso o voo esteja desbloqueado para o jogador.
- Interações com o jogador e com a fazenda.

### Efeitos
- Habilidades com cores e formas ligadas à identidade da espécie.
- Efeitos concentrados na origem e na trajetória da habilidade.
- O efeito não deve cobrir continuamente a silhueta inteira.

### Critérios de aprovação
- É a versão visualmente completa da espécie.
- É possível reconhecer a espécie em uma captura de tela sem interface.
- O modelo funciona de perto, em combate e à distância.

---

## 9. Fase 6 — Ancião

### Objetivo visual
Comunicar experiência, idade e distinção, sem depender apenas de ser maior do que o adulto.

### Proporções e postura
**PROPOSTA:**
- Manter a anatomia adulta, com diferenças de postura e detalhes.
- Pode ter uma presença mais imponente, mas o tamanho adicional não é obrigatório.
- A postura pode ser mais calma e deliberada; não fazer todos os anciões parecerem frágeis.

### Marcas de idade
Escolher apenas marcas que combinem com a espécie:
- Chifres ou cristas com formas mais elaboradas.
- Escamas, placas ou padrões únicos.
- Marcas naturais, cicatrizes ou alterações de pigmentação.
- Pequenos sinais de energia mágica em pontos específicos.
- Texturas mais variadas em regiões selecionadas.

Esses sinais não devem transformar todos os anciões em dragões brancos ou cinzentos. A paleta original da espécie deve continuar reconhecível.

### Animações
**PROPOSTA:**
- Movimentos deliberados e seguros.
- Postura de repouso distinta.
- Gestos que transmitam domínio e experiência.
- Animações de habilidade com presença visual forte, mas sem exigir partículas excessivas.

### Critérios de aprovação
- Parece antigo e experiente, não apenas adulto com escala maior.
- Mantém as cores e os traços essenciais da espécie.
- As marcas de idade não dificultam a leitura da silhueta.

---

## 10. Matriz resumida das seis fases

| Fase | Impressão principal | Mudança visual mais importante |
|---|---|---|
| Ovo | Mistério e expectativa | Casca, padrões e sinais da espécie |
| Bebê | Curiosidade e vulnerabilidade | Cabeça expressiva, corpo compacto e movimentos curiosos |
| Jovem | Crescimento e energia | Corpo mais alongado, membros e asas em desenvolvimento |
| Pré-adulto | Força em formação | Proporções quase adultas, mas ainda em transição |
| Adulto | Poder e identidade completa | Anatomia madura e silhueta emblemática |
| Ancião | Experiência e distinção | Marcas de idade, detalhes únicos e postura experiente |

---

## 11. Fichas das três espécies iniciais

As três espécies iniciais estão aprovadas como quantidade; os nomes, elementos definitivos e aparências ainda estão **PENDENTES**. Preencher cada ficha depois de confirmar a lista final de elementos e o conceito de cada espécie.

### Espécie 1 — [nome pendente]

- **Nome oficial da espécie:** PENDENTE
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elemento/poder principal:** PENDENTE — escolher somente após aprovação da lista final de elementos
- **Raridade:** definida na obtenção conforme tabela de raridades a aprovar
- **Silhueta:** PENDENTE
- **Cabeça e focinho:** PENDENTE
- **Asas:** PENDENTE
- **Patas e corpo:** PENDENTE
- **Cauda:** PENDENTE
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: definir crescimento de corpo, membros e detalhes.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 2 — [nome pendente]

- **Nome oficial da espécie:** PENDENTE
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elemento/poder principal:** PENDENTE — escolher somente após aprovação da lista final de elementos
- **Raridade:** definida na obtenção conforme tabela de raridades a aprovar
- **Silhueta:** PENDENTE
- **Cabeça e focinho:** PENDENTE
- **Asas:** PENDENTE
- **Patas e corpo:** PENDENTE
- **Cauda:** PENDENTE
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: definir crescimento de corpo, membros e detalhes.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 3 — [nome pendente]

- **Nome oficial da espécie:** PENDENTE
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elemento/poder principal:** PENDENTE — escolher somente após aprovação da lista final de elementos
- **Raridade:** definida na obtenção conforme tabela de raridades a aprovar
- **Silhueta:** PENDENTE
- **Cabeça e focinho:** PENDENTE
- **Asas:** PENDENTE
- **Patas e corpo:** PENDENTE
- **Cauda:** PENDENTE
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: definir crescimento de corpo, membros e detalhes.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

---

## 12. Modelagem, rigging e implementação

### 12.1 Organização dos modelos

**PROPOSTA:**
- Organizar os recursos por espécie e fase de crescimento.
- Manter nomes consistentes para modelos, rigs, animações, materiais e efeitos.
- Reutilizar materiais e partes quando isso não tornar as espécies visualmente iguais.
- Separar os efeitos de habilidades do modelo principal sempre que possível.
- Evitar dependências frágeis entre o modelo e a lógica de gameplay.

### 12.2 Rig e animações

O rig deve permitir, conforme a anatomia de cada espécie:
- Movimento da cabeça e pescoço.
- Movimento do tronco.
- Patas e locomoção.
- Cauda.
- Asas, se existirem.
- Mandíbula ou partes faciais, se forem necessárias.
- Transições entre repouso, movimento, combate e voo.

A complexidade do rig precisa ser validada com um protótipo no Roblox Studio. Não presumir que toda animação complexa será fácil de produzir ou terá bom desempenho.

### 12.3 Desempenho

- Limitar polígonos, materiais e partículas de acordo com os dispositivos-alvo.
- Evitar transparências sobrepostas em excesso nas asas e nos efeitos.
- Testar vários dragões simultaneamente no mesmo local.
- Verificar legibilidade em telas pequenas.
- Criar níveis de detalhe ou simplificações quando necessário.
- Não sacrificar a silhueta essencial para reduzir detalhes.

---

## 13. Lista de verificação de aprovação de cada dragão

Antes de aprovar um modelo, verificar:

- [ ] A espécie é reconhecível pela silhueta.
- [ ] As cores e padrões combinam com a ficha da espécie.
- [ ] A fase de crescimento é identificável sem depender apenas do tamanho.
- [ ] Cabeça, asas, patas, cauda e detalhes são coerentes entre as seis fases.
- [ ] O dragão se destaca do cenário sem cores ou brilhos excessivos.
- [ ] A câmera em terceira pessoa não esconde partes essenciais do modelo.
- [ ] As animações parecem adequadas à idade e à anatomia.
- [ ] Os efeitos de combate não encobrem o dragão ou os adversários.
- [ ] O modelo foi testado no Roblox Studio com outros personagens e dragões.
- [ ] O desempenho é aceitável para os dispositivos suportados.

---

## 14. Próximas decisões necessárias

1. Confirmar o estilo visual dos dragões: fantasia estilizada e detalhada, cartoon, low-poly ou semirrealista.
2. Definir os nomes e os conceitos das três espécies iniciais.
3. Confirmar a lista final dos cinco elementos e associar um elemento a cada espécie (ou definir se haverá combinações).
4. Confirmar os sete níveis de raridade, incluindo o nome e o método de obtenção da raridade secreta.
5. Escolher as silhuetas, cores e características que diferenciam as espécies.
6. Criar primeiro um modelo de referência de uma espécie em duas fases bem distintas.
7. Validar o estilo e o desempenho no Roblox Studio antes de produzir as seis fases das três espécies.

## 15. Instruções para assistentes de programação e arte

Ao usar este arquivo:
- Respeitar as seis fases aprovadas e as decisões de `GAME-DESIGN.md`.
- Usar `ART-DIRECTION.md` para manter coerência com o mundo.
- Não inventar os detalhes pendentes das três espécies como se tivessem sido aprovados.
- Apresentar propostas de design para aprovação antes de multiplicar modelos e animações.
- Garantir continuidade visual entre fases.
- Recomendar protótipos pequenos antes de criar todos os recursos.
- Não começar a programar sistemas de gameplay apenas porque este documento descreve a aparência dos dragões.
- Separar decisões visuais de regras de crescimento, combate e progressão.

## 16. Histórico de versões

- **0.1:** criada a estrutura de design visual para as seis fases; detalhes finais das três espécies permanecem pendentes.
