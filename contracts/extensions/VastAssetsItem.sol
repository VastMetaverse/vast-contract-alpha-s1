// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract VastAssetsItem is OwnableUpgradeable {
    uint256 internal _latestAssetId;
    mapping(uint256 => uint256) internal _assetCreated;
    mapping(uint256 => uint256) internal _assetCost;
    mapping(uint256 => uint256) internal _assetMaxCount;
    mapping(uint256 => uint256) internal _assetCurrentCount;
    mapping(uint256 => uint256) internal _assetStatus;

    /**
     * @dev Emitted when an asset is created.
     */
    event AssetCreated(uint256 __id, uint256 __cost, uint256 __maxCount);

    /**
     * @dev Emitted when the cost of an asset is updated.
     */
    event AssetCostUpdated(uint256 __id, uint256 __cost);

    /**
     * @dev Emitted when the maxCount of an asset is updated.
     */
    event AssetMaxCountUpdated(uint256 __id, uint256 __maxCount);

    /**
     * @dev Emitted when the status of an asset is updated.
     */
    event AssetStatusUpdated(uint256 __id, uint256 __status);

    /**
     * @dev Creates a new asset.
     *
     * Requirements:
     *
     * - `__cost` The cost of an asset.
     * - `__maxCount` The max count of an asset.
     * - `__status` The status of an asset.
     *
     * Emits a {AssetCreated} event.
     */
    function createAsset(
        uint256 __cost,
        uint256 __maxCount,
        uint256 __status
    ) public onlyOwner {
        _latestAssetId = _latestAssetId + 1;

        _assetCreated[_latestAssetId] = block.timestamp;
        _assetCost[_latestAssetId] = __cost;
        _assetMaxCount[_latestAssetId] = __maxCount;
        _assetStatus[_latestAssetId] = __status;

        emit AssetCreated(_latestAssetId, __cost, __maxCount);
    }

    /**
     * @dev Creates new asset(s).
     *
     * Requirements:
     *
     * - `__cost` The cost of an asset.
     * - `__maxCount` The max count of an asset.
     * - `__status` The status of an asset.
     *
     * Emits a {AssetCreated} event.
     */
    function createAssetBatch(
        uint256[] memory __costs,
        uint256[] memory __maxCounts,
        uint256[] memory __statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < __costs.length; i++) {
            createAsset(__costs[i], __maxCounts[i], __statuses[i]);
        }
    }

    /**
     * @dev Returns an asset.
     *
     * Requirements:
     *
     * - `__id` The id of the asset.
     */
    function getAsset(uint256 __id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(__id <= _latestAssetId, "Asset not found");

        return (
            _assetCreated[__id],
            _assetCost[__id],
            _assetCurrentCount[__id],
            _assetMaxCount[__id],
            _assetStatus[__id]
        );
    }

    /**
     * @dev Sets asset cost.
     *
     * Requirements:
     *
     * - `__id` The id of an asset.
     * - `__cost` must be an integer in wei.
     *
     * Emits a {AssetCostUpdated} event.
     */
    function setAssetCost(uint256 __id, uint256 __cost) external onlyOwner {
        require(__id <= _latestAssetId, "Asset not found");

        _assetCost[__id] = __cost;

        emit AssetCostUpdated(__id, __cost);
    }

    /**
     * @dev Sets asset cost (batch).
     *
     * Requirements:
     *
     * - `__id` The id of an asset.
     * - `__cost` must be an integer in wei.
     *
     * Emits a {AssetCostUpdated} event.
     */
    function setAssetCostBatch(uint256[] memory __ids, uint256[] memory __costs)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < __ids.length; i++) {
            require(__ids[i] <= _latestAssetId, "Asset not found");

            _assetCost[__ids[i]] = __costs[i];

            emit AssetCostUpdated(__ids[i], __costs[i]);
        }
    }

    /**
     * @dev Sets asset max count.
     *
     * Requirements:
     *
     * - `__id` The id of an asset.
     * - `__maxCount` must be an integer.
     *
     * Emits a {AssetMaxCountUpdated} event.
     */
    function setAssetMaxCount(uint256 __id, uint256 __maxCount)
        external
        onlyOwner
    {
        require(__id <= _latestAssetId, "Asset not found");
        require(_assetCurrentCount[__id] == 0, "Cannot change max");

        _assetMaxCount[__id] = __maxCount;

        emit AssetMaxCountUpdated(__id, __maxCount);
    }

    /**
     * @dev Sets asset status.
     *
     * Requirements:
     *
     * - `__id` The id of an asset.
     * - `__status` must be 0, 1 or 2.
     *
     * Emits a {AssetStatusUpdated} event.
     */
    function setAssetStatus(uint256 __id, uint256 __status) external onlyOwner {
        require(__id <= _latestAssetId, "Asset not found");
        require(
            __status == 0 || __status == 1 || __status == 2,
            "Invalid status"
        );

        _assetStatus[__id] = __status;

        emit AssetStatusUpdated(__id, __status);
    }

    /**
     * @dev Sets asset status (batch).
     *
     * Requirements:
     *
     * - `__id` The id of an asset.
     * - `__status` must be 0, 1 or 2.
     *
     * Emits a {AssetStatusUpdated} event.
     */
    function setAssetStatusBatch(
        uint256[] memory __ids,
        uint256[] memory __statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < __ids.length; i++) {
            require(__ids[i] <= _latestAssetId, "Asset not found");
            require(
                __statuses[i] == 0 || __statuses[i] == 1 || __statuses[i] == 2,
                "Invalid status"
            );

            _assetStatus[__ids[i]] = __statuses[i];

            emit AssetStatusUpdated(__ids[i], __statuses[i]);
        }
    }

    /**
     * @dev Returns totalSupply of an asset.
     */
    function totalSupply(uint256 __id) external view returns (uint256) {
        return _assetCurrentCount[__id];
    }
}
