:- dynamic grupo/2.

:- export(grupo/2).
:- export(limpar_grupos/0).
:- export(substituir_grupos/2).
:- export(snapshot_grupos/1).
:- export(inserir_grupo_db/2).
:- export(atualizar_grupo_db/3).
:- export(remover_grupo_db/2).

% Limpa todos os grupos da memória
limpar_grupos :-
    retractall(grupo(_, _)).

% Apaga todos os grupos e insere um novo conjunto de grupos
substituir_grupos(Grupos, ok) :-
    limpar_grupos,
    maplist(inserir_grupo_db, Grupos, _Resultados).

% Retorna uma lista com todos os grupos existente
snapshot_grupos(Grupos) :-
    findall(grupo(NomeGrupoId, IdsContatos),
            grupo(NomeGrupoId, IdsContatos),
            Grupos).

% Insere um novo grupo na memória
inserir_grupo_db(Grupo, ok) :-
    assertz(Grupo).

% Atualiza um grupo existente
atualizar_grupo_db(NomeGrupoId, NovoGrupo, ok) :-
    retractall(grupo(NomeGrupoId, _)),
    assertz(NovoGrupo).

% Remove um grupo buscando pelo seu NomeGrupoId
remover_grupo_db(NomeGrupoId, ok) :-
    retractall(grupo(NomeGrupoId, _)).
