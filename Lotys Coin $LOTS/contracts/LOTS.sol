// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {address public myWallet = 0x5F83d6859eFA85Eec810A1f842ACE909659f029f;
    constructor() ERC20("Lotys Coin", "LOTS") {
            _mint(myWallet, 1000000000 * 10 ** 12);
    }
}
