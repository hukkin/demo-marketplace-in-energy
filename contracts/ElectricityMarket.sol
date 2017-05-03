pragma solidity ^0.4.8;

import "./SmartMeters.sol";


contract ElectricityMarket {

    enum ContractState { NotCreated, Created, Accepted, WaitingForBuyerReport,
        WaitingForSellerReport, ReadyForWithdrawal, Resolved, TimedOut }

    struct Contract {
        address seller;
        address sellerSmartMeter;
        address buyer;
        address buyerSmartMeter;
        uint price;
        uint electricityAmount;
        uint startTime;
        uint endTime;
        bool sellerReport;  // true if everything went OK
        bool buyerReport;  // true if everything went OK
        ContractState state;
    }

    modifier contractNotCreated(uint id) {
        if (contracts[id].state != ContractState.NotCreated) {
            throw;
        }
        _;
    }

    modifier contractInState(uint id, ContractState state) {
        if (contracts[id].state != state) {
            throw;
        }
        _;
    }

    modifier waitingForSellerReport(uint id) {
        if ((contracts[id].state != ContractState.Accepted) && (contracts[id].state != ContractState.WaitingForSellerReport)) {
            throw;
        }
        _;
    }

    modifier waitingForBuyerReport(uint id) {
        if ((contracts[id].state != ContractState.Accepted) && (contracts[id].state != ContractState.WaitingForBuyerReport)) {
            throw;
        }
        _;
    }

    modifier noOverlappingContracts(address smartMeter, uint startTime, uint endTime) {
        for (uint i = 0; i < contractsBySmartMeter[smartMeter].length; i++) {
            Contract c = contracts[contractsBySmartMeter[smartMeter][i]];
            if (doTimeslotsOverlap(startTime, endTime, c.startTime, c.endTime)) {
                throw;
            }
        }
        _;
    }

    modifier ownsSmartMeter(address owner, address smartMeter) {
        if (owner != smartMeters.owner(smartMeter)) {
            throw;
        }
        _;
    }

    modifier buyerSmartMeterOnly(uint id) {
        if (msg.sender != contracts[id].buyerSmartMeter) {
            throw;
        }
        _;
    }

    modifier sellerSmartMeterOnly(uint id) {
        if (msg.sender != contracts[id].sellerSmartMeter) {
            throw;
        }
        _;
    }

    modifier condition(bool c) {
        if (!c) {
            throw;
        }
        _;
    }

    modifier costs(uint price) {
        if (msg.value != price) {
            throw;
        }
        _;
    }

    mapping (uint => Contract) contracts;
    mapping (address => uint[]) contractsBySmartMeter;
    SmartMeters smartMeters;


    // Minimum time from block.timestamp to startTime. The time needs to be long
    // enough, so that a few blocks are created in between, so that the smart
    // meters can be sure that the transmission is approved by the blockchain
    uint minTimeFromAcceptedToStart = 60;  // 1 minute
    // Maximum time from endTime to smart meters reporting about how the
    // transmission went.
    uint maxTimeFromEndToReportDeadline = 1800;  // 30 minutes

    event LogOffer(address seller, uint id, uint price, uint electricityAmount, uint startTime, uint endTime, address sellerSmartMeter);
    event LogAcceptOffer(address seller, uint id, uint price, uint electricityAmount, uint startTime, uint endTime, address sellerSmartMeter, address buyer, address buyerSmartMeter);
    event LogResolved(uint id, address seller, address buyer, address recipient);

    function ElectricityMarket() {
        smartMeters = new SmartMeters();
    }

    function makeOffer(uint id, uint price, uint electricityAmount, uint startTime, uint endTime, address sellerSmartMeter)
        contractNotCreated(id)
        condition(startTime < endTime)
        noOverlappingContracts(sellerSmartMeter, startTime, endTime)
        ownsSmartMeter(msg.sender, sellerSmartMeter)
    {
        storeAndLogNewOffer(id, price, electricityAmount, startTime, endTime, sellerSmartMeter);
    }

    function acceptOffer(uint id, address buyerSmartMeter) payable
        costs(contracts[id].price)
        contractInState(id, ContractState.Created)
        ownsSmartMeter(msg.sender, buyerSmartMeter)
    {
        // Check if contract timed out
        if ((now + minTimeFromAcceptedToStart) > contracts[id].startTime) {
            contracts[id].state = ContractState.TimedOut;
            return;
        }

        contracts[id].buyer = msg.sender;
        contracts[id].buyerSmartMeter = buyerSmartMeter;
        contracts[id].state = ContractState.Accepted;

        LogAcceptOffer(contracts[id].seller, id, contracts[id].price, contracts[id].electricityAmount, contracts[id].startTime, contracts[id].endTime, contracts[id].sellerSmartMeter, msg.sender, buyerSmartMeter);
    }

    function sellerReport(uint id, bool report)
        sellerSmartMeterOnly(id)
        waitingForSellerReport(id)
    {
        if (hasReportDeadlineExpired(id)) {
            contracts[id].state = ContractState.ReadyForWithdrawal;
            return;
        }
        contracts[id].sellerReport = report;
        contracts[id].state = (contracts[id].state == ContractState.Accepted) ? ContractState.WaitingForBuyerReport : ContractState.ReadyForWithdrawal;
    }

    function buyerReport(uint id, bool report)
        buyerSmartMeterOnly(id)
        waitingForBuyerReport(id)
    {
        if (hasReportDeadlineExpired(id)) {
            contracts[id].state = ContractState.ReadyForWithdrawal;
            return;
        }
        contracts[id].buyerReport = report;
        contracts[id].state = (contracts[id].state == ContractState.Accepted) ? ContractState.WaitingForSellerReport : ContractState.ReadyForWithdrawal;
    }

    function withdraw(uint id)
    {
        if (contracts[id].state != ContractState.ReadyForWithdrawal) {
            makeReadyForWithdrawal(id);
        }
        contracts[id].state = ContractState.Resolved;

        address recipient;

        if (!contracts[id].sellerReport) {
            recipient = contracts[id].buyer;
        }
        else if (contracts[id].buyerReport) {
            recipient = contracts[id].seller;
        }
        else {
            recipient = this;
        }

        LogResolved(id, contracts[id].seller, contracts[id].buyer, recipient);

        if (recipient != address(this)) {
            if (!recipient.send(contracts[id].price)) {
                throw;
            }
        }
    }

    // Assume that startTime < endTime for both timestamp pairs
    function doTimeslotsOverlap(uint startTime1, uint endTime1, uint startTime2, uint endTime2) private constant returns (bool) {
        if ((endTime1 < startTime2) || (endTime2 < startTime1)) {
            return false;
        }
        return true;
    }

    function hasReportDeadlineExpired(uint id) private constant returns (bool) {
        if ((contracts[id].endTime + maxTimeFromEndToReportDeadline) > now) {
            return false;
        }
        return true;
    }

    // A helper made to avoid "stack too deep" error in makeOffer.
    function storeAndLogNewOffer(uint id, uint price, uint electricityAmount, uint startTime, uint endTime, address sellerSmartMeter) private {
        contracts[id].seller = msg.sender;
        contracts[id].price = price;
        contracts[id].electricityAmount = electricityAmount;
        contracts[id].startTime = startTime;
        contracts[id].endTime = endTime;
        contracts[id].sellerSmartMeter = sellerSmartMeter;
        contracts[id].state = ContractState.Created;

        contractsBySmartMeter[sellerSmartMeter].push(id);

        LogOffer(msg.sender, id, price, electricityAmount, startTime, endTime, sellerSmartMeter);
    }

    // Change the state ReadyForWithdrawal if report deadline has expired. If
    // not succesful for any reason, then throw.
    function makeReadyForWithdrawal(uint id) private {
        if ((contracts[id].state == ContractState.Accepted
            || contracts[id].state == ContractState.WaitingForSellerReport
            || contracts[id].state == ContractState.WaitingForBuyerReport)
            && hasReportDeadlineExpired(id))
        {
            contracts[id].state = ContractState.ReadyForWithdrawal;
            return;
        }
        throw;
    }

    function getSeller(uint id) constant returns (address) {
        return contracts[id].seller;
    }

    function getBuyer(uint id) constant returns (address) {
        return contracts[id].buyer;
    }

    function getBuyerReport(uint id) constant returns (bool) {
        return contracts[id].buyerReport;
    }

    function getSellerReport(uint id) constant returns (bool) {
        return contracts[id].sellerReport;
    }

    function isCreated(uint id) constant returns (bool) {
        return contracts[id].state != ContractState.NotCreated;
    }

    function getState(uint id) constant returns (ContractState) {
        return contracts[id].state;
    }

    function getSmartMetersContract() constant returns (address) {
        return smartMeters;
    }
}
