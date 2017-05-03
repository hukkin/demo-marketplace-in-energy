const ElectricityMarket = artifacts.require("./ElectricityMarket.sol");
const SmartMeters = artifacts.require("./SmartMeters.sol");


contract('Smoke test - ElectricityMarket', function(accounts) {
  let market;
  let smartMeters;

  const issuer = accounts[0];
  const sellerSmartMeter = accounts[1];
  const seller = accounts[2];
  const buyerSmartMeter = accounts[3];
  const buyer = accounts[4];

  const offerId = 0;
  const price = 12;
  const electricityAmount = 12;
  const startTime = 1800000000;
  const endTime = startTime + 50;

  const resolvedState = 6;


  before(function() {
    return ElectricityMarket.deployed().then(function(instance) {
      market = instance;
      return market.getSmartMetersContract();
    }).then(function(smartMetersAddress) {
      return SmartMeters.at(smartMetersAddress);
    }).then(function(_smartMeters) {
      smartMeters = _smartMeters;
      smartMeters.setIssuer(issuer);
    }).then(function() {
      smartMeters.changeOwner(sellerSmartMeter, seller, {from: issuer});
    }).then(function() {
      smartMeters.changeOwner(buyerSmartMeter, buyer, {from: issuer});
    });
  });


  it("should create an offer", function() {
    market.makeOffer(offerId, price, electricityAmount, startTime, endTime, sellerSmartMeter, {from: seller}).then(function() {
      return market.getSeller(offerId);
    }).then(function(actualSeller) {
      assert.equal(actualSeller, seller, "Wrong seller address");
    });
  });

  it("should accept an offer", function() {
    market.acceptOffer(offerId, buyerSmartMeter, {from: buyer, value: price}).then(function() {
      return market.getBuyer(offerId);
    }).then(function(actualBuyer) {
      assert.equal(actualBuyer, buyer, "Wrong buyer address");
    });
  });

  it("should report OK on seller's behalf", function() {
    market.sellerReport(offerId, true, {from: sellerSmartMeter}).then(function() {
      return market.getSellerReport(offerId);
    }).then(function(report) {
      assert.equal(report, true, "Wrong seller report");
    });
  });

  it("should report OK on buyer's behalf", function() {
    market.buyerReport(offerId, true, {from: buyerSmartMeter}).then(function() {
      return market.getBuyerReport(offerId);
    }).then(function(report) {
      assert.equal(report, true, "Wrong buyer report");
    });
  });

  it("should withdraw money", function() {
    market.withdraw(offerId, {from: buyer}).then(function() {
      return market.getState(offerId);
    }).then(function(state) {
      assert.equal(state, resolvedState, "Wrong contract state");
    });
  });

});