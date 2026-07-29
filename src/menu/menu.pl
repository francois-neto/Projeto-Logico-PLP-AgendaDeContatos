:- consult('../db/contato_db.pl').

/**
 * Executa o menu principal da agenda para uma sessao autenticada.
 *
 * @param Sessao Termo `sessao/2` do usuario autenticado.
 * @param AcaoFinal Variavel que recebe `logout` ou `encerrar`.
 * @return Verdadeiro quando o fluxo finaliza a sessao atual.
 */
menu_principal(Sessao, AcaoFinal) :-
    repeat,
    exibir_menu_principal(Sessao),
    ler_opcao_menu(Opcao),
    tratar_opcao_menu(Opcao, Acao),
    Acao \= continuar,
    AcaoFinal = Acao,
    !.

/**
 * Executa o submenu de pesquisa.
 *
 * @param Resultado Variavel que recebe `continuar`.
 * @return Verdadeiro quando a navegacao retorna ao menu anterior.
 */
menu_pesquisa(continuar) :-
    format('Pesquisa depende do servico de contatos da pessoa 2.~n').

/**
 * Executa o submenu de grupos.
 *
 * @param Resultado Variavel que recebe `continuar`.
 * @return Verdadeiro quando a navegacao retorna ao menu anterior.
 */
menu_grupos(continuar) :-
    format('Gestao de grupos depende do servico da pessoa 3.~n').

tratar_opcao_menu("1", continuar) :-
    listar_contatos_menu.
tratar_opcao_menu("2", continuar) :-
    format('Cadastro de contato depende do servico da pessoa 2.~n').
tratar_opcao_menu("3", continuar) :-
    format('Edicao de contato depende do servico da pessoa 2.~n').
tratar_opcao_menu("4", continuar) :-
    format('Remocao de contato depende do servico da pessoa 2.~n').
tratar_opcao_menu("5", continuar) :-
    menu_pesquisa(_).
tratar_opcao_menu("6", continuar) :-
    menu_grupos(_).
tratar_opcao_menu("7", logout).
tratar_opcao_menu("0", encerrar).
tratar_opcao_menu(_, continuar) :-
    format('Opcao invalida.~n').

listar_contatos_menu :-
    snapshot_contatos(Contatos),
    exibir_contatos(Contatos).

exibir_contatos([]) :-
    format('Nenhum contato carregado.~n').
exibir_contatos([Contato | Restante]) :-
    exibir_contato(Contato),
    exibir_contatos(Restante).

exibir_contato(contato(Id, Nome, Telefone, Email, Grupos)) :-
    format('ID: ~w | Nome: ~w | Telefone: ~w | Email: ~w | Grupos: ~w~n',
           [Id, Nome, Telefone, Email, Grupos]).

exibir_menu_principal(sessao(Usuario, _)) :-
    format('~nAGENDA DE CONTATOS~n', []),
    format('Usuario: ~w~n', [Usuario]),
    format('1. Listar contatos~n', []),
    format('2. Cadastrar contato~n', []),
    format('3. Editar contato~n', []),
    format('4. Remover contato~n', []),
    format('5. Pesquisar contato~n', []),
    format('6. Gerenciar grupos~n', []),
    format('7. Salvar e trocar de usuario~n', []),
    format('0. Salvar e sair~n', []).

ler_opcao_menu(Opcao) :-
    format('Escolha uma opcao: '),
    read_line_to_string(user_input, Opcao).
