:- consult('../csv/csv_utils.pl').

/**
 * Carrega os usuarios persistidos em um CSV de autenticacao.
 *
 * @param Caminho Caminho do arquivo `usuarios.csv`.
 * @param Resultado Termo com a lista de usuarios carregada.
 * @return `ok(Lista)` quando a leitura e valida ou `erro(Codigo)` em caso de falha.
 */
carregar_usuarios_csv(Caminho, Resultado) :-
    ( exists_file(Caminho) ->
        ler_csv_seguro(Caminho, "usuario,hash_senha", Linhas, ResultadoLeitura),
        tratar_leitura_usuarios(Linhas, ResultadoLeitura, Resultado)
    ;
        criar_arquivo_usuarios_vazio(Caminho, ResultadoCriacao),
        tratar_criacao_arquivo_usuarios(ResultadoCriacao, Resultado)
    ).

tratar_leitura_usuarios(Linhas, ok(Linhas), ok(Usuarios)) :-
    maplist(linha_para_usuario, Linhas, Usuarios),
    !.
tratar_leitura_usuarios(_, ok(_), erro(csv_usuarios_invalido)).
tratar_leitura_usuarios(_, erro(Codigo), erro(Codigo)).

tratar_criacao_arquivo_usuarios(ok, ok([])).
tratar_criacao_arquivo_usuarios(erro(Codigo), erro(Codigo)).

/**
 * Salva a colecao de usuarios em um CSV atomico.
 *
 * @param Caminho Caminho do arquivo `usuarios.csv`.
 * @param Usuarios Lista de termos `usuario/2`.
 * @param Resultado Termo de resultado do salvamento.
 * @return `ok` quando o arquivo e persistido ou `erro(Codigo)` em caso de falha.
 */
salvar_usuarios_csv(Caminho, Usuarios, Resultado) :-
    maplist(usuario_para_linha, Usuarios, LinhasUsuarios),
    Linhas = ["usuario,hash_senha" | LinhasUsuarios],
    atomic_list_concat([Caminho, '.tmp'], CaminhoTemporario),
    salvar_csv_atomico(Caminho, Linhas, CaminhoTemporario, Resultado).

/**
 * Converte uma linha textual do CSV para o termo logico de usuario.
 *
 * @param Linha String com o conteudo de uma linha do arquivo.
 * @param Usuario Termo `usuario/2` equivalente.
 * @return Verdadeiro quando a linha possui o formato esperado.
 */
linha_para_usuario(Linha, usuario(NomeUsuario, HashSenha)) :-
    split_string(Linha, ",", "", [NomeUsuario, HashSenha]).

/**
 * Converte um termo logico de usuario para a linha textual do CSV.
 *
 * @param Usuario Termo `usuario/2` a ser serializado.
 * @param Linha String que representa a linha persistivel.
 * @return Verdadeiro quando a serializacao e produzida.
 */
usuario_para_linha(usuario(NomeUsuario, HashSenha), Linha) :-
    atomic_list_concat([NomeUsuario, HashSenha], ',', Linha).

criar_arquivo_usuarios_vazio(Caminho, Resultado) :-
    atomic_list_concat([Caminho, '.tmp'], CaminhoTemporario),
    salvar_csv_atomico(Caminho, ["usuario,hash_senha"], CaminhoTemporario, Resultado).
