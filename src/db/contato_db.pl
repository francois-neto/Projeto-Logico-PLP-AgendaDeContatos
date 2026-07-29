% Pessoa 1 - base dinâmica de contatos e operações de armazenamento em memória.

:- dynamic contato/5.

:- export(contato/5).
:- export(limpar_contatos/0).
:- export(substituir_contatos/2).
:- export(snapshot_contatos/1).
:- export(inserir_contato_db/2).
:- export(atualizar_contato_db/3).
:- export(remover_contato_db/2).

limpar_contatos :-
    retractall(contato(_, _, _, _, _)).

substituir_contatos(Contatos, ok) :-
    ids_unicos(Contatos),
    limpar_contatos,
    maplist(inserir_contato_sem_validacao, Contatos).
substituir_contatos(Contatos, erro(id_duplicado(Id))) :-
    id_duplicado_na_lista(Contatos, Id).

snapshot_contatos(Contatos) :-
    findall(contato(Id, Nome, Telefone, Email, Grupos),
            contato(Id, Nome, Telefone, Email, Grupos),
            Contatos).

inserir_contato_db(Contato, ok) :-
    Contato = contato(Id, _, _, _, _),
    \+ contato(Id, _, _, _, _),
    assertz(Contato).
inserir_contato_db(Contato, erro(id_duplicado(Id))) :-
    Contato = contato(Id, _, _, _, _).

atualizar_contato_db(Id, NovoContato, ok) :-
    retract(contato(Id, _, _, _, _)),
    assertz(NovoContato).
atualizar_contato_db(Id, _, erro(id_inexistente(Id))).

remover_contato_db(Id, ok) :- retract(contato(Id, _, _, _, _)).
remover_contato_db(Id, erro(id_inexistente(Id))).

inserir_contato_sem_validacao(Contato) :- assertz(Contato).

ids_unicos(Contatos) :- \+ id_duplicado_na_lista(Contatos, _).
id_duplicado_na_lista(Contatos, Id) :-
    select(contato(Id, _, _, _, _), Contatos, Restante),
    member(contato(Id, _, _, _, _), Restante).
