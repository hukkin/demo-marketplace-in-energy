## A guide to demoing the contract

### Install dependencies

Before the first run, dependencies need to be installed for the test scripts and the status viewer.

```shell
cd scripts/
npm install
```

```shell
cd scripts/status
bower install
```

### Run a deterministic TestRPC session

```shell
testrpc -d
```

### Deploy the contract

```shell
truffle migrate
```

### Run the issuer script that issues smart meter ownerships

```shell
cd scripts/
node issuer.js
```

### Open the status view in browser

Open `scripts/status/index.html` in browser.

### Create sell offers

Change the optional index argument to create different pre-populated offers. The default behavior is to choose the offer at index 0.
```shell
node offer [<index>]
```

### Accept offers as a buyer

```shell
node acceptoffer [<index>]
```

### Send reports from smart meters (or wait until the report deadline)

```shell
node sellerreport [<index>]
node buyerreport [<index>]
```

### Withdraw money

```shell
node withdraw [<index>]
```