:- consult('test/csv_utils_test.pl').
:- consult('test/contato_db_test.pl').
:- consult('test/contato_repository_test.pl').

run_tests :-
    plunit:run_tests.