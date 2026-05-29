// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract GovernX is ERC20, ERC20Permit, ERC20Votes {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Permit(_name) {
        address _deployer = msg.sender;
        uint256 _initialSupply = 1000000 * 10 ** 18;
        _mint(_deployer, _initialSupply);
    }

    function _update(address _from, address _to, uint256 _value) internal override(ERC20, ERC20Votes) {
        super._update(_from, _to, _value);
    }

    function nonces(address _owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(_owner);
    }

    function CLOCK_MODE() public view override(Votes) returns (string memory) {
        return super.CLOCK_MODE();
    }
}
