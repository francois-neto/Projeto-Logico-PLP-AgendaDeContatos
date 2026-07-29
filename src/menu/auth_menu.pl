:- consult('../service/auth_service.pl').
:- consult('../utils/input_utils.pl').

/**
 * Executa o menu de autenticacao no terminal.
 *
 * @param Resultado Variavel que recebe `sessao/2` ou `encerrar`.
 * @return Verdadeiro quando o fluxo escolhe uma sessao valida ou encerramento.
 */
menu_autenticacao(Resultado) :-
    repeat,
    exibir_menu_autenticacao,
    ler_opcao_autenticacao(Opcao),
    tratar_opcao_autenticacao(Opcao, Resultado),
    Resultado \= repetir,
    !.

/**
 * Executa o fluxo interativo de login.
 *
 * @param Resultado Variavel que recebe `sessao/2` ou `repetir`.
 * @return Verdadeiro quando a tentativa e processada.
 */
fluxo_login(Resultado) :-
    ler_texto_opcional('Usuario: ', Usuario),
    ler_senha('Senha: ', Senha),
    autenticar_usuario(Usuario, Senha, ResultadoAutenticacao),
    tratar_resultado_login(ResultadoAutenticacao, Resultado).

/**
 * Executa o fluxo interativo de cadastro de usuario.
 *
 * @param Resultado Variavel que recebe `repetir`.
 * @return Verdadeiro quando o cadastro e processado.
 */
fluxo_cadastro(repetir) :-
    ler_texto_opcional('Novo usuario: ', Usuario),
    ler_senha('Senha: ', Senha),
    ler_senha('Confirmacao: ', Confirmacao),
    cadastrar_usuario(Usuario, Senha, Confirmacao, ResultadoCadastro),
    exibir_resultado_cadastro(ResultadoCadastro).

tratar_opcao_autenticacao("1", Resultado) :-
    fluxo_login(Resultado).
tratar_opcao_autenticacao("2", Resultado) :-
    fluxo_cadastro(Resultado).
tratar_opcao_autenticacao("0", encerrar).
tratar_opcao_autenticacao(_, repetir) :-
    format('Opcao invalida.~n').

tratar_resultado_login(ok(sessao(Usuario, CaminhoContatos)), sessao(Usuario, CaminhoContatos)) :-
    format('Login realizado com sucesso.~n').
tratar_resultado_login(erro(_), repetir) :-
    format('Credenciais invalidas.~n').

exibir_resultado_cadastro(ok(Usuario)) :-
    format('Usuario cadastrado: ~w~n', [Usuario]).
exibir_resultado_cadastro(erro(Codigo)) :-
    format('Falha no cadastro: ~w~n', [Codigo]).

exibir_menu_autenticacao :-
    format('~nAGENDA DE CONTATOS - PROLOG~n', []),
    format('1. Entrar~n', []),
    format('2. Cadastrar usuario~n', []),
    format('0. Sair~n', []).

ler_opcao_autenticacao(Opcao) :-
    ler_texto_opcional('Escolha uma opcao: ', Opcao).
