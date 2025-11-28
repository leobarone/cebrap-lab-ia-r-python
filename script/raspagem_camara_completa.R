rm(list = ls())
library(httr2)
library(jsonlite)
library(tidyverse)
library(pdftools)
library(stringr)
library(tidytext)
library(stopwords)
library(stringi)

# 1) Requisição base (primeira página)
base_req <- request("https://dadosabertos.camara.leg.br/api/v2/proposicoes") |>
  req_headers(Accept = "application/json") |>
  req_url_query(
    siglaTipo = "PL",
    ano       = 2025,
    ordem     = "ASC",
    ordenarPor = "id",
    itens     = 100,   # máximo por página
    pagina    = 1
  )

# Função auxiliar para baixar 1 página
get_page <- function(req) {
  resp  <- req_perform(req)
  body  <- resp_body_json(resp, simplifyVector = TRUE)
  
  dados <- as_tibble(body$dados)
  
  # 'links' vem como data.frame com colunas rel, href, type
  links <- as_tibble(body$links)
  
  list(dados = dados, links = links)
}

# 2) Loop de paginação: segue o link "next" até acabar
paginas   <- list()
pagina_atual_req <- base_req
i <- 1

repeat {
  cat("Baixando página", i, "...\n")
  pg <- get_page(pagina_atual_req)
  
  # guarda dados da página
  paginas[[i]] <- pg$dados
  
  # tenta achar link "next"
  next_href <- pg$links |>
    filter(rel == "next") |>
    pull(href)
  
  # se não há "next", terminou
  if (length(next_href) == 0) break
  
  # monta nova requisição a partir do href retornado
  pagina_atual_req <- request(next_href) |>
    req_headers(Accept = "application/json")
  
  i <- i + 1
}

# 3) Junta tudo em um único tibble
df_proposicoes_simples <- bind_rows(paginas)

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
  print(x)
  Sys.sleep(0.1)
  safe_obter_proposicao_detalhe(x)
})

glimpse(df_proposicoes)

# save.image('df-comleto.RData')

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
  print(x)
  Sys.sleep(0.1)
  url_inteiro_teor <- df_proposicoes %>% filter(id == x) %>% pull(urlInteiroTeor)
  safe_baixar_inteiro_teor(x, url_inteiro_teor, 'inteiro_teor')
}
)

arquivos <- list.files("inteiro_teor")

# save.image('inteiro-teor-baixado.RData')

ler_pdf <- function(arquivo) {
  caminho <- file.path("inteiro_teor", arquivo)
  
  tryCatch(
    {
      txt_pages <- pdf_text(caminho)
      
      tibble(
        id           = str_replace(arquivo, "\\.pdf$", ""),
        n_paginas    = length(txt_pages),
        text         = paste(txt_pages, collapse = "\n"),
        n_caracteres = nchar(text)
      )
    },
    error = function(e) {
      warning("Falha ao ler ", caminho, ": ", e$message)
      
      # Você pode escolher o que fazer com arquivos ruins.
      # Aqui eu retorno uma linha com NA:
      tibble(
        id           = str_replace(arquivo, "\\.pdf$", ""),
        n_paginas    = NA_integer_,
        text         = NA_character_,
        n_caracteres = NA_integer_
      )
    }
  )
}

corpus_docs <- map_dfr(arquivos, ler_pdf)

# save.image('corpus-completo.RData')
load('corpus-completo.RData')

corpus_docs %>% write_csv2('corpus-completo.csv', quote = "all")
# df_proposicoes %>% write_csv2('proposicoes.csv', quote = "all")
# 
# df_proposicoes %>% glimpse()
# df_proposicoes$uriAutores

get_deputado_info <- function(dep_id) {
  url_dep <- paste0("https://dadosabertos.camara.leg.br/api/v2/deputados/", dep_id)
  
  req <- request(url_dep) |>
    req_headers(Accept = "application/json") |>
    req_url_query(formato = "json")
  
  resp  <- req_perform(req)
  body  <- resp_body_json(resp, simplifyVector = TRUE)
  
  d <- body$dados
  
  # redeSocial vem como vetor; vamos colapsar em uma string só
  redes <- d$redeSocial
  if (is.null(redes) || length(redes) == 0) {
    redes <- NA_character_
  }
  
  tibble(
    id_autor         = as.integer(d$id),
    nomeCivil        = d$nomeCivil,
    nomeParlamentar  = d$ultimoStatus$nome,
    siglaPartido     = d$ultimoStatus$siglaPartido,
    siglaUf          = d$ultimoStatus$siglaUf,
    idLegislatura    = d$ultimoStatus$idLegislatura,
    emailGabinete    = d$ultimoStatus$gabinete$email,
    telefoneGabinete = d$ultimoStatus$gabinete$telefone,
    gabineteNome     = d$ultimoStatus$gabinete$nome,
    sexo             = d$sexo,
    dataNascimento   = d$dataNascimento,
    escolaridade     = d$escolaridade,
    redesSociais     = paste(redes, collapse = "; ")
    # CPF também está disponível, mas em geral é melhor não armazenar por ser dado sensível
    # cpf           = d$cpf
  )
}

# Versão segura (não quebra o loop se der erro em um deputado)
safe_get_deputado_info <- purrr::possibly(
  get_deputado_info,
  otherwise = tibble()
)

#-------------------------------
# 2) Função para buscar autores de UMA proposição
#-------------------------------
get_autores_proposicao <- function(id_prop, uri_autores) {
  print(id_prop)
  if (is.na(uri_autores) || uri_autores == "") {
    return(tibble())
  }
  
  req <- request(uri_autores) |>
    req_headers(Accept = "application/json") |>
    req_url_query(formato = "json")
  
  resp <- req_perform(req)
  body <- resp_body_json(resp, simplifyVector = TRUE)
  
  if (length(body$dados) == 0) {
    return(tibble())
  }
  
  autores <- as_tibble(body$dados) |>
    mutate(
      id_proposicao = id_prop,
      # heurística: parlamentar se tipo for "Deputado(a)" (ou derivados)
      # ou se a URI apontar para /deputados/
      is_parlamentar = tipo %in% c("Deputado(a)", "Deputado", "Senador", "Senador(a)") |
        str_detect(uri, "/deputados/"),
      # extrair ID numérico do final da URI, quando for parlamentar
      id_autor = if_else(
        is_parlamentar,
        as.integer(str_extract(uri, "\\d+$")),
        NA_integer_
      )
    )
  
  # Buscar detalhes para todos os deputados distintos desta proposição
  dep_ids <- autores$id_autor[autores$is_parlamentar & !is.na(autores$id_autor)] |> unique()
  
  if (length(dep_ids) > 0) {
    dep_infos <- map_dfr(dep_ids, ~{
      # pequeno intervalo para não "martelar" a API; ajuste se quiser
      Sys.sleep(0.1)
      safe_get_deputado_info(.x)
    })
    
    autores <- autores |>
      left_join(dep_infos, by = "id_autor")
  }
  
  autores |>
    transmute(
      id_proposicao,
      id_autor,
      nome_autor = nome,          # nome que veio em /proposicoes/:id/autores
      is_parlamentar,
      tipo_autor   = tipo,
      codTipo,
      ordemAssinatura,
      proponente,
      # campos detalhados do deputado (ficam NA se não for parlamentar)
      nomeCivil,
      nomeParlamentar,
      siglaPartido,
      siglaUf,
      idLegislatura,
      emailGabinete,
      telefoneGabinete,
      gabineteNome,
      sexo,
      dataNascimento,
      escolaridade,
      redesSociais
    )
}

# Versão segura da função de autores
safe_get_autores_proposicao <- purrr::possibly(
  get_autores_proposicao,
  otherwise = tibble()
)

#-------------------------------
# 3) Aplicar a TODAS as proposições
#-------------------------------
df_autores <- df_proposicoes %>%
  select(id, uriAutores) %>%
  filter(!is.na(uriAutores), uriAutores != "") %>%
  mutate(
    autores = map2(id, uriAutores, safe_get_autores_proposicao)
  ) %>%
  unnest(autores)

# Resultado:
df_autores %>% glimpse()

df_autores %>% 
  glimpse()
df_autores %>% write_csv2('proposicoes-autores.csv', quote = "all")
df_proposicoes %>% 
  glimpse()
df_proposicoes %>% write_csv2('proposicoes-detalhes.csv', quote = "all")
