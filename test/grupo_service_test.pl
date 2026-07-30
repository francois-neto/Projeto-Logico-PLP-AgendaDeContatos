:- use_module(library(plunit)).

:- consult('../src/db/contato_db.pl').
:- consult('../src/service/contato_service.pl').
:- use_module('../src/service/grupo_service.pl').

:- begin_tests(grupo_service).

test(adiciona_lista_e_remove_grupo,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("Ana", "83999999999", "ana@example.com", [], ok),
    adicionarContatoEmGrupo(" Familia ", "83999999999", ok),
    buscar_por_id(1, contato(1, "Ana", "83999999999", "ana@example.com", ["Familia"])),
    listarGrupos(["Familia"]),
    listarContatosPorGrupo("familia", [contato(1, "Ana", "83999999999", "ana@example.com", ["Familia"])]),
    removerContatoDeGrupo("FAMILIA", "83999999999", ok),
    listarGrupos([]).

test(grupo_equivalente_nao_duplica,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("Ana", "83999999999", "ana@example.com", [], ok),
    adicionarContatoEmGrupo("Familia", "83999999999", ok),
    adicionarContatoEmGrupo("  FAMILIA ", "83999999999", erro(grupo_duplicado("FAMILIA"))),
    buscar_por_id(1, contato(_, _, _, _, ["Familia"])).

test(listagem_e_busca_em_varios_grupos,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("Ana Silva", "83999999999", "ana@example.com", [], ok),
    cadastrar_contato("Bia Lima", "83988888888", "bia@example.com", [], ok),
    adicionarContatoEmGrupo("Familia", "83999999999", ok),
    adicionarContatoEmGrupo("Trabalho", "83999999999", ok),
    adicionarContatoEmGrupo("Trabalho", "83988888888", ok),
    listarContatosPorGrupos(["familia", "TRABALHO"], Contatos),
    Contatos = [contato(1, _, _, _, _), contato(2, _, _, _, _)],
    buscarPorNomeOuTelefoneNosGrupos("bia", ["trabalho"], [contato(2, "Bia Lima", _, _, _)]).

test(apagar_grupo_preserva_contato,
     [setup(limpar_contatos), cleanup(limpar_contatos)]) :-
    cadastrar_contato("Ana", "83999999999", "ana@example.com", ["Familia", "Favoritos"], ok),
    apagarGrupo("familia", ok),
    buscar_por_id(1, contato(1, "Ana", "83999999999", "ana@example.com", ["Favoritos"])),
    listarGrupos(["Favoritos"]).

:- end_tests(grupo_service).
