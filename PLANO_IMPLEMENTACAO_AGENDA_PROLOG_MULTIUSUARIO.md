# Plano de Implementação do Projeto
## Agenda de Contatos Multiusuário em Prolog

**Disciplina:** Paradigmas de Linguagens de Programação  
**Tipo:** aplicação CLI  
**Linguagem:** Prolog  
**Implementação de referência:** SWI-Prolog  
**Equipe:** 5 integrantes  
**Persistência:** arquivos CSV  
**Requisitos adicionais obrigatórios:** autenticação e múltiplos usuários  

---

# 1. Finalidade

Este documento define a implementação completa da Agenda de Contatos em Prolog, incluindo:

- autenticação;
- cadastro de usuários;
- hash de senha;
- sessão;
- agenda isolada por usuário;
- contatos;
- grupos;
- persistência;
- arquitetura modular;
- contratos entre módulos;
- divisão da equipe;
- ordem de implementação;
- testes;
- riscos;
- critérios de aceite;
- roteiro de apresentação.

O projeto deve demonstrar o paradigma lógico sem transformar Prolog em uma sequência de comandos imperativos espalhados.

---

# 2. Correção de escopo

A versão anterior do plano considerava autenticação e múltiplos usuários fora do MVP. Essa decisão deve ser descartada.

A versão obrigatória passa a incluir:

1. cadastro de usuário;
2. login;
3. hash de senha;
4. arquivo de usuários;
5. diretório de contatos por conta;
6. sessão autenticada;
7. logout;
8. isolamento entre agendas;
9. testes específicos de autenticação e multiusuário.

Também passam a ser explicitamente restaurados:

- o modelo lógico de usuário;
- o termo de sessão;
- o fluxo de autenticação no terminal;
- o repositório de autenticação;
- os testes de autenticação;
- a visão explícita de grupos como relação derivada;
- os módulos separados de validação e utilitários CSV.

---

# 3. Objetivo geral

Desenvolver uma agenda multiusuário em Prolog na qual cada usuário:

- possua credenciais próprias;
- autentique-se antes de acessar a agenda;
- possua arquivo de contatos isolado;
- consiga gerenciar contatos e grupos;
- mantenha alterações persistidas após reiniciar.

---

# 4. Objetivos específicos

## 4.1 Paradigma lógico

- representar usuários e contatos como fatos;
- expressar buscas por regras;
- usar unificação;
- usar backtracking;
- coletar soluções;
- documentar determinismo;
- controlar fatos dinâmicos;
- separar regras de efeitos externos.

## 4.2 Autenticação

- cadastrar usuário;
- rejeitar usuário duplicado;
- validar nome;
- validar senha;
- gerar hash;
- persistir somente hash;
- autenticar;
- criar sessão;
- criar diretório individual;
- criar CSV inicial;
- realizar logout.

## 4.3 Agenda

- carregar contatos da sessão;
- cadastrar;
- listar;
- editar;
- remover;
- buscar;
- gerenciar grupos;
- salvar;
- recarregar.

---

# 5. Escopo obrigatório

| Código | Funcionalidade |
|---|---|
| A01 | Carregar usuários de `auth/usuarios.csv` |
| A02 | Validar arquivo de usuários |
| A03 | Cadastrar usuário |
| A04 | Rejeitar usuário duplicado |
| A05 | Gerar hash da senha |
| A06 | Verificar senha |
| A07 | Criar diretório individual |
| A08 | Criar CSV de contatos individual |
| A09 | Criar sessão |
| A10 | Realizar logout |
| A11 | Isolar agendas |
| C01 | Carregar contatos |
| C02 | Validar CSV |
| C03 | Cadastrar contato |
| C04 | Listar |
| C05 | Editar |
| C06 | Remover |
| C07 | Buscar por ID |
| C08 | Buscar por nome |
| C09 | Buscar por telefone |
| G01 | Listar grupos |
| G02 | Adicionar grupo |
| G03 | Remover grupo |
| G04 | Buscar por grupo |
| P01 | Salvar usuários com arquivo temporário |
| P02 | Salvar contatos com arquivo temporário |
| T01 | Tratar entradas inválidas |
| T02 | Executar testes PlUnit |
| T03 | Testar isolamento entre usuários |

---

# 6. Fora do escopo

- recuperação de senha;
- alteração de senha;
- exclusão de conta;
- administrador;
- permissões;
- compartilhamento;
- banco de dados;
- interface gráfica;
- API;
- OAuth;
- criptografia do CSV;
- histórico;
- concorrência;
- nuvem.

---

# 7. Modelo lógico

## 7.1 Usuário

```prolog
usuario(NomeUsuario, HashSenha).
```

Domínio:

```text
NomeUsuario -> string normalizada
HashSenha   -> atom opaco
```

## 7.2 Sessão

```prolog
sessao(Usuario, CaminhoContatos).
```

A sessão:

- não é persistida;
- não precisa ser dinâmica;
- é criada após o login;
- é passada ao ciclo da agenda;
- determina o arquivo acessível.

## 7.3 Contato

```prolog
contato(Id, Nome, Telefone, Email, Grupos).
```

Domínio:

```text
Id       -> integer
Nome     -> string
Telefone -> string
Email    -> string
Grupos   -> list(string)
```

## 7.4 Grupo derivado

```prolog
grupo(NomeGrupo, IdsContatos).
```

`grupo/2` é reconstruído a partir de `contato/5`.

## 7.5 Resultados

```prolog
ok
ok(Valor)
erro(Codigo)
```

Exemplos:

```prolog
erro(usuario_duplicado(Usuario)).
erro(usuario_invalido).
erro(senha_muito_curta).
erro(credenciais_invalidas).
erro(arquivo_usuario_inexistente(Caminho)).
erro(id_inexistente(Id)).
erro(grupo_duplicado(Grupo)).
```

---

# 8. Decisões de autenticação

## 8.1 Hash

Usar:

```prolog
:- use_module(library(crypto)).
```

Criação:

```prolog
crypto_password_hash(Senha, Hash).
```

Verificação:

```prolog
crypto_password_hash(SenhaInformada, HashPersistido).
```

Não armazenar senha original.

## 8.2 Nome de usuário

Regra recomendada:

- 3 a 30 caracteres;
- letras;
- números;
- `_`;
- sem espaços;
- sem `/`;
- sem `\`;
- sem `..`;
- comparação normalizada.

Isso evita nomes incompatíveis com diretórios e travessia de caminho.

## 8.3 Senha

Regra mínima:

- pelo menos 8 caracteres;
- confirmação igual;
- não vazia;
- não armazenada em logs.

## 8.4 Arquivos

Usuários:

```text
auth/usuarios.csv
```

Agenda:

```text
data/<usuario>/contatos.csv
```

---

# 9. Regras de negócio

## 9.1 Usuários

| Código | Regra |
|---|---|
| RU01 | Nome de usuário é obrigatório |
| RU02 | Nome deve passar pela validação |
| RU03 | Nome é único após normalização |
| RU04 | Senha deve obedecer ao tamanho mínimo |
| RU05 | Confirmação deve coincidir |
| RU06 | Somente hash é persistido |
| RU07 | Login inválido não informa se usuário ou senha falhou |
| RU08 | Cadastro cria pasta individual |
| RU09 | Cadastro cria CSV com cabeçalho |
| RU10 | Falha de cadastro não deixa usuário parcialmente persistido |

## 9.2 Sessão

| Código | Regra |
|---|---|
| RS01 | Agenda só abre após autenticação |
| RS02 | Sessão aponta para um único arquivo |
| RS03 | Base de contatos é limpa antes de trocar de usuário |
| RS04 | Logout salva a agenda |
| RS05 | Usuário não pode escolher caminho manualmente |
| RS06 | IDs são únicos somente dentro da agenda |

## 9.3 Contatos

| Código | Regra |
|---|---|
| RC01 | ID é inteiro e único na agenda |
| RC02 | Próximo ID é maior ID + 1 |
| RC03 | Base vazia inicia em 1 |
| RC04 | IDs removidos não são reutilizados automaticamente |
| RC05 | Nome é obrigatório |
| RC06 | Telefone é obrigatório |
| RC07 | Telefone é string |
| RC08 | Edição preserva ID |
| RC09 | Remoção exige confirmação |
| RC10 | Operação inválida preserva a base |

## 9.4 Grupos

| Código | Regra |
|---|---|
| RG01 | Contato pode ter vários grupos |
| RG02 | Grupo é identificado pelo nome |
| RG03 | Equivalência ignora capitalização e espaços |
| RG04 | Grupo equivalente não duplica |
| RG05 | Remover grupo não remove contato |
| RG06 | Visão de grupos é derivada |
| RG07 | Não existe CSV separado de grupos |

## 9.5 Persistência

| Código | Regra |
|---|---|
| RP01 | Cabeçalhos são validados |
| RP02 | Arquivo inválido não é sobrescrito |
| RP03 | Salvamento usa temporário |
| RP04 | IDs duplicados no CSV são rejeitados |
| RP05 | Hash é tratado como campo opaco |
| RP06 | Contatos só são carregados depois de limpar sessão anterior |
| RP07 | Falha de login não carrega agenda |

---

# 10. Arquitetura

```text
                    app/main.pl
                         |
             +-----------+-----------+
             |                       |
             v                       v
       auth_menu.pl               menu.pl
             |                       |
       auth_service.pl      contato_service.pl
             |              grupo_service.pl
       auth_db.pl                  |
       auth_repository.pl    contato_db.pl
             |              grupo_repository.pl
             |              contato_repository.pl
             +----------+------------+
                        |
                  csv_utils.pl
                        |
           auth/usuarios.csv e data/<usuario>/
```

## 10.1 Princípios

- menus orquestram;
- serviços validam regras;
- bancos em memória controlam fatos;
- repositórios controlam arquivos;
- validações puras ficam separadas;
- utilitários CSV são reutilizáveis;
- sessão limita o arquivo acessível.

---

# 11. Estrutura de pastas

```text
agenda-contatos-prolog/
├── app/main.pl
├── src/
│   ├── auth_db.pl
│   ├── auth_repository.pl
│   ├── auth_service.pl
│   ├── auth_menu.pl
│   ├── contato_db.pl
│   ├── contato_repository.pl
│   ├── contato_service.pl
│   ├── grupo_repository.pl
│   ├── grupo_service.pl
│   ├── input_utils.pl
│   ├── validation.pl
│   ├── csv_utils.pl
│   └── menu.pl
├── auth/
│   ├── usuarios.csv
│   └── usuarios.backup.csv
├── data/
├── test/
├── README.md
└── PLANO_DE_IMPLEMENTACAO_AGENDA_PROLOG.md
```

---

# 12. Módulos e contratos

## 12.1 `auth_db.pl`

```prolog
:- dynamic usuario/2.
```

Exportar:

```prolog
usuario/2
limpar_usuarios/0
substituir_usuarios/2
snapshot_usuarios/1
inserir_usuario_db/2
buscar_usuario_db/2
```

Responsabilidade:

- base dinâmica de usuários;
- impedir duplicidade;
- snapshot;
- nenhuma senha em texto puro.

## 12.2 `auth_repository.pl`

Exportar:

```prolog
carregar_usuarios_csv/2
salvar_usuarios_csv/3
linha_para_usuario/2
usuario_para_linha/2
```

Responsabilidade:

- cabeçalho `usuario,hash_senha`;
- leitura;
- escrita;
- temporário;
- erro controlado.

## 12.3 `auth_service.pl`

Exportar:

```prolog
normalizar_usuario/2
cadastrar_usuario/4
autenticar_usuario/3
criar_sessao/2
resolver_caminho_contatos/2
inicializar_agenda_usuario/2
```

Contrato conceitual:

```prolog
cadastrar_usuario(
    +Usuario,
    +Senha,
    +Confirmacao,
    -Resultado
).

autenticar_usuario(
    +Usuario,
    +Senha,
    -Resultado
).
```

Resultado de login:

```prolog
ok(sessao(Usuario, Caminho)).
```

## 12.4 `auth_menu.pl`

Exportar:

```prolog
menu_autenticacao/1
fluxo_login/1
fluxo_cadastro/1
```

Resultado:

```prolog
sessao(Usuario, Caminho)
encerrar
```

Não:

- gera hash diretamente;
- acessa CSV diretamente;
- cria diretórios diretamente.

## 12.5 `contato_db.pl`

Exportar:

```prolog
contato/5
limpar_contatos/0
substituir_contatos/2
snapshot_contatos/1
inserir_contato_db/2
atualizar_contato_db/3
remover_contato_db/2
```

## 12.6 `contato_repository.pl`

Exportar:

```prolog
carregar_contatos_csv/2
salvar_contatos_csv/3
linha_para_contato/2
contato_para_linha/2
serializar_grupos/2
desserializar_grupos/2
criar_csv_contatos_vazio/2
```

## 12.7 `contato_service.pl`

Exportar:

```prolog
proximo_id/1
cadastrar_contato/5
buscar_por_id/2
buscar_por_nome/2
buscar_por_telefone/2
editar_contato/5
remover_contato/2
listar_contatos_ordenados/1
```

## 12.8 `grupo_repository.pl`

Exportar:

```prolog
grupo/2
listar_grupos_derivados/1
ids_por_grupo/2
```

`grupo/2` deve ser derivado dos contatos atuais.

## 12.9 `grupo_service.pl`

Exportar:

```prolog
listar_grupos/1
buscar_por_grupo/2
adicionar_grupo/3
remover_grupo/3
grupo_equivalente/2
```

## 12.10 `validation.pl`

Exportar:

```prolog
validar_usuario/2
validar_senha/2
validar_nome_contato/2
validar_telefone/2
validar_email/2
validar_grupo/2
normalizar_texto/2
```

## 12.11 `csv_utils.pl`

Exportar:

```prolog
ler_csv_seguro/4
salvar_csv_atomico/4
validar_cabecalho/3
criar_diretorio_seguro/2
```

Responsabilidade:

- operações genéricas;
- arquivo temporário;
- substituição;
- exceções de arquivo.

## 12.12 `input_utils.pl`

Exportar:

```prolog
ler_inteiro/2
ler_texto_nao_vazio/2
ler_texto_opcional/2
ler_senha/2
ler_grupos/2
confirmar/2
exibir_contato/1
exibir_contatos/1
exibir_resultado/1
```

## 12.13 `menu.pl`

Exportar:

```prolog
menu_principal/2
menu_pesquisa/1
menu_grupos/1
```

Contrato:

```prolog
menu_principal(+Sessao, -AcaoFinal).
```

Resultados:

```prolog
logout
encerrar
```

## 12.14 `main.pl`

Fluxo:

```prolog
main :-
    inicializar_usuarios(Resultado),
    iniciar_ciclo(Resultado).
```

Responsabilidades:

- carregar usuários;
- executar ciclo de autenticação;
- abrir sessão;
- limpar contatos;
- carregar agenda;
- executar menu;
- salvar;
- logout ou encerrar.

---

# 13. Dependências proibidas

- menu não chama `assertz/1`;
- menu não chama `retract/1`;
- auth menu não gera hash;
- serviço de autenticação não imprime senha;
- serviço de contatos não lê teclado;
- repositório não implementa regra de negócio;
- grupo não possui arquivo próprio;
- contato repository não escolhe usuário;
- caminho da agenda vem da sessão;
- usuário não informa caminho manualmente.

---

# 14. Fluxo de cadastro de usuário

```text
Menu de autenticação
       ↓
Ler usuário
       ↓
Normalizar
       ↓
Validar formato
       ↓
Verificar duplicidade
       ↓
Ler senha e confirmação
       ↓
Validar senha
       ↓
Gerar hash
       ↓
Criar diretório do usuário
       ↓
Criar contatos.csv temporário
       ↓
Persistir usuários.csv
       ↓
Finalizar arquivo da agenda
       ↓
Inserir usuário na base
       ↓
Retornar sucesso
```

## 14.1 Rollback

Se o cadastro falhar:

- não inserir `usuario/2`;
- não salvar hash parcial;
- remover arquivo temporário;
- remover diretório recém-criado se estiver vazio;
- preservar `usuarios.csv`.

---

# 15. Fluxo de login

```text
Ler usuário
   ↓
Normalizar
   ↓
Buscar hash
   ↓
Verificar senha
   ↓
Resolver data/<usuario>/contatos.csv
   ↓
Confirmar existência
   ↓
Criar sessao/2
```

Mensagem pública para falha:

```text
Credenciais inválidas.
```

Não informar separadamente:

- usuário inexistente;
- senha incorreta.

---

# 16. Fluxo de troca de usuário

```text
Usuário A autenticado
        ↓
Salvar contatos de A
        ↓
Limpar contato/5
        ↓
Descartar sessão A
        ↓
Menu de autenticação
        ↓
Autenticar B
        ↓
Limpar defensivamente
        ↓
Carregar contatos de B
```

Este fluxo é obrigatório para isolamento.

---

# 17. Fluxos da agenda

## 17.1 Cadastro de contato

- validar;
- gerar ID dentro da sessão;
- inserir fato;
- não salvar ainda.

## 17.2 Busca

- ID: semidet;
- nome: parcial;
- telefone: parcial;
- grupo: consulta derivada.

## 17.3 Edição

- localizar;
- preservar ID;
- validar antes de alterar;
- preservar fato anterior em erro.

## 17.4 Remoção

- exibir;
- confirmar;
- remover somente se positivo.

## 17.5 Grupos

- normalizar;
- impedir duplicata;
- atualizar lista no contato;
- derivar visão automaticamente.

---

# 18. Menus

## 18.1 Autenticação

```text
1. Entrar
2. Cadastrar usuario
0. Sair
```

## 18.2 Agenda

```text
1. Listar contatos
2. Cadastrar contato
3. Editar contato
4. Remover contato
5. Pesquisar contato
6. Gerenciar grupos
7. Salvar e trocar de usuario
0. Salvar e sair
```

## 18.3 Pesquisa

```text
1. Nome
2. Telefone
3. ID
4. Grupo
0. Voltar
```

## 18.4 Grupos

```text
1. Listar
2. Adicionar contato
3. Remover contato
0. Voltar
```

---

# 19. Divisão das cinco pessoas

## 19.1 Pessoa 1 — persistência e base de contatos

Arquivos:

- `contato_db.pl`;
- `contato_repository.pl`;
- `csv_utils.pl`;
- testes correspondentes.

Entregas:

- fatos de contatos;
- snapshot;
- CSV;
- grupos serializados;
- arquivo temporário;
- criação de CSV vazio.

Revisão adicional:

- revisar `auth_repository.pl`.

## 19.2 Pessoa 2 — serviço de contatos

Arquivos:

- `contato_service.pl`;
- `contato_service_test.pl`.

Entregas:

- ID;
- cadastro;
- buscas;
- edição;
- remoção;
- ordenação.

## 19.3 Pessoa 3 — grupos

Arquivos:

- `grupo_repository.pl`;
- `grupo_service.pl`;
- testes.

Entregas:

- `grupo/2`;
- agregação de IDs;
- listagem;
- busca;
- associação;
- remoção;
- equivalência.

## 19.4 Pessoa 4 — autenticação, validação e entrada

Arquivos:

- `auth_db.pl`;
- `auth_repository.pl`;
- `auth_service.pl`;
- `validation.pl`;
- `input_utils.pl`;
- testes.

Entregas:

- usuário;
- hash;
- cadastro;
- login;
- regras de senha;
- validação de caminho;
- leitura segura.

Revisão:

- Pessoa 1 revisa persistência;
- Pessoa 5 revisa sessão.

## 19.5 Pessoa 5 — menus, sessão e integração

Arquivos:

- `auth_menu.pl`;
- `menu.pl`;
- `main.pl`;
- testes integrados;
- README.

Entregas:

- autenticação CLI;
- ciclo de sessão;
- carga por usuário;
- logout;
- salvamento;
- documentação;
- demonstração.

## 19.6 Compartilhado

- contratos;
- revisão;
- Git;
- testes;
- segurança de arquivos;
- apresentação.

---

# 20. Ordem de implementação

| Etapa | Objetivo | Responsáveis |
|---|---|---|
| 1 | Aprovar termos e contratos | Todos |
| 2 | Criar estrutura | Pessoa 5 |
| 3 | Implementar validações | Pessoa 4 |
| 4 | Implementar auth_db | Pessoa 4 |
| 5 | Implementar CSV genérico | Pessoa 1 |
| 6 | Implementar auth_repository | Pessoas 1 e 4 |
| 7 | Implementar auth_service | Pessoa 4 |
| 8 | Implementar contato_db | Pessoa 1 |
| 9 | Implementar contato_repository | Pessoa 1 |
| 10 | Implementar contatos | Pessoa 2 |
| 11 | Implementar grupos | Pessoa 3 |
| 12 | Implementar entrada | Pessoa 4 |
| 13 | Integrar auth menu | Pessoa 5 |
| 14 | Integrar agenda | Pessoa 5 |
| 15 | Integrar logout | Pessoas 4 e 5 |
| 16 | Testar isolamento | Todos |
| 17 | Testes finais | Todos |

Autenticação deve funcionar antes da integração completa da agenda.

---

# 21. Sprints

## Sprint 0

- instalar SWI-Prolog;
- aprovar regras;
- criar arquivos;
- definir CSV;
- definir hash;
- definir sessão.

## Sprint 1

Paralelo:

- Pessoa 1: CSV e contatos;
- Pessoa 2: serviço de contatos;
- Pessoa 3: grupos;
- Pessoa 4: auth e validação;
- Pessoa 5: menus vazios.

## Sprint 2

- cadastro;
- login;
- criação de conta;
- abertura da agenda;
- CRUD;
- grupos;
- logout;
- saída.

## Sprint 3

- segurança;
- isolamento;
- testes;
- documentação;
- apresentação.

---

# 22. Estratégia de testes

## 22.1 Autenticação

| Código | Cenário | Esperado |
|---|---|---|
| AU01 | Cadastro válido | usuário e diretório criados |
| AU02 | Usuário duplicado | rejeitado |
| AU03 | Usuário com `/` | rejeitado |
| AU04 | Usuário com `..` | rejeitado |
| AU05 | Senha curta | rejeitada |
| AU06 | Confirmação diferente | rejeitada |
| AU07 | Hash gerado | diferente da senha |
| AU08 | Login correto | sessão criada |
| AU09 | Senha incorreta | credenciais inválidas |
| AU10 | Usuário inexistente | credenciais inválidas |
| AU11 | CSV individual ausente | erro controlado |
| AU12 | Logout | contatos limpos |

## 22.2 Multiusuário

| Código | Cenário | Esperado |
|---|---|---|
| MU01 | A cadastra contato | aparece em A |
| MU02 | Login B | contato de A não aparece |
| MU03 | B usa ID 1 | permitido |
| MU04 | Volta para A | contatos de A retornam |
| MU05 | Arquivos distintos | conteúdo isolado |
| MU06 | Troca sem limpar | teste deve detectar |
| MU07 | Falha no salvamento A | não abrir B silenciosamente |

## 22.3 Contatos

- base vazia;
- próximo ID;
- cadastro;
- campos vazios;
- busca;
- edição;
- remoção.

## 22.4 Grupos

- zero grupo;
- múltiplos;
- duplicidade;
- remoção;
- visão derivada.

## 22.5 CSV

- cabeçalhos;
- linhas inválidas;
- hashes;
- telefone;
- grupos;
- round trip;
- falha de escrita.

---

# 23. PlUnit

Comando:

```bash
swipl -q -g run_tests -t halt test/run_tests.pl
```

Regras:

- usar diretório temporário;
- usar `setup` e `cleanup`;
- nunca usar dados reais;
- limpar usuários e contatos;
- apagar arquivos de teste;
- verificar estado antes e depois.

---

# 24. Git

Branches:

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

Pull request deve informar:

- predicados alterados;
- aridades;
- testes;
- arquivos;
- impacto em sessão;
- impacto em persistência.

---

# 25. Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Senha em texto puro | Alto | crypto_password_hash |
| Nome usado em travessia | Alto | whitelist |
| Vazamento entre sessões | Alto | limpar contato/5 |
| Arquivo de usuário errado | Alto | sessão resolve caminho |
| Cadastro parcial | Alto | temporário e rollback |
| CSV corrompido | Alto | validar antes de sobrescrever |
| Hash tratado como senha comum | Alto | campo opaco |
| IDs globais por engano | Médio | ID por agenda |
| Menu altera fatos | Médio | encapsulamento |
| Corte incorreto | Médio | revisão |
| Testes contaminados | Médio | setup/cleanup |

---

# 26. Definition of Done

Uma funcionalidade está pronta quando:

- implementada;
- modularizada;
- contrato preservado;
- teste válido;
- teste de erro;
- revisão;
- sem senha em logs;
- sem acesso cruzado;
- sem arquivos temporários restantes;
- documentação atualizada.

---

# 27. Checklist de aceite

| Item | Situação |
|---|---|
| Cadastro de usuário | ☐ |
| Hash de senha | ☐ |
| Login | ☐ |
| Credenciais inválidas | ☐ |
| Diretório individual | ☐ |
| CSV individual | ☐ |
| Logout | ☐ |
| Isolamento | ☐ |
| Carga de contatos | ☐ |
| CRUD | ☐ |
| Pesquisas | ☐ |
| Grupos | ☐ |
| Salvamento seguro | ☐ |
| Reinicialização | ☐ |
| Testes PlUnit | ☐ |
| README | ☐ |
| Apresentação | ☐ |

---

# 28. Roteiro de demonstração

1. mostrar `auth/usuarios.csv` sem revelar hashes completos;
2. cadastrar usuário A;
3. rejeitar cadastro duplicado;
4. testar senha incorreta;
5. entrar como A;
6. cadastrar contato;
7. editar;
8. grupos;
9. logout;
10. cadastrar ou entrar como B;
11. demonstrar agenda vazia/diferente;
12. usar ID igual em B;
13. voltar para A;
14. demonstrar persistência;
15. consultar fatos;
16. explicar unificação;
17. explicar backtracking;
18. executar testes.

---

# 29. Comandos

Executar:

```bash
swipl -q -s app/main.pl
```

Testar:

```bash
swipl -q -g run_tests -t halt test/run_tests.pl
```

Interpretador:

```prolog
?- [app/main].
?- main.
```

---

# 30. Conclusão

Arquitetura final:

```text
auth_db.pl              -> usuários em memória
auth_repository.pl      -> usuários.csv
auth_service.pl         -> cadastro, hash e login
auth_menu.pl            -> interface de autenticação

contato_db.pl           -> contatos da sessão
contato_repository.pl   -> CSV individual
contato_service.pl      -> CRUD e buscas

grupo_repository.pl     -> visão derivada
grupo_service.pl        -> regras de grupos

validation.pl           -> validações
input_utils.pl          -> terminal
csv_utils.pl            -> CSV e temporários
menu.pl                 -> agenda
main.pl                 -> sessão, logout e encerramento
```

O projeto estará completo quando:

```text
cadastrar usuário
→ autenticar
→ abrir somente sua agenda
→ alterar contatos
→ salvar
→ trocar de usuário
→ comprovar isolamento
→ reiniciar
→ recuperar cada agenda corretamente
```
