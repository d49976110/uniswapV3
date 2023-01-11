// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./PeripheryImmutableState.sol";
import "../interfaces/IPoolInitializer.sol";

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96 //初始价格 √P.
    ) external payable override returns (address pool) {
        //先排序
        require(token0 < token1);
        //getPool 是public state，3層mapping的index為token0,token1,fee，即就算兩個token是一樣的，但是fee不一樣，仍然會被視為不同池子
        //查看是否已建立pool
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            //factory為NonfungiblePositionManager中的建構子賦值而來
            //實際上createPool是使用deploy建立池子
            pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            //取得當前最新價格
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool)
                .slot0();
            // 如果價格為 0 則初始化Pool
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}
