if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    // set the provider you want from Web3.providers
    web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
}

let offers = [];
var dynatable = $('#offers').dynatable().data('dynatable');
market = web3.eth.contract(marketAbi).at(marketAddress);

market.LogOffer().watch(function(error, result) {
    if (!error) {
        let newOffer = result.args;
        newOffer.state = "Waiting for acceptance"
        formatOfferTimestamps(newOffer);
        offers.push(newOffer);
        updateDynatable(dynatable, offers);
    }
});

market.LogAcceptOffer().watch(function(error, result) {
    if (!error){
        let newOffer = result.args;
        let i = offers.findIndex((obj => obj.id.equals(newOffer.id)));
        if (i !== -1) {
            offers[i].state = "Accepted";
            offers[i].buyer = newOffer.buyer;
            offers[i].buyerSmartMeter = newOffer.buyerSmartMeter;
            updateDynatable(dynatable, offers);
        }
    }
});

market.LogResolved().watch(function(error, result) {
    if (!error) {
        let newOffer = result.args;
        let i = offers.findIndex((obj => obj.id.equals(newOffer.id)));
        if (i !== -1) {
            offers[i].state = "Resolved";
            offers[i].recipient = newOffer.recipient;
            updateDynatable(dynatable, offers);
        }
    }
});

// Create a table of account balances and update it on a set interval
var balancesTable = $('#balances').dynatable().data('dynatable');
setInterval(function() {
    let balances = [{"identity": "Smart contract", "account": marketAddress, "balance": web3.eth.getBalance(marketAddress)},
        {"identity": "Seller", "account": web3.eth.accounts[2], "balance": web3.eth.getBalance(web3.eth.accounts[2])},
        {"identity": "Buyer", "account": web3.eth.accounts[4], "balance": web3.eth.getBalance(web3.eth.accounts[4])}];
    updateDynatable(balancesTable, balances);
}, 5000);

function formatOfferTimestamps(offer) {
    const momentDateFormatString = 'HH:mm:ss, MMMM Do YYYY';
    offer.endTime = moment.unix(offer.endTime).format(momentDateFormatString);
    offer.startTime = moment.unix(offer.startTime).format(momentDateFormatString);
}

function updateDynatable(table, content) {
    table.settings.dataset.originalRecords = content;
    table.process();
}