// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract VastAssetTypes is OwnableUpgradeable {
    uint256 internal _latestAssetTypeId;
    mapping(uint256 => uint256) internal _assetTypeCreated;
    mapping(uint256 => uint256) internal _assetTypeCost;
    mapping(uint256 => uint256) internal _assetTypeMaxCount;
    mapping(uint256 => string) internal _assetTypeName;
    mapping(uint256 => uint256) internal _assetTypeCurrentCount;
    mapping(uint256 => uint256) internal _assetTypeStatus;

    /**
     * @dev Emitted when an asset is created.
     */
    event AssetTypeCreated(
        uint256 __id,
        string __name,
        uint256 __cost,
        uint256 __maxCount
    );

    /**
     * @dev Emitted when the name of an asset is updated.
     */
    event AssetTypeNameUpdated(uint256 __id, string __name);

    /**
     * @dev Emitted when the cost of an asset is updated.
     */
    event AssetTypeCostUpdated(uint256 __id, uint256 __cost);

    /**
     * @dev Emitted when the maxCount of an asset is updated.
     */
    event AssetTypeMaxCountUpdated(uint256 __id, uint256 __maxCount);

    /**
     * @dev Emitted when the status of an asset is updated.
     */
    event AssetTypeStatusUpdated(uint256 __id, uint256 __status);

    /**
     * @dev Creates a new asset.
     *
     * Requirements:
     *
     * - `__cost` The cost of an asset type.
     * - `__maxCount` The max count of an asset type.
     * - `__status` The status of an asset type.
     *
     * Emits a {AssetCreated} event.
     */
    function createAssetType(
        string memory __name,
        uint256 __cost,
        uint256 __maxCount,
        uint256 __status
    ) public onlyOwner {
        _latestAssetTypeId = _latestAssetTypeId + 1;

        _assetTypeCreated[_latestAssetTypeId] = block.timestamp;
        _assetTypeName[_latestAssetTypeId] = __name;
        _assetTypeCost[_latestAssetTypeId] = __cost;
        _assetTypeMaxCount[_latestAssetTypeId] = __maxCount;
        _assetTypeStatus[_latestAssetTypeId] = __status;

        emit AssetTypeCreated(_latestAssetTypeId, __name, __cost, __maxCount);
    }

    /**
     * @dev Creates new asset(s).
     *
     * Requirements:
     *
     * - `__cost` The cost of an asset type.
     * - `__maxCount` The max count of an asset type.
     * - `__status` The status of an asset type.
     *
     * Emits a {AssetCreated} event.
     */
    function createAssetTypeBatch(
        string[] memory __names,
        uint256[] memory __costs,
        uint256[] memory __maxCounts,
        uint256[] memory __statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < __costs.length; i++) {
            createAssetType(
                __names[i],
                __costs[i],
                __maxCounts[i],
                __statuses[i]
            );
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
        require(__id <= _latestAssetTypeId, "Asset Type not found");

        return (
            _assetTypeCreated[__id],
            _assetTypeCost[__id],
            _assetTypeCurrentCount[__id],
            _assetTypeMaxCount[__id],
            _assetTypeStatus[__id]
        );
    }

    /**
     * @dev Sets asset name.
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__name` The name of an asset type.
     *
     * Emits a {AssetCostUpdated} event.
     */
    function setAssetTypeName(uint256 __id, string memory __name)
        external
        onlyOwner
    {
        require(__id <= _latestAssetTypeId, "Asset Type not found");

        _assetTypeName[__id] = __name;

        emit AssetTypeNameUpdated(__id, __name);
    }

    /**
     * @dev Sets asset cost.
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__cost` must be an integer in wei.
     *
     * Emits a {AssetCostUpdated} event.
     */
    function setAssetTypeCost(uint256 __id, uint256 __cost) external onlyOwner {
        require(__id <= _latestAssetTypeId, "Asset Type not found");

        _assetTypeCost[__id] = __cost;

        emit AssetTypeCostUpdated(__id, __cost);
    }

    /**
     * @dev Sets asset cost (batch).
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__cost` must be an integer in wei.
     *
     * Emits a {AssetCostUpdated} event.
     */
    function setAssetTypeCostBatch(
        uint256[] memory _ids,
        uint256[] memory __costs
    ) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] <= _latestAssetTypeId, "Asset Type not found");

            _assetTypeCost[_ids[i]] = __costs[i];

            emit AssetTypeCostUpdated(_ids[i], __costs[i]);
        }
    }

    /**
     * @dev Sets asset max count.
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__maxCount` must be an integer.
     *
     * Emits a {AssetMaxCountUpdated} event.
     */
    function setAssetTypeMaxCount(uint256 __id, uint256 __maxCount)
        external
        onlyOwner
    {
        require(__id <= _latestAssetTypeId, "Asset Type not found");
        require(_assetTypeCurrentCount[__id] == 0, "Cannot change max");

        _assetTypeMaxCount[__id] = __maxCount;

        emit AssetTypeMaxCountUpdated(__id, __maxCount);
    }

    /**
     * @dev Sets asset status.
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__status` must be 0, 1 or 2.
     *
     * Emits a {AssetStatusUpdated} event.
     */
    function setAssetTypeStatus(uint256 __id, uint256 __status)
        external
        onlyOwner
    {
        require(__id <= _latestAssetTypeId, "Asset Type not found");
        require(
            __status == 0 || __status == 1 || __status == 2,
            "Invalid status"
        );

        _assetTypeStatus[__id] = __status;

        emit AssetTypeStatusUpdated(__id, __status);
    }

    /**
     * @dev Sets asset status (batch).
     *
     * Requirements:
     *
     * - `__id` The id of an asset type.
     * - `__status` must be 0, 1 or 2.
     *
     * Emits a {AssetStatusUpdated} event.
     */
    function setAssetTypeStatusBatch(
        uint256[] memory __ids,
        uint256[] memory __statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < __ids.length; i++) {
            require(__ids[i] <= _latestAssetTypeId, "Asset Type not found");
            require(
                __statuses[i] == 0 || __statuses[i] == 1 || __statuses[i] == 2,
                "Invalid status"
            );

            _assetTypeStatus[__ids[i]] = __statuses[i];

            emit AssetTypeStatusUpdated(__ids[i], __statuses[i]);
        }
    }

    /**
     * @dev Returns totalSupply of an asset type.
     */
    function totalSupplyOfType(uint256 __id) external view returns (uint256) {
        return _assetTypeCurrentCount[__id];
    }
}
