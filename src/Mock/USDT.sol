pragma solidity 0.8.7;

import "solmate/tokens/ERC20.sol";

contract USDT is ERC20 {

    constructor(uint256 amount) ERC20("Tether USD","USDT" ,6){
        _mint(msg.sender, amount * 10 ** 6);
    }

}