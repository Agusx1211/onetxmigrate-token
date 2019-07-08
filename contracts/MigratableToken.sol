pragma solidity ^0.5.8;

import "./interfaces/IERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/IsContract.sol";
import "./TokenReceiver.sol";


contract MigratableToken is IERC20 {
    using IsContract for address;
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    IERC20 public originalToken;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(IERC20 _token) public {
        originalToken = _token;
    }

    // ///
    // Migration
    // ///

    function migrationAddress(address _addr) public view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        bytes32(uint256(_addr)),
                        keccak256(type(TokenReceiver).creationCode)
                    )
                )
            )
        );
    }

    function deploy(address _addr) internal {
        bytes memory slotcode = type(TokenReceiver).creationCode;
        bytes32 key = bytes32(uint256(_addr));
        assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), key)) }
    }

    function migrate(address _addr) public {
        address receiver = migrationAddress(_addr);
        uint256 pending = originalToken.balanceOf(receiver);

        if (pending != 0) {
            if (!receiver.isContract()) {
                deploy(_addr);
            }

            // Receiver throws on failure
            TokenReceiver(receiver).pull(originalToken, pending);
            balances[_addr] = balances[_addr].add(pending);
        }
    }

    // ///
    // ERC20
    // ///

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _addr) external view returns (uint256) {
        TokenReceiver receiver = TokenReceiver(migrationAddress(_addr));
        return balances[_addr].add(originalToken.balanceOf(address(receiver)));
    }

    function approve(address _spender,  uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        migrate(msg.sender); // Try migrate tx from

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
        migrate(_from); // Try migrate tx from

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

    // ///
    // Get original token back
    // ///

    function withdraw(uint256 _value) external {
        migrate(msg.sender); // Try migrate tx from
        balances[msg.sender] = balances[msg.sender].sub(_value);
        originalToken.transfer(msg.sender, _value);
    }
}
