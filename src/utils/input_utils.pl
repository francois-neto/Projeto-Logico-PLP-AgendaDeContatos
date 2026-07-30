% Entrada e apresentação da interface de terminal.

ler_inteiro(Mensagem, Inteiro) :-
    ler_linha(Mensagem, Linha),
    ( catch(number_string(Inteiro, Linha), _, fail), integer(Inteiro) -> true
    ; format('Informe um numero inteiro valido.~n'), ler_inteiro(Mensagem, Inteiro)
    ).

ler_texto_nao_vazio(Mensagem, Texto) :-
    ler_linha(Mensagem, Linha),
    normalize_space(string(Texto), Linha),
    ( Texto \== "" -> true
    ; format('O texto nao pode ser vazio.~n'), ler_texto_nao_vazio(Mensagem, Texto)
    ).

ler_texto_opcional(Mensagem, Texto) :-
    ler_linha(Mensagem, Linha),
    normalize_space(string(Texto), Linha).

ler_senha(Mensagem, Senha) :-
    % read_line_to_string evita que a senha seja interpretada como termo Prolog.
    ler_linha(Mensagem, Senha).

confirmar(Mensagem, Confirmado) :-
    ler_linha(Mensagem, Linha),
    string_lower(Linha, Minusculo),
    normalize_space(string(Resposta), Minusculo),
    ( memberchk(Resposta, ["s", "sim"]) -> Confirmado = sim
    ; memberchk(Resposta, ["n", "nao", "não"]) -> Confirmado = nao
    ; format('Responda sim ou nao.~n'), confirmar(Mensagem, Confirmado)
    ).

exibir_contato(contato(Id, Nome, Telefone, Email, Grupos)) :-
    format('ID: ~w | Nome: ~w | Telefone: ~w | Email: ~w | Grupos: ~w~n',
           [Id, Nome, Telefone, Email, Grupos]).

exibir_contatos([]) :- format('Nenhum contato encontrado.~n').
exibir_contatos([Contato | Restante]) :- exibir_contato(Contato), exibir_contatos(Restante).

exibir_resultado(ok) :- format('Operacao realizada com sucesso.~n').
exibir_resultado(ok(Valor)) :- format('Operacao realizada: ~w~n', [Valor]).
exibir_resultado(erro(Codigo)) :- format('Falha na operacao: ~w~n', [Codigo]).

ler_linha(Mensagem, Linha) :-
    format('~w', [Mensagem]),
    read_line_to_string(user_input, Linha).

