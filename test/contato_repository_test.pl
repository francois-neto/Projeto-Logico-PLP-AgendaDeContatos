:- use_module(library(plunit)).
:- use_module(library(filesex)).

:- consult('../src/csv/csv_utils.pl').
:- consult('../src/repository/contato_repository.pl').

:- begin_tests(contato_repository).

test(carregar_csv_inexistente_cria_vazio, [setup(setup_temp_file(Arquivo, Dir)), cleanup(cleanup_temp_file(Arquivo, Dir))]) :-
    carregar_contatos_csv(Arquivo, Resultado),
    assertion(Resultado == ok([])),
    exists_file(Arquivo).

test(salvar_e_carregar_roundtrip, [setup(setup_temp_file(Arquivo, Dir)), cleanup(cleanup_temp_file(Arquivo, Dir))]) :-
    Contatos = [contato(1, 'Alice', '1111', 'alice@exemplo.com', ['amigos']), contato(2, 'Bob', '2222', 'bob@exemplo.com', [])],
    salvar_contatos_csv(Arquivo, Contatos, SalvarResultado),
    assertion(SalvarResultado == ok),
    carregar_contatos_csv(Arquivo, CarregarResultado),
    assertion(CarregarResultado == ok(Contatos)).

test(carregar_csv_com_cabecalho_invalido, [setup(setup_invalid_header(Arquivo, Dir)), cleanup(cleanup_temp_file(Arquivo, Dir))]) :-
    carregar_contatos_csv(Arquivo, Resultado),
    assertion(Resultado == erro(cabecalho_invalido(Arquivo))).

:- end_tests(contato_repository).

setup_temp_file(Arquivo, Dir) :-
    temp_dir(Dir),
    atomic_list_concat([Dir, '/contatos.csv'], Arquivo).

setup_invalid_header(Arquivo, Dir) :-
    setup_temp_file(Arquivo, Dir),
    setup_call_cleanup(
        open(Arquivo, write, Stream),
        format(Stream, 'nome,telefone~n1,Alice~n', []),
        close(Stream)
    ).

cleanup_temp_file(Arquivo, Dir) :-
    ( exists_file(Arquivo) -> delete_file(Arquivo) ; true ),
    ( exists_directory(Dir) -> delete_directory_and_contents(Dir) ; true ).

temp_dir(Dir) :-
    tmp_file_stream(text, ArquivoTemporario, Stream),
    close(Stream),
    delete_file(ArquivoTemporario),
    file_directory_name(ArquivoTemporario, Base),
    get_time(Timestamp),
    format_time(atom(Suffix), '%Y%m%d%H%M%S%3f', Timestamp),
    atomic_list_concat([Base, '/contato_repo_', Suffix], Dir),
    make_directory_path(Dir).