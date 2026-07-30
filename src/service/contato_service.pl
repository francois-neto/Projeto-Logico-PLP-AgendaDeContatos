:- consult('../db/contato_db.pl').
:- use_module('../utils/validation.pl', [
    validar_telefone/2,
    validar_email/2,
    normalizar_texto/2,
    normalizar_telefone/2
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
    normalizar_texto(NomeBruto, Nome),
    normalizar_texto(TelefoneBruto, Telefone),
    normalizar_texto(EmailBruto, Email),
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
    normalizar_telefone(TelefoneBruto, TelefoneBuscado),
    contato(Id, Nome, TelefoneAtual, Email, Grupos),
    normalizar_telefone(TelefoneAtual, TelefoneNormalizado),
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
    normalizar_telefone(ConsultaBruta, Consulta),
    findall(
        contato(Id, Nome, Telefone, Email, Grupos),
        ( contato(Id, Nome, Telefone, Email, Grupos),
          normalizar_telefone(Telefone, TelefoneNormalizado),
          sub_string(TelefoneNormalizado, _, _, _, Consulta)
        ),
        Contatos
    ).

% Edita nome, telefone e e-mail; os grupos atuais sao apenas preservados.
editar_contato(TelefoneAtual, NomeBruto, TelefoneBruto, EmailBruto, Resultado) :-
    ( buscar_contato_por_telefone(TelefoneAtual, contato(Id, _, _, _, Grupos)) ->
        normalizar_texto(NomeBruto, Nome),
        normalizar_texto(TelefoneBruto, NovoTelefone),
        normalizar_texto(EmailBruto, Email),
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
    normalizar_texto(TextoBruto, Limpo),
    string_lower(Limpo, Normalizado).

validar_campos_contato(_, Telefone, Email, _, ok) :-
    validar_telefone(Telefone, ok),
    validar_email(Email, ok),
    !.
validar_campos_contato(_, Telefone, _, _, erro(Codigo)) :-
    validar_telefone(Telefone, erro(Codigo)), !.
validar_campos_contato(_, _, Email, _, erro(Codigo)) :-
    validar_email(Email, erro(Codigo)).

