// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { MarketAPI } from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import { BigInt } from "@zondax/filecoin-solidity/contracts/v0.8/cbor/BigIntCbor.sol";

contract BeneficiaryEscrow {

    address immutable factory;
    address immutable public lender;
    address public minerID;
    address public borrower;

    bytes pieceCID;

    bool public underwritten;
    bool public active;

    uint48 created;

    uint256 immutable public duration;
    uint256 immutable public size;
    uint256 immutable public delay = 604800;
    uint256 public loanAmount;

    constructor(address _lender, uint256 _duration, uint256 _size, string _label, bool _underwritten, address _borrower) payable {
        lender = _lender;
        duration = _duration;
        size = _size;
        underwritten = _underwritten;
        created = uint48(block.timestamp);
        loanAmount = msg.value;
        factory = msg.sender;
        if (underwritten == true) {
            borrower = _borrower;
        }
        MarketAPI.publishStorageDeals(MarketTypes.PublishStorageDealsParams(CommonTypes.DealProposal(
            pieceCID,
            size,
            false,
            abi.encodePacked(lender),
            abi.encodePacked(borrower),
            _label,
            int64(block.timestamp),
            int64(block.timestamp + duration),
            BigInt(bytes(0)),
            BigInt(bytes(0)),
            BigInt(bytes(0)))
            )
        );
    }
    
    modifier isUnderwritten() {
        if (underwritten == true) {
            require(msg.sender == borrower);
        }
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }

    modifier onlyOwner() {
        bool party;
        if (msg.sender == lender) {
            party = true;
        }
        else if (msg.sender == borrower) {
            party = true;
        }
        require(party == true);
        _;
    }

    //To initiate deal, the borrower first deposits collateral equal to the loan and receives the loan

    function initiateDeal() isUnderwritten public payable returns (bool) {
        require(active == false);
        require(loanAmount == msg.value);

        borrower = msg.sender;

        (bool success, ) = 
            borrower.call{value: loanAmount}("");
            require(success, "Transfer failed.");
        return true;
    }

    //After the deal is intialized, the storage provider deploys their node and accepts the lender's storage deal.
    //Once this is done, the borrower may now withdraw their collateral and operate normally.

    function acceptDeal() isUnderwritten public payable returns (bool) {
        require(active == false);
        //require(deserializeAddress(getBeneficiary(minerAddress)) == msg.sender);
        //require(return some value from zondax or beryx to check whether the storage deal is active)
        borrower = msg.sender;
        active = true;

        (bool success, ) = 
            borrower.call{value: address(this).balance}("");
            require(success, "Transfer failed.");
        return active;
    }

    function liquidate() onlyFactory external returns (bool) {
        require(active == true);
        active == false;
        bytes memory addr = abi.encodePacked(borrower);
        //require(return some value from zondax or beryx to check whether the storage deal is active)
        MarketAPI.withdrawBalance(MarketTypes.WithdrawBalanceParams(addr, BigInt(bytes(abi.encodePacked(loanAmount)), false)));

        //Prevent SP from withdrawing any remaining rewards
        borrower = lender;

        (bool success, ) = 
            lender.call{value: address(this).balance}("");
            require(success, "Transfer failed.");
        return true;
    }

    function withdraw(uint256 _amount) onlyOwner public returns (bool) {
        require(_amount <= address(this).balance);
        //Add % split to compensate for unnecessary storage deal collateral/payment 
        (bool success, ) = 
            msg.sender.call{value: _amount}("");
            require(success, "Transfer failed.");
        return true;
    }

}