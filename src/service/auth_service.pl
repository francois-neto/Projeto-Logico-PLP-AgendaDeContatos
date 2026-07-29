:- use_module(library(crypto)).
:- consult('../db/auth_db.pl').
:- consult('../repository/auth_repository.pl').
:- consult('../repository/contato_repository.pl').
:- use_module('../utils/validation.pl', [
    normalizar_texto/2,
    validar_usuario/2,
    validar_senha/3
]).

:- dynamic auth_config/2.

/**
 * Define caminhos alternativos para persistencia de autenticacao e agendas.
 *
 * @param CaminhoUsuarios Caminho do arquivo de usuarios.
 * @param DiretorioDados Diretorio raiz das agendas por usuario.
 * @return Verdadeiro quando a configuracao passa a valer para a execucao atual.
 */
configurar_ambiente_auth(CaminhoUsuarios, DiretorioDados) :-
    retractall(auth_config(_, _)),
    assertz(auth_config(CaminhoUsuarios, DiretorioDados)).

/**
 * Restaura os caminhos padrao de autenticacao e dados.
 *
 * @param Nenhum Predicado sem parametros de entrada.
 * @return Verdadeiro quando a configuracao customizada e removida.
 */
resetar_ambiente_auth :-
    retractall(auth_config(_, _)).

/**
 * Obtem o caminho atual do arquivo de usuarios.
 *
 * @param CaminhoUsuarios Variavel que recebe o caminho efetivo.
 * @return Verdadeiro quando o caminho e resolvido.
 */
caminho_usuarios_atual(CaminhoUsuarios) :-
    auth_paths(CaminhoUsuarios, _).

/**
 * Normaliza o nome de usuario antes das regras de validacao e persistencia.
 *
 * @param UsuarioBruto Valor textual informado pelo usuario.
 * @param UsuarioNormalizado Nome normalizado para comparacao e armazenamento.
 * @return Verdadeiro quando o valor normalizado e produzido.
 */
normalizar_usuario(UsuarioBruto, UsuarioNormalizado) :-
    normalizar_texto(UsuarioBruto, UsuarioTexto),
    string_lower(UsuarioTexto, UsuarioNormalizado).

/**
 * Cadastra um novo usuario e inicializa sua agenda isolada.
 *
 * @param Usuario Nome informado no cadastro.
 * @param Senha Senha informada no cadastro.
 * @param Confirmacao Confirmacao da senha.
 * @param Resultado Termo com o desfecho da operacao.
 * @return `ok(Usuario)` quando o cadastro e concluido ou `erro(Codigo)` em caso de falha.
 */
cadastrar_usuario(Usuario, Senha, Confirmacao, Resultado) :-
    normalizar_usuario(Usuario, UsuarioNormalizado),
    validar_cadastro(UsuarioNormalizado, Senha, Confirmacao, ResultadoValidacao),
    concluir_cadastro(ResultadoValidacao, UsuarioNormalizado, Senha, Resultado).

concluir_cadastro(ok, UsuarioNormalizado, Senha, Resultado) :-
    crypto_password_hash(Senha, HashSenha),
    inicializar_agenda_usuario(UsuarioNormalizado, ResultadoAgenda),
    persistir_novo_usuario(ResultadoAgenda, UsuarioNormalizado, HashSenha, Resultado).
concluir_cadastro(erro(Codigo), _, _, erro(Codigo)).

persistir_novo_usuario(ok, UsuarioNormalizado, HashSenha, Resultado) :-
    snapshot_usuarios(UsuariosAtuais),
    append(UsuariosAtuais, [usuario(UsuarioNormalizado, HashSenha)], UsuariosAtualizados),
    caminho_usuarios_atual(CaminhoUsuarios),
    salvar_usuarios_csv(CaminhoUsuarios, UsuariosAtualizados, ResultadoPersistencia),
    concluir_persistencia(ResultadoPersistencia, UsuarioNormalizado, HashSenha, Resultado).
persistir_novo_usuario(erro(Codigo), _, _, erro(Codigo)).

concluir_persistencia(ok, UsuarioNormalizado, HashSenha, ok(UsuarioNormalizado)) :-
    inserir_usuario_db(UsuarioNormalizado, HashSenha, ok).
concluir_persistencia(erro(Codigo), _, _, erro(Codigo)).

/**
 * Autentica um usuario a partir da base em memoria e devolve uma sessao.
 *
 * @param Usuario Nome informado para login.
 * @param Senha Senha informada para verificacao.
 * @param Resultado Termo com o desfecho da autenticacao.
 * @return `ok(sessao(Usuario,Caminho))` quando as credenciais sao validas ou `erro(credenciais_invalidas)`.
 */
autenticar_usuario(Usuario, Senha, Resultado) :-
    normalizar_usuario(Usuario, UsuarioNormalizado),
    ( buscar_usuario_db(UsuarioNormalizado, HashSenha),
      crypto_password_hash(Senha, HashSenha) ->
        criar_sessao(UsuarioNormalizado, Resultado)
    ;
        Resultado = erro(credenciais_invalidas)
    ).

/**
 * Cria o termo de sessao do usuario autenticado.
 *
 * @param Usuario Nome normalizado do usuario autenticado.
 * @param Resultado Termo com a sessao resolvida.
 * @return `ok(sessao(Usuario,Caminho))` quando a agenda do usuario esta acessivel.
 */
criar_sessao(Usuario, Resultado) :-
    ( resolver_caminho_contatos(Usuario, CaminhoContatos) ->
        inicializar_agenda_usuario(Usuario, ResultadoAgenda),
        resultado_criacao_sessao(ResultadoAgenda, Usuario, CaminhoContatos, Resultado)
    ; Resultado = erro(usuario_invalido)
    ).

resultado_criacao_sessao(ok, Usuario, CaminhoContatos, ok(sessao(Usuario, CaminhoContatos))).
resultado_criacao_sessao(erro(Codigo), _, _, erro(Codigo)).

/**
 * Resolve o caminho do arquivo de contatos do usuario.
 *
 * @param Usuario Nome normalizado do usuario.
 * @param CaminhoContatos Variavel que recebe o caminho da agenda.
 * @return Verdadeiro quando o caminho e construido.
 */
resolver_caminho_contatos(Usuario, CaminhoContatos) :-
    validar_usuario(Usuario, ok),
    auth_paths(_, DiretorioDados),
    atomic_list_concat([DiretorioDados, '/', Usuario, '/contatos.csv'], CaminhoContatos).

/**
 * Garante a existencia da agenda isolada do usuario.
 *
 * @param Usuario Nome normalizado do usuario.
 * @param Resultado Termo de resultado da inicializacao.
 * @return `ok` quando a agenda do usuario existe ou e criada.
 */
inicializar_agenda_usuario(Usuario, Resultado) :-
    resolver_caminho_contatos(Usuario, CaminhoContatos),
    ( exists_file(CaminhoContatos) ->
        Resultado = ok
    ;
        criar_csv_contatos_vazio(CaminhoContatos, Resultado)
    ).

validar_cadastro(UsuarioNormalizado, Senha, Confirmacao, ok) :-
    validar_usuario(UsuarioNormalizado, ok),
    \+ buscar_usuario_db(UsuarioNormalizado, _),
    validar_senha(Senha, Confirmacao, ok).
validar_cadastro(UsuarioNormalizado, _, _, erro(usuario_duplicado(UsuarioNormalizado))) :-
    buscar_usuario_db(UsuarioNormalizado, _).
validar_cadastro(UsuarioNormalizado, _, _, erro(Codigo)) :-
    validar_usuario(UsuarioNormalizado, erro(Codigo)).
validar_cadastro(_, Senha, Confirmacao, erro(Codigo)) :-
    validar_senha(Senha, Confirmacao, erro(Codigo)).

auth_paths(CaminhoUsuarios, DiretorioDados) :-
    auth_config(CaminhoUsuarios, DiretorioDados),
    !.
auth_paths('auth/usuarios.csv', 'data').
