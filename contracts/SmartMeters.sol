pragma solidity ^0.4.8;

contract SmartMeters {

    modifier onlyIssuer() {
        if ((msg.sender != issuer) || (!issuerSet)) {
            throw;
        }
        _;
    }

    address public issuer;
    mapping (address => address) public owner;
    bool issuerSet = false;

    function changeOwner(address meterAddress, address newOwner)
        onlyIssuer()
    {
        owner[meterAddress] = newOwner;
    }

    // A function that can be run one time that sets the issuer public key. This
    // would logically belong to the constructor or be a preset value, but then
    // it would not be possible to let Truffle select it from one of the
    // accounts made available by TestRPC, and the account would have to be
    // manually changed in code when testing.
    function setIssuer(address _issuer) {
        if (!issuerSet) {
            issuer = _issuer;
            issuerSet = true;
        }
    }
}