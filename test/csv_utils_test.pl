:- use_module(library(plunit)).
:- use_module(library(filesex)).

:- consult('../src/csv/csv_utils.pl').

:- begin_tests(csv_utils).

test(validar_cabecalho_ok, [setup(setup_csv(Arquivo, 'id,nome\n1,Alice\n')), cleanup(cleanup_csv(Arquivo))]) :-
    validar_cabecalho(Arquivo, 'id,nome', Resultado),
    assertion(Resultado == ok).

test(validar_cabecalho_invalido, [setup(setup_csv(Arquivo, 'nome,id\n1,Alice\n')), cleanup(cleanup_csv(Arquivo))]) :-
    validar_cabecalho(Arquivo, 'id,nome', Resultado),
    assertion(Resultado == erro(cabecalho_invalido(Arquivo))).

test(ler_csv_seguro_ok, [setup(setup_csv(Arquivo, 'id,nome\n1,Alice\n2,Bob\n')), cleanup(cleanup_csv(Arquivo))]) :-
    ler_csv_seguro(Arquivo, 'id,nome', Linhas, Resultado),
    assertion(Resultado == ok(["1,Alice", "2,Bob"])),
    assertion(Linhas == ["1,Alice", "2,Bob"]).

test(salvar_csv_atomico_ok, [setup(setup_temp_dir(Dir, Arquivo, TempArquivo)), cleanup(cleanup_temp_dir(Dir, Arquivo, TempArquivo))]) :-
    salvar_csv_atomico(Arquivo, ["cabecalho", "linha1"], TempArquivo, Resultado),
    assertion(Resultado == ok),
    exists_file(Arquivo).

test(criar_diretorio_seguro_ok, [setup(setup_nested_path(Arquivo, Dir)), cleanup(cleanup_nested_dir(Dir, Arquivo))]) :-
    criar_diretorio_seguro(Arquivo, Resultado),
    assertion(Resultado == ok),
    exists_directory(Dir).

:- end_tests(csv_utils).

setup_csv(Arquivo, Conteudo) :-
    setup_temp_dir(_Dir, Arquivo, _TempArquivo),
    setup_call_cleanup(
        open(Arquivo, write, Stream),
        format(Stream, '~s', [Conteudo]),
        close(Stream)
    ).

setup_temp_dir(Dir, Arquivo, TempArquivo) :-
    tmp_dir_base(Base),
    get_time(Timestamp),
    format_time(atom(Suffix), '%Y%m%d%H%M%S%3f', Timestamp),
    atomic_list_concat([Base, '/csv_utils_', Suffix], Dir),
    make_directory_path(Dir),
    atomic_list_concat([Dir, '/dados.csv'], Arquivo),
    atomic_list_concat([Arquivo, '.tmp'], TempArquivo).

setup_nested_path(Arquivo, Dir) :-
    tmp_dir_base(Base),
    get_time(Timestamp),
    format_time(atom(Suffix), '%Y%m%d%H%M%S%3f', Timestamp),
    atomic_list_concat([Base, '/csv_utils_dir_', Suffix, '/sub'], Dir),
    atomic_list_concat([Dir, '/dados.csv'], Arquivo).

cleanup_csv(Arquivo) :-
    ( exists_file(Arquivo) -> delete_file(Arquivo) ; true ),
    file_directory_name(Arquivo, Dir),
    cleanup_directory(Dir).

cleanup_temp_dir(Dir, Arquivo, TempArquivo) :-
    ( exists_file(Arquivo) -> delete_file(Arquivo) ; true ),
    ( exists_file(TempArquivo) -> delete_file(TempArquivo) ; true ),
    cleanup_directory(Dir).

cleanup_nested_dir(Dir, Arquivo) :-
    ( exists_file(Arquivo) -> delete_file(Arquivo) ; true ),
    parent_directory(Dir, Root),
    cleanup_directory(Root).

cleanup_directory(Dir) :-
    ( exists_directory(Dir) -> delete_directory_and_contents(Dir) ; true ).

parent_directory(Dir, Root) :-
    file_directory_name(Dir, Parent),
    ( Parent = '.' -> Root = Dir ; parent_directory(Parent, Root) ).

tmp_dir_base(Base) :-
    tmp_file_stream(text, ArquivoTemporario, Stream),
    close(Stream),
    delete_file(ArquivoTemporario),
    file_directory_name(ArquivoTemporario, Base).
