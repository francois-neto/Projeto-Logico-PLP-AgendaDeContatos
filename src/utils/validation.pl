:- module(validation, [
    validar_telefone_brasil/1,
    normalizar_telefone/2,
    validar_telefone/2
]).

% Valida telefones brasileiros com DDD, celulares, fixos e servicos.
validar_telefone_brasil(TelefoneBruto) :-
    normalizar_telefone(TelefoneBruto, Telefone),
    string_length(Telefone, Tamanho),
    ( Tamanho =:= 11,
      prefixo_de_servico(Telefone)
    ; Tamanho =:= 10,
      telefone_fixo_valido(Telefone)
    ; Tamanho =:= 11,
      telefone_celular_valido(Telefone)
    ).

% Interface de validacao usada pelo restante do projeto.
validar_telefone(Telefone, ok) :-
    validar_telefone_brasil(Telefone),
    !.
validar_telefone(_, erro("Telefone invalido para o padrao brasileiro.")).

% Mantem somente os digitos, assim como filter isDigit no Haskell.
normalizar_telefone(TelefoneBruto, TelefoneNormalizado) :-
    texto_para_string(TelefoneBruto, Telefone),
    string_codes(Telefone, Codigos),
    include(codigo_digito, Codigos, Digitos),
    string_codes(TelefoneNormalizado, Digitos).

prefixo_de_servico(Telefone) :-
    sub_string(Telefone, 0, 4, _, Prefixo),
    memberchk(Prefixo, [
        "0800", "0300", "0500", "1800", "1900",
        "4004", "4010", "4020", "4040", "4050",
        "4060", "4070", "4080", "4090"
    ]).

telefone_fixo_valido(Telefone) :-
    separar_ddd(Telefone, Ddd, Prefixo),
    ddd_valido(Ddd),
    string_length(Prefixo, 8),
    sub_string(Prefixo, 0, 1, _, PrimeiroDigito),
    memberchk(PrimeiroDigito, ["2", "3", "4", "5"]).

telefone_celular_valido(Telefone) :-
    separar_ddd(Telefone, Ddd, Corpo),
    ddd_valido(Ddd),
    string_length(Corpo, 9),
    sub_string(Corpo, 0, 1, _, "9").

separar_ddd(Telefone, Ddd, Corpo) :-
    sub_string(Telefone, 0, 2, _, Ddd),
    sub_string(Telefone, 2, _, 0, Corpo).

ddd_valido(Ddd) :-
    memberchk(Ddd, [
        "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "21", "22", "24", "27", "28",
        "31", "32", "33", "34", "35", "37", "38",
        "41", "42", "43", "44", "45", "46", "47", "48", "49",
        "51", "53", "54", "55",
        "61", "62", "63", "64", "65", "66", "67", "68", "69",
        "71", "73", "74", "75", "77", "79",
        "81", "82", "83", "84", "85", "86", "87", "88", "89",
        "91", "92", "93", "94", "95", "96", "97", "98", "99"
    ]).

codigo_digito(Codigo) :-
    code_type(Codigo, digit).

texto_para_string(Texto, Texto) :-
    string(Texto),
    !.
texto_para_string(Atomo, Texto) :-
    atom(Atomo),
    !,
    atom_string(Atomo, Texto).
texto_para_string(Numero, Texto) :-
    number(Numero),
    !,
    number_string(Numero, Texto).
texto_para_string(_, "").
