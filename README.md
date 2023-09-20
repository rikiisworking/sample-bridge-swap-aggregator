# sample-bridge-swap-aggregator

This project demonstrates how basic bridge-swap aggregator can be structured through smart contract.

# Project Description

## Details

Based on user's request, server performs all the swap & bridge procedures and sends swapped token back to recipient.

### Diagram

```mermaid
sequenceDiagram

participant User
participant Server
participant Contract
participant Router


User->>Server: 1. request swap
Server->>User: 2. request deposit
User->>Contract: 3. deposit amount to swap
Server->>Contract: 4. request swap
Contract->>Router: 5. perform swap through router
Router->>Contract: 6. receive swapped token
Server->>Contract: 7. request withdraw to recipient
Contract->>User: 8. send swapped token

```

### Contracts

<img src="./classDiagram.svg">

- Since using diamondcut pattern, facet contracts share same address for call.
- Check details for diamondcut pattern here: https://github.com/mudgen/diamond

### Run Test Script

run hardhat node with forked ethereum

```bash
yarn hardhat node --fork ${ ETHEREUM_RPC_URL }
yarn hardhat test --network localhost
```

### TODOs (Archived)

<details>
  <summary> archived </summary>

- [x] add deploy script
- [x] add test script
- [x] update readme

</details>
