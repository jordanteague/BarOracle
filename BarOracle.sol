// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract BarOracle {

    event memberRequestsListing(address lawyer_);
    event memberAdded(address lawyer_);
    event memberSuspended(address lawyer_);
    event memberDeactivated(address lawyer_);
    event doesMemberExistCalled(address _caller, address _lawyer);
    event isMemberInGoodStandingCalled(address _caller, address _lawyer);

    string name; //@dev e.g., "South Carolina Bar"
    mapping (address => Member) public members;
    mapping (address => bool) public admins;
    address[] public memberList;
    address[] public requests;

    struct Member {
        address lawyerKey;
        string first;
        string last;
        uint dateAdmitted; //@dev convert to uni date
        bool goodStanding; //@dev potentially redundant if member is deleted when not in good standing
        bool exists;
    }

    constructor(string memory name_) {
        name = name_;
    }

    modifier onlyAdmin {
        require(admins[msg.sender] == true, "admins only");
        _;
    }

    function requestListing() public {
        require(members[msg.sender].exists == false, "This address is already a member");
        emit memberRequestsListing(msg.sender); //@dev front end to forward request
    }

    //require off-chain verification of member wallet address and manual creation of member record by bar association
    function listMember(address lawyer_, string memory first_, string memory last_, uint dateAdmitted_) public onlyAdmin {
        require(members[lawyer_].exists == false, "This address is already a member");
        Member memory newMember = Member({
            lawyerKey: lawyer_,
            first: first_,
            last: last_,
            dateAdmitted: dateAdmitted_,
            goodStanding: true,
            exists: true
        });
        //if NFT bar card eventually given, mint here
        emit memberAdded(lawyer_);
    }

    function suspendMember(address lawyer_) public onlyAdmin {
        members[lawyer_].goodStanding = false;
        emit memberSuspended(lawyer_);
    }

    function deactivateMember(address lawyer_) public onlyAdmin {
        members[lawyer_].exists = false;
        emit memberDeactivated(lawyer_);
    }

    //@dev functions for external contracts to call

    function doesMemberExist(address lawyer_) external returns(bool) {
        emit doesMemberExistCalled(msg.sender, lawyer_);
        return members[lawyer_].exists;
    }

    function isMemberInGoodStanding(address lawyer_) external returns(bool) {
        emit isMemberInGoodStandingCalled(msg.sender, lawyer_);
        return members[lawyer_].goodStanding;
    }

}

contract TestCall {

    constructor() {

    }

    function isMember(address contract_, address lawyer_) public returns(bool) {
        return BarOracle(contract_).doesMemberExist(lawyer_);
    }

    function isMemberInGoodStanding(address contract_, address lawyer_) public returns(bool) {
        return BarOracle(contract_).isMemberInGoodStanding(lawyer_);
    }

}
