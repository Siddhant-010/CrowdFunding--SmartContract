// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding{
    mapping(address=> uint) public contributors;  // address=> amount donated
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        uint noOfVoters;
        bool completed;
        mapping(address=> bool) voters;
    }
    mapping(uint=> Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline){
        target=_target;
        deadline= block.timestamp+_deadline; // _deadline = 1hr =3600s
        manager=msg.sender;
        minContribution= 100 wei;
    }

    function sendEth() public payable{
        require(block.timestamp<deadline,"Deadline has passed");
        require(msg.value>= minContribution,"Minimum contribution is 100 wei");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp> deadline && raisedAmount< target,"You are not elegible for refund");
        require(contributors[msg.sender]>0);

        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can access this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest= requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    function voteRequest(uint requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest = requests[requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]==true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint requestNo) public onlyManager{
        require(raisedAmount>target);
        Request storage thisRequest = requests[requestNo];
        require(thisRequest.completed==false,"This request has already completed");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majoriy does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }


}