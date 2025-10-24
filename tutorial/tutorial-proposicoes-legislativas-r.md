# Tutorial — Proposições da Câmara: da API ao corpus de PDFs (com R)

> **Resumo do que vamos fazer**
>
> 1. Consultar a API da Câmara para listar **PLs de 2025**;
> 2. Para cada **id**, buscar o **detalhe** (status, ementa, url do inteiro teor…);
> 3. **Baixar** os PDFs de inteiro teor;
> 4. Ler os PDFs com `pdftools` e montar um **corpus** para análises textuais.

> Dica de estilo: vou manter a mesma pegada “tutorial passo-a-passo + comentários no código” que você usa — com pequenas pausas pra reflexão e micro-exercícios — como nos tutoriais de API, PDF, tidytext e stringr do seu curso.    

---

## 0) Preparação do ambiente

Vamos começar “limpando a casa” e carregando os pacotes. Tudo que não for essencial fica de fora por agora; adicionamos depois se precisar.

```r
# zera o ambiente (opcional)
rm(list = ls())

# pacotes
library(httr2)     # requests HTTP modernos e simples
library(jsonlite)  # parse de JSON quando precisar
library(tidyverse) # dplyr, purrr, tibble, stringr etc.
library(pdftools)  # leitura de PDFs
library(stringr)   # utilidades de texto complementares
library(tidytext)  # (opcional) análises textuais depois
```

---

## 1) Puxando a **lista simples** de proposições (PL, 2025) via API

A API da Câmara é bem razoável de usar: montamos uma requisição com `req_url_query()` e pedimos `Accept: application/json`. O retorno traz um campo `dados` com as proposições “básicas”. Essa etapa espelha seu estilo no tutorial de APIs (organizar endpoint, parâmetros e depois parsear), só que agora com `httr2` em vez de `httr`. 

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

> **Nota rápida sobre paginação**: se você quiser **mais que 100** registros, inclua o parâmetro `pagina` em loop — a mesma lógica de loops que você ensina nos exercícios com sequências (ver Tutorial 5). 

---

## 2) Função para buscar o **detalhe** de uma proposição

Agora, para cada `id` da etapa anterior, buscamos o detalhe em `/proposicoes/{id}`. A função abaixo retorna um `tibble` “achatado” com campos úteis, incluindo **status de tramitação** e o **`urlInteiroTeor`** (quando houver).

> Repare nas escolhas de tratamento de `NULL` com `%||%` e no uso de `purrr::possibly()` pra robustez — o mesmo espírito que você já usa nos tutoriais de raspagem quando uma página pode falhar: seguimos o baile e coletamos o que der. 

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

safe_obter_proposicao_detalhe <- purrr::possibly(obter_proposicao_detalhe, otherwise = NULL)

# iteramos com uma pequena pausa por respeito à API
df_proposicoes <- purrr::map_df(df_proposicoes_simples$id, function(x) {
  Sys.sleep(0.1)
  safe_obter_proposicao_detalhe(x)
})

glimpse(df_proposicoes)
```

**Exercício relâmpago:** acrescente uma coluna booleana `tem_pdf = nzchar(urlInteiroTeor)` e faça um `count(tem_pdf)` para ver quantas têm/ não têm PDF.

---

## 3) **Baixar** os PDFs de inteiro teor

Vamos criar uma função simples de download. Mantenho `tryCatch` e uma versão “safe” com `possibly` — padrão robusto que você curte nos seus tutoriais de raspagem e formulários.  

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

# loop de downloads (com pausa curtinha)
purrr::walk(df_proposicoes$id, function(x){
  Sys.sleep(0.1)
  url_pdf <- df_proposicoes %>% filter(id == x) %>% pull(urlInteiroTeor) %>% .[[1]]
  safe_baixar_inteiro_teor(x, url_pdf, "inteiro_teor")
})

# checagem rápida
arquivos <- list.files("inteiro_teor", pattern = "\\.pdf$")
length(arquivos); head(arquivos, 10)
```

> **Observação**: quando falamos de baixar arquivos em massa e nomear certinho, a sua metodologia é a mesma que aparece nos tutoriais de web scraping e também quando você pega PDFs científicos/relatórios (nome vindo do id; `unique()` quando necessário; checagens de existência etc.).  

---

## 4) Lendo os PDFs com `pdftools` e montando um **corpus**

Agora a parte gostosa: transformar dezenas/centenas de PDFs em uma única tabela com **id**, **número de páginas**, **texto completo** e **tamanho** (em caracteres). A estratégia de “ler todas as páginas, colar com `collapse = '\n'` e construir um tibble” segue exatamente a prática dos seus exercícios de PDF. 

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

**(Opcional)**: já dá pra brincar com `tidytext` neste ponto — tokenização, remoção de stopwords, contagens etc., como você mostra nos tutoriais 12 e 13. Abaixo vai um aquecimento bem curto, só pra validar o corpus.  

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

> Dica: se quiser padronizar antes (minúsculas, remover pontuação, tirar acentos), reaproveite o pipeline do Tutorial 12 (`str_to_lower`, `str_remove_all("[:punct:]")`, função `remove_acentos`) antes de tokenizar. Isso costuma deixar o corpus redondinho. 

---

## 5) Robustez, paginação e pequenas melhorias

* **Paginação**: a API retorna 100 por página. Para varrer tudo, faça um loop em `pagina = 1:n` enquanto `length(dados) > 0`. É a mesma lógica do seu loop de páginas (sequências) — só que aqui o “contador” é o parâmetro `pagina`. 
* **Falhas de rede**: além de `possibly()`, você pode implementar **backoff** simples (tentar 3x com `Sys.sleep()` exponencial).
* **Checagem de PDF**: alguns `urlInteiroTeor` podem apontar para HTML/indisponível. Um try pequeno já resolve.
* **Versões**: salve `df_proposicoes` e `corpus_docs` com `write_csv()`/`write_rds()` pra não ter que re-rodar tudo.

---

## 6) Tarefinhas (pra se acostumar com o fluxo)

1. **Contar por situação**: do `df_proposicoes`, crie um `count(status_descricaoSituacao, sort = TRUE)`.
2. **Filtrar só quem tem PDF** e refaça o corpus.
3. **Limpeza textual extra**: padronize o texto do corpus com o mini-pipeline do seu Tutorial 12 antes de tokenizar. Compare as 30 palavras mais frequentes **antes x depois**. 
4. **Bigrams**: gere bigrams com `unnest_tokens(bigram, text, token = "ngrams", n = 2)` e filtre stopwords como no Tutorial 13. Quais são as duplas mais comuns? 

---

## 7) Código completo (copiar/colar)

```r
# --- Setup ---
rm(list = ls())
library(httr2)
library(jsonlite)
library(tidyverse)
library(pdftools)
library(stringr)
library(tidytext)
library(stopwords)

# --- 1) Lista simples (PL/2025) ---
req <- request("https://dadosabertos.camara.leg.br/api/v2/proposicoes") |>
  req_headers(Accept = "application/json") |>
  req_url_query(siglaTipo = "PL", ano = 2025, ordem = "ASC", ordenarPor = "id", itens = 100)

resp  <- req_perform(req)
props <- resp_body_json(resp, simplifyVector = TRUE)$dados
df_proposicoes_simples <- as_tibble(props)

# --- 2) Detalhes por id ---
obter_proposicao_detalhe <- function(id) {
  req  <- request(paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes/", id))
  resp <- req_perform(req)
  p <- resp_body_json(resp, simplifyVector = TRUE)$dados
  s <- p$statusProposicao %||% list()
  tibble(
    id = p$id %||% NA_integer_,
    siglaTipo = p$siglaTipo %||% NA_character_,
    numero = p$numero %||% NA_integer_,
    ano = p$ano %||% NA_integer_,
    descricaoTipo = p$descricaoTipo %||% NA_character_,
    ementa = p$ementa %||% NA_character_,
    ementaDetalhada = p$ementaDetalhada %||% NA_character_,
    keywords = p$keywords %||% NA_character_,
    dataApresentacao = p$dataApresentacao %||% NA_character_,
    urlInteiroTeor = p$urlInteiroTeor %||% NA_character_,
    uriAutores = p$uriAutores %||% NA_character_,
    status_dataHora = s$dataHora %||% NA_character_,
    status_sequencia = s$sequencia %||% NA_integer_,
    status_siglaOrgao = s$siglaOrgao %||% NA_character_,
    status_regime = s$regime %||% NA_character_,
    status_descricaoTramitacao = s$descricaoTramitacao %||% NA_character_,
    status_codTipoTramitacao = s$codTipoTramitacao %||% NA_character_,
    status_descricaoSituacao = s$descricaoSituacao %||% NA_character_,
    status_codSituacao = s$codSituacao %||% NA_integer_,
    status_despacho = s$despacho %||% NA_character_,
    status_ambito = s$ambito %||% NA_character_,
    status_apreciacao = s$apreciacao %||% NA_character_
  )
}
safe_obter_proposicao_detalhe <- purrr::possibly(obter_proposicao_detalhe, otherwise = NULL)

df_proposicoes <- purrr::map_df(df_proposicoes_simples$id, function(x) {
  Sys.sleep(0.1)
  safe_obter_proposicao_detalhe(x)
})

# --- 3) Download dos PDFs ---
baixar_inteiro_teor <- function(id, url, diretorio = "inteiro_teor") {
  if (is.null(url) || !nzchar(url)) return(invisible(NULL))
  if (!dir.exists(diretorio)) dir.create(diretorio)
  destino <- file.path(diretorio, paste0(id, ".pdf"))
  req  <- request(url)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) return(invisible(NULL))
  writeBin(resp_body_raw(resp), destino)
}
safe_baixar_inteiro_teor <- purrr::possibly(baixar_inteiro_teor, otherwise = NULL)

purrr::walk(df_proposicoes$id, function(x){
  Sys.sleep(0.1)
  url_pdf <- df_proposicoes %>% filter(id == x) %>% pull(urlInteiroTeor) %>% .[[1]]
  safe_baixar_inteiro_teor(x, url_pdf, "inteiro_teor")
})

arquivos <- list.files("inteiro_teor", pattern = "\\.pdf$")

# --- 4) Ler PDFs e montar corpus ---
ler_pdf <- function(arq, pasta = "inteiro_teor") {
  paginas <- pdftools::pdf_text(file.path(pasta, arq))
  tibble(
    id = str_replace(arq, "\\.pdf$", ""),
    n_paginas = length(paginas),
    text = paste(paginas, collapse = "\n"),
    n_caracteres = nchar(text)
  )
}
corpus_docs <- purrr::map_dfr(arquivos, ler_pdf)

# --- 5) (Opcional) Primeiros tokens ---
stop_pt <- stopwords::stopwords("pt")
tokens <- corpus_docs %>%
  select(id, text) %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% stop_pt, str_detect(word, "[[:alpha:]]"))

top_palavras <- tokens %>% count(word, sort = TRUE) %>% slice_head(n = 30)
top_palavras
```

---

### Fechamento

Com esse pipeline você sai da **API** direto para um **corpus de PDFs** pronto para exploração textual. A arquitetura é a mesma que você já domina nos seus tutoriais: **requisição → iteração segura → download nomeado → leitura batelada → data frame canônico** — e, se quiser, emenda **`stringr`** pra limpeza e **`tidytext`** pra análise.    

Se quiser, eu já adapto o texto pra **RMarkdown/Quarto** com sumário, `code_folding` e seção de “tarefas”, no mesmo formato dos seus PDFs do curso.
