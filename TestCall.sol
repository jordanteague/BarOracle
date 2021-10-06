// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Jordan Teague

pragma solidity ^0.8.9;

contract TestCall {

    constructor() {

    }

    function isMember(address _contract, address _lawyer) public view returns(bool) {
        return BarOracle(_contract).doesMemberExist(_lawyer);
    }

    function isMemberInGoodStanding(address _contract, address _lawyer) public view returns(bool) {
        return BarOracle(_contract).isMemberInGoodStanding(_lawyer);
    }

    function newAddress(address _contract) public view returns(address) {
        return BarOracle(_contract).newAddress();
    }

}
