// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//STILL IN PROGRESS !!
//NOT EVEN TESTED !!

contract RestrictedFunds {
    address public owner;
    address public authorizedKey;
    uint public cancellationRequestTime;
    uint public lastCancellationAbortion;
    bool public isCancellationRequestedByOwner;
    bool public isResetRequestedByOwner;
    bool public isResetRequestedByAuthorized;

    uint constant cancellationDelay = 24 hours;
    uint constant newCancellationRequestDelay = 24 hours;


    constructor(address _authorizedKey) {
        owner = msg.sender;
        authorizedKey = _authorizedKey;
    }

    modifier onlyAuthorized() {
        require(msg.sender == authorizedKey, "Not authorized");
        require(!isCancellationPending(), "Cancellation is pending");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    function transferFunds(address payable _to, uint _amount) public onlyAuthorized {
        require(!isCancellationPending(), "The account is blocked")
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.transfer(_amount);
    }

    function requestCancellation() public onlyOwner {
        require(msg.sender == owner, "Not authorized to cancel");
        require(!isCancellationPending(), "There is already a cancellation pending");
        //ensure there is a delay between cancellations for safety
        require(block.timestamp >= lastCancellationAbortion + newCancellationRequestDelay);
        isCancellationRequestedByOwner = true;
        cancellationRequestTime = block.timestamp;
    }

    function finalizeCancellation() public onlyOwner {
        require(isCancellationPending(), "Cancellation not requested");
        require(block.timestamp >= cancellationRequestTime + cancellationDelay, "Cancellation delay not met");
        authorizedKey = owner;
        isCancellationRequestedByOwner = false;
    }

    function resetCancellationRequest() public {
        require(isCancellationPending(), "Cancellation not requested");
        require(isResetRequestedByOwner && isResetRequestedByAuthorized, "Cancellation not requested");
        cancellationRequestTime = 0;
        isCancellationRequestedByOwner = false;
        isResetRequestedByOwner = false;
        isResetRequestedByAuthorized = false;
        lastCancellationAbortion = block.timestamp;
    }

    function resetCancellationRequest() public onlyOwner{
        isResetRequestedByOwner = true;
    }

    function resetCancellationRequest() public onlyAuthorized{
        isResetRequestedByAuthorized = true;
    }

    function isCancellationPending() public view returns (bool) {
        return isCancellationRequestedByOwner;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function setNewAuthorizedKey(adress newAuthorizedKey) public onlyOwner{
        require(owner == authorizedKey);
        authorizedKey = newAuthorizedKey;
    }

    receive() external payable {}
}
