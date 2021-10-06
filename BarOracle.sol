// SPDX-License-Identifier: GPL-3.0-or-later
// Author: Jordan Teague

pragma solidity ^0.8.9;

contract BarOracle {

    event memberRequestsListing(address lawyer);
    event memberAdded(address lawyer);
    event memberSuspended(address lawyer);
    event memberDeactivated(address lawyer);
    event contractMigrated(address migratedTo);

    string public jx; //@dev jurisdiction, e.g., "SC" for South Carolina
    address public superadmin; //@dev adding admins, migrating contract
    mapping (address => bool) public admins; //@dev multiple people could be in charge of approval process
    mapping (address => Member) public members;
    address[] public historicalMemberList; //@dev historical data, in case there is a need to pull a list. will include all members, including suspended and deactivated.
    address[] public requests; //@dev list of addresses with pending requests
    address public migratedTo; //@dev in case contract needs upgrading

    struct Member {
        string first;
        string middle; //@dev since like 90% of lawyers are middle-namers
        string last;
        string barID; //@dev not always a number, sadly
        uint dateAdmitted; //@dev unix date
        bool goodStanding; //@dev potentially redundant if member is deactivated when not in good standing
        bool exists; //@dev active once approved; can be deactivated by admin
        bool pending; //@dev if member listing request is still pending
    }

    modifier onlyAdmin {
        require(admins[msg.sender] == true, "admins only");
        _;
    }

    modifier onlySuperadmin {
        require(msg.sender == superadmin, "superadmin only");
        _;
    }

    constructor(string memory _jx) {
        jx = _jx;
        admins[tx.origin] = true;
        superadmin = tx.origin;
    }

    function addAdmin(address _admin) public onlySuperadmin {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlySuperadmin {
        admins[_admin] = false;
    }

    function migrate(address _newAddress) public onlyAdmin {
        migratedTo = _newAddress;
    }

    //require member to request listing - reduce bar association gas cost and data entry burden
    //require off-chain verification of member wallet address
    function requestListing(string memory _first, string memory _middle, string memory _last, string memory _barID, uint _dateAdmitted) public {
        require(members[msg.sender].exists == false, "This address is already a member");
        require(members[msg.sender].pending == false, "There is already a request pending for this address");

        Member memory newMember = Member({
            first: _first,
            middle: _middle,
            last: _last,
            barID: _barID,
            dateAdmitted: _dateAdmitted,
            goodStanding: true,
            exists: false,
            pending: true
        });

        members[msg.sender] = newMember;

        requests.push(msg.sender);
        emit memberRequestsListing(msg.sender); //@dev front end to forward request
    }

    //require off-chain verification of member wallet address - e.g., bar calls member at phone number on file and verifies address over phone (old school, I know)
    function listMember(uint _id) public onlyAdmin {
        address _lawyer = requests[_id];
        require(_lawyer != address(0), "This is the zero address");
        require(members[_lawyer].exists == false, "This address is already a member");
        members[_lawyer].exists = true;
        members[_lawyer].pending = false;
        historicalMemberList.push(_lawyer);
        delete requests[_id];
        emit memberAdded(_lawyer);
    }

    function suspendMember(address _lawyer) public onlyAdmin {
        members[_lawyer].goodStanding = false;
        emit memberSuspended(_lawyer);
    }

    function deactivateMember(address _lawyer) public onlyAdmin {
        members[_lawyer].exists = false;
        emit memberDeactivated(_lawyer);
    }

    //@dev functions for external contracts to call

    function doesMemberExist(address _lawyer) external view returns(bool) {
        return members[_lawyer].exists;
    }

    function isMemberInGoodStanding(address _lawyer) external view returns(bool) {
        return members[_lawyer].goodStanding;
    }

    function getMemberBarID(address _lawyer) external view returns(string memory) {
        return members[_lawyer].barID;
    }

    function newAddress() external view returns(address) {
        require(migratedTo != address(0), "This contract has not migrated");
        return migratedTo;
    }

    function getHistoricalMemberList() external view returns(address[] memory) {
        return historicalMemberList;
    }

}
