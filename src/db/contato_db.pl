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
    limpar_contatos,
    maplist(inserir_contato_db, Contatos, _Resultados).

snapshot_contatos(Contatos) :-
    findall(contato(Id, Nome, Telefone, Email, Grupos),
            contato(Id, Nome, Telefone, Email, Grupos),
            Contatos).

inserir_contato_db(Contato, ok) :-
    assertz(Contato).

atualizar_contato_db(Id, NovoContato, ok) :-
    retractall(contato(Id, _, _, _, _)),
    assertz(NovoContato).

remover_contato_db(Id, ok) :-
    retractall(contato(Id, _, _, _, _)).
