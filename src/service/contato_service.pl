:- consult('../db/contato_db.pl').
:- use_module('../utils/validation.pl', [
    validar_nome_contato/2,
    validar_telefone/2,
    validar_email/2,
    validar_grupo/2
]).
:- use_module(library(lists), [max_list/2]).

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
    validar_campos_contato(Nome, Telefone, Email, GruposBrutos, ResultadoValidacao),
    ( ResultadoValidacao = erro(_) ->
        Resultado = ResultadoValidacao
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

% Busca exata pelo telefone, desconsiderando espaços e formatação.
buscar_contato_por_telefone(TelefoneBruto, Contato) :-
    telefone_para_comparacao(TelefoneBruto, TelefoneBuscado),
    contato(Id, Nome, TelefoneAtual, Email, Grupos),
    telefone_para_comparacao(TelefoneAtual, TelefoneNormalizado),
    TelefoneNormalizado == TelefoneBuscado,
    Contato = contato(Id, Nome, TelefoneAtual, Email, Grupos),
    !.

% Retorna todos os contatos cujo nome contem a consulta, sem diferenciar caixa.
buscar_por_nome(ConsultaBruta, Contatos) :-
    normalizar_texto_contato(ConsultaBruta, Consulta),
    findall(
        contato(Id, Nome, Telefone, Email, Grupos),
        ( contato(Id, Nome, Telefone, Email, Grupos),
          normalizar_texto_contato(Nome, NomeNormalizado),
          sub_string(NomeNormalizado, _, _, _, Consulta)
        ),
        Contatos
    ).

% Retorna todos os contatos cujo telefone contem a consulta.
buscar_por_telefone(ConsultaBruta, Contatos) :-
    telefone_para_comparacao(ConsultaBruta, Consulta),
    findall(
        contato(Id, Nome, Telefone, Email, Grupos),
        ( contato(Id, Nome, Telefone, Email, Grupos),
          telefone_para_comparacao(Telefone, TelefoneNormalizado),
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
        validar_campos_contato(Nome, NovoTelefone, Email, Grupos, ResultadoValidacao),
        ( ResultadoValidacao = erro(_) ->
            Resultado = ResultadoValidacao
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
    normalizar_texto_contato(NomeA, NomeNormalizadoA),
    normalizar_texto_contato(NomeB, NomeNormalizadoB),
    compare(OrdemNome, NomeNormalizadoA, NomeNormalizadoB),
    ( OrdemNome == (=) -> compare(Ordem, IdA, IdB) ; Ordem = OrdemNome ).

normalizar_texto_contato(TextoBruto, Normalizado) :-
    texto_limpo(TextoBruto, Limpo),
    string_lower(Limpo, Normalizado).

telefone_para_comparacao(TelefoneBruto, Normalizado) :-
    texto_limpo(TelefoneBruto, Texto),
    string_codes(Texto, Codigos),
    include(codigo_digito, Codigos, Digitos),
    string_codes(Normalizado, Digitos).

codigo_digito(Codigo) :- code_type(Codigo, digit).

validar_campos_contato(Nome, Telefone, Email, Grupos, ok) :-
    validar_nome_contato(Nome, ok),
    validar_telefone(Telefone, ok),
    validar_email(Email, ok),
    grupos_validos(Grupos),
    !.
validar_campos_contato(Nome, _, _, _, erro(Codigo)) :-
    validar_nome_contato(Nome, erro(Codigo)), !.
validar_campos_contato(_, Telefone, _, _, erro(Codigo)) :-
    validar_telefone(Telefone, erro(Codigo)), !.
validar_campos_contato(_, _, Email, _, erro(Codigo)) :-
    validar_email(Email, erro(Codigo)), !.
validar_campos_contato(_, _, _, _, erro(grupo_invalido)).

grupos_validos(Grupos) :-
    is_list(Grupos),
    maplist(grupo_valido, Grupos).

grupo_valido(Grupo) :- validar_grupo(Grupo, ok).

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
