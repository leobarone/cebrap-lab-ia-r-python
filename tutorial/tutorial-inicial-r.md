# Tutorial Inicial - Manipulação de dados com **dplyr**

Um dos aspectos mais incríveis da linguagem R é o desenvolvimento de novas funcionalidades pela comunidade de usuárias e usuários. 

Há diversas "gramática para bases de dados", ou seja, formas de importar, organizar, manipular e extrair informações das bases de dados, que foram desenvolvidas ao longo da última década.

A "gramática" mais popular da linguagem é a do pacote _dplyr_, parte do _tidyverse_. Nesta oficina veremos como utilizar algumas das principais funções, ou "verbos", do pacote _dplyr_.

Existem outras formas de se trabalhar com conjuntos de dados mais, digamos, antigas. É comum encontrarmos códigos escritos na "gramática" original da linguagem, que chamaremos de "base" ou "básico".

Podemos pensar na linguagem R como uma língua com diversos dialétos. Os dois dialétos mais falados para manipulação de dados são o "base" e o do pacote _dplyr_.

# Instalando e carregando pacotes no R

Quando você abre R ou RStudio, diversas funções estão disponíveis para uso. Elas são parte do pacote "base", que é carregado automaticamente. "base" é a linguagem tal como ela foi desenhada originalmente.

Se quiseremos utilizar funções de pacotes desenvolvidos na comunidade de R que não sejam parte do "base", precisamos instalar _pacotes_ e carregá-los ao iniciar a seção. Vamos ver como fazer isso.

Em primeiro lugar, vamos instalar um pacote. Começaremos com o _dplyr_

```{r}
install.packages('dplyr')
```

Lembre-se de colocar aspas no nome do pacote, pois, até agora, _dplyr_ é um nome desconhecido para a linguagem R no seu computador.

Após a instalação, sempre que queremos utilizar o pacote _dplyr_ devemos carregá-lo com a função _library_. Você deve fazer isso toda vez que abrir R.

```{r}
library(dplyr)
```

Pronto!

Antes de avançar, treine com outros dois pacotes: _ggplot2_, que é a gramática de visualização de dados que utilizaremos na oficina; e _tidyverse_, que é um pacote guarda-chuva que contém _dplyr_, _gglopt2_ e vários outros, ou seja, ao carregá-lo, você carrega um conjunto de pacotes. Tidyverse também é um "movimento" de reescrever a linguagem sobre a qual falaremos um pouquinho. 

# Introdução ao pacote _dplyr_

## Começando pelo meio: data frames

Uma característica distintiva da linguagem de programação R é ter sido desenvolvida para a análise de dados. E quando pensamos em análise de dados, a protagonista do show é a _base de dados_ ou, como vamos conhecer a partir de agora, __data frame__.

Por esta razão, em vez de aprender como fazer aritmética, elaborar funções ou executar loops para repetir tarefas e outros aspectos básicos da linguagem, vamos começar olhando para o R como um software concorrente dos demais utilizados para análise de dados em ciências sociais, como SPSS, Stata, SAS e companhia.

As principais características de um data frame são: (1) cada coluna representa uma variável (ou característica) de um conjunto de observações; (2) cada linha representa uma observação e contém os valores de cada variável para tal observação. Vejamos um exemplo:

| Candidato | Partido | Votos | 
| --------- |:-------:| -----:|
| Beatriz   | PMDB    |   350 | 
| Danilo    | SOL     |  1598 | 
| Pedro     | PTB     |   784 | 
| Davi      | PSD     |   580 | 
| Mateus    | PV      |   2   | 

Note que em uma linha os elementos são de tipos de diferentes: na primeira coluna há uma nome (texto), na segunda uma sigla de partido (texto, mas limitado a um conjunto de siglas) e na terceira votos (número inteiros). 

Por outro lado, em cada coluna há somente elementos de um tipo. Por exemplo, há apenas números inteiros na coluna votos. Colunas são variáveis e por isso aceitam registros de um único tipo. Se você já fez um curso de estatísticas básica ou de métodos quantitativos deve se lembrar que as variáveis são classificadas da seguinte maneira:

1- Discretas

  - Nominais, que são categorias (normalmente texto) não ordenadas
  
  - Ordinais, que são categorias (normalmente texto) ordenadas
  
  - Inteiros, ou seja, o conjunto dos números inteiros

2- Contínuas, números que podem assumir valores não inteiros

Se destacamos uma coluna do nosso data frame, temos um __vetor__. Por exemplo, a variável "Votos" pode ser presentado da seguinte maneira: {350, 1598, 784, 580, 2}. Um data frame é um conjunto de variáveis (vetores!) dispostos na vertical e combinados um ao lado do outro.

Data frame e vetores são __objetos__ na linguagem R.

Vamos ver como o R representa vetores e data frames na tela. Antes disso, é preciso "abrir" um data frame.

## Cadastro de Escolas

Neste tutorial vamos trabalhar com as bases de dados da educação municipal da cidade de São Paulo. Em particular, vamos começar trabalhando com o  cadastro de escolas da Prefeitura de São Paulo.

A página na qual você encontrará o cadastro de escolas é essa aqui [aqui](https://dados.prefeitura.sp.gov.br/dataset/cadastro-de-escolas-municipais-conveniadas-e-privadas). Comece baixando o dicionário de dados e os dados mais atuais.

## Abrindo dados em R com botão

Se você decidiu aprender a programar em R, provavelmente quer substituir a análise de dados com cliques no mouse que fazemos no editor de planilhas pela construção de scripts que documentam o passo a passo da análise. Daqui em diante estaremos num mundo sem botões. Exceto um, por enquanto, aí no canto direito superior chamado "Import Dataset".

Clique no botão. Veja que temos a opção de importar arquivos de texto com duas bibliotecas diferentes, _base_ e _readr_ (que é o pacote de abertura de dados do _tidyverse_) e dados em alguns outros formatos, como MS Excel e outros softwares de análise estatística.

Use a primeira opção, "From Text (base)" para carregar os dados do cadastro de escola.

## Abrindo dados em R (com script)


(Lembre-se de instalar e carregar o pacote _tidyverse_ antes de prosseguir)

```{r}
install.packages('tidyverse')
library(tidyverse)
```

Use o recurso "Import Dataset" enquanto não se sentir confortável com a linguagem. Mas, aos poucos, vá abandonando. Abrir dados em R é muito simples.

Repetindo o procedimento com código, para abrir o cadastro de escola basta fazer:

```{r}
url_escolas <- "https://dados.prefeitura.sp.gov.br/dataset/8da55b0e-b385-4b54-9296-d0000014ddd5/resource/533188c6-1949-4976-ac4e-acd313415cd1/download/escolas122024.csv"

escolas <- read_csv2(url_escolas)
```

Em R, as funções "read." são as funções de abertura de dados do _base_ e as funções "read_" são as análogas do pacote _readr_, parte do _tidyverse_. Há funções "read" para abrir/ler/carregar todos os tipos de dados, de arquivos de texto a páginas em HTML.

No nosso caso, utilizamos a função _read\_csv2_ para abrir um arquivo de texto cujos valores das colunas são separados por vírgula. Infelizmente, não há tempo para aprender sobre as variedades das funções de abertura de dados, mas você pode aprender um pouco mais [aqui](https://jonnyphillips.github.io/FLS6397_2019/tutorials/tutorial04.html) ou [aqui](https://r4ds.had.co.nz/data-import.html).

Note que utilizamos o URL dos dados diretamente. Não precisamos fazer download para uma pasta local para, depois, abrir os dados. 

Um jeito mais confortável, na mina opinião, de fazer a abertura de dados com um URL é guardar o URL em um objeto de texto e, depois, utilizar esse objeto como input da função:

```{r}
url_escolas <- "https://dados.prefeitura.sp.gov.br/dataset/8da55b0e-b385-4b54-9296-d0000014ddd5/resource/533188c6-1949-4976-ac4e-acd313415cd1/download/escolas122024.csv"
escolas <- read_csv2(url_escolas)
```

Note que, pela segunda vez, utilizamos o símbolo "<-". Ele é um símbolo de atribuição, e é um das marcas mais importantes da linguagem. Atribuir, significa "guardar na memória com um nome". O nome é o que vai do lado esquerdo. A parte do lado direito da equação de atribuição é o objeto a ser guardado.

Você pode usar "=" no lugar de "<-". Mas, aviso desde já, há casos em R em que há ambiguidade e os símbolos não funcionam como esperado.

Vamos avançar.

### Explorando sem olhar para a matriz de dados

No editor de planilhas estamos acostumados a ver os dados, célula a célula. Mas será que é realmente útil ficar olhando para os dados? Você perceberá com o tempo que olhar os dados é desnecessário e até contraproducente.

Você pode ver os dados clicando no nome do objeto que está no "Environment" ou utilizando a função _View_ (cuidado, o "V" é maiúsculo, algo raro em nomes de funções de R).

```{r}
View(escolas)
```

Agora que carregamos o cadastro de escolas na memória, vamos conhecer um pouco sobre estes dados sem olhar para a matriz de dados.

Podemos rapidamente olhar para uma "amostra" dos dados com a função _head_, que nos apresenta as 6 primeiras linhas do conjunto de dados.

```{r}
head(escolas)
```

Com apenas as 6 primeiras linhas do data frame temos noção de todo o conjunto. Sabemos rapidamente que existem informações sobre o nome das escolas, seus códigos de cadastro, de que tipo de escola se trata, à qual diretoria regional de ensino (DRE) pertence, etc.

Quantas escolas há? Há tantas escolas quanto linhas no data frame. Com _nrow_ descobrimos quantas são.

```{r}
nrow(escolas)
```

Quantas informações temos disponíveis para cada escola? Ou seja, quantas variáveis há no conjunto de dados?

```{r}
ncol(escolas)
```

Qual é o nome das variáveis?

```{r}
names(escolas)
```

## Pausa para um comentário

Podemos fazer comentários no meio do código. Basta usar # e tudo que seguir até o final da linha não será interpertado pelo R como código. Por exemplo:

```{r}
# Imprime o nome das variaveis do data frame cadastro
names(escolas)

names(escolas) # Repetindo o comando acima com comentario em outro lugar
```

Comentários são extremamente úteis para documentar seu código. Documentar é parte de programar e você deve pensar nas pessoas com as quais vai compartilhar o código e no fato de que com certeza não se lembrará do que fez em pouco tempo (garanto, você vai esquecer).

## Argumentos ou parâmetros das funções

Note que em todas as funções que utilizamos até agora, _escolas_ está dentro do parênteses que segue o nome da função. Essa __sintaxe__ é característica das funções de R. O que vai entre parêntesis são os __argumentos__ ou __parâmetros__ da função, ou seja, os "inputs" que serão transformados.

Uma função pode receber mais de um argumento. Pode também haver argumentos não obrigatórios, ou seja, para os quais não é necessário informar nada se você não quiser alterar os valores pré-definidos. Por exemplo, a função _head_ contém o argumento _n_, que se refere ao número de linhas a serem __impressas__ na tela, pré-estabelecido em 6 (você pode conhecer os argumentos da função na documentação do R usando _?_ antes do nome da função). Para alterar o parâmetro _n_ para 10, por exemplo, basta fazer:

```{r}
head(x = escolas, n = 10)
```

_x_ é o argumento que já havíamos utilizado anteriormente e indica em que objeto a função _head_ será aplicada. Dica: você pode omitir tanto "x =" quanto "n =" se você já conhecer a ordem de cada argumento no uso da função.

## Mais funções para explorar os dados

Todos os objetos em R tem uma estrutura. Você pode investigar essa estrutura utilizando a função _str_. No caso de data frames, o output é legível (para outras classes de objeto isso não é verdade necessariamente):

```{r}
str(escolas)
```

Há informações sobre o nome das variáveis, dispostas na vertical, tipo de dados (texto -- char -- ou números -- num ou int) e uma amostra das primeiras observações.

Uma função semelhante, e com resultado um pouco mais "limpo", é _glimpse_, parte do _dplyr_:

```{r}
glimpse(escolas)
```

Vamos agora renomear os dados.

## Renomeando variáveis

Quando trabalhamos com dados que não coletamos, em geral, não vamos gostar dos nomes das variáveis que quem produziu os dados escolheu. Mais ainda, com certa frequência, obtemos dados cujos nomes das colunas são compostos ou contêm acentuação, cedilha e demais caracteres especiais. Dá um tremendo trabalho usar nomes com tais característica, apesar de possível. O ideal é termos nomes sem espaço (você pode usar ponto ou subscrito para separar palavras em um nome composto) e que contenham preferencialmente letras minísculas sem acento e números.

Vamos começar renomeando algumas variáveis no nosso banco de dados, cujos nomes vemos com o comando abaixo:

```{r}
names(escolas)
```

O primeiro argumento da função _rename_ deve ser o objeto cujos nomes das variáveis serão renomeados. Depois da primeira vírgula, inserimos todas as modificações de nomes, novamente separadas por vírgulas, e da seguinte maneira. Exemplo 1: nome\_novo = nome\_velho. Exemplo 2: nome\_novo = Nome_Velho. Veja o exemplo abaixo, em que damos novos nomes às variáveis "tipoesc", "latitute" e "longitude":

```{r}
escolas <- rename(escolas, tipo = TIPOESC, lat = LATITUDE, lon = LONGITUDE)
```

Simples, não? 

## Uma gramática, duas formas

No _tidyverse_, existe uma outra sintaxe para executar a mesma tarefa de (re)nomeação. Vamos olhar para ela (lembre-se de carregar novamente os dados, pois os nomes velhos já não existem mais e não existe Ctrl+Z em R):

```{r, eval = F}
escolas <- read_csv2(url_escolas)

escolas <- escolas %>%
  rename(tipo = TIPOESC,
         lat = LATITUDE,
         lon = LONGITUDE)
```

Usando o operador %>%, denominado _pipe_, retiramos de dentro da função _rename_ o data frame cujas variáveis serão renomeadas. As quebras de linha depois do %>% e dentro da função _rename_ são opcionais. Porém, o pardão é 'verticalizar o código' e colcar os 'verbos' à esquerda, o que torna sua leitura mais confortável.

Compare com o código que havíamos executado anteriormente:

```{r, eval = F}
escolas <- read_csv2(url_escolas)

escolas <- rename(escolas, tipo = TIPOESC, lat = LATITUDE, lon = LONGITUDE)
```

Essa outra sintaxe tem uma vantagem grande sobre a anterior: ela permite emendar uma operação de transformação do banco de dados na outra. Veremos adiante como fazer isso. Por enquanto, tenha em mente que o resultado é o mesmo para qualquer uma das duas formas.

Vamos trabalhar com várias variáveis (sic) de uma única vez. Reabra o banco de dados:

```{r, include = F, echo=F}
escolas <- read_csv2(url_escolas)
```

Renomeie as variáveis "dre", "codesc", "tipoesc", "nomesc", "diretoria", "latitude", "longitude" e "codinep".

```{r, include = F, echo=F}
escolas <- escolas %>%
  rename(dre_abreviatura = DRE,
         codigo = CODESC,
         tipo = TIPOESC,
         nome = NOMES,
         dre = DIRETORIA,
         lat = LATITUDE,
         lon = LONGITUDE,
         codigo_inep = CODINEP)
```

## Selecionando colunas

Algumas colunas podem ser dispensáveis em nosso banco de dados a depender da análise. Por exemplo, pode ser que nos interessem apenas as variáveis que já renomeamos. Para selecionar um conjunto de variáveis, utilizaremos o segundo verbo do _dplyr_ que aprenderemos: _select_

```{r}
escolas <- select(escolas, dre_abreviatura, codigo, tipo, nome, dre, lat, lon, codigo_inep)
```

ou usando o operador %>%, chamado __pipe__.

Nota: o operador |> agora é nativo de R, mas tanto faz utilizar |> ou %>%). Nos tutoriais vamos ficar com a forma antiga %>%

```{r}
escolas <- escolas %>%
  select(dre_abreviatura,
         codigo,
         tipo,
         nome,
         dre,
         lat,
         lon,
         codigo_inep)
```

## Operador %>% para "emendar" tarefas

O que o operador __pipe__ faz é simplesmente colocar o primeiro argumento da função (no caso acima, o _data frame_), fora e antes da própria função. Ele permite lermos o código, informalmente, da seguinte maneira: "pegue o data frame x e aplique a ele esta função". Veremos abaixo que podemos fazer uma cadeia de operações ("pipeline"), que pode ser lida informalmente como: "pegue o data frame x e aplique a ele esta função, e depois essa, e depois essa outra, etc".

A grande vantagem de trabalharmos com o operador %>% é não precisar repetir o nome do _data frame_ diversas vezes ao aplicarmos a ele um conjunto de operações.

Vejamos agora como usamos o operador %>% para "emendar" tarefas, começando da abertura desde dados. Note que o primeiro input é o url da base de dados e, que, uma vez carregados, vai sendo transformado a cada novo verbo.

```{r}
escolas <- url_escolas %>%
  read_csv2() %>%
  rename(dre_abreviatura = DRE,
         codigo = CODESC,
         tipo = TIPOESC,
         nome = NOMES,
         dre = DIRETORIA,
         lat = LATITUDE,
         lon = LONGITUDE,
         codigo_inep = CODINEP)  %>%
  select(dre_abreviatura,
         codigo,
         tipo,
         nome,
         dre,
         lat,
         lon,
         codigo_inep)
```

Em uma única sequência de operações, abrimos os dados, alteramos os nomes das variáveis e selecionamos as que permaneceriam no banco de dados. Esta forma de programa,r tenha certeza, é bastante mais econômica e mais fácil de ler, pois podemos identificar erros mais facilmente.

## Transformando variáveis

Usaremos a função _mutate_ para operar transformações nas variáveis existentes e criar variáveis novas. Há inúmeras transformações possíveis e elas lembram bastante as funções de outros softwares, como MS Excel. Vamos ver algumas das mais importantes.

No nosso caso, o formato dos valores de latitude e longitude estão em formato diferente do convenional. Latitudes são representadas por números entre -90 e 90, com 8 casas decimais, e Longitudes por números entre -180 e 180, também com 8 casas decimais. Em nosso par de variáveis, latitude está sem separador de decimal está omitido. Faremos a correção divindo latitude e lonmgitude por 1 milhão.

```{r}
escolas <- escolas %>% 
  mutate(lat = lat / 1000000, 
         lon = lon / 1000000) 
```

Como utilizamos os nomes das próprias variáveis à esquerda da operação de transformação, produziremos uma substituição e não haverá novas colunas na base de dados.

## Filtrando linhas

Por vezes, queremos trabalhar apenas com um conjunto de linhas do nosso banco de dados. Por exemplo, se quisermos selecionar apenas escolas municipais de educação infantil, utilizamos o verbo 'filter' com a condição desejada. Note que estamos criando um novo data frame (ou seja, um novo objeto) que contém a seleção de linhas produzida:

```{r}
emeis <- escolas %>% 
  filter(tipo == "EMEI")
```

Além da igualdade, poderíamos usar outros símbolos: maior (>). maior ou igual (>=), menor (<), menor ou igual (<=) e diferente (!=) para selecionar casos. Para casos de _NA_, podemos usar a função is.na(), pois a igualdade '== NA' é inválida em R.

Vamos supor agora que todos centros de educação infantil (creche) da rede direta, indireta e conveniada. Como combinar condições?

```{r}
creches <- escolas %>% 
  filter(tipo == "CEI DIRET" | tipo == "CEI INDIR" | tipo == "CR.P.CONV")
```

Note que, para dizer que para combinarmos as condições de seleção de linha, utilizamos uma barra vertical. A barra é o símbolo "ou", e indica que todas as observações que atenderem a uma ou outra condição serão incluídas.

Vamos supor que queremos estabelecer agora condições para a seleção de linhas a partir de duas variáveis. Por exemplo, queremos incluir as mesmas escolas já escolhidas e que também sejam da Diretoria Regional do Ipiranga. O símbolo da conjunção "e" é "&". Veja como utilizá-lo:

```{r}
creches <- escolas %>% 
  filter(tipo == "CEI DIRET" | 
            tipo == "CEI INDIR" | 
            tipo == "CR.P.CONV" &
            dre == "DIRETORIA REGIONAL DE EDUCACAO IPIRANGA")


```

Ao usar duas variáveis diferentes para filter e a conjunção "e", podemos escrever o comando separando as condições por vírgula e dispensar o operador "&":

```{r}
creches_ipiranga <- escolas %>% 
  filter((tipo == "CEI DIRET" | 
            tipo == "CEI INDIR" | 
            tipo == "CR.P.CONV"),
           dre == "DIRETORIA REGIONAL DE EDUCACAO IPIRANGA")
```

Você pode combinar quantas condições precisar. Se houver ambiguidade quanto à ordem das condições, use parênteses, como fizemos acima.

Vamos uma aplicação interessante dos dados com os quais trabalhamos.

