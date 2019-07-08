pragma solidity ^0.5.10;

import "./interfaces/IERC20.sol";


contract TokenReceiver {
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    function pull(IERC20 _token, uint256 _amount) external {
        require(msg.sender == owner);
        require(_token.transfer(msg.sender, _amount));
    }
}
