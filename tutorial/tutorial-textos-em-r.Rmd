# Preparação e Análise de Texto em R com *stringr* e *tidytext* 

Neste tutorial faremos uma rápida introdução aos pacotes *stringr* e *tidytext* para prepração da dados textuais para a análise. Nosso objetivo é saber transformar e identificar padrões em textos para que posssamos organizar e prepar uma coleção de documentos para análise após a coleta via raspagem de dados e/ou após a extração a partir de documentos de imagem/pdf.

Com o pacote *stringr* aprenderemos a fazer manipulações simples nos conjuntos de dados, como buscas com expressões regulares simples, remoção de caracateres, transformação em maiúsculas e minúsculas, remoção de espaços extras e etc. 

A seguir, utilizaremos o pacote *tidytext*, que organiza um _corpus_ como data frame e torna o trabalho de manipulação das informações relativamente simples.

O pacote *tidytext* é acompanhado de um livro em formato digital aberto que contém exemplos interessantes e úteis de como analisar textos: [Text Mininig with R](http://tidytextmining.com/).

Depois de terminar este tutorial, sugiro a leitura de um dos seguintes capítulos do livro que, após este tutorial, podem ser lidos em qualquer ordem e de maneira independente:

- [Capítulo 2 - Análise de Sentimento (com textos em inglês)](http://tidytextmining.com/sentiment.html)

- [Capítulo 3 - Análise de frequência de palavras](http://tidytextmining.com/tfidf.html)

- [Capítulo 4 - Relacionamento entre palavras, n-gramas e correlação](http://tidytextmining.com/ngrams.html)

- [Capítulo 6 - Topic Modeling](http://tidytextmining.com/topicmodeling.html)

---

## Prepararão para o tutorial: pacotes e objeto *corpus*

Vamos utilizar os seguintes pacotes:

* **stringr**: funções de manipulação de strings (prefixo `str_`).
* **tidyverse**: manipulação de dados em data frames (`dplyr`, `tibble`, `purrr`, etc.).
* **tidytext**: organização do **corpus** em formato “*tidy*” e funções para tokenização e análises.
* **tm**: lista de *stopwords* (português e inglês).

Se ainda não tiver instalado tais pacotes, instale-os:

```{r}
#install.package('stringr')
#install.package('tidyverse')
#install.package('tidytext')
#install.package('tm')
```

A seguir, carregue todos:

```{r}
library(stringr)
library(tidyverse)
library(tidytext)
library(tm)
```

Vamos agora carregar os textos que analisaremos. Há no curso um [tutorial sobre como criar um corpus a partir dos PDFs de proposições legislativas em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-proposicoes-legislativas-r.md). Você pode fazê-lo antes desse, se quiser aprender um pouco sobre o assunto.

*Corpus*, no contexto do análise de dados, é o conjunto de documentos textuais. Em R podemos representá-lo como lista ou como um data frame. Deve sempre conter pelo menos dois atributos mínimos: um identificador e o conteúdo do texto (texto). Pode conter também outros metadados daquele texto, como autoria, data, grupo de documentos ao qual pertence, etc.

O *corpus* que vamos utilizar neste tutorial pode ser carregado diretamente fazendo:

```{r}
# corpus_docs <- readr::read_csv2('https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/data/corpus_docs.csv')
corpus_docs <- readr::read_csv2('data/corpus_docs.csv') %>% 
  rename(texto = text)
```
---

## Limpeza e preparação de textos com *stringr*

O pacote ***stringr*** é relativamente simples de utilizar. Suas funções principais começam com `str_` e o **primeiro argumento** é sempre um **vetor de texto** (ou uma coluna de texto em um data frame) a ser modificado ou a partir do qual extrairemos informação.

Os vetores de texto podem ser objetos no seu "Environment" ou variáveis dentro de um data frame. Neste tutorial, vamos preferir trabalhar com textos como variáveis em um data frame, que é uma situação usual na maioria dos projetos. Por esta razão, vamos utilizar as funções do pacote **stringr** dentro do verbo `mutate()` do pacote **dplyr**, pois estaremos modificando uma coluna ou criando uma nova variável.

ótimo! abaixo está o **trecho completo**, mantendo as seções 1–3 como você escreveu (com funções/pacotes marcados) e adicionando a **seção 4** com mini-blocos para `str_squish`, `str_replace` e `str_remove`, no mesmo estilo.

---

### Remover acentos

Antes de seguir para as funções do **`stringr`**, vamos criar uma função bastante útil para trabalhar com textos em português: a função `remove_acentos()`, que encontrei há vários anos em algum fórum ou código cuja autoria não me lembro:

```{r}
remove_acentos <- function(x) iconv(x, to = "ASCII//TRANSLIT")
```

Seu uso e resultado são elementares: o texto modificado perde todos os acentos e caracteres especiais, como ç, por exemplo:

```{r}
corpus_docs <- corpus_docs %>%
  mutate(texto = remove_acentos(texto))
```

É conveniente remover os acentos ao trabalharmos com um corpus, em particular quando suspeitamos que uma parte dos textos já esteja sem acentuação e a outra não.

### Padronizar minúsculas/maiúsculas

Como em R há diferenciação entre letras maiúsculas e minúsculas, convém também tornar o texto completo em minúsculo. Podemos utilizar a função `str_to_lower` do pacote `stringr`. Ela é semelhante à função `tolower` do pacote `base` de R.
Como o R diferencia maiúsculas e minúsculas, convém tornar o texto todo **minúsculo**:

```{r}
corpus_docs <- corpus_docs %>%
  mutate(texto = str_to_lower(texto))
```

`str_to_upper`, por sua vez, transformaria todos os caracteres em maísculo e `str_to_title` manteria em maísculo apenas o primeiro caracter de cada palavra e os demais em minúsculo.

### Remover pontuação

Outra limpeza comum na preparação de textos é a remoção de todo a pontuação. A função `str_remove_all` nos permite remover uma padrão de dentro de um texto. Por exemplo, para removermos todas as palavras "artigo" faríamos `str_remove_all(texto, "artigo")`. Para remover pontuação, porém, precisamos de uma expressão regular que represente "qualquer caracter de pontuação", como a expressão `[:punct:]`.

```{r}
corpus_docs <- corpus_docs %>%
  mutate(texto = str_remove_all(texto, '[:punct:]'))
```

Expressões regulares são grandes aliadas das funções do pacote `stringr`. Ao final do tutorial há uma indicação onde você pode aprender um pouco mais como escrever expressões regulares.

Vejamos como ficaram os primeiros mil caracateres do texto depois de modificado:

```{r}
corpus_docs %>% 
  slice(1) %>%             # seleciona o 1o texto
  pull(texto) %>%          # retira do data frame como vetor
  str_sub(1, 1000)         # limita do 1o ao milesimo caracter
```

### Normalização de espaços

Há muitos espeços inúteis no texto provenientes dos espaços dos arquivos em .pdf originais. Com `str_squish` podemos remover estes espaços que estão sobrando e comprimir múltiplos espaços internos em um único:

```{r}
corpus_docs <- corpus_docs %>%
  mutate(texto = str_squish(texto))
```

### Substituição de textos

Por vezes, há palavras inteiras que queremos substituir no texto (ou padrões de carateres). `str_replace` e `str_replace_all` cumprem essa função. `str_replace` substitui o **primeiro** substitui **apenas a primeira ocorrência** de um padrão por outro.

```{r}
# Ex.: trocar a primeira ocorrencia de "projeto" por "PL"
corpus_docs <- corpus_docs %>%
  mutate(texto = str_replace(texto, "projeto de lei", "PL"))
```

Para substituir **todas** as ocorrências, usamos `str_replace_all()`.

```{r}
# Ex.: trocar todas as ocorrencias de "projeto" por "PL"
corpus_docs <- corpus_docs %>%
  mutate(texto = str_replace_all(texto, "projeto de lei", "PL"))
```

### Remoção de textos

Se queremos apenas remover um texto, em vez de usarmos `str_replace_all()` para substituir por vazio, podemos usar `str_replace_remove()`:

```{r}
# Ex.: remove todas as ocorrencias da palavra deputado
corpus_docs <- corpus_docs %>%
  mutate(texto = str_remove_all(texto, "deputado"))
```

### Medidas simples e detecção de padrões

**Qual dos textos do nosso *corpus* é o mais longo?** Vamos criar uma variável de **tamanho** (em caracteres) dos textos:

```{r}
corpus_docs <- corpus_docs %>% 
  mutate(tamanho = str_length(texto))

```

**Vamos agora identificar padrões** dentro de nossos textos. Há 3 funções muito úteis e similares para identificar padrões. Antes de utilizá-las dentro do data frame completo, vamos aplicá-las a um **vetor de textos** para entender seus resultados. Compare com os termos **“jornada de trabalho”** e **“meio ambiente”**:

```{r}
# Vetor lógico com TRUE/FALSE por linha
str_detect(corpus_docs$texto, "jornada de trabalho")
str_detect(corpus_docs$texto, "meio ambiente")
```

`str_detect` procura, em cada um dos textos do vetor, o padrão informado no segundo parâmetro e retorna um vetor lógico indicando quais textos contêm o padrão.

```{r}
# Índices (posições) onde aparece
str_which(corpus_docs$texto, "jornada de trabalho")
str_which(corpus_docs$texto, "meio ambiente")
```

`str_which`, por sua vez, também procura os padrões informados, mas retorna um **vetor com as posições** dos textos que contêm o padrão.

```{r}
# Subconjuntos com os textos que contêm o padrão
str_subset(corpus_docs$texto, "jornada de trabalho") %>% str_sub(1,300)
str_subset(corpus_docs$texto, "meio ambiente")%>% str_sub(1,300) 
```

Finalmente, `str_subset` seleciona, do vetor de textos, **apenas os que contêm** o padrão e retorna esse subconjunto.

**`str_detect` é bastante útil para selecionar linhas** em um data frame. Por exemplo, vamos criar um novo data frame que contenha apenas os documentos com pelo menos uma menção a “jornada de trabalho”:

```{r}
docs_jornada <- corpus_docs %>% 
  filter(str_detect(texto, "jornada de trabalho"))
```

Ótimo! Mas vamos continuar trabalhando no **data frame completo**.

**Marcar no data frame (em vez de filtrar)**: vamos criar colunas lógicas e colunas de **contagem** de ocorrências para os dois termos:

```{r}
corpus_docs <- corpus_docs %>% 
  mutate(
    tem_jornada   = str_detect(texto, "jornada de trabalho"),
    tem_meioamb   = str_detect(texto, "meio ambiente"),
    n_jornada     = str_count(texto, "jornada de trabalho"),
    n_meioamb     = str_count(texto, "meio ambiente")
  )
```

---

## Tidy text com *tidytext*: tokens, stopwords e frequências

Agora vamos organizar o texto em **formato *tidy***: cada linha corresponde a um **token** (palavra, bigram, trigram…). Começaremos por **palavras**.

> A ideia central: transformar a coluna `texto` em muitos registros, um por token, preservando a ligação com `id`.

### 1) Tokenização em palavras

Neste exercício, vamos trabalhar apenas com as variáveis **`id`** e **`texto`** do nosso corpus:

```{r}
corpus_docs <- corpus_docs %>% 
  select(id, texto)
```

O primeiro passo para organizar um texto para análise com o pacote *tidytext* é a **tokenização** da variável de conteúdo. “Tokenizar” significa fragmentar o texto em unidades, que podem ser **palavras**, **palavras**, **duplas**, **trios** ou conjuntos ainda maiores de palavras, como **sentenças**, ou menores, como conjuntos de **caracteres**. Vamos trabalhar inicialmente com **palavras** como tokens:

```{r}
docs_token <- corpus_docs %>%
  unnest_tokens(word, texto)

glimpse(docs_token)
```

Note que a variável **`id`** é mantida. `texto`, porém, se torna `word`, organizada ordenadamente na sequência prévia dos textos. Veja que o formato de um *tidytext* é completamente diferente do data frame original, pois o conteúdo textual agora são os **tokens** (palavras).

## Palavras muito comuns: stopwords

Quando analisamos textos podemos observar, entre outros aspectos, a **frequência** ou a **co-ocorrência** entre tokens. Entretanto, em todas as línguas há palavras muito frequentes e pouco informativas sobre o conteúdo. São as **stopwords**.

O pacote `tm` contém uma lista de stopwords em português. Veja:

```{r}
stopwords("pt")
```

Dependendo do propósito da análise, podemos **ampliar manualmente** a lista de stopwords acrescentando novos termos ao vetor.

Para excluir stopwords nessa abordagem, precisamos de um **data frame** com stopwords:

```{r}
stopwords_df <- tibble(word = c(stopwords("pt")))
```

Com `anti_join` (função de junção do `dplyr`), mantemos em `docs_token` apenas as palavras que **não** estão em `stopwords_df`:

```{r}
docs_token <- docs_token %>%
  anti_join(stopwords_df, by = "word")
```

Pronto! Excluímos os termos mais comuns do nosso data frame e eles não influenciarão a análise. Note que o novo data frame tem **menos linhas** (menos tokens) associados aos seus respectivos textos.

Para observarmos a **frequência de palavras**, usamos `count`, do pacote `dplyr`:

```{r}
docs_token %>%
  count(word, sort = TRUE) %>% View
```

Opa! Há muitos tokens que são apenas **caracteres soltos**. Em documentos oficiais é comum encontrar símbolos, siglas muito curtas ou marcas de formatação. Vamos, assim, **excluir todas as palavras de 1 caracter** e rever a frequência dos tokens:

```{r}
docs_token <- docs_token %>%
  filter(str_length(word) > 1) 

docs_token %>%
  count(word, sort = TRUE) %>% View
```

Bem melhor. Ainda seria possível aprimorar a limpeza do texto, mas podemos avançar.

Com `ggplot2`, que é um pacote gráfico de R, podemos construir um **gráfico de barras** dos termos mais frequentes (por exemplo, com frequência maior do que 200 — ajuste conforme o volume do seu corpus). Neste ponto do curso, nada do que estamos fazendo abaixo deve ser novo a você:

```{r}
docs_token %>%
  count(word, sort = TRUE) %>%
  filter(n > 200) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
    geom_col() +
    xlab(NULL) +
    coord_flip()
```

## Bigrams e n-grams

Já produzimos a tokenização do texto, sem, no entanto, refletir sobre esse procedimento. **Tokens não precisam ser palavras únicas**. Se o objetivo for, por exemplo, observar a **ocorrência conjunta** de termos, convém trabalharmos com **bigrams** (tokens de 2 palavras) ou **n-grams** (tokens de *n* palavras). Vejamos como:

```{r}
docs_bigram <- corpus_docs %>%
  unnest_tokens(bigram, texto, token = "ngrams", n = 2)
```

> Obs.: ao tokenizar o texto com `unnest_tokens`, as **pontuações** são removidas automaticamente e as palavras são convertidas para **minúsculas** (use `to_lower = FALSE` caso não queira a conversão). Em muitos fluxos, as transformações anteriores ficariam redundantes.

Vamos **contar os bigrams**:

```{r}
docs_bigram %>%
  count(bigram, sort = TRUE)
```

Como excluir as **stopwords** quando elas ocorrem em bigrams? Primeiro precisamos **separar** os bigrams em duas colunas:

```{r}
bigrams_separados <- docs_bigram %>%
  separate(bigram, c("word1", "word2"), sep = " ")
```

Em seguida, **filtramos** excluindo stopwords em **cada posição** (reaproveitando `stopwords_df`):

```{r}
bigrams_filtrados <- bigrams_separados %>%
  anti_join(stopwords_df, by = c("word1" = "word")) %>%  
  anti_join(stopwords_df, by = c("word2" = "word"))
```

Produzindo a **frequência de bigrams**:

```{r}
bigrams_filtrados %>% 
  count(word1, word2, sort = TRUE)
```

Reunindo as palavras do bigram (após filtragem) em uma única coluna novamente:

```{r}
bigrams_filtrados %>%
  unite(bigram, word1, word2, sep = " ")
```

A abordagem *tidy* traz uma tremenda flexibilidade. Se, por exemplo, quisermos ver com quais palavras a palavra **“trabalho”** é **antecedida**:

```{r}
bigrams_filtrados %>%
  filter(word2 == "trabalho") %>%
  count(word1, sort = TRUE)
```

Ou com quais palavras **“ambiente”** é **sucedida**:

```{r}
bigrams_filtrados %>%
  filter(word1 == "ambiente") %>%
  count(word2, sort = TRUE)
```

Ou **ambos**:

```{r}
bind_rows(
  bigrams_filtrados %>%
    filter(word2 == "ambiente") %>%
    count(word1, sort = TRUE) %>%
    rename(word = word1),
  
  bigrams_filtrados %>%
    filter(word1 == "ambiente") %>%
    count(word2, sort = TRUE) %>%
    rename(word = word2)
) %>%
  arrange(desc(n))
```

### Ngrams

Repetindo o procedimento para **trigrams**:

```{r}
corpus_docs %>%
  unnest_tokens(trigram, texto, token = "ngrams", n = 3) %>%
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%
  anti_join(stopwords_df, by = c("word1" = "word")) %>%
  anti_join(stopwords_df, by = c("word2" = "word")) %>%
  anti_join(stopwords_df, by = c("word3" = "word")) %>%
  count(word1, word2, word3, sort = TRUE)
```

## Onde aprender um pouco mais?

* **Expressões regulares e *stringr* (em português)**: seção do livro *Ciência de Dados em R* do curso-r: [https://livro.curso-r.com/7-4-o-pacote-stringr.html](https://livro.curso-r.com/7-4-o-pacote-stringr.html)
* **Strings (em inglês)**: capítulo do *R for Data Science*: [https://r4ds.had.co.nz/strings.html](https://r4ds.had.co.nz/strings.html)
* **Livro do *tidytext***: *Text Mining with R*: [http://tidytextmining.com/](http://tidytextmining.com/)
* **Capítulos sugeridos (após este tutorial)**:

  * Cap. 2 — Análise de Sentimento (inglês): [http://tidytextmining.com/sentiment.html](http://tidytextmining.com/sentiment.html)
  * Cap. 3 — Frequência de Palavras / TF-IDF: [http://tidytextmining.com/tfidf.html](http://tidytextmining.com/tfidf.html)
  * Cap. 4 — N-gramas e correlação: [http://tidytextmining.com/ngrams.html](http://tidytextmining.com/ngrams.html)
  * Cap. 6 — Topic Modeling: [http://tidytextmining.com/topicmodeling.html](http://tidytextmining.com/topicmodeling.html)

---
