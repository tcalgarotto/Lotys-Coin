// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Importando a interface do token BEP-20
import "./IERC20.sol";

// Definindo o contrato da loteria
contract Loteria {
    // Definindo as variáveis de estado
    address public owner; // O endereço do dono do contrato
    uint256 public premio; // O valor do prêmio em tokens
    IERC20 public token; // O token usado para participar da loteria
    uint256 public preco; // O preço de cada número da loteria em tokens
    uint256 public total; // O total de tokens arrecadados na loteria
    uint256 public sorteado; // O número sorteado na última rodada
    bool public aberta; // O status da loteria (aberta ou fechada)
    
    // Definindo as estruturas de dados
    mapping(address => uint256[]) public numeros; // Um mapeamento de endereços para os números que eles compraram
    mapping(uint256 => address[]) public apostadores; // Um mapeamento de números para os endereços que os compraram
    
    // Definindo os eventos
    event Compra(address indexed comprador, uint256[] numeros); // Um evento que é emitido quando alguém compra números
    event Sorteio(address indexed vencedor, uint256 premio, uint256 sorteado); // Um evento que é emitido quando o dono sorteia um número
    event Retirada(address indexed retirante, uint256 valor); // Um evento que é emitido quando alguém retira tokens do contrato
    
    // Definindo o modificador onlyOwner, que restringe o acesso a certas funções apenas ao dono do contrato
    modifier onlyOwner {
        require(msg.sender == owner, "Somente o dono pode chamar essa funcao");
        _;
    }
    
    // Definindo o construtor do contrato, que recebe o endereço do token e o preço de cada número
    constructor(address _token, uint256 _preco) {
        owner = msg.sender; // Define o dono do contrato como o criador do contrato
        token = IERC20(_token); // Define o token usado na loteria como o token passado como argumento
        preco = _preco; // Define o preço de cada número como o preço passado como argumento
        aberta = true; // Define o status da loteria como aberta
    }
    
    // Definindo a função comprar, que permite que alguém compre números da loteria usando tokens
    function comprar(uint256[] memory _numeros) public {
        require(aberta, "A loteria esta fechada"); // Verifica se a loteria está aberta
        require(_numeros.length > 0, "Voce deve comprar pelo menos um numero"); // Verifica se o comprador está comprando pelo menos um número
        uint256 valor = _numeros.length * preco; // Calcula o valor total da compra em tokens
        require(token.transferFrom(msg.sender, address(this), valor), "Transferencia de tokens falhou"); // Transfere os tokens do comprador para o contrato e verifica se a transferência foi bem sucedida
        total += valor; // Atualiza o total de tokens arrecadados na loteria
        for (uint256 i = 0; i < _numeros.length; i++) { // Para cada número comprado pelo comprador
            numeros[msg.sender].push(_numeros[i]); // Adiciona o número ao array de números do comprador
            apostadores[_numeros[i]].push(msg.sender); // Adiciona o endereço do comprador ao array de apostadores do número
        }
        emit Compra(msg.sender, _numeros); // Emite o evento Compra com os dados da compra
    }
    
    // Definindo a função sortear, que permite que o dono do contrato sorteie um número e distribua o prêmio ao vencedor
    function sortear() public onlyOwner {
        require(aberta, "A loteria esta fechada"); // Verifica se a loteria está aberta
        require(total > 0, "A loteria nao tem fundos"); // Verifica se a loteria tem fundos suficientes para distribuir o prêmio
        aberta = false; // Define o status da loteria como fechada
        sorteado = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number))) % 100 + 1; // Gera um número aleatório entre 1 e 100 usando o hash do bloco atual
        address[] memory vencedores = apostadores[sorteado]; // Obtém o array de endereços que compraram o número sorteado
        if (vencedores.length > 0) { // Se houver pelo menos um vencedor
            uint256 premio = (total * 95) / 100; // Calcula o valor do prêmio como 95% do total de tokens arrecadados
            uint256 valor = premio / vencedores.length; // Calcula o valor que cada vencedor receberá
            for (uint256 i = 0; i < vencedores.length; i++) { // Para cada vencedor
                token.transfer(vencedores[i], valor); // Transfere os tokens do prêmio para o vencedor
                emit Retirada(vencedores[i], valor); // Emite o evento Retirada com os dados da transferência
            }
            emit Sorteio(vencedores[0], premio, sorteado); // Emite o evento Sorteio com os dados do sorteio e do primeiro vencedor
        } else { // Se não houver nenhum vencedor
            emit Sorteio(address(0), 0, sorteado); // Emite o evento Sorteio com os dados do sorteio e sem vencedor
        }
        uint256 taxa = total - premio; // Calcula o valor da taxa como 5% do total de tokens arrecadados
        token.transfer(owner, taxa); // Transfere os tokens da taxa para o dono do contrato
        emit Retirada(owner, taxa); // Emite o evento Retirada com os dados da transferência
        total = 0; // Zera o total de tokens arrecadados na loteria
    }
    
    // Definindo a função reabrir, que permite que o dono do contrato reabra a loteria para uma nova rodada
    function reabrir() public onlyOwner {
        require(!aberta, "A loteria ja esta aberta"); // Verifica se a loteria está fechada
        aberta = true; // Define o status da loteria como aberta
    }
}
