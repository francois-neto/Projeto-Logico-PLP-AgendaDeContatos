:- consult('integration_test.pl').
:- consult('csv_utils_test.pl').
:- consult('contato_db_test.pl').
:- consult('contato_repository_test.pl').

run_tests :-
    plunit:run_tests.
