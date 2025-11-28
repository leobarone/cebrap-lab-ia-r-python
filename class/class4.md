# cebrap.lab - IA em R e python

## 4o encontro

Data: 28 de Novembro de 2025
Horário: 17 às 19h
Local: CEBRAP

### Objetivo

Nosso objetivo nos dois primeiros encontros do curso foi habituar todas e todos no uso de uma das linguagens, R ou python, e compreendermos como coletar/construir e preparar coleções de documentos. No terceiro encontro, trabalhamos alguns possíveis usos de modelos abertos Large Language Models disponíveis na plataforma Hugging Face.

Neste último encontro, vamos tentar juntar tudo que aprendemos.cla

### Roteiro

Em duplas ou trios, escolha um dos seguintes desafios. Em todos os desafios seu objetivo é construir um script que execute a qualquer momento todas as tarefas, da obtenção e preparação dos dados à aplicação de um LLM.

##### *Desafio básico* - ementas de projetos urgentes (para pessoas quem fez os primeiros passos em R)

1 - Carregar os dados de proposições que estão [neste link](https://raw.githubusercontent.com/leobarone/cebrap-lab-ia-r-python/refs/heads/main/tutorial/data/proposicoes-detalhes.csv);

2 - Filtrar as proposições com base no `status_regime` para selecionar apenas as proposições com urgência -- *"Urgência"*, *"Urgência (Art. 155, RICD)"* ou *"Urgência (Art. 64, CF)"*;

3 - Aplicar uma tarefa de LLM às ementas dos projetos urgentes

##### *Desafio intermediário* - bi-encoder no corpus completo (para quem se sente confortável em combinar bases de dados)

1 - Carregar os dados de proposições que estão [neste link](https://raw.githubusercontent.com/leobarone/cebrap-lab-ia-r-python/refs/heads/main/tutorial/data/proposicoes-detalhes.csv);

2 - Filtrar as proposições com base no `status_regime` para selecionar apenas as proposições com urgência -- *"Urgência"*, *"Urgência (Art. 155, RICD)"* ou *"Urgência (Art. 64, CF)"*;

3 - Baixar os arquivos completos das proposições urgentes;

4 - Transformar as proposições urgentes em um *corpus*;

5 - Aplicar a técnica de classificação de bi-encoder ou cross-encoder para identificar os projetos associados a um tema de sua escolha;

6 - Carregar os dados de proponentes dos PLs de 2025 que estão [neste link](https://raw.githubusercontent.com/leobarone/cebrap-lab-ia-r-python/refs/heads/main/tutorial/data/proposicoes-autores.csv);

7 - Produzir uma análise dos temas por partido da(o) proponente;

Obs: você pode pular os passos 3 e 4, se quiser, usando o *corpus* completo disponível [neste link](https://raw.githubusercontent.com/leobarone/cebrap-lab-ia-r-python/refs/heads/main/tutorial/data/corpus-completo.csv);

##### *Desafio avançado* - zero-shot em ementas do corpus completos (para quem tiver tempo para continuar depois do curso)

1 - Reproduzir por inteiro a construção do *corpus* de PLs de 2025. Use o tutorial atualizado de apoio [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-proposicoes-legislativas-r.md)

2 - Aplicar a tarefa de zero-shot, escolhendo rótulos próprios, para o corpus completo, ou para uma seleção.

3- Produzir uma análise de sua autoria, eventualmente com o auxílio dos dados de proponentes, que você pode capturar com apoio do tutorial mencionado em (1).

### Tutoriais do curso

- Introdução à programação [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-inicial-r.md) ou [em python](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-inicial-python.ipynb) 

- Preparação de texto como dados [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-textos-em-r.md) ou em [em python](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-textos-python.ipynb)

- Construção de um corpus de textos legislativos utilizando a API da Câmara dos Deputados [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-proposicoes-legislativas-r.md) ou [em python](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-proposicoes-legislativas-python.ipynb). Versão expandida para coletar a informação sobre os autores dos projetos de lei [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-proposicoes-legislativas-r.md)

- Tarefas de LLMs ou encoders de linguagem) para preparação ou classificação de dados textuais. Tutorial  [em R](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-tecnicas-llm-para-pesquisa.md) ou [em python](https://github.com/leobarone/cebrap-lab-ia-r-python/blob/main/tutorial/tutorial-tecnicas-llm-para-pesquisa.ipynb)

