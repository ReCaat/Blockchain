// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Eleicao2 {

    // Controle para o andamento da eleição
    enum EstadoEleicao { NaoIniciada, EmAndamento, Encerrada }
    EstadoEleicao public estadoAtual;

    // Endereço do criador do contrato (admin)
    address public admin;

    // Struct que representa um eleitor
    struct Eleitor {
        bool autorizado; // Agora, para votar precisa ser autorizado pelo admin
        bool votou;      
        // Não guarda mais o campo de quem ele votou
    }

    
    // Struct que representa cada proposta
    struct Proposta {
        uint id; // Id interno da blockchain
        string proposta;
        string descricao;
        uint numero; // Numero publico para votação
        uint votosRecebidos;
    }

    // Listas de propostas e eleitores e mapeamento de numero para id
    mapping(uint => Proposta) public propostas;
    mapping(address => Eleitor) public eleitores;
    mapping(uint => uint) public numero_id; 

    uint public qtdPropostas;
    uint public qtdEleitores; 
    uint public votosNulos;

    // Variavies para aumentar a escalabilidade já que reduzem os propostas maximos
    uint public idVencedorAtual;
    uint public votosVencedorAtual;
    bool public existeEmpate; // Flag para indicar se há mais de um com a mesma quantia máxima

    constructor() {
        admin = msg.sender; // quem implantar o contrato vira admin
        qtdPropostas = 0;
        votosNulos = 0;
        votosVencedorAtual = 0;
        estadoAtual = EstadoEleicao.NaoIniciada;
    }

    // Modificadores de estado
    modifier somenteAdmin() {
        require(msg.sender == admin, "ERRO: Apenas o admin pode executar essa funcao");
        _;
    }

    modifier apenasAutorizado() { //Controle para autorização de eleitores 
        require(eleitores[msg.sender].autorizado, "ERRO: Voce nao tem permissao para votar.");
        _;
    }

    modifier eleicaoNaoIniciada() {
        require(estadoAtual == EstadoEleicao.NaoIniciada, "ERRO: A eleicao nao permite alteracoes agora.");
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

    function autorizarEleitor(address _eleitor) public somenteAdmin eleicaoNaoIniciada {
        require(!eleitores[_eleitor].autorizado, "Eleitor ja autorizado.");
        eleitores[_eleitor].autorizado = true;
        eleitores[_eleitor].votou = false;
    }



    // Cadastrar nova proposta
    function addProposta(string memory _proposta, string memory _descricao, uint _numero) 
    public 
    somenteAdmin eleicaoNaoIniciada {
        require(_numero > 9, "ERRO: numero deve ter 2 digitos ou mais");
        require(numero_id[_numero] == 0, "ERRO: numero ja cadastrado");

        qtdPropostas++;
        propostas[qtdPropostas] = Proposta({
            id: qtdPropostas,
            proposta: _proposta,
            descricao: _descricao,
            numero: _numero,
            votosRecebidos: 0
        });
        numero_id[_numero] = qtdPropostas;
    }

    // Função de votar
    function votar(uint _numero) 
    public 
    eleicaoEmAndamento 
    apenasAutorizado {
        require(!eleitores[msg.sender].votou, "ERRO: Voce ja votou.");

        uint id = numero_id[_numero];
        
        if (id == 0) {
            votosNulos++;
        } else {
            propostas[id].votosRecebidos++;
            uint novosVotos = propostas[id].votosRecebidos;

            // Lógica de Atualização do Vencedor (O(1))
            if (novosVotos > votosVencedorAtual) {
                // Temos um novo líder isolado
                votosVencedorAtual = novosVotos;
                idVencedorAtual = id;
                existeEmpate = false;
            } else if (novosVotos == votosVencedorAtual) {
                //detecta se tem um empate mas apenas mantem um dos líderes
                existeEmpate = true;
            }
        }

        eleitores[msg.sender].votou = true;
        qtdEleitores++;
    }

    // Retorna o proposta do vencedor e porcentagem de votos
    function vencedor() 
    public view 
    eleicaoEncerrada 
    returns (string memory status, string memory propostaLider, uint votos, uint porcentagem) {
        require(qtdPropostas > 0, "Nenhum proposta cadastrado.");
        require(qtdEleitores > 0, "Nenhum voto registrado");
        

        // Se o maior número de votos for zero (só houve nulos) ou se o ID for 0
        if (votosVencedorAtual == 0)
            return ("Vencedor: Nulos", "Nulos", votosNulos, (votosNulos * 100) / qtdEleitores);
        

        uint _porcentagem = (votosVencedorAtual * 100) / qtdEleitores;

        if (existeEmpate)
            // Retorna o proposta de um dos líderes, mas avisa que há empate
            return ("EMPATE DETECTADO", propostas[idVencedorAtual].proposta, votosVencedorAtual, _porcentagem);
        else 
            return ("Vencedor Definido", propostas[idVencedorAtual].proposta, votosVencedorAtual, _porcentagem);
        
    }

    function obterVotosNulos() 
    public view 
    returns (uint) {
        return votosNulos;
    }

    function obterProposta(uint _numero) 
    public view 
    returns (string memory proposta, string memory descricao, uint numero, uint votos) {

        uint idInternoProposta = numero_id[_numero];
        require(idInternoProposta != 0, "Erro: nenhum canditado encontrado com esse numero.");
        Proposta storage c = propostas[idInternoProposta];
        
        return (c.proposta, c.descricao, c.numero, c.votosRecebidos);
    }

    function listarPropostas() public view returns (string[] memory propostas, string[] memory descricaos, uint[] memory numeros, uint[] memory votos) {

        propostas = new string[](qtdPropostas);
        descricaos = new string[](qtdPropostas);
        numeros = new uint[](qtdPropostas);
        votos = new uint[](qtdPropostas);

        for (uint i = 1; i <= qtdPropostas; i++) {
            propostas[i-1] = propostas[i].proposta;
            descricaos[i-1] = propostas[i].descricao;
            numeros[i-1] = propostas[i].numero;
            votos[i-1] = propostas[i].votosRecebidos;
        }
        return (propostas, descricaos, numeros, votos);
    }
}