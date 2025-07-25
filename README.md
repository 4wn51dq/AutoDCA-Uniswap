#### Implementation of a simple investment strategy
 - User creates an investment plan, can choose how often, how much and how long they want to invest.
 - (via time-based upkeep/automation) the user's deposits are invested systematically, and are converted into assets.
 - DCA (Dollar Cost Averaging) reduces timing risk by spreading purchase of asset over-time.

 ### DCA
 1. Automates long-term buying behaviour
  - instead of buying an asset all at once and waiting for prices to do sum shi 
  - the 'interval' and 'investmentPerSwap' feature gives control to the user
  - the contract buys the asset for them 
 2. The volatility impact
  - this would help reduce the impact of volatility on net investment
  - if prices fluctuate 
  - The contract would also ensure buys occur regardless of market price 
 


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
