:- use_module(library(plunit)).
:- use_module('../src/utils/validation.pl').

:- begin_tests(validation).

test(normalizar_texto_remove_espacos) :-
    normalizar_texto("  Ana Silva  ", "Ana Silva").

test(usuario_valido) :- validar_usuario("maria_2026", ok).
test(usuario_inseguro) :- validar_usuario("../admin", erro(usuario_invalido)).
test(senha_curta) :- validar_senha("curta", "curta", erro(senha_muito_curta)).
test(confirmacao_invalida) :- validar_senha("senha123", "senha321", erro(confirmacao_senha_invalida)).
test(telefone_formatado) :- validar_telefone("(83) 99999-9999", ok).
test(telefone_invalido) :- validar_telefone("123", erro(telefone_invalido)).
test(campos_csv_validos) :-
    validar_nome_contato("Ana Silva", ok),
    validar_email("ana@example.com", ok),
    validar_grupo("Familia", ok).

:- end_tests(validation).
