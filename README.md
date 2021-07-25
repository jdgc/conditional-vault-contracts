## conditional vault

Some simple contracts that demonstrate how ERC20 tokens can be locked until a specified condition is true as reported by chainlink oracles.
Some use cases for this might be locking funds until a market index is above a key level, or until the price of the asset itself reaches a target.

While it has limited practical use now, this could potentially be expanded into a useful protocol by adding some of the following:
- deposit locked funds in a yield farming protocol
- allow emergency withdraw that slashes a % of funds as protocol revenue
- change the deposit into a wager by adding a beneficiary address who can withdaw the funds if the condition is not met by a specified timestamp
