# DRAGON-VISUAL-DESIGN.md
## Especificação visual dos dragões por fase de crescimento
**Versão:** 0.2  
**Documento relacionado:** `GAME-DESIGN.md` e `ART-DIRECTION.md`  
**Status:** Estrutura visual inicial; nomes e elementos das cinco espécies aprovados; aparências ainda precisam ser aprovadas.

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

Não apresentar propostas como decisões aprovadas. As cinco espécies iniciais e seus elementos estão aprovados; raridades aprovadas; aparências ainda precisam ser confirmadas.

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
- **APROVADO (12/10/2026):** cinco espécies na V1, com possibilidade de adicionar outras em atualizações.
- **APROVADO (12/10/2026):** elementos Fogo, Eletricidade, Vento, Terra, Água e Chuva, distribuídos conforme a seção 11.
- **APROVADO:** sete níveis de raridade, incluindo Secreto acima de Mítico.
- **PROPOSTA SELECIONADA PARA AVALIAÇÃO:** cada indivíduo terá o nome oficial da espécie e um nome personalizado escolhido pelo jogador.
- **APROVADO (12/10/2026):** a raridade muda muito o dragão — ataques e voo muito mais bonitos, voo mais rápido e mecânicas de combate extras (ver `GAME-DESIGN.md` §4.2).

### Elementos
**APROVADO:** Fogo, Eletricidade, Vento, Terra, Água e Chuva. A lista candidata anterior (Fogo, Água, Natureza, Gelo e Raio) foi substituída. **APROVADO:** Água (mar, rios) e Chuva (chuva, tempestades, raios) são distintas. Espécies com dois elementos têm poderes combinados e poderes separados de cada elemento; os efeitos visuais precisam mostrar as três variações.

### Raridades
**APROVADO:** Comum → Incomum → Raro → Épico → Lendário → Mítico → Secreto. Chances e obtenção em `GAME-DESIGN.md` §4.2. O Secreto só é obtido por descoberta especial.

### Regra visual da raridade
- A raridade pode ser comunicada por moldura, ícone, brilho ou efeitos visuais controlados na interface e na apresentação do dragão.
- Não alterar a identidade da espécie apenas para indicar raridade.
- Variantes raras podem ter padrões, detalhes, materiais ou efeitos especiais, desde que a leitura da espécie continue clara.
- Não aplicar brilho intenso permanente a todos os dragões raros; reservar os efeitos mais chamativos para momentos e variantes especiais.
- A raridade não deve tornar o dragão visualmente ilegível.
- Cada raridade acima de Comum precisa de uma versão visual própria dos poderes e do rastro de voo, cada vez mais impressionante; Lendário, Mítico e Secreto devem ser claramente espetaculares, sem esconder a silhueta.

### Nome oficial e nome personalizado
A interface deverá distinguir o nome da espécie do apelido do indivíduo. Exemplo de apresentação: **[Nome personalizado] — [Nome da espécie]**. O formato exato da interface ainda é uma proposta. O nome personalizado não substitui nem altera a espécie, o elemento ou a raridade.

### Consequência para as fichas das espécies
Cada uma das cinco fichas deve incluir: nome oficial da espécie, elementos, silhueta, cores, traços anatômicos, efeito característico e como esses elementos visuais evoluem nas seis fases.

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
- É possível distinguir os ovos das cinco espécies sem depender apenas do nome exibido.
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

## 11. Fichas das cinco espécies iniciais

**APROVADO (12/10/2026):** cinco espécies com seus elementos. As silhuetas abaixo seguem a anatomia tradicional de cada tipo e são **PROPOSTA** até aprovação; a referência de anatomia é a imagem enviada pelo responsável (usar só como referência de forma, sem copiar a arte).

| Espécie | Elementos | Asas | Patas |
|---|---|---|---|
| Wyvern | Fogo / Eletricidade | Sim (são os braços) | 2 |
| Dragão Ocidental | Fogo | Sim | 4 |
| Amphiptere | Vento / Fogo | Sim | 0 |
| Wyrm | Terra / Água | Não | 0 |
| Dragão Asiático | Água / Chuva | Não | 4 |

As cinco silhuetas já são bem diferentes entre si, o que atende à regra 3.2.

### Espécie 1 — Wyvern

- **Nome oficial da espécie:** Wyvern (APROVADO)
- **Papel no combate:** Atacante aéreo — dano explosivo, mergulhos rápidos (APROVADO) — a silhueta e a postura devem comunicar esse papel
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elementos:** Fogo / Eletricidade (APROVADO)
- **Raridade:** definida na obtenção (ver tabela em `GAME-DESIGN.md` §4.2)
- **Silhueta (PROPOSTA, baseada na anatomia tradicional do tipo):** bípede; as asas funcionam como membros dianteiros; postura inclinada para a frente.
- **Cabeça e focinho:** PROPOSTA: cabeça angulosa, com chifres voltados para trás.
- **Asas:** Grandes asas membranosas, que também servem de apoio no chão.
- **Patas e corpo:** Duas patas traseiras fortes; tronco compacto.
- **Cauda:** Longa, fina, possivelmente com ponta em espinho.
- **Voo:** Asas — voo convencional.
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE — devem refletir os elementos
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE — ligado aos elementos
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: já bem maior que o jogador; precisa ter porte crível para voar com o jogador.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 2 — Dragão Ocidental

- **Nome oficial da espécie:** Dragão Ocidental (APROVADO)
- **Papel no combate:** Força bruta — mais vida e dano direto (APROVADO) — a silhueta e a postura devem comunicar esse papel
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elementos:** Fogo (APROVADO)
- **Raridade:** definida na obtenção (ver tabela em `GAME-DESIGN.md` §4.2)
- **Silhueta (PROPOSTA, baseada na anatomia tradicional do tipo):** quadrúpede robusto com um par de asas nas costas; silhueta clássica de dragão.
- **Cabeça e focinho:** PROPOSTA: cabeça grande, mandíbula forte, chifres e cristas proeminentes.
- **Asas:** Par de asas membranosas grandes, separado das patas.
- **Patas e corpo:** Quatro patas fortes; peito largo.
- **Cauda:** Longa e grossa, com espinhos ou placas.
- **Voo:** Asas — voo convencional.
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE — devem refletir os elementos
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE — ligado aos elementos
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: já bem maior que o jogador; precisa ter porte crível para voar com o jogador.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 3 — Amphiptere

- **Nome oficial da espécie:** Amphiptere (APROVADO)
- **Papel no combate:** Mobilidade — o mais rápido no ar, rajadas que empurram (APROVADO) — a silhueta e a postura devem comunicar esse papel
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elementos:** Vento / Fogo (APROVADO)
- **Raridade:** definida na obtenção (ver tabela em `GAME-DESIGN.md` §4.2)
- **Silhueta (PROPOSTA, baseada na anatomia tradicional do tipo):** corpo de serpente com asas; sem patas.
- **Cabeça e focinho:** PROPOSTA: cabeça pequena e aerodinâmica, cristas leves.
- **Asas:** Um par de asas (membranosas ou emplumadas), principal traço da silhueta.
- **Patas e corpo:** Sem patas; corpo longo e esguio.
- **Cauda:** Longa, contínua com o corpo.
- **Voo:** Asas — voo ágil, combina com o elemento Vento.
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE — devem refletir os elementos
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE — ligado aos elementos
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: já bem maior que o jogador; precisa ter porte crível para voar com o jogador.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 4 — Wyrm

- **Nome oficial da espécie:** Wyrm (APROVADO)
- **Papel no combate:** Defesa e emboscada — muito rápido em terra, ataques saindo do chão (APROVADO) — a silhueta e a postura devem comunicar esse papel
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elementos:** Terra / Água (APROVADO)
- **Raridade:** definida na obtenção (ver tabela em `GAME-DESIGN.md` §4.2)
- **Silhueta (PROPOSTA, baseada na anatomia tradicional do tipo):** serpente gigante, corpo grosso e enrolado; sem asas e sem patas.
- **Cabeça e focinho:** PROPOSTA: cabeça massiva, mandíbula larga, aspecto de criatura escavadora.
- **Asas:** Nenhuma (na anatomia tradicional).
- **Patas e corpo:** Sem patas; corpo grosso e pesado.
- **Cauda:** Contínua com o corpo.
- **Voo:** não voa (APROVADO). É muito rápido em terra — mais rápido em solo que as espécies voadoras. A animação de corrida/deslizamento deve transmitir essa velocidade. No estágio Jovem, por missão, desbloqueia **entrar na terra**: precisa de animação de mergulho no solo, deslocamento subterrâneo (rastro de terra na superfície) e saída.
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE — devem refletir os elementos
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE — ligado aos elementos
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: já bem maior que o jogador; precisa ter porte crível para voar com o jogador.
- Pré-adulto: definir transição para as proporções adultas.
- Adulto: definir modelo de referência principal da espécie.
- Ancião: definir marcas de idade que preservem sua identidade.

### Espécie 5 — Dragão Asiático

- **Nome oficial da espécie:** Dragão Asiático (APROVADO)
- **Papel no combate:** Área e suporte — tempestades em área, chuva que cura aliados (APROVADO) — a silhueta e a postura devem comunicar esse papel
- **Nome personalizado pelo jogador:** permitido para cada indivíduo; formato de interface PENDENTE
- **Elementos:** Água / Chuva (APROVADO)
- **Raridade:** definida na obtenção (ver tabela em `GAME-DESIGN.md` §4.2)
- **Silhueta (PROPOSTA, baseada na anatomia tradicional do tipo):** corpo serpentino muito longo, com quatro patas curtas; sem asas.
- **Cabeça e focinho:** PROPOSTA: focinho alongado, bigodes, chifres ramificados, juba.
- **Asas:** Nenhuma (na anatomia tradicional, voa por magia).
- **Patas e corpo:** Quatro patas curtas com garras; corpo longo e ondulante.
- **Cauda:** Longa, contínua com o corpo, com tufo ou juba na ponta.
- **Voo:** voa sem asas, ondulando o corpo de um lado para o outro (APROVADO). A animação de voo é a principal marca da espécie.
- **Chifres/cristas/espinhos:** PENDENTE
- **Cores principais e secundárias:** PENDENTE — devem refletir os elementos
- **Padrão de escamas/superfície:** PENDENTE
- **Efeito mágico característico:** PENDENTE — ligado aos elementos
- **Animação ou postura característica:** PENDENTE

**Progressão visual por fase**
- Ovo: definir padrão da casca ligado à espécie.
- Bebê: definir versão compacta e expressiva dos traços principais.
- Jovem: já bem maior que o jogador; precisa ter porte crível para voar com o jogador.
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
2. ~~Definir os nomes das espécies~~ (resolvido: cinco espécies). Aprovar as silhuetas propostas na seção 11.
3. ~~Associar elementos às espécies~~ e ~~locomoção do Wyrm e do Dragão Asiático~~ (resolvidos).
4. ~~Confirmar raridades~~ (resolvido). Definir o visual de poderes e voo para cada raridade.
5. Escolher as silhuetas, cores e características que diferenciam as espécies.
6. Criar primeiro um modelo de referência de uma espécie em duas fases bem distintas.
7. Validar o estilo e o desempenho no Roblox Studio antes de produzir as seis fases das cinco espécies.

## 15. Instruções para assistentes de programação e arte

Ao usar este arquivo:
- Respeitar as seis fases aprovadas e as decisões de `GAME-DESIGN.md`.
- Usar `ART-DIRECTION.md` para manter coerência com o mundo.
- Não inventar os detalhes pendentes das cinco espécies como se tivessem sido aprovados.
- Apresentar propostas de design para aprovação antes de multiplicar modelos e animações.
- Garantir continuidade visual entre fases.
- Recomendar protótipos pequenos antes de criar todos os recursos.
- Não começar a programar sistemas de gameplay apenas porque este documento descreve a aparência dos dragões.
- Separar decisões visuais de regras de crescimento, combate e progressão.

## 16. Histórico de versões

- **0.1:** criada a estrutura de design visual para as seis fases; detalhes finais das três espécies permanecem pendentes.
- **0.2 (12/10/2026):** cinco espécies (Wyvern, Dragão Ocidental, Amphiptere, Wyrm, Dragão Asiático) com elementos aprovados; fichas reescritas com anatomia-base proposta.
