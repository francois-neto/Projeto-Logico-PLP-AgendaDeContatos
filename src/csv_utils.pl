% Pessoa 1 - utilidades genéricas de leitura/escrita CSV, arquivos temporários e criação de diretórios.

ler_csv_seguro(Caminho, CabecalhoEsperado, Linhas, Resultado) :-
    ( exists_file(Caminho) ->
        open(Caminho, read, Stream),
        read_line_to_string(Stream, LinhaCabecalho),
        ( LinhaCabecalho = end_of_file ->
            close(Stream),
            Resultado = erro(arquivo_vazio(Caminho))
        ;
            ( LinhaCabecalho = CabecalhoEsperado ->
                ler_linhas_restantes(Stream, Linhas),
                close(Stream),
                Resultado = ok(Linhas)
            ;
                close(Stream),
                Resultado = erro(cabecalho_invalido(Caminho))
            )
        )
    ;
        Resultado = erro(arquivo_inexistente(Caminho))
    ).

ler_linhas_restantes(Stream, Linhas) :-
    read_line_to_string(Stream, Linha),
    ( Linha = end_of_file ->
        Linhas = []
    ;
        Linhas = [Linha | Resto],
        ler_linhas_restantes(Stream, Resto)
    ).

salvar_csv_atomico(Caminho, Linhas, TempPath, Resultado) :-
    criar_diretorio_seguro(Caminho, _),
    ( exists_file(TempPath) -> delete_file(TempPath) ; true ),
    open(TempPath, write, Stream),
    escrever_linhas(Stream, Linhas),
    close(Stream),
    rename_file(TempPath, Caminho),
    Resultado = ok.

escrever_linhas(_, []).
escrever_linhas(Stream, [Linha | Rest]) :-
    format(Stream, '~s~n', [Linha]),
    escrever_linhas(Stream, Rest).

validar_cabecalho(Caminho, CabecalhoEsperado, ok) :-
    exists_file(Caminho),
    open(Caminho, read, Stream),
    read_line_to_string(Stream, LinhaCabecalho),
    close(Stream),
    LinhaCabecalho = CabecalhoEsperado.

validar_cabecalho(Caminho, _, erro(cabecalho_invalido(Caminho))) :-
    exists_file(Caminho),
    open(Caminho, read, Stream),
    read_line_to_string(Stream, LinhaCabecalho),
    close(Stream),
    LinhaCabecalho \= _.

validar_cabecalho(Caminho, _, erro(arquivo_inexistente(Caminho))) :-
    \+ exists_file(Caminho).

criar_diretorio_seguro(Caminho, ok) :-
    file_directory_name(Caminho, Diretorio),
    ( Diretorio = '.' ->
        true
    ;
        ( exists_directory(Diretorio) ->
            true
        ;
            make_directory_path(Diretorio)
        )
    ).
