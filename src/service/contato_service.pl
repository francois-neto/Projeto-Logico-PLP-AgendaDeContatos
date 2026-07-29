:- module(contato_service, [
    proximo_id/1,
    adicionar_contato/5,
    cadastrar_contato/5,
    buscar_por_id/2,
    buscar_contato_por_telefone/2,
    buscar_por_nome/2,
    buscar_por_telefone/2,
    editar_contato/5,
    remover_contato/2,
    ordenar_por_nome/1,
    listar_contatos_ordenados/1
]).

:- use_module('../db/contato_db.pl').
:- use_module(library(lists), [max_list/2, predsort/3]).

% Retorna o proximo ID disponivel na base de contatos.
proximo_id(ProximoId) :-
    snapshot_contatos(Contatos),
    ( Contatos == [] ->
        ProximoId = 1
    ; maplist(id_do_contato, Contatos, Ids),
      max_list(Ids, MaiorId),
      ProximoId is MaiorId + 1
    ).

id_do_contato(contato(Id, _, _, _, _), Id).

% Adiciona um contato depois de validar nome e telefone.
adicionar_contato(NomeBruto, TelefoneBruto, EmailBruto, GruposBrutos, Resultado) :-
    texto_limpo(NomeBruto, Nome),
    texto_limpo(TelefoneBruto, Telefone),
    texto_limpo(EmailBruto, Email),
    ( Nome == "" ->
        Resultado = erro("Nome nao pode ser vazio.")
    ; Telefone == "" ->
        Resultado = erro("Telefone nao pode ser vazio.")
    ; \+ telefone_brasileiro_valido(Telefone) ->
        Resultado = erro("Telefone invalido para o padrao brasileiro.")
    ; proximo_id(Id),
      inserir_contato_db(contato(Id, Nome, Telefone, Email, GruposBrutos), Resultado)
    ).

% Nome utilizado pelo plano de implementacao do projeto.
cadastrar_contato(Nome, Telefone, Email, Grupos, Resultado) :-
    adicionar_contato(Nome, Telefone, Email, Grupos, Resultado).

% Busca exata pelo ID.
buscar_por_id(Id, Contato) :-
    contato(Id, Nome, Telefone, Email, Grupos),
    Contato = contato(Id, Nome, Telefone, Email, Grupos),
    !.

% Busca exata pelo telefone, desconsiderando espacos nas extremidades.
buscar_contato_por_telefone(TelefoneBruto, Contato) :-
    texto_limpo(TelefoneBruto, TelefoneBuscado),
    contato(Id, Nome, TelefoneAtual, Email, Grupos),
    texto_limpo(TelefoneAtual, TelefoneNormalizado),
    TelefoneNormalizado == TelefoneBuscado,
    Contato = contato(Id, Nome, TelefoneAtual, Email, Grupos),
    !.

% Retorna todos os contatos cujo nome contem a consulta, sem diferenciar caixa.
buscar_por_nome(ConsultaBruta, Contatos) :-
    normalizar_texto(ConsultaBruta, Consulta),
    findall(
        contato(Id, Nome, Telefone, Email, Grupos),
        ( contato(Id, Nome, Telefone, Email, Grupos),
          normalizar_texto(Nome, NomeNormalizado),
          sub_string(NomeNormalizado, _, _, _, Consulta)
        ),
        Contatos
    ).

% Retorna todos os contatos cujo telefone contem a consulta.
buscar_por_telefone(ConsultaBruta, Contatos) :-
    texto_limpo(ConsultaBruta, Consulta),
    findall(
        contato(Id, Nome, Telefone, Email, Grupos),
        ( contato(Id, Nome, Telefone, Email, Grupos),
          texto_limpo(Telefone, TelefoneNormalizado),
          sub_string(TelefoneNormalizado, _, _, _, Consulta)
        ),
        Contatos
    ).

% Edita nome, telefone e e-mail; os grupos atuais sao apenas preservados.
editar_contato(TelefoneAtual, NomeBruto, TelefoneBruto, EmailBruto, Resultado) :-
    ( buscar_contato_por_telefone(TelefoneAtual, contato(Id, _, _, _, Grupos)) ->
        texto_limpo(NomeBruto, Nome),
        texto_limpo(TelefoneBruto, NovoTelefone),
        texto_limpo(EmailBruto, Email),
        ( Nome == "" ->
            Resultado = erro("Nome nao pode ser vazio.")
        ; NovoTelefone == "" ->
            Resultado = erro("Telefone nao pode ser vazio.")
        ; \+ telefone_brasileiro_valido(NovoTelefone) ->
            Resultado = erro("Telefone invalido para o padrao brasileiro.")
        ; atualizar_contato_db(
              Id,
              contato(Id, Nome, NovoTelefone, Email, Grupos),
              Resultado
          )
        )
    ; Resultado = erro("Contato nao encontrado.")
    ).

% Remove um contato pelo ID.
remover_contato(Id, Resultado) :-
    ( buscar_por_id(Id, _) ->
        remover_contato_db(Id, Resultado)
    ; Resultado = erro("Contato nao encontrado.")
    ).

% Retorna os contatos ordenados alfabeticamente pelo nome, ignorando caixa.
ordenar_por_nome(ContatosOrdenados) :-
    snapshot_contatos(Contatos),
    predsort(comparar_contatos_por_nome, Contatos, ContatosOrdenados).

listar_contatos_ordenados(Contatos) :-
    ordenar_por_nome(Contatos).

comparar_contatos_por_nome(Ordem, contato(IdA, NomeA, _, _, _), contato(IdB, NomeB, _, _, _)) :-
    normalizar_texto(NomeA, NomeNormalizadoA),
    normalizar_texto(NomeB, NomeNormalizadoB),
    compare(OrdemNome, NomeNormalizadoA, NomeNormalizadoB),
    ( OrdemNome == (=) -> compare(Ordem, IdA, IdB) ; Ordem = OrdemNome ).

normalizar_texto(TextoBruto, Normalizado) :-
    texto_limpo(TextoBruto, Limpo),
    string_lower(Limpo, Normalizado).

texto_limpo(TextoBruto, Limpo) :-
    ( string(TextoBruto) -> Texto = TextoBruto
    ; atom(TextoBruto) -> atom_string(TextoBruto, Texto)
    ; number(TextoBruto) -> number_string(TextoBruto, Texto)
    ; Texto = ""
    ),
    string_codes(Texto, Codigos),
    remover_espacos_inicio(Codigos, SemEspacosInicio),
    reverse(SemEspacosInicio, Reverso),
    remover_espacos_inicio(Reverso, ReversoSemEspacos),
    reverse(ReversoSemEspacos, CodigosLimpos),
    string_codes(Limpo, CodigosLimpos).

remover_espacos_inicio([Codigo | Resto], Resultado) :-
    code_type(Codigo, space),
    !,
    remover_espacos_inicio(Resto, Resultado).
remover_espacos_inicio(Codigos, Codigos).

% Aceita celular (11 digitos) e telefone fixo (10 digitos), com ou sem
% pontuacao usual. O DDD e o primeiro digito nao podem ser zero.
telefone_brasileiro_valido(Telefone) :-
    string_codes(Telefone, Codigos),
    include(codigo_digito, Codigos, Digitos),
    maplist(codigo_telefone_permitido, Codigos),
    length(Digitos, Quantidade),
    memberchk(Quantidade, [10, 11]),
    Digitos = [DDD1, _, PrimeiroNumero | _],
    DDD1 =\= 0'0,
    PrimeiroNumero =\= 0'0.

codigo_digito(Codigo) :- code_type(Codigo, digit).

codigo_telefone_permitido(Codigo) :-
    ( code_type(Codigo, digit)
    ; memberchk(Codigo, [0' , 0'(, 0'), 0'-, 0'.])
    ).
