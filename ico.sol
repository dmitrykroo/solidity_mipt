// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ICO is ERC20{
    address payable private _creator;

    uint private immutable _hardCap;
    uint private immutable _multiplier;
    uint private immutable _priceInWei;

    bool _mintActive;

    constructor(uint hardCap_, uint priceInWei_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _hardCap = hardCap_;
        _multiplier = 10 ** 18;
        _priceInWei = priceInWei_;
        _creator = payable(msg.sender);
        _mintActive = true;
    }

    function _cappedMint(address account, uint256 amount) internal {
        require(totalSupply() + amount <= _hardCap, "Hard cap reached");
        _mint(account, amount);
    }

    function buy() public payable {
        require(_mintActive, "ICO closed");
        uint token_amount = msg.value / _priceInWei * _multiplier;
        _cappedMint(msg.sender, token_amount);
        _creator.transfer(msg.value);
    }

    function stopMint() public {
        require(msg.sender == _creator);
        _mintActive = false;
    }
}
