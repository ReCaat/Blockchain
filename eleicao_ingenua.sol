// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Eleicao {

    // Controle para o andamento da eleição
    enum EstadoEleicao { NaoIniciada, EmAndamento, Encerrada }
    EstadoEleicao public estadoAtual;

    // Endereço do criador do contrato (admin)
    address public admin;

    // Struct que representa um eleitor
    struct Eleitor {
        bool votou;
        uint voto;
    }

    // Struct que representa cada candidato
    struct Candidato {
        uint id; // Id interno da blockchain
        string nome;
        string partido;
        uint numero; // Numero publico para votação
        uint votosRecebidos;
    }

    // Listas de candidatos e eleitores e mapeamento de numero para id
    mapping(uint => Candidato) public candidatos;
    mapping(address => Eleitor) public eleitores;
    mapping(uint => uint) public numero_id;

    uint public qtdCandidatos;
    uint public qtdEleitores;
    uint public votosNulos;

    constructor() {
        admin = msg.sender; // quem implantar o contrato vira admin
        qtdCandidatos = 0;
        votosNulos = 0;
        estadoAtual = EstadoEleicao.NaoIniciada;
    }



    // Modificadores de estado
    modifier somenteAdmin() {
        require(msg.sender == admin, "ERRO: Apenas o admin pode executar essa funcao");
        _;
    }
    
    modifier eleicaoNaoIniciada() {
        require(estadoAtual == EstadoEleicao.NaoIniciada, "ERRO: A eleicao ja foi iniciada ou encerrada.");
        _;
    }

    modifier eleicaoEmAndamento() {
        require(estadoAtual == EstadoEleicao.EmAndamento, "ERRO: A eleicao nao esta em andamento.");
        _;
    }

    modifier eleicaoEncerrada() {
        require(estadoAtual == EstadoEleicao.Encerrada, "ERRO: A eleicao nao foi encerrada.");
        _;
    }

    // Funções para modificar o estado da eleição
    function iniciarEleicao() public somenteAdmin eleicaoNaoIniciada {
        estadoAtual = EstadoEleicao.EmAndamento;
    }

    function encerrarEleicao() public somenteAdmin eleicaoEmAndamento {
        estadoAtual = EstadoEleicao.Encerrada;
    }



    // Cadastrar novo candidato
    function addCandidato(string memory _nome, string memory _partido, uint _numero) 
    public 
    somenteAdmin eleicaoNaoIniciada {
        require(_numero > 9, "ERRO: o numero do candidato nao pode ter um unico digito");
        require(numero_id[_numero] == 0, "ERRO: ja existe um candidato com esse numero");

        qtdCandidatos++;
        candidatos[qtdCandidatos] = Candidato({
            id: qtdCandidatos,
            nome: _nome,
            partido: _partido,
            numero: _numero,
            votosRecebidos: 0
        });
        numero_id[_numero] = qtdCandidatos; // Atualiza o mapeamento para id interno
    }

    // Função de votar
    function votar(uint _numero) 
    public 
    eleicaoEmAndamento {
        require(!eleitores[msg.sender].votou, "ERRO: Voce ja votou.");

        uint id = numero_id[_numero];
        if (id == 0)
            votosNulos++;
        else 
            candidatos[id].votosRecebidos++;
        

        eleitores[msg.sender].votou = true;
        eleitores[msg.sender].voto = _numero;
        
        qtdEleitores++;
    }

    // Retorna o nome do vencedor e porcentagem de votos
    function vencedor() 
    public view 
    eleicaoEncerrada 
    returns (string memory nomeVencedor, uint porcentagem) {
        require(qtdCandidatos > 0, "Nenhum candidato cadastrado.");
        require(qtdEleitores > 0, "Nenhum voto registrado");
        

        uint maiorVoto = 0;
        uint idCandidatoVencedor = 1; // Default para o primeiro se houver 0 votos

        // Encontra o candidato com mais votos
        for (uint i = 1; i <= qtdCandidatos; i++) {
            if (candidatos[i].votosRecebidos > maiorVoto) {
                maiorVoto = candidatos[i].votosRecebidos;
                idCandidatoVencedor = i;
            }
        }

        nomeVencedor = candidatos[idCandidatoVencedor].nome;
        porcentagem = (maiorVoto * 100) / qtdEleitores; // Cálculo da porcentagem sobre quem votou
    }
    
    function obterVotosNulos() 
    public view 
    returns (uint) {
        return votosNulos;
    }

    function obterCandidato(uint _numero) 
    public view 
    returns (string memory nome, string memory partido, uint numero, uint votos) {

        uint idInternoCandidato = numero_id[_numero];
        require(idInternoCandidato != 0, "Erro: nenhum canditado encontrado com esse numero.");
        Candidato storage c = candidatos[idInternoCandidato];
        return (c.nome, c.partido, c.numero, c.votosRecebidos);
    }

    function listarCandidatos() public view returns (string[] memory nomes, string[] memory partidos, uint[] memory numeros, uint[] memory votos) {

        nomes = new string[](qtdCandidatos);
        partidos = new string[](qtdCandidatos);
        numeros = new uint[](qtdCandidatos);
        votos = new uint[](qtdCandidatos);

        for (uint i = 1; i <= qtdCandidatos; i++) {
            nomes[i-1] = candidatos[i].nome;
            partidos[i-1] = candidatos[i].partido;
            numeros[i-1] = candidatos[i].numero;
            votos[i-1] = candidatos[i].votosRecebidos;
        }
        return (nomes, partidos, numeros, votos);
    }
}
