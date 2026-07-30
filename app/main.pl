:- consult('../src/db/auth_db.pl').
:- consult('../src/db/contato_db.pl').
:- consult('../src/repository/auth_repository.pl').
:- consult('../src/repository/contato_repository.pl').
:- consult('../src/service/auth_service.pl').
:- use_module('../src/service/grupo_service.pl').
:- consult('../src/menu/auth_menu.pl').
:- consult('../src/menu/menu.pl').

:- initialization(run_main_if_entry, main).

/**
 * Inicializa a base de usuarios a partir do CSV configurado.
 *
 * @param Resultado Termo com o resultado da carga inicial.
 * @return `ok` quando a base e carregada ou `erro(Codigo)` em caso de falha.
 */
iniciar_aplicacao(Resultado) :-
    caminho_usuarios_atual(CaminhoUsuarios),
    carregar_usuarios_csv(CaminhoUsuarios, ResultadoCarga),
    tratar_carga_inicial(ResultadoCarga, Resultado).

tratar_carga_inicial(ok(Usuarios), ok) :-
    substituir_usuarios(Usuarios, ok).
tratar_carga_inicial(erro(Codigo), erro(Codigo)).

/**
 * Carrega os contatos associados a uma sessao autenticada.
 *
 * @param Sessao Termo `sessao/2` com o usuario autenticado e o caminho do CSV.
 * @param Resultado Termo com o resultado da carga da agenda.
 * @return `ok` quando a agenda e carregada ou `erro(Codigo)` em caso de falha.
 */
abrir_sessao(sessao(_, CaminhoContatos), Resultado) :-
    limpar_contatos,
    carregar_contatos_csv(CaminhoContatos, ResultadoCarga),
    tratar_carga_contatos(ResultadoCarga, Resultado).

tratar_carga_contatos(ok(Contatos), ok) :-
    substituir_contatos(Contatos, ok).
tratar_carga_contatos(erro(Codigo), erro(Codigo)).

/**
 * Persiste os contatos carregados na sessao atual.
 *
 * @param Sessao Termo `sessao/2` com o caminho da agenda autenticada.
 * @param Resultado Termo com o resultado do salvamento.
 * @return `ok` quando a agenda e salva ou `erro(Codigo)` em caso de falha.
 */
salvar_sessao(sessao(_, CaminhoContatos), Resultado) :-
    snapshot_contatos(Contatos),
    salvar_contatos_csv(CaminhoContatos, Contatos, Resultado).

/**
 * Finaliza a sessao atual salvando e limpando os contatos em memoria.
 *
 * @param Sessao Termo `sessao/2` da conta autenticada.
 * @param Resultado Termo com o resultado do encerramento.
 * @return `ok` quando a sessao e encerrada ou `erro(Codigo)` em caso de falha.
 */
encerrar_sessao(Sessao, Resultado) :-
    salvar_sessao(Sessao, ResultadoSalvar),
    tratar_encerramento(ResultadoSalvar, Resultado).

tratar_encerramento(ok, ok) :-
    limpar_contatos.
tratar_encerramento(erro(Codigo), erro(Codigo)).

/**
 * Executa o fluxo principal do programa.
 *
 * @param Nenhum Predicado sem parametros de entrada.
 * @return Nao retorna valor util; inicia ou encerra a aplicacao.
 */
main :-
    iniciar_aplicacao(ResultadoInicial),
    iniciar_ciclo(ResultadoInicial).

run_main_if_entry :-
    deve_iniciar_main,
    !,
    main.
run_main_if_entry.

deve_iniciar_main :-
    source_file(main, ArquivoAtual),
    current_prolog_flag(os_argv, Argumentos),
    member(Argumento, Argumentos),
    normalizar_caminho(ArquivoAtual, CaminhoAtual),
    normalizar_caminho(Argumento, CaminhoArgumento),
    CaminhoAtual = CaminhoArgumento.

normalizar_caminho(Entrada, Saida) :-
    catch(absolute_file_name(Entrada, Absoluto, [file_errors(fail)]), _, fail),
    !,
    Saida = Absoluto.
normalizar_caminho(Entrada, Entrada).

iniciar_ciclo(ok) :-
    ciclo_autenticacao.
iniciar_ciclo(erro(Codigo)) :-
    format('Falha ao inicializar o sistema: ~w~n', [Codigo]).

ciclo_autenticacao :-
    menu_autenticacao(ResultadoAutenticacao),
    tratar_resultado_autenticacao(ResultadoAutenticacao).

tratar_resultado_autenticacao(encerrar).
tratar_resultado_autenticacao(sessao(Usuario, CaminhoContatos)) :-
    Sessao = sessao(Usuario, CaminhoContatos),
    abrir_sessao(Sessao, ResultadoCarga),
    tratar_sessao_aberta(Sessao, ResultadoCarga).

tratar_sessao_aberta(Sessao, ok) :-
    menu_principal(Sessao, AcaoFinal),
    tratar_acao_final(Sessao, AcaoFinal).
tratar_sessao_aberta(_, erro(Codigo)) :-
    format('Falha ao carregar agenda: ~w~n', [Codigo]),
    limpar_contatos,
    ciclo_autenticacao.

tratar_acao_final(Sessao, logout) :-
    encerrar_sessao(Sessao, Resultado),
    tratar_logout(Resultado).
tratar_acao_final(Sessao, encerrar) :-
    encerrar_sessao(Sessao, Resultado),
    exibir_resultado_final(Resultado).

tratar_logout(ok) :- ciclo_autenticacao.
tratar_logout(erro(Codigo)) :-
    format('Falha ao salvar agenda; a troca de usuario foi cancelada: ~w~n', [Codigo]).

exibir_resultado_final(ok).
exibir_resultado_final(erro(Codigo)) :-
    format('Falha ao salvar agenda: ~w~n', [Codigo]).
