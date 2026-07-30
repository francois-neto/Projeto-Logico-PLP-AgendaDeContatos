:- use_module(library(plunit)).
:- use_module(library(filesex)).
:- use_module(library(crypto)).

:- consult('../src/db/auth_db.pl').
:- consult('../src/db/contato_db.pl').
:- consult('../src/service/auth_service.pl').
:- consult('../app/main.pl').

:- begin_tests(integration).

test(cadastro_persiste_hash_e_autentica, [setup(setup_auth_env(Contexto)), cleanup(cleanup_auth_env(Contexto))]) :-
    cadastrar_usuario("ana", "senha123", ResultadoCadastro),
    assertion(ResultadoCadastro == ok("ana")),
    snapshot_usuarios(Usuarios),
    assertion(Usuarios = [usuario("ana", HashSenha)]),
    assertion(HashSenha \== "senha123"),
    autenticar_usuario("ana", "senha123", ResultadoLogin),
    assertion(ResultadoLogin = ok(sessao("ana", _))).

test(cadastro_aceita_credenciais_sem_validacao, [setup(setup_auth_env(Contexto)), cleanup(cleanup_auth_env(Contexto))]) :-
    cadastrar_usuario("../admin", "opa", Resultado),
    assertion(Resultado == ok("../admin")),
    snapshot_usuarios(Usuarios),
    assertion(Usuarios = [usuario("../admin", _)]).

test(criar_sessao_aceita_usuario_sem_restricao_de_formato, [setup(setup_auth_env(Contexto)), cleanup(cleanup_auth_env(Contexto))]) :-
    criar_sessao("../admin", Resultado),
    assertion(Resultado = ok(sessao("../admin", _))).

test(login_aceita_credenciais_existentes_sem_validacao_de_tamanho, [setup(setup_auth_env(Contexto)), cleanup(cleanup_auth_env(Contexto))]) :-
    crypto_password_hash("x", HashSenha),
    inserir_usuario_db("ab", HashSenha, ok),
    autenticar_usuario("ab", "x", Resultado),
    assertion(Resultado = ok(sessao("ab", _))).

test(isolamento_entre_usuarios, [setup(setup_auth_env(Contexto)), cleanup(cleanup_auth_env(Contexto))]) :-
    cadastrar_usuario("ana", "senha123", ok("ana")),
    cadastrar_usuario("bob", "senha123", ok("bob")),
    autenticar_usuario("ana", "senha123", ok(SessaoAna)),
    abrir_sessao(SessaoAna, ok),
    inserir_contato_db(contato(1, 'Ana Silva', '1111', 'ana@email.com', [familia]), ok),
    salvar_sessao(SessaoAna, ok),
    limpar_contatos,
    autenticar_usuario("bob", "senha123", ok(SessaoBob)),
    abrir_sessao(SessaoBob, ok),
    snapshot_contatos(ContatosBob),
    assertion(ContatosBob == []),
    inserir_contato_db(contato(1, 'Bob Lima', '2222', 'bob@email.com', [trabalho]), ok),
    salvar_sessao(SessaoBob, ok),
    limpar_contatos,
    abrir_sessao(SessaoAna, ok),
    snapshot_contatos(ContatosAna),
    assertion(ContatosAna == [contato(1, 'Ana Silva', '1111', 'ana@email.com', [familia])]),
    encerrar_sessao(SessaoAna, ok).

:- end_tests(integration).

setup_auth_env(contexto(DirRaiz, CaminhoUsuarios, DiretorioDados)) :-
    criar_diretorio_temporario(DirRaiz),
    atomic_list_concat([DirRaiz, '/auth/usuarios.csv'], CaminhoUsuarios),
    atomic_list_concat([DirRaiz, '/data'], DiretorioDados),
    configurar_ambiente_auth(CaminhoUsuarios, DiretorioDados),
    iniciar_aplicacao(ok).

cleanup_auth_env(contexto(DirRaiz, _, _)) :-
    limpar_usuarios,
    limpar_contatos,
    resetar_ambiente_auth,
    ( exists_directory(DirRaiz) -> delete_directory_and_contents(DirRaiz) ; true ).

criar_diretorio_temporario(DirRaiz) :-
    tmp_file_stream(text, ArquivoTemporario, Stream),
    close(Stream),
    delete_file(ArquivoTemporario),
    file_directory_name(ArquivoTemporario, DiretorioBase),
    get_time(Timestamp),
    format_time(atom(Sufixo), '%Y%m%d%H%M%S%3f', Timestamp),
    atomic_list_concat([DiretorioBase, '/agenda_auth_', Sufixo], DirRaiz),
    make_directory_path(DirRaiz).
