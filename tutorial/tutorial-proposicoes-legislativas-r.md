# Tutorial — Proposições da Câmara: da API ao corpus de PDFs (com R)

Neste tutorial, voltado às pessoas já habituadas à linguagem nos primeiros encontros, vamos trabalhar com dados de proposições de Projeto de Lei na Câmara dos Deputados, criando um corpus a partir dos dados obtidos na API da Câmara, passando pelo download dos arquivos até a organização de um corpus.

> **Resumo do que vamos fazer**
>
> 1. Consultar a API da Câmara para listar os **PLs de 2025**;
> 2. Buscar os metadados de cada proposição e obter os **id** e endereços dos arquivos originais das proposições de inteiro teor;
> 3. **Baixar** os PDFs de inteiro teor;
> 4. Construir um **corpus** a partir dos pdfs para análises textuais.

---

## 0) Preparação do ambiente

Vamos começar carregando os pacotes que vamos utulizar

```r
# zera o ambiente (opcional)
rm(list = ls())

# pacotes
library(httr2)     # requests HTTP
library(jsonlite)  # parse de JSON
library(tidyverse) # dplyr, purrr, tibble, stringr etc.
library(pdftools)  # leitura de PDFs
library(stringr)   # utilidades de texto complementares
library(tidytext)  # análises textuais depois da constucao do corpus
```

---

## 1) API da Câmara dos Deputados - obtendo as proposições de PLs de 2025

Nosso primeiro objeto é entender como funciona uma API. Antes de avançar, visite a página da [API de Dados Abertos da Câmara dos Deputados](https://dadosabertos.camara.leg.br/swagger/api.html)

Para obter os dados das proposições de PLs de 2025, vamos utilizar o endpoint `/proposicoes` com os parâmetros de sigla do tipo de propisição, ano e mais alguns parâmetros obrigatórios. Vamos limitar a 100 itens.

A API da Câmara é bem simples de usar em R: vamos construir uma requisição no endpoint com `hhtr::request`, e com com `req_headers` e `req_url_query()` vamos informar o que mais vai no "header" e nos parâmetros da requisição. `req_perform` exexuta o request. O retorno, em formato json, traz um campo `dados` com as informações básicas das proposições.
```r
req <- request("https://dadosabertos.camara.leg.br/api/v2/proposicoes") |>
  req_headers(Accept = "application/json") |>
  req_url_query(
    siglaTipo = "PL",
    ano = 2025,
    ordem = "ASC",
    ordenarPor = "id",
    itens = 100
  )

resp  <- req_perform(req)
props <- resp_body_json(resp, simplifyVector = TRUE)$dados
df_proposicoes_simples <- as_tibble(props)

glimpse(df_proposicoes_simples)
```

> **Nota rápida sobre paginação da API**: se você quiser **mais que 100** registros, inclua o parâmetro `pagina` em loop. 

O resultado do processo é um data frame que contém uma informação essencial para o próximo passo, que é o **id** da inspeção. Vamos agora utilizar estes ids em outro endpoint da API para obter informações detalhadas das proposições

---

## 2) Função para buscar o **detalhe** de uma proposição

Agora, para cada `id` da etapa anterior, buscamos o detalhe no endpoint `/proposicoes/{id}`. A função abaixo retorna um `tibble` “achatado” com campos úteis, incluindo o **`urlInteiroTeor`**, que é o endereço que contém o documento da proposição.

```r
obter_proposicao_detalhe <- function(id) {
  req  <- request(paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes/", id))
  resp <- req_perform(req)
  proposicao <- resp_body_json(resp, simplifyVector = TRUE)$dados

  status_proposicao <- proposicao$statusProposicao %||% list()

  tibble(
    id                         = proposicao$id %||% NA_integer_,
    siglaTipo                  = proposicao$siglaTipo %||% NA_character_,
    numero                     = proposicao$numero %||% NA_integer_,
    ano                        = proposicao$ano %||% NA_integer_,
    descricaoTipo              = proposicao$descricaoTipo %||% NA_character_,
    ementa                     = proposicao$ementa %||% NA_character_,
    ementaDetalhada            = proposicao$ementaDetalhada %||% NA_character_,
    keywords                   = proposicao$keywords %||% NA_character_,
    dataApresentacao           = proposicao$dataApresentacao %||% NA_character_,
    urlInteiroTeor             = proposicao$urlInteiroTeor %||% NA_character_,
    uriAutores                 = proposicao$uriAutores %||% NA_character_,
    status_dataHora            = status_proposicao$dataHora %||% NA_character_,
    status_sequencia           = status_proposicao$sequencia %||% NA_integer_,
    status_siglaOrgao          = status_proposicao$siglaOrgao %||% NA_character_,
    status_regime              = status_proposicao$regime %||% NA_character_,
    status_descricaoTramitacao = status_proposicao$descricaoTramitacao %||% NA_character_,
    status_codTipoTramitacao   = status_proposicao$codTipoTramitacao %||% NA_character_,
    status_descricaoSituacao   = status_proposicao$descricaoSituacao %||% NA_character_,
    status_codSituacao         = status_proposicao$codSituacao %||% NA_integer_,
    status_despacho            = status_proposicao$despacho %||% NA_character_,
    status_ambito              = status_proposicao$ambito %||% NA_character_,
    status_apreciacao          = status_proposicao$apreciacao %||% NA_character_
  )
}

```

> Repare nas escolhas de tratamento de `NULL` com `%||%` e no uso de `purrr::possibly()` pra evitar erros. `purrr::possibly()` contribui para evitar quebra do código quando uma página pode falhar, ou seja, seguimos e coletamos o que der. 

```r

safe_obter_proposicao_detalhe <- purrr::possibly(obter_proposicao_detalhe, otherwise = NULL)
```

Com `purrr::map_df` vamos aplicar a função a todos os ids das proposições coletadas na seção anterior, dando um intervalo de 0,1 segundo para não sobrecarregar a API. `purrr::map_df` já retorna todos os dataframes coletados com `obter_proposicao_detalhe` em um único data frame, facilitando nossa vida:

```r

df_proposicoes <- purrr::map_df(df_proposicoes_simples$id, function(x) {
  Sys.sleep(0.1)
  safe_obter_proposicao_detalhe(x)
})

glimpse(df_proposicoes)
```

O resultado é um novo data frame que contém um grande conjunto de dados das proposições.

---

## 3) **Baixar** os PDFs de inteiro teor

Com os urls dos documentos de inteiro teor, podemos fazer o download da coleção completa dos dados. Vamos criar uma função simples de download. Vamos usar `tryCatch` e uma versão “safe” com `possibly` para eveitar novamente quebra do código.  Cada arquivo será salvo com o nome "id" + ".pdf", para podermos associar às proposições por id.

```r
baixar_inteiro_teor <- function(id, url, diretorio = "inteiro_teor") {
  
  if (is.null(url) || !nzchar(url)) return(invisible(NULL))  # sem URL, sem download

  if (!dir.exists(diretorio)) dir.create(diretorio)

  destino <- file.path(diretorio, paste0(id, ".pdf"))
  req  <- request(url)
  resp <- tryCatch(req_perform(req), error = function(e) e)

  if (inherits(resp, "error")) return(invisible(NULL))  # falhou a request

  writeBin(resp_body_raw(resp), destino)
}

safe_baixar_inteiro_teor <- purrr::possibly(baixar_inteiro_teor, otherwise = NULL)

```

Com `purrr::walk` aplicamos `baixar_inteiro_teor` a todos os ids, fazendo o download de todos nos arquvios no diretório "inteiro_teor" que vamos criar.

```r
dir.create("inteiro_teor")

purrr::walk(df_proposicoes$id, function(x){
  Sys.sleep(0.1)
  url_pdf <- df_proposicoes %>% filter(id == x) %>% pull(urlInteiroTeor) %>% .[[1]]
  safe_baixar_inteiro_teor(x, url_pdf, "inteiro_teor")
})

arquivos <- list.files("inteiro_teor", pattern = "\\.pdf$")

length(arquivos); head(arquivos, 10)
```

---

## 4) Lendo os PDFs com `pdftools` e montando um **corpus**

Agora a parte final da coleta dos dados: transformar os PDFs baixados em uma única tabela com **id**, **número de páginas**, **texto completo** e **tamanho** (em caracteres). Para termos um texto único para proposição, e não um vetor que contém o texto de cada página, vamos "colar" os textos extraídos com `collapse = '\n'`. No que estamos presumindo que os documentos tem OCR (para 2025 isso é um pressuposto aceitável). Caso os documentos não tenham caracteres reconhecíveis, temos que aplicar uma função de OCR antes de extrair o texto. **corpus_docs** contém o resultado:

```r
ler_pdf <- function(arquivo_pdf, pasta = "inteiro_teor") {
  caminho <- file.path(pasta, arquivo_pdf)
  # extrai texto por página
  paginas <- pdftools::pdf_text(caminho)

  tibble(
    id           = str_replace(arquivo_pdf, "\\.pdf$", ""),
    n_paginas    = length(paginas),
    text         = paste(paginas, collapse = "\n"),
    n_caracteres = nchar(text)
  )
}

corpus_docs <- purrr::map_dfr(arquivos, ler_pdf)
glimpse(corpus_docs)
```

---

## 5) **(Opcional)**: já dá pra brincar com `tidytext` neste ponto, fazendo tokenização, remoção de stopwords, contagens etc.

```r
stop_pt <- stopwords::stopwords("pt")

tokens <- corpus_docs %>%
  select(id, text) %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% stop_pt, str_detect(word, "[[:alpha:]]"))

top_palavras <- tokens %>%
  count(word, sort = TRUE) %>%
  slice_head(n = 30)

top_palavras
```

> Dica: se quiser padronizar antes (minúsculas, remover pontuação, tirar acentos), reaproveite o pipeline do Tutorial 12 (`str_to_lower`, `str_remove_all("[:punct:]")`, função `remove_acentos`) antes de tokenizar. Isso costuma deixar o corpus mais fácil de trabalhar. 
