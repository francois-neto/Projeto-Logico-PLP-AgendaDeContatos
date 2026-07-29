:- dynamic usuario/2.

/**
 * Remove todos os usuarios carregados em memoria.
 *
 * @param Nenhum Predicado sem parametros de entrada.
 * @return Verdadeiro quando a base dinamica e limpa.
 */
limpar_usuarios :-
    retractall(usuario(_, _)).

/**
 * Substitui o estado atual da base por uma nova colecao de usuarios.
 *
 * @param Usuarios Lista de termos `usuario/2`.
 * @param Resultado Termo de resultado da operacao.
 * @return `ok` quando a base e reconstruida.
 */
substituir_usuarios(Usuarios, ok) :-
    limpar_usuarios,
    maplist(inserir_usuario_sem_validacao, Usuarios).

/**
 * Captura uma copia em memoria dos usuarios carregados.
 *
 * @param Usuarios Variavel que recebe a lista de termos `usuario/2`.
 * @return Verdadeiro quando a lista e produzida.
 */
snapshot_usuarios(Usuarios) :-
    findall(usuario(NomeUsuario, HashSenha),
            usuario(NomeUsuario, HashSenha),
            Usuarios).

/**
 * Insere um novo usuario na base em memoria quando ele ainda nao existe.
 *
 * @param NomeUsuario Nome normalizado do usuario.
 * @param HashSenha Hash persistivel da senha.
 * @param Resultado Termo de resultado da insercao.
 * @return `ok` quando o usuario e inserido ou `erro(usuario_duplicado(NomeUsuario))`.
 */
inserir_usuario_db(NomeUsuario, HashSenha, ok) :-
    \+ usuario(NomeUsuario, _),
    assertz(usuario(NomeUsuario, HashSenha)).
inserir_usuario_db(NomeUsuario, _, erro(usuario_duplicado(NomeUsuario))).

/**
 * Busca o hash persistido de um usuario em memoria.
 *
 * @param NomeUsuario Nome normalizado do usuario.
 * @param HashSenha Variavel que recebe o hash encontrado.
 * @return Verdadeiro quando o usuario existe.
 */
buscar_usuario_db(NomeUsuario, HashSenha) :-
    usuario(NomeUsuario, HashSenha).

inserir_usuario_sem_validacao(usuario(NomeUsuario, HashSenha)) :-
    assertz(usuario(NomeUsuario, HashSenha)).
