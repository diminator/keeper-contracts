pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
@title Ocean Protocol ERC20 Token Contract
@author Team: Fang Gong
*/

contract OceanToken is ERC20 {

    using SafeMath for uint256;

    // ============
    // DATA STRUCTURES:
    // ============
    string public constant name = 'OceanToken';                      // Set the token name for display
    string public constant symbol = 'OCN';                           // Set the token symbol for display

    // SUPPLY
    uint8 public constant decimals = 18;                             // Set the number of decimals for display
    uint256 public constant TOTAL_SUPPLY = 1400000000 * 10 ** 18;    // OceanToken total supply

    // EMIT TOKENS
    address public _receiver = address(0);                           // address to receive TOKENS
    uint256 public totalSupply;                                      // total supply of Ocean tokens including initial tokens plus block rewards

    /**
    * @dev OceanToken Constructor
    * Runs only on initial contract creation.
    */
    constructor() public {
        totalSupply = TOTAL_SUPPLY;
    }

    /**
    * @dev setReceiver set the address to receive the emitted tokens
    * @param _to The address to send tokens
    * @return success setting is successful.
    */
    function setReceiver(address _to) public returns (bool success){
        // make sure receiver is not set already
        require(_receiver == address(0), 'Receiver address already set.');
        // Creator address is assigned initial available tokens
        super._mint(_to, TOTAL_SUPPLY);
        // set receiver
        _receiver = _to;
        return true;
    }

    /**
    * @dev Transfer token for a specified address when not paused
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), 'To address is 0x0.');
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another when not paused
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), 'To address is 0x0.');
        return super.transferFrom(_from, _to, _value);
    }

}
