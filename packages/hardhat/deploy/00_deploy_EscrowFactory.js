require("hardhat-deploy")
require("hardhat-deploy-ethers")

const { networkConfig } = require("../helper-hardhat-config")

console.log(ethers.provider)
const provider = new ethers.providers.JsonRpcProvider('https://api.hyperspace.node.glif.io/rpc/v1');
const private_key = network.config.accounts[0]
const wallet = new ethers.Wallet(private_key, provider)
console.log(provider)


module.exports = async ({ deployments }) => {
    console.log("Wallet Ethereum Address:", wallet.address)
    const chainId = network.config.chainId
    // const tokensToBeMinted = networkConfig[chainId]["tokensToBeMinted"]

    //deploy EscrowFactory
    const EscrowFactory = await ethers.getContractFactory('EscrowFactory', wallet);
    console.log('Deploying EscrowFactory...');
    const escrowFactory = await EscrowFactory.deploy();
    await escrowFactory.deployed()
    console.log('EscrowFactory deployed to:', escrowFactory.address);
}
// module.exports.tags = ["EscrowFactory"];
