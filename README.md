# OracleIntegration

This repository contains a small contract that interacts with a price oracle.
Its purpose is to fetch price data, validate it, store it, and use it for simple ETH ↔ USD conversions.

The contract focuses on correctness, clean structure, and clear validation logic.

## What the contract does

### 1. **Fetches the latest oracle data**

The contract calls a price feed and retrieves:

* the price
* the round ID
* the timestamp

It also scales the price to 18 decimals so it’s easier to work with.

### 2. **Validates the incoming data**

It checks that:

* the price is not zero
* the round ID is valid
* the timestamp is not from the future
* the timestamp is not stale

If any condition fails, the contract reverts with a specific custom error.

### 3. **Stores the data**

After the checks:

* the price is saved in storage
* the timestamp is saved
* an event is emitted with the values

This makes the updated state available for other functions or external contracts.

### 4. **Converts values using the stored price**

The contract supports a `usePrice` function that can:

* convert ETH → USD
* convert USD → ETH

It chooses the logic based on the token type passed in.
If the token type is not recognized, it reverts.

### 5. **Rejects invalid token types**

Only valid enum values are accepted.
If a caller forces an invalid enum value, the contract throws a custom error.

### 6. **Provides an external getter for the stored state**

You can read:

* the last stored price
* the last timestamp
* the price feed address

This keeps the oracle data accessible to other contracts.

## Testing

The test suite covers:

* successful price updates
* stale timestamp detection
* future timestamp detection
* invalid round ID
* invalid price data
* invalid token types
* consistent conversion behavior
* fuzz tests for usePrice

A mock price feed is used to simulate oracle responses.

## Structure

```
src/            → main contract
test/           → all tests
test/mocks/     → mock aggregator
script/         → deployment scripts
helper/         → config for local and test networks
```


