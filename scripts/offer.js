const Constants = require("./constants.js");
const market = Constants.market;

let offers = require("./offer-objects.js");

let offerIndex = parseInt(process.argv[2]);
if (isNaN(offerIndex)) {
	offerIndex = 0;
}

const offer = offers[offerIndex];

market.makeOffer(offer.id, offer.price, offer.electricityAmount,
	offer.startTime, offer.endTime, offer.sellerSmartMeter,
	{from: Constants.accounts.seller, gas: 300000});