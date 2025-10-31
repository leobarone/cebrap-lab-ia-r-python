# ------------------------------------------------------------
# Oficina: Introdução ao R e ao dplyr (script consolidado)
# ------------------------------------------------------------
# Este script reúne, em uma única sequência, os trechos de código
# apresentados na apostila. Você pode rodar tudo de cima a baixo.
# ------------------------------------------------------------

# 1) Instalação e carregamento de pacotes (execute uma vez por máquina)
# Obs.: execute install.packages() somente se ainda não tiver os pacotes.
# install.packages('dplyr')
# install.packages('tidyverse')

library(dplyr)
library(tidyverse)  # carrega readr, stringr, ggplot2, etc.

# 2) URL dos dados (Cadastro de Escolas – Prefeitura de São Paulo)
url_escolas <- "https://dados.prefeitura.sp.gov.br/dataset/8da55b0e-b385-4b54-9296-d0000014ddd5/resource/533188c6-1949-4976-ac4e-acd313415cd1/download/escolas122024.csv"

# 3) Abertura dos dados
escolas <- read_csv2(url_escolas)

# 4) Exploração inicial (sem olhar a matriz inteira)
# View(escolas)  # opcional e interativo; comente ou descomente conforme preferir
head(escolas)      # primeiras 6 linhas
nrow(escolas)      # nº de linhas (escolas)
ncol(escolas)      # nº de colunas (variáveis)
names(escolas)     # nomes das variáveis

# 5) Comentários no código (exemplos)
# Imprime o nome das variáveis do data frame 'escolas'
names(escolas)
names(escolas) # mesmo comando com comentário no fim da linha

# 6) Argumentos/parâmetros de funções (exemplo com head)
head(x = escolas, n = 10)  # mostra 10 linhas

# 7) Mais funções para explorar os dados
str(escolas)       # estrutura do objeto
glimpse(escolas)   # visão "limpa" (do dplyr/tibble)

# 8) Renomeando variáveis (primeiro com rename direto)
# Atenção: os nomes originais são maiúsculos neste dataset.
# Ex.: DRE, CODESC, TIPOESC, NOMES, DIRETORIA, LATITUDE, LONGITUDE, CODINEP
escolas <- rename(
  escolas,
  dre_abreviatura = DRE,
  codigo          = CODESC,
  tipo            = TIPOESC,
  nome            = NOMES,
  dre             = DIRETORIA,
  lat             = LATITUDE,
  lon             = LONGITUDE,
  codigo_inep     = CODINEP
)

# 9) Selecionando colunas relevantes
escolas <- select(
  escolas,
  dre_abreviatura,
  codigo,
  tipo,
  nome,
  dre,
  lat,
  lon,
  codigo_inep
)

# 10) Exemplo equivalente usando pipeline (%>%) desde a leitura (didático)
# (mantemos o resultado no mesmo objeto 'escolas' para seguir com o fluxo)
escolas <- url_escolas %>%
  read_csv2() %>%
  rename(
    dre_abreviatura = DRE,
    codigo          = CODESC,
    tipo            = TIPOESC,
    nome            = NOMES,
    dre             = DIRETORIA,
    lat             = LATITUDE,
    lon             = LONGITUDE,
    codigo_inep     = CODINEP
  ) %>%
  select(
    dre_abreviatura,
    codigo,
    tipo,
    nome,
    dre,
    lat,
    lon,
    codigo_inep
  )

# 11) Transformações de variáveis (mutate)
# - lat está sem separador decimal → dividir por 1e6
# - lon vem com separadores inconsistentes → remover pontos, transformar em numérico e dividir por 1e6
escolas <- escolas %>%
  mutate(
    lat = as.numeric(lat) / 1000000,
    lon = stringr::str_replace_all(lon, "\\.", ""),
    lon = as.numeric(lon) / 1000000
  )

# 12) Filtrando linhas (exemplos)
# 12.1) Apenas EMEIs
emeis <- escolas %>%
  filter(tipo == "EMEI")

# 12.2) Creches (três categorias)
creches <- escolas %>%
  filter(
    tipo == "CEI DIRET" |
      tipo == "CEI INDIR" |
      tipo == "CR.P.CONV"
  )

# 12.3) Creches na DRE Ipiranga (com 'e' lógico e duas variáveis)
creches_ipiranga <- escolas %>%
  filter(
    (tipo == "CEI DIRET" |
       tipo == "CEI INDIR" |
       tipo == "CR.P.CONV"),
    dre == "DIRETORIA REGIONAL DE EDUCACAO IPIRANGA"
  )

# 13) Saídas rápidas para conferir
head(emeis)
head(creches)
head(creches_ipiranga)

# Fim do script
