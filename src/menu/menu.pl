:- consult('../db/contato_db.pl').
:- consult('../service/contato_service.pl').
:- use_module('../service/grupo_service.pl').
:- consult('../utils/input_utils.pl').

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
    once(tratar_opcao_menu(Opcao, Acao)),
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
    repeat,
    format('~nPESQUISAR CONTATO~n1. Nome~n2. Telefone~n3. ID~n0. Voltar~n', []),
    ler_texto_opcional('Escolha uma opcao: ', Opcao),
    once(tratar_opcao_pesquisa(Opcao, Resultado)),
    Resultado \= continuar_pesquisa,
    !.

/**
 * Executa o submenu de grupos.
 *
 * @param Resultado Variavel que recebe `continuar`.
 * @return Verdadeiro quando a navegacao retorna ao menu anterior.
 */
menu_grupos(continuar) :-
    repeat,
    format('~nGERENCIAR GRUPOS~n1. Listar grupos~n2. Adicionar contato a um grupo~n3. Remover contato de um grupo~n0. Voltar~n', []),
    ler_texto_opcional('Escolha uma opcao: ', Opcao),
    once(tratar_opcao_grupos(Opcao, Resultado)),
    Resultado \= continuar_grupos,
    !.

tratar_opcao_menu("1", continuar) :-
    listar_contatos_menu.
tratar_opcao_menu("2", continuar) :-
    fluxo_cadastro_contato.
tratar_opcao_menu("3", continuar) :-
    fluxo_edicao_contato.
tratar_opcao_menu("4", continuar) :-
    fluxo_remocao_contato.
tratar_opcao_menu("5", continuar) :-
    menu_pesquisa(_).
tratar_opcao_menu("6", continuar) :-
    menu_grupos(_).
tratar_opcao_menu("7", logout).
tratar_opcao_menu("0", encerrar).
tratar_opcao_menu(_, continuar) :-
    format('Opcao invalida.~n').

listar_contatos_menu :-
    listar_contatos_ordenados(Contatos),
    exibir_contatos(Contatos).

fluxo_cadastro_contato :-
    ler_texto_nao_vazio('Nome: ', Nome),
    ler_texto_nao_vazio('Telefone: ', Telefone),
    ler_texto_opcional('E-mail (opcional): ', Email),
    cadastrar_contato(Nome, Telefone, Email, [], Resultado),
    exibir_resultado(Resultado).

fluxo_edicao_contato :-
    ler_texto_nao_vazio('Telefone atual: ', TelefoneAtual),
    ler_texto_nao_vazio('Novo nome: ', Nome),
    ler_texto_nao_vazio('Novo telefone: ', Telefone),
    ler_texto_opcional('Novo e-mail (opcional): ', Email),
    editar_contato(TelefoneAtual, Nome, Telefone, Email, Resultado),
    exibir_resultado(Resultado).

fluxo_remocao_contato :-
    ler_inteiro('ID do contato: ', Id),
    confirmar('Confirmar remocao? (sim/nao): ', Confirmacao),
    ( Confirmacao == sim -> remover_contato(Id, Resultado), exibir_resultado(Resultado)
    ; format('Remocao cancelada.~n')
    ).

tratar_opcao_pesquisa("1", continuar_pesquisa) :-
    ler_texto_nao_vazio('Nome: ', Nome), buscar_por_nome(Nome, Contatos), exibir_contatos(Contatos).
tratar_opcao_pesquisa("2", continuar_pesquisa) :-
    ler_texto_nao_vazio('Telefone: ', Telefone), buscar_por_telefone(Telefone, Contatos), exibir_contatos(Contatos).
tratar_opcao_pesquisa("3", continuar_pesquisa) :-
    ler_inteiro('ID: ', Id),
    ( buscar_por_id(Id, Contato) -> exibir_contato(Contato) ; format('Contato nao encontrado.~n') ).
tratar_opcao_pesquisa("0", voltar).
tratar_opcao_pesquisa(_, continuar_pesquisa) :- format('Opcao invalida.~n').

tratar_opcao_grupos("1", continuar_grupos) :-
    listarGrupos(Grupos),
    exibir_grupos(Grupos).
tratar_opcao_grupos("2", continuar_grupos) :-
    ler_texto_nao_vazio('Telefone do contato: ', Telefone),
    ler_texto_nao_vazio('Nome do grupo: ', Nome),
    adicionarContatoEmGrupo(Nome, Telefone, Resultado),
    exibir_resultado(Resultado).
tratar_opcao_grupos("3", continuar_grupos) :-
    ler_texto_nao_vazio('Telefone do contato: ', Telefone),
    ler_texto_nao_vazio('Nome do grupo: ', Nome),
    removerContatoDeGrupo(Nome, Telefone, Resultado),
    exibir_resultado(Resultado).
tratar_opcao_grupos("0", voltar).
tratar_opcao_grupos(_, continuar_grupos) :- format('Opcao invalida.~n').

exibir_grupos([]) :- format('Nenhum grupo cadastrado.~n').
exibir_grupos([Grupo | Restante]) :-
    format('~w~n', [Grupo]),
    exibir_restante_grupos(Restante).

exibir_restante_grupos([]).
exibir_restante_grupos([Grupo | Restante]) :-
    format('~w~n', [Grupo]),
    exibir_restante_grupos(Restante).

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
    ler_texto_opcional('Escolha uma opcao: ', Opcao).
