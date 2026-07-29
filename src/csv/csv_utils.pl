% Pessoa 1 - utilidades genericas de leitura/escrita CSV, arquivos temporarios e criacao de diretorios.

ler_csv_seguro(Caminho, CabecalhoEsperado, Linhas, Resultado) :-
    ( exists_file(Caminho) ->
        open(Caminho, read, Stream),
        read_line_to_string(Stream, LinhaCabecalhoBruta),
        normalizar_linha_csv(LinhaCabecalhoBruta, LinhaCabecalho),
        normalizar_texto_csv(CabecalhoEsperado, CabecalhoNormalizado),
        ( LinhaCabecalho = end_of_file ->
            close(Stream),
            Resultado = erro(arquivo_vazio(Caminho))
        ;
            ( LinhaCabecalho = CabecalhoNormalizado ->
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
    read_line_to_string(Stream, LinhaBruta),
    normalizar_linha_csv(LinhaBruta, Linha),
    ( Linha = end_of_file ->
        Linhas = []
    ;
        Linhas = [Linha | Resto],
        ler_linhas_restantes(Stream, Resto)
    ).

salvar_csv_atomico(Caminho, Linhas, TempPath, Resultado) :-
    catch(salvar_csv_com_backup(Caminho, Linhas, TempPath), Erro,
          ( limpar_temporario(TempPath), Resultado = erro(falha_salvamento(Erro)) )),
    ( var(Resultado) -> Resultado = ok ; true ).

salvar_csv_com_backup(Caminho, Linhas, TempPath) :-
    criar_diretorio_seguro(Caminho, ok),
    limpar_temporario(TempPath),
    setup_call_cleanup(
        open(TempPath, write, Stream),
        escrever_linhas(Stream, Linhas),
        close(Stream)
    ),
    substituir_arquivo_preservando_backup(Caminho, TempPath).

substituir_arquivo_preservando_backup(Caminho, TempPath) :-
    atomic_list_concat([Caminho, '.backup'], BackupPath),
    limpar_temporario(BackupPath),
    ( exists_file(Caminho) -> rename_file(Caminho, BackupPath) ; true ),
    catch(rename_file(TempPath, Caminho), Erro,
          ( restaurar_backup(Caminho, BackupPath), throw(Erro) )),
    limpar_temporario(BackupPath).

restaurar_backup(Caminho, BackupPath) :-
    ( exists_file(BackupPath), \+ exists_file(Caminho) -> rename_file(BackupPath, Caminho) ; true ).

limpar_temporario(Caminho) :- ( exists_file(Caminho) -> delete_file(Caminho) ; true ).

escrever_linhas(_, []).
escrever_linhas(Stream, [Linha | Rest]) :-
    format(Stream, '~w~n', [Linha]),
    escrever_linhas(Stream, Rest).

validar_cabecalho(Caminho, CabecalhoEsperado, ok) :-
    ler_primeira_linha_csv(Caminho, LinhaCabecalho),
    normalizar_texto_csv(CabecalhoEsperado, CabecalhoNormalizado),
    LinhaCabecalho = CabecalhoNormalizado,
    !.
validar_cabecalho(Caminho, _, erro(cabecalho_invalido(Caminho))) :-
    exists_file(Caminho),
    !.
validar_cabecalho(Caminho, _, erro(arquivo_inexistente(Caminho))).

ler_primeira_linha_csv(Caminho, LinhaCabecalho) :-
    exists_file(Caminho),
    open(Caminho, read, Stream),
    read_line_to_string(Stream, LinhaBruta),
    close(Stream),
    normalizar_linha_csv(LinhaBruta, LinhaCabecalho).

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

normalizar_linha_csv(end_of_file, end_of_file).
normalizar_linha_csv(LinhaBruta, LinhaNormalizada) :-
    string_codes(LinhaBruta, CodigosBrutos),
    excluir_codigo_cr(CodigosBrutos, CodigosLimpos),
    string_codes(LinhaNormalizada, CodigosLimpos).

% Predicado interno: a normalização de entrada da aplicação pertence a
% utils/validation.pl e possui semântica diferente (remove espaços externos).
normalizar_texto_csv(Texto, StringNormalizada) :-
    string(Texto),
    !,
    StringNormalizada = Texto.
normalizar_texto_csv(Texto, StringNormalizada) :-
    atom(Texto),
    !,
    atom_string(Texto, StringNormalizada).
normalizar_texto_csv(Texto, StringNormalizada) :-
    term_string(Texto, StringNormalizada).

excluir_codigo_cr([], []).
excluir_codigo_cr([13 | Resto], Limpos) :-
    excluir_codigo_cr(Resto, Limpos).
excluir_codigo_cr([Codigo | Resto], [Codigo | Limpos]) :-
    Codigo =\= 13,
    excluir_codigo_cr(Resto, Limpos).
