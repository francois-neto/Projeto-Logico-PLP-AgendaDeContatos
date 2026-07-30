:- module(grupo_repository, [
    grupo/2,
    listar_grupos_derivados/1,
    ids_por_grupo/2,
    chave_grupo/2
]).

:- use_module('../utils/validation.pl', [normalizar_texto/2]).

% A relacao de grupos e uma visao dos grupos armazenados em contato/5.
% Nomes que diferem apenas por caixa ou espacos representam o mesmo grupo.
grupo(Nome, Ids) :-
    grupos_com_chaves(Grupos),
    member(Chave-Nome, Grupos),
    findall(Id,
            ( user:contato(Id, _, _, _, GruposDoContato),
              member(GrupoDoContato, GruposDoContato),
              chave_grupo(GrupoDoContato, Chave)
            ),
            Ids).

listar_grupos_derivados(Grupos) :-
    findall(Nome, grupo(Nome, _), Grupos).

ids_por_grupo(NomeBuscado, Ids) :-
    chave_grupo(NomeBuscado, Chave),
    ( grupo_por_chave(Chave, _, Ids) -> true ; Ids = [] ).

grupo_por_chave(Chave, Nome, Ids) :-
    grupos_com_chaves(Grupos),
    member(Chave-Nome, Grupos),
    findall(Id,
            ( user:contato(Id, _, _, _, GruposDoContato),
              member(GrupoDoContato, GruposDoContato),
              chave_grupo(GrupoDoContato, Chave)
            ),
            Ids).

grupos_com_chaves(Grupos) :-
    findall(Chave-Nome,
            ( user:contato(_, _, _, _, GruposDoContato),
              member(Nome, GruposDoContato),
              chave_grupo(Nome, Chave)
            ),
            Pares),
    pares_unicos_por_chave(Pares, Grupos).

pares_unicos_por_chave([], []).
pares_unicos_por_chave([Chave-Nome | Restante], [Chave-Nome | Unicos]) :-
    excluir_chave(Chave, Restante, SemEquivalentes),
    pares_unicos_por_chave(SemEquivalentes, Unicos).

excluir_chave(_, [], []).
excluir_chave(Chave, [Chave-_ | Restante], SemEquivalentes) :-
    !,
    excluir_chave(Chave, Restante, SemEquivalentes).
excluir_chave(Chave, [Par | Restante], [Par | SemEquivalentes]) :-
    excluir_chave(Chave, Restante, SemEquivalentes).

chave_grupo(GrupoBruto, Chave) :-
    normalizar_texto(GrupoBruto, Limpo),
    string_lower(Limpo, Chave).
