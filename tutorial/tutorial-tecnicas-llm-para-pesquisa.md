# Introdução prática: Técnicas com LLM (Python)

Neste notebook em python vamos utilizar exemplos simples de como utilizar LLMs para diferentes tarefas de dados textuais. Em contextos de pesquisa podemos aplicar as mesmas técnicas para diversos fins de organização, preparação ou classificação do *corpus* e nosso próximo passo seguinte, no próximo encontro, será a sua aplicação a dados obtidos via API da Câmara dos Deputados.

Em todos os exemplos vamos utilizar modelos disponíveis na plataforma Hugging Face, preferencialmente modelos treinados para português. A Hugging Face é uma plataforma aberta voltada para aprendizado de máquina, que funciona como um “hub” de modelos e datasets, dentre os quais muitos modelos de LLM desenvolvidos por grandes empressa de tecnologia. Lá, pesquisadores e desenvolvedores publicam modelos pré-treinados (como BERT, GPT, etc.), com documentação e código de exemplo, o que permite que outras pessoas reutilizem e adaptem esses modelos facilmente em seus próprios projetos, sem precisar treinar o modelo, tarefa computacionalmente muito custosa e, portanto, cara.

Para cada um dos exemplos vamos apresentar:

* **Funcionamento:** explicação intuitiva do funcionamento
* **Escolha do modelo:** razão para escolha do modelo.
* **Modelo:** explicação técnica do modelo.
* **Código:** um exemplo pequeno que roda em CPU em poucas amostras.

---

## Instalação de Pacotes

Antes de iniciar os exemplos, instale os seguintes pacotes:

```{r}
# Instalação de pacotes em R e Python via reticulate
# install.packages("reticulate")

library(reticulate)
use_python("/usr/bin/python3", required = TRUE)

# Cria/usa um ambiente Python e instala os pacotes necessários:
# py_install(c(
#   "transformers",
#   "sentence-transformers",
#   "datasets",
#   "accelerate",
#   "torch",
#   "bertopic"
# ))
#
# Se precisar de versão CPU-only do PyTorch, siga as instruções do site:
# https://pytorch.org/get-started/locally/
```

**Escolha do modelo.** Usamos `all-MiniLM-L6-v2` pelos embeddings rápidos e robustos em CPU, com boa qualidade para tópicos em português simples. Em domínios específicos, troque por um encoder multilíngue ou treinado no seu domínio.

---

## 1) Named Entity Recognition (NER)

#### Funcionamento

Modelos de NER tem como objetivo identificar e classificar, dentro de um texto, quais palavras ou grupos de palavras são “entidades nomeadas”, tais como pessoas, organizações, lugares, datas, leis, etc. O texto é dividio em palavras (*tokens*) e cada palavra é classificada como:

B-PER, I-PER – início/interior de um nome de pessoa

B-ORG, I-ORG – início/interior de um nome de organização

B-LOC, I-LOC – início/interior de um nome de localidade

O – token que não faz parte de nenhuma entidade

*B* e *I* indicam "início" e "interior" do nome composto de uma entidade

Por exemplo, queremos as palavras do texto "O deputado João Silva visitou Brasília ontem." sejam classificadas como:

O → O

deputado → O

João → B-PER

Silva → I-PER

visitou → O

Brasília → B-LOC

ontem → O

Extrair nomes de pessoas, instituições, locais pode ser extremamente útil para identificar em um *corpus* a presença ou a ausência de entidades de interesse pra pesquisa.

#### Escolha do modelo

Idealmente utilizaríamos para PT-BR dois modelos diferentes: `neuralmind/bert-base-portuguese-cased` (BERTimbau) e `xlm-roberta-base` que são modelos treinados em português. Por questões didáticas e problemas técnicos vamos utilizar `dslim/bert-base-NER`

#### Modelo

Trata-se de uma classificação dos *tokens*: cada token recebe um rótulo no esquema BIO/IOB. Encoders capturam contexto para decidir limites e tipo da entidade.

Modelos pré-treinados gerais funcionam bem, mas domínios específicos (por exemplo, jurídico, médico) pedem *fine-tuning* próprio.

```{r}
transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

ner <- hf_pipeline(
  "token-classification",
  model = "dslim/bert-base-NER",
  aggregation_strategy = "simple"
)

txt <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

ner(txt)
```

---

## 2) Anonimização com NER

### Funcionamento

A anonimização de documentos de pesquisa, seja para compartilhamento público dos dados coletados, seja para ser utilizada de forma anônima na análise, pode ser um tarefa importante da preparação de um *corpus* construído para pesquisa. Usando novamente NER, podemos **mascarar nomes e locais** para proteger identidades. Adaptando o exemplo anterior, podemos aplicar o mesmo modelo para substituir entidades no texto. Isso preserva o conteúdo temático para pesquisa sem expor dados pessoais sensíveis.

#### Escolha do modelo

Idealmente utilizaríamos para PT-BR dois modelos diferentes: `neuralmind/bert-base-portuguese-cased` (BERTimbau) e `xlm-roberta-base` que são modelos treinados em português. Por questões didáticas e problemas técnicos vamos utilizar `dslim/bert-base-NER`

#### Modelo

O modelo aplica NER (token classification) e depois pós-processa as entidades identificadas para omití-las. A qualidade do resultado depende do NER e do domínio de aplicação.

É possível combinar esta técnica com regras (regex) para formatos rígidos, como CPFs e telefones, e aprimorar o modelo e auditoria humana em amostras.

```{r}

transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

mask_ner <- function(text, label_set = c("PER", "ORG", "LOC")) {
  ner <- hf_pipeline(
    "token-classification",
    model = "dslim/bert-base-NER",
    aggregation_strategy = "simple"
  )
  ents  <- ner(text)

  # Coleta spans (start, end) das entidades desejadas
  spans <- list()
  for (e in ents) {
    if (e$entity_group %in% label_set) {
      spans <- append(spans, list(c(e$start, e$end)))
    }
  }

  s <- text

  # Ordena por início decrescente para não invalidar os índices
  if (length(spans) > 0) {
    starts <- sapply(spans, function(x) x[1])
    order_idx <- order(starts, decreasing = TRUE)

    for (i in order_idx) {
      a0 <- spans[[i]][1]
      b0 <- spans[[i]][2]
      # Índices de Python são 0-based e end exclusivo.
      # Em R: 1-based e final inclusivo.
      a <- a0 + 1
      b <- b0
      s <- paste0(
        substr(s, 1, a - 1),
        "[OMITIDO]",
        substr(s, b + 1, nchar(s))
      )
    }
  }
  s
}

txt <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

mask_ner(txt)
```

---

## 3) Zero-shot para Inferência de Linguagem Natural (NLI)

### Funcionamento

O objetivo deste modelo é classificar um texto do "zero", ou seja, sem ter um conjunto de dados anotado (já classificado) para espelhar a tarefa. Em zero-shot NLI devemos escolher rótulos candidatos em linguagem natural (ex.: “saúde”, “educação”) e o modelo estima se o texto **combina** com cada rótulo, sem precisar de exemplos anotados.

Esta é uma técnica particularmente útil para classificação inicial de textos e faz grande uso do potencial dos LLM. Diferentemente de outras técnicas de *machine learning* que dependeriam de um conjunto anotado para treinar um modelo supervisionado ou de técnicas de agrupamento, como modelagem de tópicos, que cria conjuntos de textos similares mas não associados a um rótulo, zero-shot parte de um conjunto não anotado e entrega associação a rótulos.

#### Escolha do modelo

Idealmente utilizaríamos para PT-BR dois modelos diferentes: `neuralmind/bert-base-portuguese-cased` (BERTimbau) e `xlm-roberta-base` que são modelos treinados em português. Por questões didáticas e problemas técnicos vamos utilizar `facebook/bart-large-mnli`

### Modelo

Baseia-se em **NLI** (entailment/contradiction). Montamos frases do tipo: “Este texto é sobre {rótulo}” e o modelo calcula a probabilidade de entailment.

Como depende do *verbalizer* (a forma da frase), é comum calibrar *templates* e thresholds por rótulo.

```{r}
library(reticulate)

transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

clf <- hf_pipeline(
  "zero-shot-classification",
  model = "facebook/bart-large-mnli"
)

text <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

labels <- c("esporte", "política", "meio-ambiente")

result <- clf(
  text,
  candidate_labels   = labels,
  hypothesis_template = "Este discurso é sobre {}."
)

best_label <- result$labels[[1]]
cat("Este discurso é sobre", best_label, ".\n")
```

Podemos utilizar modelos de classificação única (*single label*), como acabamos de fazer, ou multinomial (*multi-label*), como abaixo:

```{r}
library(reticulate)

transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

clf <- hf_pipeline(
  "zero-shot-classification",
  model = "facebook/bart-large-mnli"
)

text <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

labels <- c("esporte", "política", "saúde", "meio-ambiente")

result <- clf(
  text,
  candidate_labels    = labels,
  hypothesis_template = "Este texto é sobre {}.",
  multi_label         = TRUE
)

for (i in seq_along(result$labels)) {
  label <- result$labels[[i]]
  score <- result$scores[[i]]
  if (score > 0.5) {
    cat(sprintf("Este texto é sobre %s. (score=%.2f)\n", label, score))
  }
}
```

---

## 4) Sumarização - modelo generativo

### Funcionamento

Essa é uma tarefa das mais clássicas em LLM: resumir um texto. O modelo lê um texto maior e produz um resumo enxuto, preservando as ideias centrais. Em pesquisa, sumarizar os textos de um *corpus* pode ser uma tarefa interessante. Textos longos podem ser computacionalmente caros de serem processados por outros modelos, de LLM inclusive. Então transformar o conjunto de dados em um *corpus* menor, mas que mantém o sentido essencial de cada texto pode contribuir para a viabilidade do processamento de grandes conjuntos de dados ou em modelos mais pesados. Certamente há outros usos criativos possíveis para este modelo em pesquisa. O tamanho e estilo (mais conciso ou mais detalhado) são parâmetros que podem ser controlados.

#### Escolha do modelo

Vamos utilizar o modelo facebook/bart-large-cnn. Trata-se de uma variante do BART large treinada originalmente em inglês e ajustada para gerar resumos de textos longos (especialmente notícias). Mesmo não sendo um modelo específico para português, sua biblioteca funciona bem como exemplo didático de sumarização.

### Modelo

O modelo é do tipo encoder–decoder (seq2seq). O encoder lê o texto de entrada e constrói uma representação contextual; o decoder gera o resumo token a token, de forma autoregressiva, usando atenção sobre os estados do encoder.

Na prática, o pipeline("summarization") recebe o texto original e aplica o tokenizer do BART, passa os tokens pelo encoder, o decoder começa com um token de início e vai gerando a sequência resumida, usando técnicas como beam search e os limites max_length / min_length. O texto de saída não é só um recorte do original, trata-se de sumarização abstrativa, em que o modelo pode parafrasear, condensar e reorganizar as ideias principais. Parâmetros como max_length, min_length e do_sample permitem controlar o tamanho e a “criatividade” do resumo.

```{r}
library(reticulate)

transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

summ <- hf_pipeline(
  "summarization",
  model = "facebook/bart-large-cnn"
)

text <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

summ(text, max_length = 40L, min_length = 15L, do_sample = FALSE)
```

---

## 5) QA extrativo

#### Funcionamento

A maior parte das ferramentas comerciais que popularmente conhecidas como "IA" na internet são assistentes de QA que fazem geração de texto. Em contexto de pesquisa, QA pode ser útil como estratégia de sumarizar um *corpus*, fazendo uma pergunta para todos os seus itens, ou para rotular este conjunto de dados, também atráves da formulação de uma pergunta sobre seu conteúdo. Diferente de geração de texto, aqui a saída é um trecho do próprio (con)texto fornecido, o que reduz risco da resposta ser "inventada". Seu funcionamento é bem direto: a partir de um texto e uma pergunta sobre este texto, o modelo destaca o trecho exato que contém a resposta, ou seja, busca o ponto inicial e o final do texto onde a resposta está. É útil quando a resposta está com certeza no documento.

#### Escolha do modelo

Vamos usar o modelo deepset/roberta-base-squad2. Ele é um RoBERTa base fine-tuned no conjunto SQuAD 2.0, um benchmark clássico de perguntas e respostas em inglês, que inclui tanto perguntas com resposta no texto quanto perguntas sem resposta possível (“no answer”). Mesmo não sendo treinado em português, funciona muito bem como exemplo didático de QA extrativo.

#### Modelo

Esse tipo de QA é extrativo e usa apenas um encoder (RoBERTa). Passamos um contexto e uma questão, e o modelo devolve o trecho do contexto mais provável como resposta. O encoder gera representações contextuais para cada token. Sobre essas representações, o modelo aprende duas "cabeças" de classificação, uma para prever a posição inicial da resposta no contexto; outra para prever a posição final da resposta. O pipeline("question-answering") cuida de tokenizar pergunta e contexto, rodar o modelo, encontrar o par de índices (start, end) com maior pontuação e remontar o texto correspondene.

```{r}
library(reticulate)

transformers <- import("transformers")
hf_pipeline  <- transformers$pipeline

qa <- hf_pipeline(
  "question-answering",
  model = "deepset/roberta-base-squad2"
)

context <- "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino."

qa(
  question = "O Brasil espera ser líder em que tema?",
  context  = context
)
```

Mas se a pergunta estiver fora do escopo do texto, o modelo ainda assim emitirá uma resposta, ainda que completamente inventada:

```{r}
qa(
  question = "O Brasil ganhará a copa do mundo?",
  context  = context
)
```

---

## 6) RAG - Retrieval Augmented Generation

### Funcionamento

RAG mistura um pouco dos dois exemplos anteriores. O modelo, por um lado, gera uma resposta, então tem função generativa. Por outro, o modelo busca respostas exclusivamente dentro do acervo fornecido, reduzindo bastante a probabilidade de respostas fora do contexto que é fornecido, reduzindo alucinações e permitindo, ao mesmo tempo, citar fontes. É ideal para responder perguntas sobre documentos longos ou muitos arquivos.

#### Escolha do modelo

Neste exemplo combinamos dois modelos, um para busca semântica e outro para geração de resposta. all-MiniLM-L6-v2 (SentenceTransformers) é utilizado como retriever: é um modelo de sentence embeddings leve e rápido, adequado para criar vetores densos de sentenças e calcular similaridade semântica entre pergunta e trechos longos. Ele gera representações em um espaço vetorial onde textos parecidos ficam próximos. google/flan-t5-small (pipeline "text2text-generation") é usado como gerador de texto: é um T5 pequeno, instruction-tuned, capaz de seguir instruções em linguagem natural. Aqui ele recebe um prompt com contexto recuperado + pergunta e produz uma resposta curta em português.

### Modelo

O fluxo tem duas etapas principais. Na primeira, retriever (SentenceTransformer / bi-encoder), cada trecho é codificada em um vetor P[i] = retriever.encode(...) com normalize_embeddings=True, o que permite usar o produto interno (P @ qv) como similaridade tipo cosseno. Dada uma pergunta q, calculamos qv = retriever.encode(q, normalize_embeddings=True) e os escores sims = P @ qv. Selecionamos os índices dos k maiores escores (argsort()[-k:][::-1]) e montamos o contexto como a junção desses trechos (ctx = "\n".join(...)).

Na segunda parte, usamos um modelo gerador de texto (Flan-T5 / encoder–decoder). O encoder lê esse texto inteiro (instrução + contexto + pergunta) e o decoder gera a resposta token a token, condicionado tanto pelo contexto quanto pela instrução “Use APENAS o contexto…” e “em 1 frase”. O parâmetro max_new_tokens=100 limita o comprimento da resposta. O resultado é uma resposta ancorada explicitamente no contexto recuperado, em vez de o modelo "inventar" a partir dos dados utilizados no treinamento.

```{r}
library(reticulate)

sentence_transformers <- import("sentence_transformers")
SentenceTransformer   <- sentence_transformers$SentenceTransformer
transformers          <- import("transformers")
hf_pipeline           <- transformers$pipeline
np                    <- import("numpy")

passages <- c(
  "Pela terceira vez compareço a este Congresso Nacional para agradecer ao povo brasileiro o voto de confiança que recebemos. Renovo o juramento de fidelidade à Constituição da República, junto com o vice-presidente Geraldo Alckmin e os ministros que conosco vão trabalhar pelo Brasil. Se estamos aqui, hoje, é graças à consciência política da sociedade brasileira e à frente democrática que formamos ao longo desta histórica campanha eleitoral. Foi a democracia a grande vitoriosa nesta eleição, superando a maior mobilização de recursos públicos e privados que já se viu; as mais violentas ameaças à liberdade do voto, a mais abjeta campanha de mentiras e de ódio tramada para manipular e constranger o eleitorado. Nunca os recursos do estado foram tão desvirtuados em proveito de um projeto autoritário de poder. Nunca a máquina pública foi tão desencaminhada dos controles republicanos. Nunca os eleitores foram tão constrangidos pelo poder econômico e por mentiras disseminadas em escala industrial. Apesar de tudo, a decisão das urnas prevaleceu, graças a um sistema eleitoral internacionalmente reconhecido por sua eficácia na captação e apuração dos votos. Foi fundamental a atitude corajosa do Poder Judiciário, especialmente do Tribunal Superior Eleitoral, para fazer prevalecer a verdade das urnas sobre a violência de seus detratores.",
  "SENHORAS E SENHORES PARLAMENTARES, Ao retornar a este plenário da Câmara dos Deputados, onde participei da Assembleia Constituinte de 1988, recordo com emoção os embates que travamos aqui, democraticamente, para inscrever na Constituição o mais amplo conjunto de direitos sociais, individuais e coletivos, em benefício da população e da soberania nacional. Vinte anos atrás, quando fui eleito presidente pela primeira vez, ao lado do companheiro vice-presidente José Alencar, iniciei o discurso de posse com a palavra “mudança”. A mudança que pretendíamos era simplesmente concretizar os preceitos constitucionais. A começar pelo direito à vida digna, sem fome, com acesso ao emprego, saúde e educação. Disse, naquela ocasião, que a missão de minha vida estaria cumprida quando cada brasileiro e brasileira pudesse fazer três refeições por dia. Ter de repetir este compromisso no dia de hoje – diante do avanço da miséria e do regresso da fome, que havíamos superado – é o mais grave sintoma da devastação que se impôs ao país nos anos recentes. Hoje, nossa mensagem ao Brasil é de esperança e reconstrução. O grande edifício de direitos, de soberania e de desenvolvimento que esta Nação levantou, a partir de 1988, vinha sendo sistematicamente demolido nos anos recentes. É para reerguer este edifício de direitos e valores nacionais que vamos dirigir todos os nossos esforços.",
  "SENHORAS E SENHORES, Em 2002, dizíamos que a esperança tinha vencido o medo, no sentido de superar os temores diante da inédita eleição de um representante da classe trabalhadora para presidir os destinos do país. Em oito anos de governo deixamos claro que os temores eram infundados. Do contrário, não estaríamos aqui novamente. Ficou demonstrado que um representante da classe trabalhadora podia, sim, dialogar com a sociedade para promover o crescimento econômico de forma sustentável e em benefício de todos, especialmente dos mais necessitados. Ficou demonstrado que era possível, sim, governar este país com a mais ampla participação social, incluindo os trabalhadores e os mais pobres no orçamento e nas decisões de governo. Ao longo desta campanha eleitoral vi a esperança brilhar nos olhos de um povo sofrido, em decorrência da destruição de políticas públicas que promoviam a cidadania, os direitos essenciais, a saúde e a educação. Vi o sonho de uma Pátria generosa, que ofereça oportunidades a seus filhos e filhas, em que a solidariedade ativa seja mais forte que o individualismo cego. O diagnóstico que recebemos do Gabinete de Transição de Governo é estarrecedor. Esvaziaram os recursos da Saúde. Desmontaram a Educação, a Cultura, Ciência e Tecnologia. Destruíram a proteção ao Meio Ambiente. Não deixaram recursos para a merenda escolar, a vacinação, a segurança pública, a proteção às florestas, a assistência social. Desorganizaram a governança da economia, dos financiamentos públicos, do apoio às empresas, aos empreendedores e ao comércio externo. Dilapidaram as estatais e os bancos públicos; entregaram o patrimônio nacional. Os recursos do país foram rapinados para saciar a cupidez dos rentistas e de acionistas privados das empresas públicas. É sobre estas terríveis ruínas que assumo o compromisso de, junto com o povo brasileiro, reconstruir o país e fazer novamente um Brasil de todos e para todos.",
  "SENHORAS E SENHORES, Diante do desastre orçamentário que recebemos, apresentei ao Congresso Nacional propostas que nos permitam apoiar a imensa camada da população que necessita do estado para, simplesmente, sobreviver. Agradeço à Câmara e ao Senado pela sensibilidade frente às urgências do povo brasileiro. Registro a atitude extremamente responsável do Supremo Tribunal Federal e do Tribunal de Contas da União frente às situações que distorciam a harmonia dos poderes. Assim fiz porque não seria justo nem correto pedir paciência a quem tem fome. Nenhuma nação se ergueu nem poderá se erguer sobre a miséria de seu povo. Os direitos e interesses da população, o fortalecimento da democracia e a retomada da soberania nacional serão os pilares de nosso governo. Este compromisso começa pela garantia de um Programa Bolsa Família renovado, mais forte e mais justo, para atender a quem mais necessita. Nossas primeiras ações visam a resgatar da fome 33 milhões de pessoas e resgatar da pobreza mais de 100 milhões de brasileiras e brasileiros, que suportaram a mais dura carga do projeto de destruição nacional que hoje se encerra.",
  "SENHORAS E SENHORES, Este processo eleitoral também foi caracterizado pelo contraste entre distintas visões de mundo. A nossa, centrada na solidariedade e na participação política e social para a definição democrática dos destinos do país. A outra, no individualismo, na negação da política, na destruição do estado em nome de supostas liberdades individuais. A liberdade que sempre defendemos é a de viver com dignidade, com pleno direito de expressão, manifestação e organização. A liberdade que eles pregam é a de oprimir o vulnerável, massacrar o oponente e impor a lei do mais forte acima das leis da civilização. O nome disso é barbárie. Compreendi, desde o início da jornada, que deveria ser candidato por uma frente mais ampla do que o campo político em que me formei, mantendo o firme compromisso com minhas origens. Esta frente se consolidou para impedir o retorno do autoritarismo ao país. A partir de hoje, a Lei de Acesso à Informação voltará a ser cumprida, o Portal da Transparência voltará a cumprir seu papel, os controles republicanos voltarão a ser exercidos para defender o interesse público. Não carregamos nenhum ânimo de revanche contra os que tentaram subjugar a Nação a seus desígnios pessoais e ideológicos, mas vamos garantir o primado da lei. Quem errou responderá por seus erros, com direito amplo de defesa, dentro do devido processo legal. O mandato que recebemos, frente a adversários inspirados no fascismo, será defendido com os poderes que a Constituição confere à democracia. Ao ódio, responderemos com amor. À mentira, com a verdade. Ao terror e à violência, responderemos com a Lei e suas mais duras consequências. Sob os ventos da redemocratização, dizíamos: ditadura nunca mais! Hoje, depois do terrível desafio que superamos, devemos dizer: democracia para sempre! Para confirmar estas palavras, teremos de reconstruir em bases sólidas a democracia em nosso país. A democracia será defendida pelo povo na medida em que garantir a todos e a todas os direitos inscritos na Constituição.",
  "SENHORAS E SENHORES, Hoje mesmo estou assinando medidas para reorganizar as estruturas do Poder Executivo, de modo que voltem a permitir o funcionamento do governo de maneira racional, republicana e democrática. Para resgatar o papel das instituições do estado, bancos públicos e empresas estatais no desenvolvimento do país. Para planejar os investimentos públicos e privados na direção de um crescimento econômico sustentável, ambientalmente e socialmente. Em diálogo com os 27 governadores, vamos definir prioridades para retomar obras irresponsavelmente paralisadas, que são mais de 14 mil no país. Vamos retomar o Minha Casa, Minha Vida e estruturar um novo PAC para gerar empregos na velocidade que o Brasil requer. Buscaremos financiamento e cooperação – nacional e internacional – para o investimento, para dinamizar e expandir o mercado interno de consumo, desenvolver o comércio, exportações, serviços, agricultura e a indústria. Os bancos públicos, especialmente o BNDES, e as empresas indutoras do crescimento e inovação, como a Petrobras, terão papel fundamental neste novo ciclo. Ao mesmo tempo, vamos impulsionar as pequenas e médias empresas, potencialmente as maiores geradoras de emprego e renda, o empreendedorismo, o cooperativismo e a economia criativa. A roda da economia vai voltar a girar e o consumo popular terá papel central neste processo. Vamos retomar a política de valorização permanente do salário-mínimo. E estejam certos de que vamos acabar, mais uma vez, com a vergonhosa fila do INSS, outra injustiça restabelecida nestes tempos de destruição. Vamos dialogar, de forma tripartite – governo, centrais sindicais e empresariais – sobre uma nova legislação trabalhista. Garantir a liberdade de empreender, ao lado da proteção social, é um grande desafio nos tempos de hoje.",
  "SENHORAS E SENHORES, O Brasil é grande demais para renunciar a seu potencial produtivo. Não faz sentido importar combustíveis, fertilizantes, plataformas de petróleo, microprocessadores, aeronaves e satélites. Temos capacitação técnica, capitais e mercado em grau suficiente para retomar a industrialização e a oferta de serviços em nível competitivo. O Brasil pode e deve figurar na primeira linha da economia global. Caberá ao estado articular a transição digital e trazer a indústria brasileira para o Século XXI, com uma política industrial que apoie a inovação, estimule a cooperação público-privada, fortaleça a ciência e a tecnologia e garanta acesso a financiamentos com custos adequados. O futuro pertencerá a quem investir na indústria do conhecimento, que será objeto de uma estratégia nacional, planejada em diálogo com o setor produtivo, centros de pesquisa e universidades, junto com o Ministério de Ciência, Tecnologia e Inovação, os bancos públicos, estatais e agências de fomento à pesquisa. Nenhum outro país tem as condições do Brasil para se tornar uma grande potência ambiental, a partir da criatividade da bioeconomia e dos empreendimentos da socio-biodiversidade. Vamos iniciar a transição energética e ecológica para uma agropecuária e uma mineração sustentáveis, uma agricultura familiar mais forte, uma indústria mais verde. Nossa meta é alcançar desmatamento zero na Amazônia e emissão zero de gases do efeito estufa na matriz elétrica, além de estimular o reaproveitamento de pastagens degradadas. O Brasil não precisa desmatar para manter e ampliar sua estratégica fronteira agrícola. Incentivaremos, sim, a prosperidade na terra. Liberdade e oportunidade de criar, plantar e colher continuará sendo nosso objetivo. O que não podemos admitir é que seja uma terra sem lei. Não vamos tolerar a violência contra os pequenos, o desmatamento e a degradação do ambiente, que tanto mal já fizeram ao país. Esta é uma das razões, não a única, da criação do Ministério dos Povos Indígenas. Ninguém conhece melhor nossas florestas nem é mais capaz de defendê-las do que os que estavam aqui desde tempos imemoriais. Cada terra demarcada é uma nova área de proteção ambiental. A estes brasileiros e brasileiras devemos respeito e com eles temos uma dívida histórica. Vamos revogar todas as injustiças cometidas contra os povos indígenas.",
  "SENHORAS E SENHORES, Uma nação não se mede apenas por estatísticas, por mais impressionantes que sejam. Assim como um ser humano, uma nação se expressa verdadeiramente pela alma de seu povo. A alma do Brasil reside na diversidade inigualável da nossa gente e das nossas manifestações culturais. Estamos refundando o Ministério da Cultura, com a ambição de retomar mais intensamente as políticas de incentivo e de acesso aos bens culturais, interrompidas pelo obscurantismo nos últimos anos. Uma política cultural democrática não pode temer a crítica nem eleger favoritos. Que brotem todas as flores e sejam colhidos todos os frutos da nossa criatividade, Que todos possam dela usufruir, sem censura nem discriminações. Não é admissível que negros e pardos continuem sendo a maioria pobre e oprimida de um país construído com o suor e o sangue de seus ascendentes africanos. Criamos o Ministério da Promoção da Igualdade Racial para ampliar a política de cotas nas universidades e no serviço público, além de retomar as políticas voltadas para o povo negro e pardo na saúde, educação e cultura. É inadmissível que as mulheres recebam menos que os homens, realizando a mesma função. Que não sejam reconhecidas em um mundo político machista. Que sejam assediadas impunemente nas ruas e no trabalho. Que sejam vítimas da violência dentro e fora de casa. Estamos refundando também o Ministério das Mulheres para demolir este castelo secular de desigualdade e preconceito. Não existirá verdadeira justiça num país em que um só ser humano seja injustiçado. Caberá ao Ministério dos Direitos Humanos zelar e agir para que cada cidadão e cidadã tenha seus direitos respeitados, no acesso aos serviços públicos e particulares, na proteção frente ao preconceito ou diante da autoridade pública. Cidadania é o outro nome da democracia. O Ministério da Justiça e da Segurança Pública atuará para harmonizar os Poderes e entes federados no objetivo de promover a paz onde ela é mais urgente: nas comunidades pobres, no seio das famílias vulneráveis ao crime organizado, às milícias e à violência, venha ela de onde vier. Estamos revogando os criminosos decretos de ampliação do acesso a armas e munições, que tanta insegurança e tanto mal causaram às famílias brasileiras. O Brasil não quer mais armas; quer paz e segurança para seu povo. Sob a proteção de Deus, inauguro este mandato reafirmando que no Brasil a fé pode estar presente em todas as moradas, nos diversos templos, igrejas e cultos. Neste país todos poderão exercer livremente sua religiosidade.",
  "SENHORAS E SENHORES, O período que se encerra foi marcado por uma das maiores tragédias da história: a pandemia de Covid-19. Em nenhum outro país a quantidade de vítimas fatais foi tão alta proporcionalmente à população quanto no Brasil, um dos países mais preparados para enfrentar emergências sanitárias, graças à competência do nosso Sistema Único de Saúde. Este paradoxo só se explica pela atitude criminosa de um governo negacionista, obscurantista e insensível à vida. As responsabilidades por este genocídio hão de ser apuradas e não devem ficar impunes. O que nos cabe, no momento, é prestar solidariedade aos familiares, pais, órfãos, irmãos e irmãs de quase 700 mil vítimas da pandemia. O SUS é provavelmente a mais democrática das instituições criadas pela Constituição de 1988. Certamente por isso foi a mais perseguida desde então, e foi, também, a mais prejudicada por uma estupidez chamada Teto de Gastos, que haveremos de revogar. Vamos recompor os orçamentos da Saúde para garantir a assistência básica, a Farmácia Popular, promover o acesso à medicina especializada. Vamos recompor os orçamentos da Educação, investir em mais universidades, no ensino técnico, na universalização do acesso à internet, na ampliação das creches e no ensino público em tempo integral. Este é o investimento que verdadeiramente levará ao desenvolvimento do país. O modelo que propomos, aprovado nas urnas, exige, sim, compromisso com a responsabilidade, a credibilidade e a previsibilidade; e disso não vamos abrir mão. Foi com realismo orçamentário, fiscal e monetário, buscando a estabilidade, controlando a inflação e respeitando contratos que governamos este país. Não podemos fazer diferente. Teremos de fazer melhor.",
  "SENHORAS E SENHORES, Os olhos do mundo estiveram voltados para o Brasil nestas eleições. O mundo espera que o Brasil volte a ser um líder no enfrentamento à crise climática e um exemplo de país social e ambientalmente responsável, capaz de promover o crescimento econômico com distribuição de renda, combater a fome e a pobreza, dentro do processo democrático. Nosso protagonismo se concretizará pela retomada da integração sul-americana, a partir do Mercosul, da revitalização da Unasul e demais instâncias de articulação soberana da região. Sobre esta base poderemos reconstruir o diálogo altivo e ativo com os Estados Unidos, a Comunidade Europeia, a China, os países do Oriente e outros atores globais; fortalecendo os BRICS, a cooperação com os países da África e rompendo o isolamento a que o país foi relegado. O Brasil tem de ser dono de si mesmo, dono de seu destino. Tem de voltar a ser um país soberano. Somos responsáveis pela maior parte da Amazônia e por vastos biomas, grandes aquíferos, jazidas de minérios, petróleo e fontes de energia limpa. Com soberania e responsabilidade seremos respeitados para compartilhar essa grandeza com a humanidade – solidariamente, jamais com subordinação. A relevância da eleição no Brasil refere-se, por fim, às ameaças que o modelo democrático vem enfrentando. Ao redor do planeta, articula-se uma onda de extremismo autoritário que dissemina o ódio e a mentira por meios tecnológicos que não se submetem a controles transparentes. Defendemos a plena liberdade de expressão, cientes de que é urgente criarmos instâncias democráticas de acesso à informação confiável e de responsabilização dos meios pelos quais o veneno do ódio e da mentira são inoculados. Este é um desafio civilizatório, da mesma forma que a superação das guerras, da crise climática, da fome e da desigualdade no planeta. Reafirmo, para o Brasil e para o mundo, a convicção de que a Política, em seu mais elevado sentido – e apesar de todas as suas limitações – é o melhor caminho para o diálogo entre interesses divergentes, para a construção pacífica de consensos. Negar a política, desvalorizá-la e criminalizá-la é o caminho das tiranias. Minha mais importante missão, a partir de hoje, será honrar a confiança recebida e corresponder às esperanças de um povo sofrido, que jamais perdeu a fé no futuro nem em sua capacidade de superar os desafios. Com a força do povo e as bênçãos de Deus, haveremos der reconstruir este país. Viva a democracia! Viva o povo brasileiro! Muito obrigado"
)

retriever <- SentenceTransformer("all-MiniLM-L6-v2")
P         <- retriever$encode(passages, normalize_embeddings = TRUE)

retrieve <- function(q, k = 2L) {
  qv   <- retriever$encode(q, normalize_embeddings = TRUE)
  sims <- np$dot(P, qv)
  sims_r <- as.numeric(sims)
  idx <- order(sims_r, decreasing = TRUE)[1:k]
  passages[idx]
}

generator <- hf_pipeline("text2text-generation", model = "google/flan-t5-small")

question <- "O Brasil espera ser líder em que tema?"
ctx      <- paste(retrieve(question, k = 2L), collapse = "\n")
prompt   <- sprintf(
  "Use APENAS o contexto abaixo para responder em 1 frase.\n\nContexto:\n%s\n\nPergunta: %s\nResposta:",
  ctx,
  question
)

generator(prompt, max_new_tokens = 100L)
```

---

## 7) Busca semântica com bi-encoder (Embeddings)

#### Corpus de PLs da Câmara dos deputados

Ne exemplo vamos utilizar o corpus dos PLs da Câmara dos Deputados

```{r}
library(readr)

CSV_PATH <- "corpus.csv"
df <- read_csv(
  CSV_PATH,
  show_col_types = FALSE,
  progress = FALSE
)

# Para manter o exemplo leve, usamos apenas as 10 primeiras linhas:
df <- head(df, 10)

stopifnot("text" %in% names(df))

head(df, 3)
```

#### Funcionamento

Uma possibilidade de classificar textos sem o uso de LLM ou modelos probabilísticos é fazer buscas determinísticas, ou seja, verificar se um ou mais termos (e suas variações) estão presentes num texto. Mas a busca por palavras exatas pode gerar classificações muito imprecisas, pois as palavras dependem, evidentemente, de contexto. LLMs são bastante úteis para esta tarefa em substituição a busca determinística. vamos utilizar um modelo de busca semâtica para tentar classificar um *corpus*. Em vez de procurarmos por palavras exatas, fazemos uma busca por significado. Em primeiro transformamos cada documento do corpus em um vetor numérico (embedding). Depois transformamos também a consulta (ex: "meio ambiente") em um vetor no mesmo espaço vetorial. Calculamos a similaridade entre o vetor da consulta e o vetor de cada documento e ordenamos os documentos do mais parecido para o menos parecido. Assim conseguimos recuperar, para cada item do corpus, um score de proximidade semântica, mesmo que o texto não contenha literalmente a expressão “meio ambiente”, mas fale de clima, florestas, Amazônia, transição energética etc.

#### Escolha do modelo

Para gerar os embeddings utilizamos o modelo all-MiniLM-L6-v2 da biblioteca SentenceTransformers. É um modelo leve e eficiente, treinado para produzir vetores de sentenças úteis em tarefas de similaridade semântica e recuperação de informação. Ele é uma didática, porque é rápido o suficiente para rodar em CPU e funciona razoavelmente bem em vários idiomas (incluindo português, mesmo não sendo especializado). Já vem integrado à API SentenceTransformer, facilitando o uso em poucas linhas de código.

#### Modelo

O all-MiniLM-L6-v2 é um bi-encoder de sentenças. Um mesmo encoder transforma tanto os documentos quanto a consulta em vetores de dimensão fixa. Esses vetores são normalizados e comparados via produto interno, que se comporta como similaridade de cosseno. Durante o treinamento, o modelo é otimizado para que textos semanticamente parecidos fiquem próximos no espaço vetorial e textos diferentes fiquem distantes.

```{r}
library(reticulate)

sentence_transformers <- import("sentence_transformers")
SentenceTransformer   <- sentence_transformers$SentenceTransformer

corpus <- df$text

model <- SentenceTransformer("all-MiniLM-L6-v2")

# Embeddings do corpus
C <- model$encode(corpus, normalize_embeddings = TRUE)

# Query
query <- "judiciário"
q     <- model$encode(query, normalize_embeddings = TRUE)

# Similaridade tipo cosseno (produto interno)
np <- import("numpy")
scores_np <- np$dot(C, q)
scores    <- as.numeric(scores_np)

# Monta data.frame com scores
df_scores <- df
df_scores$score_judiciario <- scores

# Ordena do mais parecido para o menos parecido
df_scores <- df_scores[order(-df_scores$score_judiciario), ]
df_scores[, setdiff(names(df_scores), "text"), drop = FALSE]
```

---

## 8) Busca semântica com cross-encoder (Embeddings)

#### Funcionamento

Uma maneira alternativa para realizar a mesma tarefa é usar um modelo *cross-encoder* em vez de um modelo *bi-encoder* (modelo anterior) para busca semântica. Os dois fazem busca semântica por similaridade, mas de jeitos diferentes. No *bi-encoder* cada documento e a *query* viram um vetor para comparação, ou seja, compara-se se os contextos são semelhantes. No *cross-encoder*, *query* e texto são concatenados e lidos juntos. Então busca-se saber se a *query* tem similaridade semântica com cada palavra do documento, ou seja, se combinam entre si. Convém usar *bi-encoder* quando o objetivo for buscar num conjunto grande de documentos quais são os melhores candidatos para a *query* fornecida. *Cross-enconder* é mais adequado se queremos ordenar (rankear) todos os documentos em relação à *query*. É mais preciso, mas pode ser impraticável para coleções de documentos muito grandes.

#### Escolha do modelo

Para o cross-encoder, uma escolha típica é um modelo treinado em ranking de perguntas e passagens, como por exemplo, *cross-encoder/ms-marco-MiniLM-L-6-v2* (da biblioteca SentenceTransformers). É relativamente leve (base MiniLM) e foi ajustado em conjuntos de dados de busca (como MS MARCO), aprendendo a dar um score alto quando a pergunta e o trecho realmente se correspondem. Mesmo sendo treinado em inglês, funciona como exemplo didático: o foco aqui é mostrar como mudar de busca por embeddings (bi-encoder) para scoring direto de pares (cross-encoder).

#### Modelo

O cross-encoder usa um único Transformer para processar consulta (*query*) e documento juntos. A consulta ("judiciário") e cada texto do corpus são concatenados em uma sequência única, com separadores especiais (tipo [CLS] consulta [SEP] documento [SEP]). Essa sequência é passada pelo Transformer, que aplica atenção cruzada entre tokens da pergunta e do documento, permitindo que o modelo compare cada palavra da consulta com cada palavra do texto. O vetor correspondente ao token de classificação (por exemplo, [CLS]) alimenta uma camada final de regressão/ classificação, que produz um score de relevância para aquele par. Diferentemente do bi-encoder, aqui não dá para pré-computar embeddings do corpus e só comparar depois: cada par consulta–documento precisa ser passado pelo modelo. Isso deixa o cross-encoder mais caro computacionalmente, mas em geral mais preciso, justamente porque ele olha para a interação token-a-token entre a pergunta e cada texto do seu corpus.

```{r}
library(reticulate)

sentence_transformers <- import("sentence_transformers")
CrossEncoder          <- sentence_transformers$CrossEncoder

query  <- "judiciário"
corpus <- df$text

pairs <- lapply(corpus, function(doc) list(query, doc))

reranker <- CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

scores <- reranker$predict(pairs)
scores <- as.numeric(scores)

ranking <- order(scores, decreasing = TRUE)

cat(sprintf("Ranking por similaridade (cross-encoder) com a query: '%s'\n", query))
for (i in seq_along(ranking)) {
  idx <- ranking[i]
  doc_id <- if ("id" %in% names(df)) df$id[idx] else idx
  cat(sprintf("%2d. idx=%d, id=%s, score=%.4f\n", i, idx, as.character(doc_id), scores[idx]))
}
```

