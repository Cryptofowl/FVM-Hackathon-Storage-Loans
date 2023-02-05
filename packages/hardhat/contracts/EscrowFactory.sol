// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./BeneficiaryEscrow.sol";

contract EscrowFactory {

    BeneficiaryEscrow[] public agreements;
    mapping (address => userAgreements[]) indexes;

    struct userAgreements {
        BeneficiaryEscrow agreement;
        uint256 index;
        bool active;
    }

    //Deploys a new agreement contract with the given terms

    function newAgreement(address _lender, uint256 _duration, uint256 _size, bool _underwritten, address _borrower) public returns (address) {
        BeneficiaryEscrow beneficiary = new 
        BeneficiaryEscrow(
            _lender, 
            _duration, 
            _size, 
            _underwritten, 
            _borrower);
        agreements.push(beneficiary);
        return address(beneficiary);
    }

    //Liquidate an existing agreement, withdraw collateral, and return it to the lender
    //Only the lender may liquidate an existing deal

    function callLiquidate(uint256 index, address _user) public returns (bool) {
        BeneficiaryEscrow agreementContract = indexes[_user][index].agreement;

        require(indexes[_user][index].active == true);
        require(msg.sender == agreementContract.lender());
            //Mark agreement as inactive
            indexes[_user][index].active == false;

            (bool success) = 
            agreementContract.liquidate() &&
            agreementContract.withdraw(address(agreementContract).balance);
        require(success, "Liquidation failed.");
        return success;
    }

    //Withdraw contract balance from all active deals

    function withdrawFromAllDeals(address _user) public returns (bool) {
        uint256[] memory _indexes = indexesFor(_user);
        for (uint256 i=0; i < _indexes.length; i++) {
            bool success = 
            indexes[_user][i].agreement.withdraw(address(indexes[_user][i].agreement).balance);
            require(success, "Withdrawal failed.");
        }
        return true;
    }

    //Returns all active loan agreements for a user

    function indexesFor(address _user) public view returns (uint256[] memory indexes_) {
        for (uint256 i=0; i < indexes[_user].length; i++) {
            if (indexes[_user][i].active == true) {
                indexes_[i] = i; 
            }
        }
        return indexes_;
    }

}