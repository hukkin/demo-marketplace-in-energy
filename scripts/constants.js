const Web3 = require('web3');
const web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

exports.marketAddress = "0xcfeb869f69431e42cdb54a4f4f105c19c080a601";

exports.marketAbi = require('../build/contracts/ElectricityMarket.json').abi;
exports.smartMetersAbi = require('../build/contracts/SmartMeters.json').abi;
exports.market = web3.eth.contract(exports.marketAbi).at(exports.marketAddress);
exports.web3 = web3;
exports.accounts = {
  "issuer": web3.eth.accounts[0],
  "sellerSmartMeter": web3.eth.accounts[1],
  "seller": web3.eth.accounts[2],
  "buyerSmartMeter": web3.eth.accounts[3],
  "buyer": web3.eth.accounts[4]
};