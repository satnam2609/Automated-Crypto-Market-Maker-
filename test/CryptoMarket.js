const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

describe("Automated Crypto Market Maker", () => {
  it("should work", async () => {
    const accounts = await ethers.getSigners();
    let owner = accounts[0];
    const ERC20 = await ethers.getContractFactory("Token");

    const tokenA = await ERC20.deploy("PROTON", "PTR", "1000");
    const tokenB = await ERC20.deploy("ELECTRON", "ETR", "1000");

    const Pool = await ethers.getContractFactory("Pool");
    const pool = await Pool.deploy(tokenA.address, tokenB.address);

    let transactToPoolFromA = await tokenA
      .connect(owner)
      .transfer(pool.address, tokens(100));
    await transactToPoolFromA.wait();

    let transactToPoolFromB = await tokenB
      .connect(owner)
      .transfer(pool.address, tokens(50));
    await transactToPoolFromB.wait();

    let wallet = {
      X: (await tokenA.balanceOf(pool.address)) / tokens(1),
      Y: (await tokenB.balanceOf(pool.address)) / tokens(1),
    };

    console.log("TOKENS IN THE MARKET INITIALLY", wallet);

    let approveA = await tokenA
      .connect(owner)
      .approve(pool.address, tokens(20));
    await approveA.wait();

    let approveB = await tokenB
      .connect(owner)
      .approve(pool.address, tokens(10));
    await approveB.wait();

    const addLiquidity = await pool
      .connect(owner)
      .addLiquidity(tokens(20), tokens(10));

    await addLiquidity.wait();
    wallet.X = (await tokenA.balanceOf(pool.address)) / tokens(1);
    wallet.Y = (await tokenB.balanceOf(pool.address)) / tokens(1);

    console.log("THE TOKENS IN THE POOL AFTER ADDING LIQUIDITY ----->", wallet);

    const balance = await pool.connect(owner).balanceOf(owner.address);
    console.log("SHARES", balance / tokens(1));

    const total = await pool.connect(owner).totalShares();
    console.log("Total Shares ", total / tokens(1));

    let swapPrice = await pool
      .connect(owner)
      .getTradePrice(tokenA.address, tokenB.address, tokens(5));

    console.log("TOKENS SWAPPING PRICE IS ====>", swapPrice / tokens(1));

    let approveTrade = await tokenA
      .connect(owner)
      .approve(pool.address, tokens(5));
    await approveTrade.wait();

    let trade = await pool
      .connect(owner)
      .swap(tokenA.address, tokenB.address, tokens(5));
    await trade.wait();

    wallet.X = (await tokenA.balanceOf(pool.address)) / tokens(1);
    wallet.Y = (await tokenB.balanceOf(pool.address)) / tokens(1);

    console.log("THE TOKENS IN THE POOL AFTER TRADING COINS ----->", wallet);

    const removeLP = await pool.connect(owner).removeLiquidity(tokens(10));

    await removeLP.wait();

    wallet.X = (await tokenA.balanceOf(pool.address)) / tokens(1);
    wallet.Y = (await tokenB.balanceOf(pool.address)) / tokens(1);

    console.log(
      "THE TOKENS IN THE POOL AFTER REMOVING LIQUIDITY ----->",
      wallet
    );

    console.log(
      "SHARES AFTER REMOVING LIQUIDITY",
      (await pool.connect(owner).balanceOf(owner.address)) / tokens(1)
    );

    // extra
    approveTrade = await tokenA.connect(owner).approve(pool.address, tokens(5));
    await approveTrade.wait();

    swapPrice = await pool
      .connect(owner)
      .getTradePrice(tokenA.address, tokenB.address, tokens(5));

    console.log("TOKENS SWAPPING PRICE IS ====>", swapPrice / tokens(1));

    trade = await pool
      .connect(owner)
      .swap(tokenA.address, tokenB.address, tokens(5));
    await trade.wait();

    wallet.X = (await tokenA.balanceOf(pool.address)) / tokens(1);
    wallet.Y = (await tokenB.balanceOf(pool.address)) / tokens(1);

    console.log("THE TOKENS IN THE POOL AFTER TRADING COINS ----->", wallet);
  });
});
