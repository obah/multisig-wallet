// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultisigWallet{
    event TransactionInitiated(uint256 indexed transactionId, address indexed initiator, address indexed recipient, uint256 amount);
    event TransactionCompleted(uint256 indexed transactionId);
    event TransactionSigned(uint256 indexed transactionId, address indexed signer); 

    struct Transaction {
        uint256 amount;
        address sender;
        address recipient;
        address tokenAddress;
        bool isCompleted;
        address[] signers;
    }

    uint256 txId;    
    uint8 public quorum;
    uint8 public noOfSigners;

    mapping(address => bool) isValidSigner;
    mapping(uint256 => Transaction) transactions;
    mapping(uint256 => address[]) transactionSigners;
    //check if signer has signed a transaction
    mapping(address => mapping(uint256 => bool)) hasSigned;

    constructor (uint8 _quorum, address[] memory _signers, uint8 _noOfSigners) {
        quorum = _quorum;
        noOfSigners = _noOfSigners;

        for(uint8 i = 0; i < noOfSigners; i++) {
            isValidSigner[_signers[i]] = true;
        }
    }

    function transfer(uint256 _amount, address _recipient, address _tokenAddress) external {
        require(msg.sender != address(0), "Invalid address");
        require(isValidSigner[msg.sender], "Not authorized");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Insufficient amount");
        require(_recipient != address(0), "Invalid address");
        require(_tokenAddress != address(0), "Invalid address");

        Transaction storage trx = transactions[txId + 1];

        trx.amount = _amount;
        trx.sender = msg.sender;
        trx.recipient = _recipient;
        trx.tokenAddress = _tokenAddress;
        trx.signers.push(msg.sender);

        txId = txId + 1;

        emit TransactionInitiated(txId - 1, msg.sender, _recipient, _amount);
    }

    function approve(uint256 _txId) external {
        require(isValidSigner[msg.sender], "Not authorized");

        Transaction storage trx = transactions[_txId];

        require(IERC20(trx.tokenAddress).balanceOf(address(this)) >= trx.amount, "insufficient amount");
        require(!hasSigned[msg.sender][_txId], "Signer has signed");

        trx.signers.push(msg.sender);

        emit TransactionSigned(_txId, msg.sender);

        if(trx.signers.length == quorum) {
            trx.isCompleted = true;
            IERC20(trx.tokenAddress).transfer(trx.recipient, trx.amount);

            emit TransactionCompleted(_txId);
        }
    }
}