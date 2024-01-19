
pragma solidity ^0.8.0;

contract RestrictedFunds {
    address public owner;
    address public authorizedKey;
    uint public cancellationRequestTime = 0;
    uint public lastCancellationAbortion = 0;
    bool public isCancellationRequestedByOwner = false;
    bool public isResetRequestedByOwner = false;
    bool public isResetRequestedByAuthorized = false;
    uint public dailyWithdrawalLimit = 0;
    uint public spentToday = 0;
    uint public lastSpendDate;

    uint constant cancellationDelay = 1 weeks;
    uint constant newCancellationRequestDelay = 24 hours;

    constructor(address _authorizedKey) {
        owner = msg.sender;
        authorizedKey = _authorizedKey;
    }

    modifier onlyAuthorized() {
        require(msg.sender == authorizedKey, "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferFunds(address payable _to, uint _amount) public onlyAuthorized {
        require(!isCancellationPending(), "The account is blocked");
        require(address(this).balance >= _amount, "Insufficient balance");
        if (block.timestamp > lastSpendDate + 24 hours) {
            spentToday = 0;
            lastSpendDate = block.timestamp;
        }
        require((spentToday + _amount) <= dailyWithdrawalLimit || dailyWithdrawalLimit == 0, "Withdrawal limit reached");
        spentToday += _amount;
        _to.transfer(_amount);
    }

    function requestCancellation() public onlyOwner {
        require(msg.sender == owner, "Not authorized to cancel");
        require(!isCancellationPending(), "There is already a cancellation pending");
        //ensure there is a delay between cancellations for safety
        require(block.timestamp >= lastCancellationAbortion + newCancellationRequestDelay, "A delay is required to request a cancellation");
        isCancellationRequestedByOwner = true;
        cancellationRequestTime = block.timestamp;
        emit CancelRequest();
    }

    function finalizeCancellation() public onlyOwner {
        require(isCancellationPending(), "Cancellation not requested");
        require(block.timestamp >= cancellationRequestTime + cancellationDelay, "Cancellation delay not met");
        authorizedKey = owner;
        isCancellationRequestedByOwner = false;
    }

    function resetCancellationRequest() public {
        require(isCancellationPending(), "Cancellation not requested");
        require(isResetRequestedByOwner && isResetRequestedByAuthorized, "Not authorized to reset cancellation");
        cancellationRequestTime = 0;
        isCancellationRequestedByOwner = false;
        isResetRequestedByOwner = false;
        isResetRequestedByAuthorized = false;
        lastCancellationAbortion = block.timestamp;
    }

    function resetCancellationRequestOwner() public onlyOwner{
        isResetRequestedByOwner = true;
    }

    function resetCancellationRequestAuthorized() public onlyAuthorized{
        isResetRequestedByAuthorized = true;
    }

    function isCancellationPending() public view returns (bool) {
        return isCancellationRequestedByOwner;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function setNewAuthorizedKey(address newAuthorizedKey) public onlyOwner{
        require(owner == authorizedKey);
        authorizedKey = newAuthorizedKey;
    }

    function setDailyWithdrawalLimit(uint newWithdrawalLimit) public onlyOwner{
        dailyWithdrawalLimit = newWithdrawalLimit;
        emit NewWithdrawalLimit(newWithdrawalLimit);
    }

    event CancelRequest();
    event NewWithdrawalLimit(uint amount);

    receive() external payable {}
}
