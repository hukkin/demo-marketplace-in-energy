const Constants = require("./constants.js");
const market = Constants.market;

let offers = require("./offer-objects.js");

let offerIndex = parseInt(process.argv[2]);
if (isNaN(offerIndex)) {
	offerIndex = 0;
}

const offer = offers[offerIndex];

market.acceptOffer(offer.id, offer.buyerSmartMeter,
	{from: Constants.accounts.buyer, gas: 300000, value: offer.price});
