rm(list=ls())
library(httr2)
library(jsonlite)
library(tidyverse)
library(pdftools)
library(stringr)
library(tidytext)
library(stopwords)
library(stringi)


req <- request("https://dadosabertos.camara.leg.br/api/v2/proposicoes") |>
  req_headers(Accept = "application/json") |>
  req_url_query(
    siglaTipo = "PL",
    ano = 2025,
    ordem = "ASC",
    ordenarPor = "id",
    itens = 100,
  )

resp <- req_perform(req)
props <- resp_body_json(resp, simplifyVector = TRUE)$dados
df_proposicoes_simples <- as_tibble(props)

glimpse(df_proposicoes_simples)



obter_proposicao_detalhe <- function(id) {

  req <- request(paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes/", id))
  
  resp <- req_perform(req)
  proposicao <- resp_body_json(resp, simplifyVector = TRUE)
  
  proposicao <- proposicao$dados
  
  status_proposicao <- proposicao$statusProposicao %||% list()
  
  tibble(
    id              = proposicao$id %||% NA_integer_,
    siglaTipo       = proposicao$siglaTipo %||% NA_character_,
    numero          = proposicao$numero %||% NA_integer_,
    ano             = proposicao$ano %||% NA_integer_,
    descricaoTipo   = proposicao$descricaoTipo %||% NA_character_,
    ementa          = proposicao$ementa %||% NA_character_,
    ementaDetalhada = proposicao$ementaDetalhada %||% NA_character_,
    keywords        = proposicao$keywords %||% NA_character_,
    dataApresentacao= proposicao$dataApresentacao %||% NA_character_,
    urlInteiroTeor  = proposicao$urlInteiroTeor %||% NA_character_,
    uriAutores      = proposicao$uriAutores %||% NA_character_,
    status_dataHora           = status_proposicao$dataHora %||% NA_character_,
    status_sequencia          = status_proposicao$sequencia %||% NA_integer_,
    status_siglaOrgao         = status_proposicao$siglaOrgao %||% NA_character_,
    status_regime             = status_proposicao$regime %||% NA_character_,
    status_descricaoTramitacao= status_proposicao$descricaoTramitacao %||% NA_character_,
    status_codTipoTramitacao  = status_proposicao$codTipoTramitacao %||% NA_character_,
    status_descricaoSituacao  = status_proposicao$descricaoSituacao %||% NA_character_,
    status_codSituacao        = status_proposicao$codSituacao %||% NA_integer_,
    status_despacho           = status_proposicao$despacho %||% NA_character_,
    status_ambito             = status_proposicao$ambito %||% NA_character_,
    status_apreciacao         = status_proposicao$apreciacao %||% NA_character_
  )

}

safe_obter_proposicao_detalhe <- possibly(obter_proposicao_detalhe, otherwise = NULL)

df_proposicoes <- map_df(df_proposicoes_simples$id, function(x) {
  Sys.sleep(0.1)
  safe_obter_proposicao_detalhe(x)
})

glimpse(df_proposicoes)


baixar_inteiro_teor <- function(id, url, diretorio) {

  nome_arquivo_pdf <- file.path(diretorio, paste0(id, '.pdf'))

  req <- request(url)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  body <- resp_body_raw(resp)
  writeBin(body, nome_arquivo_pdf)
  
}

safe_baixar_inteiro_teor <- possibly(baixar_inteiro_teor, otherwise = NULL)

dir.create('inteiro_teor')

map(df_proposicoes$id, function(x){
  Sys.sleep(0.1)
  url_inteiro_teor <- df_proposicoes %>% filter(id == x) %>% pull(urlInteiroTeor)
  safe_baixar_inteiro_teor(x, url_inteiro_teor, 'inteiro_teor')
  }
)

arquivos <- list.files("inteiro_teor")

ler_pdf <- function(arquivo) {
  txt_pages <- pdf_text(file.path('inteiro_teor', arquivo))
  tibble(
    id = str_replace(arquivo, ".pdf", ""),
    n_paginas = length(txt_pages),
    text = paste(txt_pages, collapse = "\n"),
    n_caracteres = nchar(text)
  )
}

corpus_docs <- map_dfr(arquivos, ler_pdf)

glimpse(corpus_docs)
