:- use_module(library(plunit)).
:- consult('../src/db/contato_db.pl').

:- begin_tests(contato_db).

test(inserir_e_snapshot, [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    inserir_contato_db(contato(1, 'Alice', '1111', 'alice@exemplo.com', ['amigos']), Resultado),
    assertion(Resultado == ok),
    snapshot_contatos(Contatos),
    assertion(Contatos == [contato(1, 'Alice', '1111', 'alice@exemplo.com', ['amigos'])]).

test(substituir_contatos, [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    substituir_contatos([
        contato(1, 'Alice', '1111', 'alice@exemplo.com', [])
    ], Resultado),
    assertion(Resultado == ok),
    snapshot_contatos(Contatos),
    assertion(Contatos == [contato(1, 'Alice', '1111', 'alice@exemplo.com', [])]).

test(atualizar_contato, [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    inserir_contato_db(contato(1, 'Alice', '1111', 'alice@exemplo.com', []), _),
    atualizar_contato_db(1, contato(1, 'Alice 2', '2222', 'alice2@exemplo.com', ['trabalho']), Resultado),
    assertion(Resultado == ok),
    snapshot_contatos(Contatos),
    assertion(Contatos == [contato(1, 'Alice 2', '2222', 'alice2@exemplo.com', ['trabalho'])]).

test(remover_contato, [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    inserir_contato_db(contato(1, 'Alice', '1111', 'alice@exemplo.com', []), _),
    remover_contato_db(1, Resultado),
    assertion(Resultado == ok),
    snapshot_contatos(Contatos),
    assertion(Contatos == []).

:- end_tests(contato_db).