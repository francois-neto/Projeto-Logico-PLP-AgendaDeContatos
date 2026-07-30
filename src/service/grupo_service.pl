:- module(grupo_service, [
    apagarGrupo/2,
    adicionarContatoEmGrupo/3,
    removerContatoDeGrupo/3,
    listarGrupos/1,
    listarContatosPorGrupo/2,
    listarContatosPorGrupos/2,
    buscarPorNomeOuTelefoneNosGrupos/3
]).

:- use_module('../repository/grupo_repository.pl', [chave_grupo/2]).
:- use_module('../utils/validation.pl', [normalizar_texto/2]).
:- use_module(library(lists)).

apagarGrupo(NomeBruto, Resultado) :-
    ( grupo_existente(NomeBruto, Chave) ->
        findall(Id, (user:contato(Id, _, _, _, Grupos), possui_chave(Grupos, Chave)), Ids),
        remover_grupo_dos_contatos(Ids, Chave),
        Resultado = ok
    ; Resultado = erro(grupo_inexistente)
    ).

adicionarContatoEmGrupo(NomeBruto, TelefoneBruto, Resultado) :-
    ( normalizar_nome_grupo(NomeBruto, Nome) ->
        ( user:buscar_contato_por_telefone(TelefoneBruto, contato(Id, NomeContato, Telefone, Email, Grupos)) ->
          chave_grupo(Nome, Chave),
          ( possui_chave(Grupos, Chave) -> Resultado = erro(grupo_duplicado(Nome))
          ; append(Grupos, [Nome], NovosGrupos),
            user:atualizar_contato_db(Id, contato(Id, NomeContato, Telefone, Email, NovosGrupos), Resultado)
          )
        ; Resultado = erro(contato_inexistente)
        )
    ).

removerContatoDeGrupo(NomeBruto, TelefoneBruto, Resultado) :-
    ( user:buscar_contato_por_telefone(TelefoneBruto, contato(Id, NomeContato, Telefone, Email, Grupos)) ->
      ( \+ grupo_existente(NomeBruto, _) -> Resultado = erro(grupo_inexistente)
      ; chave_grupo(NomeBruto, Chave),
      ( remover_chave(Chave, Grupos, NovosGrupos) ->
          user:atualizar_contato_db(Id, contato(Id, NomeContato, Telefone, Email, NovosGrupos), Resultado)
      ; Resultado = erro(contato_nao_pertence_ao_grupo)
      )
      )
    ; Resultado = erro(contato_inexistente)
    ).

listarGrupos(Grupos) :- grupo_repository:listar_grupos_derivados(Grupos).

listarContatosPorGrupo(Nome, Contatos) :-
    grupo_repository:ids_por_grupo(Nome, Ids),
    contatos_por_ids(Ids, Contatos).

listarContatosPorGrupos(Nomes, Contatos) :-
    findall(Id,
            ( member(Nome, Nomes),
              grupo_repository:ids_por_grupo(Nome, IdsDoGrupo),
              member(Id, IdsDoGrupo)
            ),
            IdsRepetidos),
    list_to_set(IdsRepetidos, Ids),
    contatos_por_ids(Ids, Contatos).

buscarPorNomeOuTelefoneNosGrupos(TermoBruto, Nomes, Resultados) :-
    chave_grupo(TermoBruto, Termo),
    listarContatosPorGrupos(Nomes, Contatos),
    include(corresponde_ao_termo(Termo), Contatos, Resultados).

corresponde_ao_termo(Termo, contato(_, Nome, Telefone, _, _)) :-
    chave_grupo(Nome, NomeNormalizado),
    normalizar_texto(Telefone, TelefoneNormalizado),
    ( sub_string(NomeNormalizado, _, _, _, Termo)
    ; sub_string(TelefoneNormalizado, _, _, _, Termo)
    ).

normalizar_nome_grupo(NomeBruto, Nome) :-
    normalizar_texto(NomeBruto, Nome).

grupo_existente(Nome, Chave) :-
    chave_grupo(Nome, Chave),
    grupo_repository:grupo(NomeExistente, _),
    chave_grupo(NomeExistente, Chave),
    !.

possui_chave(Grupos, Chave) :- member(Grupo, Grupos), chave_grupo(Grupo, Chave), !.

remover_chave(Chave, Grupos, Restantes) :-
    select(Grupo, Grupos, Restantes), chave_grupo(Grupo, Chave), !.

contatos_por_ids([], []).
contatos_por_ids([Id | Ids], [Contato | Contatos]) :-
    user:contato(Id, Nome, Telefone, Email, Grupos),
    Contato = contato(Id, Nome, Telefone, Email, Grupos),
    contatos_por_ids(Ids, Contatos).

remover_grupo_dos_contatos([], _).
remover_grupo_dos_contatos([Id | Ids], Chave) :-
    user:contato(Id, Nome, Telefone, Email, Grupos),
    remover_chave(Chave, Grupos, NovosGrupos),
    user:atualizar_contato_db(Id, contato(Id, Nome, Telefone, Email, NovosGrupos), ok),
    remover_grupo_dos_contatos(Ids, Chave).
