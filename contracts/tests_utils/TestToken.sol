pragma solidity ^0.5.10;

import "../utils/SafeMath.sol";


/*  ERC 20 token */
contract StandardToken {
    using SafeMath for uint256;

    uint256 public totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender,  uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract TestToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event Destroy(address indexed from, uint256 amount);

    uint256 public constant PRICE = 4000;

    // metadata
    string public constant name = "Infinite Test Token";
    string public constant symbol = "TEST";
    uint8 public constant decimals = 18;
    string public version = "1.1";

    event CreatedToken(address _address);
    event SetBalance(address _address, uint256 _balance);

    constructor() public {
        emit CreatedToken(address(this));
    }

    function setBalance(address _address, uint256 _balance) external {
        uint256 prevBalance = balances[_address];
        emit SetBalance(_address, _balance);
        if (_balance > prevBalance) {
            // Mint tokens
            uint256 toAdd = _balance.sub(prevBalance);
            emit Transfer(address(0), _address, toAdd);
            emit Mint(_address, toAdd);
            totalSupply = totalSupply.add(toAdd);
            balances[_address] = prevBalance.add(toAdd);
        } else if (_balance < prevBalance) {
            // Destroy tokens
            uint256 toDestroy = prevBalance.sub(_balance);
            emit Transfer(_address, address(0), toDestroy);
            emit Destroy(_address, toDestroy);
            totalSupply = totalSupply.sub(toDestroy);
            balances[_address] = prevBalance.sub(toDestroy);
        }
    }
}