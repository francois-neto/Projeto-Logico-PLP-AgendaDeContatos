:- use_module(library(plunit)).
:- use_module('../src/utils/validation.pl').

:- begin_tests(validation).

test(normalizar_texto_remove_espacos) :-
    normalizar_texto("  Ana Silva  ", "Ana Silva").

test(telefone_formatado) :- validar_telefone("(83) 99999-9999", ok).
test(telefone_invalido) :- validar_telefone("123", erro(telefone_invalido)).
test(email_com_arroba) :- validar_email("ana@exemplo", ok).
test(email_sem_arroba) :- validar_email("ana.exemplo", erro(email_invalido)).

:- end_tests(validation).
