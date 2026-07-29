:- module(grupo_service, [
    criarGrupo/2,
    apagarGrupo/2,
    editarNomeGrupo/3,
    adicionarContatoEmGrupo/3,
    removerContatoDeGrupo/3,
    listarContatosPorGrupo/2,
    listarContatosPorGrupos/2,
    buscarPorNomeOuTelefoneNosGrupos/3
]).

:- use_module('../db/grupo_db.pl').
:- use_module('contato_service.pl', [buscar_por_id/2]).
:- use_module(library(lists)).
:- use_module(library(apply)). % Necessário para o exclude/3

% Cria um novo grupo
criarGrupo(NomeBruto, Resultado) :-
    texto_limpo(NomeBruto, Nome),
    ( Nome == "" ->
        Resultado = erro("O nome do grupo nao pode ser vazio.")
    ; grupo(Nome, _) ->
        Resultado = erro("Ja existe um grupo com este nome.")
    ; inserir_grupo_db(grupo(Nome, []), Resultado)
    ).

% Apaga um grupo existente
apagarGrupo(NomeGrupo, Resultado) :-
    ( grupo(NomeGrupo, _) ->
        remover_grupo_db(NomeGrupo, Resultado)
    ; Resultado = erro("Grupo nao encontrado.")
    ).

% Edita o nome de um grupo
editarNomeGrupo(NomeAntigo, NomeNovoBruto, Resultado) :-
    texto_limpo(NomeNovoBruto, NomeNovo),
    ( NomeNovo == "" ->
        Resultado = erro("O novo nome do grupo nao pode ser vazio.")
    ; \+ grupo(NomeAntigo, _) ->
        Resultado = erro("Grupo antigo nao encontrado.")
    ; grupo(NomeNovo, _) ->
        Resultado = erro("Ja existe um grupo com este novo nome.")
    ; 
      grupo(NomeAntigo, Contatos),
      remover_grupo_db(NomeAntigo, _),
      inserir_grupo_db(grupo(NomeNovo, Contatos), Resultado)
    ).

% Adiciona um contato em um grupo
adicionarContatoEmGrupo(NomeGrupo, IdContato, Resultado) :-
    ( \+ grupo(NomeGrupo, _) ->
        Resultado = erro("Grupo nao encontrado.")
    ; \+ buscar_por_id(IdContato, _) ->
        Resultado = erro("Contato nao encontrado no sistema.")
    ; grupo(NomeGrupo, Contatos),
      ( member(IdContato, Contatos) ->
          Resultado = ok 
      ; append(Contatos, [IdContato], NovosContatos),
        atualizar_grupo_db(NomeGrupo, grupo(NomeGrupo, NovosContatos), Resultado)
      )
    ).


% Remove um contato de um grupo
removerContatoDeGrupo(NomeGrupo, IdContato, Resultado) :-
    ( \+ grupo(NomeGrupo, Contatos) ->
        Resultado = erro("Grupo nao encontrado.")
    ; ( select(IdContato, Contatos, NovosContatos) ->
          atualizar_grupo_db(NomeGrupo, grupo(NomeGrupo, NovosContatos), Resultado)
      ; Resultado = erro("O contato nao esta neste grupo.")
      )
    ).


% Lista todos os contatos de um grupo
listarContatosPorGrupo(NomeGrupo, ContatosDetalhados) :-
    ( grupo(NomeGrupo, IdsContatos) ->
        maplist(buscar_por_id_seguro, IdsContatos, ListaIncompleta),
        exclude(==(nulo), ListaIncompleta, ContatosDetalhados)
    ; ContatosDetalhados = []
    ).

buscar_por_id_seguro(Id, Contato) :-
    ( buscar_por_id(Id, C) -> Contato = C ; Contato = nulo ).

% Lista contatos de múltiplos grupos
listarContatosPorGrupos(ListaGrupos, ContatosUnicos) :-
    % Busca as listas de Ids para cada grupo fornecido
    findall(Ids, (member(G, ListaGrupos), grupo(G, Ids)), ListaDeListas),
    flatten(ListaDeListas, TodosIds), 
    list_to_set(TodosIds, IdsUnicos), 
    
    maplist(buscar_por_id_seguro, IdsUnicos, ListaIncompleta),
    exclude(==(nulo), ListaIncompleta, ContatosUnicos).

% Busca por Nome ou Telefone dentro de Grupos Específicos
buscarPorNomeOuTelefoneNosGrupos(TermoBusca, ListaGrupos, Resultados) :-
    listarContatosPorGrupos(ListaGrupos, ContatosDosGrupos),
    normalizar_texto(TermoBusca, BuscaNormalizada),
    findall(Contato,
        ( member(Contato, ContatosDosGrupos),
          Contato = contato(_, Nome, Telefone, _, _),
          normalizar_texto(Nome, NomeNorm),
          texto_limpo(Telefone, TelLimpo),
          ( sub_string(NomeNorm, _, _, _, BuscaNormalizada)
          ; sub_string(TelLimpo, _, _, _, BuscaNormalizada)
          )
        ),
        ResultadosBrutos
    ),
    list_to_set(ResultadosBrutos, Resultados).

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
