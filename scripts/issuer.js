const Constants = require("./constants.js");
const web3 = Constants.web3;

const electricityMarket = Constants.market;

const smartMetersAddress = electricityMarket.getSmartMetersContract();
const smartMeters = web3.eth.contract(Constants.smartMetersAbi).at(smartMetersAddress);

smartMeters.setIssuer(Constants.accounts.issuer, {from: Constants.accounts.issuer});
smartMeters.changeOwner(Constants.accounts.sellerSmartMeter, Constants.accounts.seller, {from: Constants.accounts.issuer});
smartMeters.changeOwner(Constants.accounts.buyerSmartMeter, Constants.accounts.buyer, {from: Constants.accounts.issuer});