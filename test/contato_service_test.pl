:- use_module(library(plunit)).

:- consult('../src/db/contato_db.pl').
:- consult('../src/service/contato_service.pl').

:- begin_tests(contato_service).

test(crud_com_busca_por_telefone_normalizado,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("Ana Silva", "(83) 99999-9999", "ana@example.com", [], ok),
    buscar_por_telefone("839999", [contato(1, "Ana Silva", "(83) 99999-9999", "ana@example.com", [])]),
    editar_contato("83999999999", "Ana Souza", "(83) 98888-8888", "ana.souza@example.com", ok),
    buscar_por_id(1, contato(1, "Ana Souza", "(83) 98888-8888", "ana.souza@example.com", [])),
    remover_contato(1, ok),
    \+ buscar_por_id(1, _).

test(telefone_invalido_nao_altera_base,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("", "123", "email-invalido", [], erro(telefone_invalido)),
    snapshot_contatos([]).

test(id_duplicado_e_rejeitado,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    inserir_contato_db(contato(1, "Ana", "83999999999", "ana@example.com", []), ok),
    inserir_contato_db(contato(1, "Bia", "83988888888", "bia@example.com", []), erro(id_duplicado(1))).

:- end_tests(contato_service).
