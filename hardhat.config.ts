import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";

dotenv.config();

export default {
  solidity: {
    version: "0.8.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: process.env.ALCHEMY_MAINNET_RPC_URL,
        blockNumber: 12365669,
      },
    },
    kovan: {
      url: process.env.KOVAN_RPC_URL,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
    },
  },
  defaultNetwork: "hardhat",
  mocha: {
    timeout: 10000000,
  },
};
