# Agenda de Contatos em Prolog

Este projeto implementa uma agenda de contatos em **Prolog**, executada pelo terminal, com cadastro, edição, remoção, pesquisa, organização por grupos, autenticação e suporte a múltiplos usuários.

Cada usuário possui credenciais próprias e uma agenda isolada. As credenciais são persistidas em `auth/usuarios.csv`, enquanto os contatos de cada conta são armazenados em:

```text
data/<usuario>/contatos.csv
```

A senha nunca deve ser gravada em texto puro. O sistema utiliza `crypto_password_hash/2`, da `library(crypto)` do SWI-Prolog, para gerar e verificar hashes de senha.

O objetivo acadêmico não é somente implementar as funcionalidades de uma agenda. A arquitetura foi adaptada para explorar fundamentos do paradigma lógico:

- fatos;
- regras;
- consultas;
- unificação;
- backtracking;
- recursão;
- listas;
- predicados determinísticos e não determinísticos;
- módulos;
- base de conhecimento dinâmica;
- separação entre lógica de domínio e efeitos externos.

A implementação de referência é o **SWI-Prolog**.

---

## Funcionalidades

### Autenticação e usuários

- cadastrar usuário;
- impedir nomes de usuário duplicados;
- validar o formato do nome de usuário;
- gerar hash da senha;
- autenticar comparando a senha informada com o hash persistido;
- criar uma pasta de dados exclusiva para cada usuário;
- abrir somente a agenda do usuário autenticado;
- salvar a agenda antes de trocar de usuário;
- encerrar a sessão e retornar ao menu de autenticação;
- impedir que um usuário consulte os contatos de outro.

### Contatos

- carregar contatos do CSV do usuário autenticado;
- validar cabeçalho e registros;
- cadastrar contato com ID automático;
- listar contatos;
- editar contato por ID;
- remover contato mediante confirmação;
- buscar por ID;
- buscar parcialmente por nome;
- buscar parcialmente por telefone.

### Grupos

- permitir que um contato pertença a vários grupos;
- adicionar contato a grupo;
- remover contato de grupo;
- listar grupos existentes;
- buscar contatos por grupo;
- impedir grupos equivalentes duplicados;
- reconstruir a visão de grupos a partir dos contatos.

### Persistência e robustez

- persistir usuários em CSV;
- persistir uma agenda separada por usuário;
- manter senhas somente como hashes;
- salvar arquivos por meio de arquivo temporário;
- preservar o arquivo anterior quando a escrita falhar;
- tratar opções e IDs inválidos sem encerrar o programa;
- executar testes automatizados com PlUnit.

---

## Itens fora do escopo

A primeira versão não inclui:

- recuperação de senha;
- troca de senha;
- exclusão de conta;
- permissões administrativas;
- compartilhamento de contatos entre usuários;
- banco de dados;
- interface gráfica;
- API web;
- sincronização em rede;
- autenticação por serviço externo;
- histórico de alterações;
- edição concorrente;
- armazenamento em nuvem.

---

## Estrutura do projeto

```text
agenda-contatos-prolog/
├── app/
│   └── main.pl
│
├── src/
│   ├── db/
│   │   ├── auth_db.pl
│   │   └── contato_db.pl
│   ├── repository/
│   │   ├── auth_repository.pl
│   │   ├── contato_repository.pl
│   │   └── grupo_repository.pl
│   ├── service/
│   │   ├── auth_service.pl
│   │   ├── contato_service.pl
│   │   └── grupo_service.pl
│   ├── menu/
│   │   ├── auth_menu.pl
│   │   └── menu.pl
│   ├── csv/
│   │   └── csv_utils.pl
│   └── utils/
│       ├── input_utils.pl
│       └── validation.pl
│
├── auth/
│   ├── usuarios.csv
│   └── usuarios.backup.csv
│
├── data/
│   ├── usuario_a/
│   │   └── contatos.csv
│   └── usuario_b/
│       └── contatos.csv
│
├── test/
│   ├── auth_db_test.pl
│   ├── auth_repository_test.pl
│   ├── auth_service_test.pl
│   ├── contato_db_test.pl
│   ├── contato_repository_test.pl
│   ├── contato_service_test.pl
│   ├── grupo_repository_test.pl
│   ├── grupo_service_test.pl
│   ├── input_utils_test.pl
│   ├── validation_test.pl
│   ├── integration_test.pl
│   └── run_tests.pl
│
├── README.md
├── ESTRUTURA_DO_PROJETO.md
├── PLANO_DE_IMPLEMENTACAO_AGENDA_PROLOG.md
└── .gitignore
```

---

## Responsabilidade dos módulos

### Autenticação

- `src/db/auth_db.pl`: mantém os fatos dinâmicos `usuario/2`.
- `src/repository/auth_repository.pl`: lê e salva `auth/usuarios.csv`.
- `src/service/auth_service.pl`: valida cadastro, gera hash, autentica e resolve o caminho da agenda do usuário.
- `src/menu/auth_menu.pl`: apresenta login, cadastro e saída.

### Contatos e grupos

- `src/db/contato_db.pl`: controla os fatos dinâmicos `contato/5` da sessão atual.
- `src/repository/contato_repository.pl`: lê e salva o CSV de contatos do usuário autenticado.
- `src/service/contato_service.pl`: implementa cadastro, edição, remoção e pesquisas.
- `src/repository/grupo_repository.pl`: reconstrói a visão lógica dos grupos a partir dos contatos.
- `src/service/grupo_service.pl`: implementa adição, remoção, listagem e pesquisa por grupos.

### Infraestrutura da CLI

- `src/utils/input_utils.pl`: lê entradas, senhas, confirmações e exibe dados.
- `src/utils/validation.pl`: concentra validações puras de usuário, senha, contato e grupo.
- `src/csv/csv_utils.pl`: reúne operações genéricas de CSV e salvamento temporário.
- `src/menu/menu.pl`: coordena a agenda depois da autenticação.
- `app/main.pl`: inicializa usuários, executa autenticação, abre a agenda correta, salva e encerra.

---

## Modelagem em Prolog

### Usuário

Cada conta carregada de `auth/usuarios.csv` é representada por:

```prolog
usuario(NomeUsuario, HashSenha).
```

Exemplo:

```prolog
usuario(
    "eduardo",
    '$pbkdf2-sha512$t=...'
).
```

O conteúdo do hash deve ser tratado como dado opaco. A aplicação não analisa o hash manualmente; apenas o gera ou verifica por meio de `crypto_password_hash/2`.

### Sessão

A sessão não precisa ser persistida nem armazenada como fato global. Ela pode circular entre os módulos como um termo:

```prolog
sessao(Usuario, CaminhoContatos).
```

Exemplo:

```prolog
sessao(
    "eduardo",
    "data/eduardo/contatos.csv"
).
```

A sessão informa:

- qual usuário foi autenticado;
- qual arquivo de contatos pode ser carregado e salvo.

### Contato

O predicado principal da agenda é:

```prolog
contato(Id, Nome, Telefone, Email, Grupos).
```

Exemplo:

```prolog
contato(
    1,
    "Ana Silva",
    "83999999999",
    "ana@email.com",
    ["Familia", "Favoritos"]
).
```

### Grupo

O contato é a fonte principal da verdade. Não existe um arquivo separado de grupos.

A visão de grupo é reconstruída por uma relação derivada:

```prolog
grupo(NomeGrupo, IdsContatos).
```

Exemplo conceitual:

```prolog
grupo("Familia", [1, 3]).
```

`grupo/2` não precisa ser um fato dinâmico persistido. Ele pode ser calculado a partir dos fatos `contato/5`, evitando duplicação entre duas fontes de dados.

---

## Como a aplicação funciona

### 1. Inicialização dos usuários

Ao executar o programa:

1. `main.pl` localiza `auth/usuarios.csv`;
2. `auth_repository.pl` valida e carrega os usuários;
3. `auth_db.pl` recebe os fatos `usuario/2`;
4. o menu de autenticação é exibido.

### 2. Cadastro

No cadastro:

1. o nome de usuário é lido;
2. o nome é normalizado;
3. `validation.pl` verifica o formato;
4. o sistema confirma que o usuário não existe;
5. a senha e a confirmação são lidas;
6. a senha é validada;
7. `crypto_password_hash/2` gera o hash;
8. o usuário é persistido em `auth/usuarios.csv`;
9. `data/<usuario>/` é criada;
10. `data/<usuario>/contatos.csv` é criado com o cabeçalho.

O nome de usuário deve ser seguro para uso como diretório. A regra recomendada é aceitar apenas:

```text
letras, números e underscore
```

Exemplos válidos:

```text
eduardo
maria_2026
usuario01
```

Exemplos inválidos:

```text
../admin
maria/silva
usuario com espaco
```

### 3. Login

No login:

1. o usuário informa nome e senha;
2. o sistema procura `usuario/2`;
3. o hash persistido é recuperado;
4. `crypto_password_hash/2` verifica a senha;
5. uma sessão é criada;
6. somente o arquivo dessa sessão é carregado.

### 4. Abertura da agenda

Antes de carregar uma agenda:

1. os fatos `contato/5` da sessão anterior são removidos;
2. o caminho da nova sessão é validado;
3. o CSV é carregado;
4. os contatos são inseridos na base dinâmica;
5. o menu principal é exibido.

### 5. Logout

Ao escolher logout:

1. os contatos da sessão atual são salvos;
2. a base dinâmica de contatos é limpa;
3. o termo de sessão deixa de ser usado;
4. o programa retorna ao menu de autenticação.

### 6. Encerramento

Ao escolher sair:

1. a agenda atual é salva, caso exista uma sessão;
2. os arquivos temporários são finalizados;
3. a aplicação é encerrada.

---

## Isolamento entre usuários

O ID de um contato é único dentro da agenda do usuário, não em todo o sistema.

Assim, é válido existir:

```text
data/ana/contatos.csv      → contato de ID 1
data/carlos/contatos.csv   → contato de ID 1
```

Esses contatos pertencem a agendas diferentes.

Todos os predicados de persistência de contatos recebem o caminho da sessão. Nenhum módulo deve usar um caminho global fixo como:

```text
data/contatos.csv
```

A regra correta é:

```prolog
sessao(Usuario, Caminho),
carregar_contatos_csv(Caminho, Resultado).
```

Ao trocar de usuário, a base dinâmica precisa ser limpa antes de carregar a próxima agenda. Essa limpeza é obrigatória para impedir vazamento de contatos entre sessões.

---

## O que torna o projeto lógico

### Fatos

Usuários e contatos carregados são fatos:

```prolog
usuario("maria", Hash).

contato(3, "Joao Lima", "83977777777",
        "joao@email.com", ["Familia", "Trabalho"]).
```

### Consultas

Uma busca por ID declara a relação esperada:

```prolog
buscar_por_id(Id, Contato).
```

### Unificação

A consulta:

```prolog
?- contato_db:contato(1, Nome, Telefone, Email, Grupos).
```

associa as variáveis aos valores do fato correspondente.

### Backtracking

A consulta:

```prolog
?- contato_db:contato(Id, Nome, _, _, Grupos).
```

pode produzir várias soluções. O usuário do interpretador solicita a próxima solução usando `;`.

### Coleta de soluções

Os menus normalmente precisam de listas completas. Para isso, os serviços podem usar `findall/3`.

```prolog
findall(
    contato(Id, Nome, Telefone, Email, Grupos),
    contato(Id, Nome, Telefone, Email, Grupos),
    Contatos
).
```

---

## Base dinâmica controlada

Os predicados dinâmicos esperados são:

```prolog
:- dynamic usuario/2.
:- dynamic contato/5.
```

Os menus não devem utilizar diretamente:

```prolog
assertz/1
retract/1
retractall/1
```

Essas operações ficam encapsuladas em:

- `auth_db.pl`;
- `contato_db.pl`.

Essa separação reduz:

- IDs duplicados;
- usuários duplicados;
- atualizações parciais;
- vazamento entre sessões;
- regras repetidas;
- dependência dos menus em detalhes internos.

---

## Autenticação

### Persistência de usuários

Arquivo:

```text
auth/usuarios.csv
```

Cabeçalho:

```csv
usuario,hash_senha
```

Exemplo conceitual:

```csv
usuario,hash_senha
eduardo,$pbkdf2-sha512$...
maria,$pbkdf2-sha512$...
```

O arquivo deve ser lido e gravado usando a biblioteca CSV, pois o hash é um valor opaco e pode precisar de tratamento adequado de delimitadores.

### Hash de senha

A criação de hash utiliza:

```prolog
crypto_password_hash(Senha, Hash).
```

A verificação utiliza o mesmo predicado com o hash já instanciado:

```prolog
crypto_password_hash(SenhaInformada, HashPersistido).
```

O projeto não deve:

- salvar a senha original;
- imprimir a senha em logs;
- comparar hashes gerando um hash novo manualmente;
- usar hash genérico simples sem sal para senhas.

### Regras recomendadas

- nome de usuário entre 3 e 30 caracteres;
- apenas letras, números e `_`;
- comparação de usuário sem diferença entre maiúsculas e minúsculas;
- senha com pelo menos 8 caracteres;
- confirmação de senha obrigatória;
- usuário duplicado rejeitado;
- pasta de dados criada somente para usuário válido.

---

## Operações de contatos

### Cadastro

O cadastro:

1. valida nome e telefone;
2. calcula o maior ID da agenda atual;
3. gera o próximo ID;
4. constrói `contato/5`;
5. insere o fato por meio de `contato_db.pl`.

### Busca por ID

```prolog
buscar_por_id(3, Contato).
```

Como os IDs são únicos dentro da sessão, a consulta produz no máximo uma solução.

### Busca por nome

A busca:

- remove espaços periféricos;
- normaliza capitalização;
- aceita correspondência parcial;
- retorna todos os contatos compatíveis.

### Busca por telefone

O telefone permanece como string. Para comparar, a implementação pode manter somente os dígitos.

### Edição

A edição mantém o ID e os grupos, salvo quando o fluxo específico de grupos for utilizado.

Uma entrada vazia pode preservar o valor anterior.

### Remoção

A exclusão exige confirmação. Qualquer resposta diferente de `s` ou `sim` cancela por padrão.

---

## Grupos

Os grupos ficam armazenados na lista presente em cada contato:

```prolog
["Familia", "Favoritos"]
```

Os seguintes valores são equivalentes:

```text
Familia
familia
  FAMILIA
```

Adicionar um grupo equivalente deve retornar erro controlado e preservar o contato.

Remover um grupo:

- não remove o contato;
- preserva os demais grupos;
- pode deixar a lista vazia;
- atualiza automaticamente a visão derivada de grupos.

---

## Persistência dos contatos

Cada usuário possui:

```text
data/<usuario>/contatos.csv
```

Cabeçalho:

```csv
id,nome,telefone,email,grupos
```

Exemplo:

```csv
id,nome,telefone,email,grupos
1,Ana Silva,83999999999,ana@email.com,Familia|Favoritos
2,Carlos Souza,83988888888,carlos@email.com,Trabalho
3,Joao Lima,83977777777,joao@email.com,Familia|Trabalho
4,Marina Costa,83966666666,marina@email.com,
```

A vírgula separa colunas. `|` separa grupos.

Na primeira versão:

- nome, telefone, e-mail e grupo não devem conter vírgula;
- nomes de grupo não devem conter `|`;
- IDs devem ser inteiros;
- IDs devem ser únicos dentro de cada arquivo;
- nome e telefone não podem ser vazios.

### Salvamento seguro

Tanto `usuarios.csv` quanto cada `contatos.csv` devem ser salvos usando arquivo temporário:

```text
arquivo principal
      ↓
arquivo.tmp
      ↓
gravação concluída
      ↓
substituição do principal
```

Se a escrita falhar, o arquivo anterior deve permanecer preservado.

---

## Menus

### Autenticação

```text
----------------------------------------
AGENDA DE CONTATOS - PROLOG
----------------------------------------
1. Entrar
2. Cadastrar usuario
0. Sair
----------------------------------------
Escolha uma opcao:
```

### Agenda

```text
----------------------------------------
AGENDA DE CONTATOS
Usuario: eduardo
----------------------------------------
1. Listar contatos
2. Cadastrar contato
3. Editar contato
4. Remover contato
5. Pesquisar contato
6. Gerenciar grupos
7. Salvar e trocar de usuario
0. Salvar e sair
----------------------------------------
Escolha uma opcao:
```

### Pesquisa

```text
PESQUISAR CONTATO
1. Buscar por nome
2. Buscar por telefone
3. Buscar por ID
4. Buscar por grupo
0. Voltar
```

### Grupos

```text
GERENCIAR GRUPOS
1. Listar grupos
2. Adicionar contato a um grupo
3. Remover contato de um grupo
0. Voltar
```

---

## Pré-requisitos

- SWI-Prolog com `library(crypto)`, `library(csv)` e PlUnit;
- terminal PowerShell, Prompt de Comando, Bash ou equivalente;
- Git, caso o projeto seja clonado.

Verifique a instalação:

```bash
swipl --version
```

---

## Como executar

Na raiz:

```bash
swipl -q -s app/main.pl
```

`app/main.pl` deve possuir:

```prolog
:- initialization(main, main).
```

### Pelo interpretador

```bash
swipl
```

```prolog
?- [app/main].
?- main.
```

Para encerrar:

```prolog
?- halt.
```

---

## Consultas manuais

### Usuários carregados

Não exiba o hash durante a demonstração comum. Para testes internos:

```prolog
?- auth_db:usuario(Usuario, _).
```

### Contatos da sessão atual

```prolog
?- contato_db:contato(Id, Nome, Telefone, Email, Grupos).
```

### Busca por nome

```prolog
?- contato_service:buscar_por_nome("ana", Contatos).
```

### Visão de grupos

```prolog
?- grupo_repository:grupo(Nome, Ids).
```

### Busca por grupo

```prolog
?- grupo_service:buscar_por_grupo("familia", Contatos).
```

---

## Testes

O projeto utiliza PlUnit.

Execute:

```bash
swipl -q -g run_tests -t halt test/run_tests.pl
```

Os testes devem cobrir:

- cadastro de usuário;
- usuário duplicado;
- nome de usuário inválido;
- hash gerado;
- login correto;
- login com senha incorreta;
- criação da pasta da conta;
- criação do CSV individual;
- isolamento entre dois usuários;
- logout e troca de usuário;
- CRUD de contatos;
- grupos;
- CSV inválido;
- salvamento e reinicialização.

### Isolamento dos testes

Testes de autenticação e persistência devem usar diretórios temporários.

Testes de fatos dinâmicos devem usar `setup` e `cleanup`.

Nenhum teste deve:

- alterar `auth/usuarios.csv` oficial;
- alterar dados reais de usuários;
- deixar fatos de uma sessão contaminando a seguinte.

---

## Regras principais

### Usuários

- nome de usuário é único;
- comparação do nome é normalizada;
- senha não é persistida em texto puro;
- cada usuário possui um diretório próprio;
- uma sessão acessa somente um CSV;
- logout salva e limpa os contatos carregados.

### Contatos

- ID é único dentro de cada agenda;
- próximo ID é o maior existente mais um;
- base vazia inicia em `1`;
- nome e telefone são obrigatórios;
- telefone é texto;
- edição e remoção usam ID;
- remoção exige confirmação.

### Grupos

- contato pode possuir vários grupos;
- grupo equivalente não é duplicado;
- grupos são derivados dos contatos;
- remover grupo não remove contato.

---

## Tratamento de resultados

Consultas simples podem usar sucesso ou falha.

Operações com alteração retornam termos explícitos:

```prolog
ok
ok(Valor)
erro(Codigo)
```

Exemplos:

```prolog
erro(usuario_duplicado("eduardo")).
erro(usuario_invalido).
erro(senha_muito_curta).
erro(credenciais_invalidas).
erro(id_inexistente(99)).
erro(grupo_duplicado("Familia")).
erro(falha_salvamento(Motivo)).
```

O menu traduz esses termos em mensagens. Serviços não devem imprimir mensagens de interface.

---

## Divisão da equipe

| Pessoa | Responsabilidade principal |
|---|---|
| Pessoa 1 | Base de contatos, persistência de contatos, utilitários CSV e salvamento seguro. |
| Pessoa 2 | Cadastro, edição, remoção e pesquisas de contatos. |
| Pessoa 3 | Repositório derivado e operações de grupos. |
| Pessoa 4 | Base de usuários, autenticação, validações e entrada segura. |
| Pessoa 5 | Menus, sessão, integração, documentação e testes de fluxo completo. |

A persistência de usuários deve ser revisada pelas Pessoas 1 e 4. A troca de sessão deve ser revisada pelas Pessoas 4 e 5.

---

## Git

Branches sugeridas:

```text
main
develop
feature/auth
feature/modelo-csv
feature/contato-service
feature/grupo-service
feature/input-utils
feature/menu-integracao
```

Exemplos de commits:

```text
feat: adiciona cadastro de usuario
feat: implementa verificacao de senha
feat: cria agenda isolada por usuario
feat: adiciona base dinamica de contatos
fix: limpa contatos ao trocar de usuario
fix: impede nome de usuario inseguro
fix: preserva telefone como texto no CSV
test: verifica isolamento entre agendas
docs: documenta autenticacao em Prolog
```

---

## Roteiro de demonstração

1. iniciar com dois usuários de teste;
2. tentar login com senha incorreta;
3. autenticar como usuário A;
4. listar os contatos do usuário A;
5. cadastrar e editar um contato;
6. adicionar e remover grupos;
7. salvar e trocar de usuário;
8. autenticar como usuário B;
9. comprovar que o contato do usuário A não aparece;
10. cadastrar um contato com o mesmo ID lógico no usuário B;
11. salvar e sair;
12. reiniciar;
13. comprovar a persistência das duas agendas;
14. mostrar uma consulta direta e o backtracking.

---

## Por que Prolog faz sentido

O domínio possui relações naturais:

- um nome identifica uma conta;
- uma conta possui um hash;
- uma sessão relaciona usuário e arquivo;
- um ID identifica um contato dentro da agenda;
- contatos pertencem a grupos;
- uma consulta pode retornar zero, uma ou várias respostas.

Prolog permite representar essas relações diretamente. A aplicação utiliza:

- fatos para usuários e contatos;
- regras para pesquisas e grupos;
- unificação para localizar dados;
- backtracking para múltiplos resultados;
- `findall/3` para construir listas;
- falha para ausência;
- termos `ok/1` e `erro/1` para operações;
- base dinâmica como estado temporário;
- CSV como persistência externa.

---

## Documentação complementar

- `PLANO_DE_IMPLEMENTACAO_AGENDA_PROLOG.md`: arquitetura completa, contratos, etapas e divisão da equipe.
- `ESTRUTURA_DO_PROJETO.md`: descrição dos diretórios e módulos.
- `test/integration_test.pl`: cenários integrados.
- `auth/usuarios.backup.csv`: cópia de segurança da base de usuários.

---

## Status da implementacao atual

Nesta etapa foram implementadas as responsabilidades da **Pessoa 5** e a parte funcional de **autenticacao com hash de senha** necessaria para a integracao:

- `app/main.pl`: ciclo principal, carga inicial, abertura de sessao, logout e encerramento;
- `src/menu/auth_menu.pl`: fluxo CLI de login, cadastro e saida;
- `src/menu/menu.pl`: menu principal, listagem da agenda carregada e navegacao de sessao;
- `src/db/auth_db.pl`: base dinamica de usuarios;
- `src/repository/auth_repository.pl`: leitura e escrita de `auth/usuarios.csv`;
- `src/service/auth_service.pl`: cadastro, hash de senha, login, criacao de sessao e isolamento por usuario.

O hash da senha e persistido em `auth/usuarios.csv`. O valor armazenado nao corresponde ao texto puro informado no cadastro.

As funcionalidades de CRUD detalhado de contatos e de grupos continuam separadas nos modulos das Pessoas 2 e 3. O menu principal preserva essa separacao e nao desloca essas regras para a camada de interface.

