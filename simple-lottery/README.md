##  Simple lottery

URL: https://www.rareskills.io/post/beginner-solidity-projects

Challenge:

> Any user can call createLottery and a lottery will be created with a ticket purchase window for the next 24 hours. Once the 24 hours is up, there is a 1 hour delay, then the lottery is over. Generating random numbers safely on Ethereum is tricky, but for the purpose of this, relying on a future blockhash (which the players cannot predict), is good enough for this project. After createLottery is called people can purchaseTicket for a particular lotteryId. The lottery must consist of a deadline for when purchasing tickets stops, and time afterwards when the future blockhash determines the winner. The winner must then claim the winnings within 256 blocks (the maximum lookback of the blockhash function), otherwise, everyone can get their tickets back.

## Usage

### Install

```shell
$ make install
```

### Test

```shell
$ make test
```
