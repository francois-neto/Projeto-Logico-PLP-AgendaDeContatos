% Pessoa 1 - persistência de contatos em CSV individual por usuário.

:- use_module('../csv/csv_utils.pl').

carregar_contatos_csv(Caminho, Resultado) :-
    ( exists_file(Caminho) ->
        ler_csv_seguro(Caminho, "id,nome,telefone,email,grupos", Linhas, LerResultado),
        ( LerResultado = ok(Linhas) ->
            ( maplist(linha_para_contato, Linhas, Contatos) ->
                Resultado = ok(Contatos)
            ;
                Resultado = erro(csv_invalido(Caminho))
            )
        ; LerResultado = erro(Codigo) ->
            Resultado = erro(Codigo)
        )
    ;
        ( criar_csv_contatos_vazio(Caminho, ok) ->
            Resultado = ok([])
        ;
            Resultado = erro(nao_foi_possivel_criar_csv(Caminho))
        )
    ).

salvar_contatos_csv(Caminho, Contatos, Resultado) :-
    maplist(contato_para_linha, Contatos, Linhas),
    append([["id,nome,telefone,email,grupos"], Linhas], Conteudo),
    atomic_list_concat([Caminho, '.tmp'], TempPath),
    salvar_csv_atomico(Caminho, Conteudo, TempPath, Resultado).

linha_para_contato(Linha, contato(Id, Nome, Telefone, Email, Grupos)) :-
    split_string(Linha, ",", "", Campos),
    Campos = [IdTexto, Nome, Telefone, Email, GruposTexto],
    number_string(Id, IdTexto),
    desserializar_grupos(GruposTexto, Grupos).

contato_para_linha(contato(Id, Nome, Telefone, Email, Grupos), Linha) :-
    number_string(Id, IdTexto),
    serializar_grupos(Grupos, GruposTexto),
    atomic_list_concat([IdTexto, Nome, Telefone, Email, GruposTexto], ',', Linha).

serializar_grupos([], "").
serializar_grupos(Grupos, Texto) :-
    atomic_list_concat(Grupos, '|', Texto).

desserializar_grupos("", []).
desserializar_grupos(Texto, Grupos) :-
    split_string(Texto, "|", "", Grupos).

criar_csv_contatos_vazio(Caminho, Resultado) :-
    criar_diretorio_seguro(Caminho, _),
    atomic_list_concat([Caminho, '.tmp'], TempPath),
    salvar_csv_atomico(Caminho, ["id,nome,telefone,email,grupos"], TempPath, Resultado).
