var ElectricityMarket = artifacts.require("./ElectricityMarket.sol");

module.exports = function(deployer) {
  deployer.deploy(ElectricityMarket);
};
