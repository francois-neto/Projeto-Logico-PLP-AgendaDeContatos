:- module(validation, [
    validar_usuario/2,
    validar_senha/3,
    validar_nome_contato/2,
    validar_telefone/2,
    validar_email/2,
    validar_grupo/2,
    normalizar_texto/2,
    validar_telefone_brasil/1,
    normalizar_telefone/2
]).

% Validações puras compartilhadas entre autenticação, contatos e interface.

normalizar_texto(Entrada, Normalizado) :-
    texto_para_string(Entrada, Texto),
    normalize_space(string(Normalizado), Texto).

validar_usuario(Usuario, ok) :-
    string(Usuario),
    string_length(Usuario, Tamanho),
    between(3, 30, Tamanho),
    string_codes(Usuario, Codigos),
    Codigos \= [],
    maplist(codigo_usuario_valido, Codigos),
    !.
validar_usuario(_, erro(usuario_invalido)).

validar_senha(Senha, Confirmacao, ok) :-
    string(Senha),
    Senha == Confirmacao,
    string_length(Senha, Tamanho),
    Tamanho >= 8,
    !.
validar_senha(Senha, Confirmacao, erro(confirmacao_senha_invalida)) :-
    Senha \== Confirmacao,
    !.
validar_senha(_, _, erro(senha_muito_curta)).

validar_nome_contato(Nome, ok) :-
    texto_csv_nao_vazio(Nome),
    !.
validar_nome_contato(_, erro(nome_contato_invalido)).

% A agenda trabalha com telefones brasileiros; formatações comuns são aceitas
% porque a validação considera apenas os dígitos.
validar_telefone(Telefone, ok) :-
    texto_csv_nao_vazio(Telefone),
    validar_telefone_brasil(Telefone),
    !.
validar_telefone(_, erro(telefone_invalido)).

validar_email(Email, ok) :-
    texto_para_string(Email, Texto),
    ( Texto == "" ; email_basico_valido(Texto) ),
    !.
validar_email(_, erro(email_invalido)).

validar_grupo(Grupo, ok) :-
    normalizar_texto(Grupo, Normalizado),
    Normalizado \== "",
    \+ sub_string(Normalizado, _, _, _, ","),
    \+ sub_string(Normalizado, _, _, _, "|"),
    !.
validar_grupo(_, erro(grupo_invalido)).

validar_telefone_brasil(TelefoneBruto) :-
    normalizar_telefone(TelefoneBruto, Telefone),
    ( telefone_de_servico_valido(Telefone)
    ; telefone_fixo_valido(Telefone)
    ; telefone_celular_valido(Telefone)
    ).

normalizar_telefone(TelefoneBruto, TelefoneNormalizado) :-
    texto_para_string(TelefoneBruto, Telefone),
    string_codes(Telefone, Codigos),
    include(codigo_digito, Codigos, Digitos),
    string_codes(TelefoneNormalizado, Digitos).

texto_csv_nao_vazio(Entrada) :-
    normalizar_texto(Entrada, Normalizado),
    Normalizado \== "",
    \+ sub_string(Normalizado, _, _, _, ",").

email_basico_valido(Email) :-
    \+ sub_string(Email, _, _, _, ","),
    split_string(Email, "@", "", [Local, Dominio]),
    Local \== "",
    Dominio \== "",
    sub_string(Dominio, _, _, _, ".").

telefone_de_servico_valido(Telefone) :-
    string_length(Telefone, 11),
    sub_string(Telefone, 0, 4, _, Prefixo),
    memberchk(Prefixo, ["0800", "0300", "0500", "1800", "1900", "4004", "4010",
                         "4020", "4040", "4050", "4060", "4070", "4080", "4090"]).

telefone_fixo_valido(Telefone) :-
    string_length(Telefone, 10),
    separar_ddd(Telefone, Ddd, Prefixo),
    ddd_valido(Ddd),
    sub_string(Prefixo, 0, 1, _, PrimeiroDigito),
    memberchk(PrimeiroDigito, ["2", "3", "4", "5"]).

telefone_celular_valido(Telefone) :-
    string_length(Telefone, 11),
    separar_ddd(Telefone, Ddd, Corpo),
    ddd_valido(Ddd),
    sub_string(Corpo, 0, 1, _, "9").

separar_ddd(Telefone, Ddd, Corpo) :-
    sub_string(Telefone, 0, 2, _, Ddd),
    sub_string(Telefone, 2, _, 0, Corpo).

ddd_valido(Ddd) :-
    memberchk(Ddd, ["11", "12", "13", "14", "15", "16", "17", "18", "19",
                    "21", "22", "24", "27", "28", "31", "32", "33", "34", "35",
                    "37", "38", "41", "42", "43", "44", "45", "46", "47", "48",
                    "49", "51", "53", "54", "55", "61", "62", "63", "64", "65",
                    "66", "67", "68", "69", "71", "73", "74", "75", "77", "79",
                    "81", "82", "83", "84", "85", "86", "87", "88", "89", "91",
                    "92", "93", "94", "95", "96", "97", "98", "99"]).

codigo_usuario_valido(Codigo) :- code_type(Codigo, alnum).
codigo_usuario_valido(0'_).
codigo_digito(Codigo) :- code_type(Codigo, digit).

texto_para_string(Texto, Texto) :- string(Texto), !.
texto_para_string(Atomo, Texto) :- atom(Atomo), !, atom_string(Atomo, Texto).
texto_para_string(Numero, Texto) :- number(Numero), !, number_string(Numero, Texto).
texto_para_string(_, "").
