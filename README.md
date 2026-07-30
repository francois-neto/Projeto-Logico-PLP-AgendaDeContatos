# Agenda de Contatos em Prolog

Este projeto implementa uma agenda de contatos em Prolog com cadastro, edicao, remocao, busca, organizacao por grupos e autenticacao por usuario. Os dados sao persistidos em arquivos CSV, com uma pasta de dados separada para cada usuario autenticado.

O diferencial principal do projeto nao esta apenas no que ele faz, mas em como ele faz. A implementacao foi pensada para usar conceitos de programacao logica: fatos, regras, unificacao, consultas e backtracking. O estado da agenda fica em fatos dinamicos controlados, enquanto a interface e a persistencia permanecem separadas das regras de negocio.

## Estrutura do projeto

Os modulos estao organizados por responsabilidade:

- `app/main.pl`: ponto de entrada, ciclo de autenticacao e sessao.
- `src/menu/auth_menu.pl`: fluxo de login e cadastro no terminal.
- `src/menu/menu.pl`: menus da agenda, pesquisa e grupos.
- `src/db/auth_db.pl`: fatos dinamicos de usuarios.
- `src/db/contato_db.pl`: fatos dinamicos de contatos da sessao.
- `src/service/auth_service.pl`: autenticacao, sessao e hash de senha.
- `src/service/contato_service.pl`: regras de negocio de contatos.
- `src/service/grupo_service.pl`: regras de negocio de grupos.
- `src/repository/auth_repository.pl`: persistencia CSV de usuarios.
- `src/repository/contato_repository.pl`: persistencia CSV de contatos.
- `src/repository/grupo_repository.pl`: visao de grupos derivada dos contatos.
- `src/csv/csv_utils.pl`: leitura, escrita atomica e backup de CSV.
- `src/utils/input_utils.pl`: leitura de dados no terminal.
- `src/utils/validation.pl`: validacoes de telefone e e-mail.
- `test/`: testes automatizados do projeto.

## Como a aplicacao funciona

O usuario primeiro entra ou se cadastra. As credenciais ficam em `auth/usuarios.csv`, e a senha nao e salva em texto puro: antes de ser persistida, ela passa por uma funcao de hash da biblioteca `crypto` do SWI-Prolog.

Depois do login, a aplicacao resolve o caminho dos dados daquele usuario e carrega os contatos em fatos dinamicos. Cada conta possui seu proprio arquivo de contatos dentro de `data/<usuario>/contatos.csv`. Ao sair ou trocar de usuario, os fatos da sessao sao salvos no CSV e limpos da memoria.

Os grupos nao sao tratados como uma fonte independente da verdade. Cada contato guarda os nomes dos grupos aos quais pertence, e a camada de grupos monta a visao agregada quando necessario. Para adicionar ou remover um contato de grupo, a interface usa o telefone como identificador; o ID continua sendo apenas um detalhe interno do contato.

## O que faz este projeto ser funcional de verdade

Em linguagens imperativas, o caminho mais comum seria manipular objetos e colecoes diretamente. Em Prolog, a aplicacao descreve relacoes por fatos e faz perguntas a essas relacoes por regras.

Exemplo conceitual:

- um contato em memoria e representado pelo fato `contato(Id, Nome, Telefone, Email, Grupos)`;
- uma consulta pode localizar um contato sem informar todas as variaveis;
- a unificacao preenche as variaveis com valores que tornam a regra verdadeira;
- o backtracking permite procurar outras solucoes quando uma regra possui alternativas.

Isso afeta diretamente partes importantes do projeto:

- Ao carregar uma agenda, os contatos do CSV se tornam fatos dinamicos da sessao.
- Ao buscar por nome ou telefone, as regras consultam os fatos existentes e constroem a lista de resultados.
- Ao editar ou remover um contato, a camada de servico atualiza somente os fatos necessarios.
- Ao listar grupos, a relacao entre contato e grupo e derivada dos grupos presentes nos contatos.

Essa abordagem deixa as regras de consulta explicitas. A interface solicita dados, os servicos aplicam regras e os repositorios convertem entre fatos e arquivos.

## Diferencas importantes para quem vem de linguagens comuns

### 1. A consulta pode preencher variaveis

Em Prolog, uma chamada nao serve apenas para retornar `true` ou `false`. Ela tambem pode unificar variaveis com os resultados encontrados.

No projeto, isso aparece em chamadas como:

- `buscar_por_id(Id, Contato)`;
- `buscar_por_nome(Consulta, Contatos)`;
- `listarGrupos(Grupos)`.

O predicado descreve a relacao, e as variaveis recebem valores que satisfazem essa relacao.

### 2. Erro nao precisa ser excecao

Em vez de depender de excecoes para regras comuns, os servicos retornam termos como:

- `ok`;
- `ok(Valor)`;
- `erro(Codigo)`.

Isso torna o resultado da operacao parte do contrato do predicado. O menu traduz esses termos em mensagens para o usuario.

### 3. IO fica mais isolado

Leitura de teclado, escrita em arquivo e exibicao no terminal sao efeitos colaterais. No projeto, essas acoes ficam concentradas nos menus, utilitarios de entrada e repositorios.

Na pratica:

- `menu` conversa com o usuario;
- `repository` conversa com o sistema de arquivos;
- `service` aplica as regras de negocio;
- `db` concentra os fatos dinamicos da sessao.

Isso melhora a testabilidade e evita que a interface altere fatos diretamente.

### 4. O estado da sessao precisa ser controlado

Os contatos em memoria sao fatos dinamicos, portanto podem mudar durante a execucao. Por isso o fluxo da aplicacao precisa carregar a agenda ao abrir a sessao, salvar antes de encerrar e limpar os fatos antes de trocar de usuario.

No terminal, isso significa:

- carregar os usuarios;
- autenticar;
- carregar os contatos daquele usuario;
- executar operacoes na agenda;
- salvar e limpar a sessao no logout ou encerramento.

## Modelagem adotada

### Contatos

Cada contato possui:

- identificador interno;
- nome;
- telefone;
- e-mail;
- lista de grupos.

O telefone e validado conforme as regras brasileiras existentes no projeto. O e-mail e opcional; quando informado, deve conter `@`.

### Grupos

Cada grupo e representado pelo seu nome dentro da lista de grupos de um contato. A lista de grupos e reconstruida a partir dos contatos, evitando duplicar a mesma relacao em outro arquivo ou base de fatos.

As operacoes de adicionar e remover contato de grupo recebem o telefone do contato. A busca pelo telefone encontra o contato da sessao e atualiza seus grupos.

### Usuarios

Cada usuario possui:

- nome de usuario;
- hash da senha.

A sessao guarda:

- qual usuario autenticou;
- qual arquivo de contatos deve ser usado naquele login.

## Persistencia em CSV

O projeto usa CSV por ser simples, transparente e facil de inspecionar manualmente. Isso combina bem com um projeto academico em Prolog, porque os fatos podem ser carregados do arquivo, consultados durante a sessao e persistidos novamente no final.

Arquivos relevantes:

- `auth/usuarios.csv`: usuarios cadastrados e hashes de senha;
- `data/<usuario>/contatos.csv`: contatos do usuario autenticado.

A escrita usa um arquivo temporario e backup. Assim, a aplicacao reduz o risco de perder o CSV original caso ocorra uma falha durante o salvamento.

Essa decisao traz vantagens:

- nao exige banco de dados;
- facilita depuracao;
- deixa visivel como os fatos sao carregados e salvos;
- mantem a persistencia separada das regras logicas.

## Autenticacao

O fluxo atual de autenticacao funciona assim:

1. O usuario escolhe entre login, cadastro ou sair.
2. No cadastro, a senha e transformada em hash.
3. O usuario e salvo em `auth/usuarios.csv`.
4. No login, o hash da senha digitada e comparado com o hash persistido.
5. Em caso de sucesso, a sessao aponta para o CSV de contatos daquele usuario.

O cadastro e o login nao aplicam validacoes de tamanho ou formato para usuario e senha. A unica verificacao de consistencia nessa etapa e impedir o cadastro de dois usuarios com o mesmo nome normalizado.

## Como compilar e executar

Prolog nao exige uma etapa separada de compilacao para este projeto. O SWI-Prolog carrega o arquivo de entrada e inicia a aplicacao.

Na raiz do projeto:

```powershell
swipl -q -s app/main.pl
```

O menu de autenticacao sera exibido no terminal.

## Como executar os testes

Na raiz do projeto:

```powershell
swipl -q -s test/run_tests.pl -g run_tests -t halt
```

A suite cobre autenticacao, validacoes, CSV, base de contatos, servicos de contatos, grupos e isolamento entre usuarios.

## Por que Prolog faz sentido aqui

Uma agenda de contatos parece simples, mas envolve consultas, identificacao de contatos, grupos, persistencia em arquivo e autenticacao. Prolog ajuda porque permite modelar a parte central do sistema como fatos e relacoes:

- contatos podem ser consultados por diferentes campos;
- grupos podem ser derivados dos contatos;
- unificacao reduz codigo de busca e correspondencia;
- backtracking permite explorar alternativas de consulta;
- regras e resultados ficam explicitos em predicados pequenos.

Em outras palavras, o projeto nao usa Prolog apenas como sintaxe diferente. A organizacao foi moldada para aproveitar fatos, regras e consultas como parte central da solucao.
