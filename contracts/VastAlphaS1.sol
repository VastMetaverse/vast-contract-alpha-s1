// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

// import "./layerzero/contracts-upgradable/lzApp/NonblockingLzAppUpgradeable.sol";

import "./extensions/VastAdminUpgradeable.sol";
import "./extensions/VastAssetTypes.sol";

import "./VastToken.sol";

contract VastAlphaS1 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    // NonblockingLzAppUpgradeable,
    VastAdminUpgradeable,
    VastAssetTypes
{
    using StringsUpgradeable for uint256;

    VastToken private _tokenContract;

    mapping(uint256 => uint256) private _assetTypes;

    string public imageBaseURI;
    string public animationBaseURI;
    string public externalBaseURI;

    bool public useCustomAdapterParams;

    /**
     * @dev Emitted when `__amount` tokens are received from `__srcChainId` into the `__toAddress` on the local chain.
     * `__nonce` is the inbound nonce.
     */
    event ReceiveFromChain(
        uint16 indexed __srcChainId,
        bytes indexed __srcAddress,
        address indexed __toAddress,
        uint256 __tokenId,
        uint64 __nonce
    );

    /**
     * @dev Emitted when `__amount` tokens are moved from the `__sender` to (`__dstChainId`, `__toAddress`)
     * `__nonce` is the outbound nonce
     */
    event SendToChain(
        address indexed __sender,
        uint16 indexed __dstChainId,
        bytes indexed __toAddress,
        uint256 __tokenId,
        uint64 __nonce
    );

    /**
     * @dev Emitted when `imageBaseURI` is updated.
     */
    event ImageBaseURIUpdate(string __imageBaseURI);

    /**
     * @dev Emitted when `imageBaseURI` is updated.
     */
    event AnimationBaseURIUpdate(string __animationBaseURI);

    /**
     * @dev Emitted when `imageBaseURI` is updated.
     */
    event ExternalBaseURIUpdate(string __externalBaseURI);

    function initialize(
        address __tokenContractAddress
        // address __lzEndpoint
    ) public initializer {
        __ERC721_init("VAST: ALPHA S1", "VastAlphaS1");
        // __NonblockingLzAppUpgradeable_init(__lzEndpoint);
        __Ownable_init();
        __UUPSUpgradeable_init();

        _tokenContract = VastToken(__tokenContractAddress);

        createAdmin(owner());
    }

    // function _nonblockingLzReceive(
    //     uint16 __srcChainId,
    //     bytes memory __srcAddress,
    //     uint64 __nonce,
    //     bytes memory __payload
    // ) internal virtual override {
    //     // decode and load the toAddress
    //     (bytes memory toAddressBytes, uint256 tokenId) = abi.decode(
    //         __payload,
    //         (bytes, uint256)
    //     );
    //     address toAddress;
    //     assembly {
    //         toAddress := mload(add(toAddressBytes, 20))
    //     }

    //     _safeMint(toAddress, tokenId);

    //     emit ReceiveFromChain(
    //         __srcChainId,
    //         __srcAddress,
    //         toAddress,
    //         tokenId,
    //         __nonce
    //     );
    // }

    // function estimateSendFee(
    //     uint16 __dstChainId,
    //     bytes memory __toAddress,
    //     uint256 __tokenId,
    //     bool __useZro,
    //     bytes memory __adapterParams
    // ) public view virtual returns (uint256 nativeFee, uint256 zroFee) {
    //     bytes memory payload = abi.encode(__toAddress, __tokenId);
    //     return
    //         lzEndpoint.estimateFees(
    //             __dstChainId,
    //             address(this),
    //             payload,
    //             __useZro,
    //             __adapterParams
    //         );
    // }

    // function bridge(
    //     address __from,
    //     uint16 __dstChainId,
    //     bytes memory __toAddress,
    //     uint256 __tokenId,
    //     address payable __refundAddress,
    //     address __zroPaymentAddress,
    //     bytes memory __adapterParams
    // ) public payable virtual {
    //     address sender = _msgSender();

    //     require(__from == sender, "Not owned.");

    //     _burn(__tokenId);

    //     bytes memory payload = abi.encode(__toAddress, __tokenId);
    //     if (useCustomAdapterParams) {
    //         _checkGasLimit(__dstChainId, 1, __adapterParams, 0);
    //     } else {
    //         require(
    //             __adapterParams.length == 0,
    //             "LzApp: _adapterParams must be empty."
    //         );
    //     }
    //     _lzSend(
    //         __dstChainId,
    //         payload,
    //         __refundAddress,
    //         __zroPaymentAddress,
    //         __adapterParams
    //     );

    //     uint64 nonce = lzEndpoint.getOutboundNonce(__dstChainId, address(this));

    //     emit SendToChain(__from, __dstChainId, __toAddress, __tokenId, nonce);
    // }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 assetType = _assetTypes[tokenId];

        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            _assetTypeName[assetType],
            '", "image": "',
            imageBaseURI,
            tokenId.toString(),
            '.png", "animation_url": "',
            animationBaseURI,
            tokenId.toString(),
            '.mp4", "external_url": "',
            externalBaseURI,
            tokenId.toString(),
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(dataURI)
                )
            );
    }

    /**
     * @dev Sets new Image Base URI.
     *
     * Requirements:
     *
     * - `__imageBaseURI` must be a string (ie. ipfs://abc/).
     *
     * Emits a {ImageBaseURIUpdate} event.
     */
    function setImageBaseURI(string memory __imageBaseURI) external onlyOwner {
        imageBaseURI = __imageBaseURI;

        emit ImageBaseURIUpdate(__imageBaseURI);
    }

    /**
     * @dev Sets new Animation Base URI.
     *
     * Requirements:
     *
     * - `__animationBaseURI` must be a string (ie. ipfs://abc/).
     *
     * Emits a {AnimationBaseURIUpdate} event.
     */
    function setAnimationBaseURI(string memory __animationBaseURI)
        external
        onlyOwner
    {
        animationBaseURI = __animationBaseURI;

        emit AnimationBaseURIUpdate(__animationBaseURI);
    }

    /**
     * @dev Sets new External Base URI.
     *
     * Requirements:
     *
     * - `__externalBaseURI` must be a string (ie. ipfs://abc/).
     *
     * Emits a {ExternalBaseURIUpdate} event.
     */
    function setExternalBaseURI(string memory __externalBaseURI)
        external
        onlyOwner
    {
        externalBaseURI = __externalBaseURI;

        emit ExternalBaseURIUpdate(__externalBaseURI);
    }

    function _getDiscount(uint256 __amount, uint256 __maxCount)
        private
        pure
        returns (uint256)
    {
        if (__maxCount < 10) {
            return 0;
        }

        uint256 percentage = (__amount * (10**2)) / __maxCount;

        uint256 discount = 0;
        if (percentage >= 80) {
            discount = 50;
        } else if (percentage >= 60) {
            discount = 40;
        } else if (percentage >= 40) {
            discount = 30;
        } else if (percentage >= 20) {
            discount = 20;
        }

        return discount;
    }

    function getTokenContract() external view onlyOwner returns (VastToken) {
        return _tokenContract;
    }

    function setTokenContract(address __tokenContractAddress)
        external
        onlyOwner
    {
        _tokenContract = VastToken(__tokenContractAddress);
    }

    function balanceOfType(address __account, uint256 __assetType)
        public
        view
        returns (uint256)
    {
        uint256 balance = balanceOf(__account);
        uint256 total = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 token = tokenOfOwnerByIndex(__account, i);
            if (_assetTypes[token] == __assetType) {
                total++;
            }
        }

        return total;
    }

    /**
     * @dev Internal mint function.
     *
     * Requirements:
     *
     * - `__account` The address receiving the mint.
     * - `__type` The ID of the token to mint.
     * - `__amount` The number of tokens to mint.
     */
    function _callMint(
        address __account,
        uint256 __type,
        uint256 __amount
    ) private {
        require(__type <= _latestAssetTypeId, "Asset type not found");
        require(__amount > 0, "Invalid amount");
        require(
            _assetTypeCurrentCount[__type] + __amount <=
                _assetTypeMaxCount[__type],
            "Not enough inventory"
        );

        uint256 nextId = totalSupply() + 1;
        for (uint256 n = 0; n < __amount; n++) {
            _safeMint(__account, nextId + n);
            _assetTypes[nextId + n] = __type;
        }

        _assetTypeCurrentCount[__type] =
            _assetTypeCurrentCount[__type] +
            __amount;
    }

    /**
     * @dev Internal mint function.
     *
     * Requirements:
     *
     * - `__account` The address receiving the mint.
     * - `__types` An array of token id(s).
     * - `__amounts` An array of token amount(s).
     */
    function _callMintBatch(
        address __account,
        uint256[] memory __types,
        uint256[] memory __amounts
    ) private {
        for (uint256 i = 0; i < __types.length; i++) {
            require(__types[i] <= _latestAssetTypeId, "Asset not found");
            require(__amounts[i] > 0, "Invalid amount");
            require(
                _assetTypeCurrentCount[__types[i]] + __amounts[i] <=
                    _assetTypeMaxCount[__types[i]],
                "Not enough inventory"
            );

            for (uint256 n = 0; n < __amounts[i]; n++) {
                _safeMint(__account, __types[i]);
            }

            _assetTypeCurrentCount[__types[i]] =
                _assetTypeCurrentCount[__types[i]] +
                __amounts[i];
        }
    }

    /**
     * @dev Mints token(s) as admin.
     *
     * Requirements:
     *
     * - `__account` The account address to receive the mint.
     * - `__type` The type of the token to mint.
     * - `__amount` The number of tokens to mint.
     */
    function adminMint(
        address __account,
        uint256 __type,
        uint256 __amount
    ) external onlyAdmin {
        _callMint(__account, __type, __amount);
    }

    /**
     * @dev Mints token(s) as admin.
     *
     * Requirements:
     *
     * - `__account` The account address to receive the mint.
     * - `__types` The type(s) the token(s) to mint.
     * - `__amounts` The number of token(s) to mint.
     */
    function adminMintBatch(
        address __account,
        uint256[] memory __types,
        uint256[] memory __amounts
    ) external onlyAdmin {
        _callMintBatch(__account, __types, __amounts);
    }

    /**
     * @dev Mints token(s) as admin.
     *
     * Requirements:
     *
     * - `__account` The account address to receive the mint.
     * - `__type` The type of the token to mint.
     * - `__amount` The number of tokens to mint.
     */
    function adminMintMany(
        address[] memory __accounts,
        uint256 __type,
        uint256 __amount
    ) external onlyAdmin {
        for (uint256 i = 0; i < __accounts.length; i++) {
            _callMint(__accounts[i], __type, __amount);
        }
    }

    function _beforeMint(uint256 __type, uint256 __amount)
        private
        view
        returns (uint256)
    {
        require(_assetTypeStatus[__type] == 2, "Public sale disabled");

        uint256 discount = _getDiscount(__amount, _assetTypeMaxCount[__type]);

        uint256 usdTotal = _assetTypeCost[__type] * __amount;
        if (discount > 0) {
            usdTotal = usdTotal - ((usdTotal * discount) / (10**2));
        }

        return usdTotal;
    }

    /**
     * @dev Mints token(s) (public sale).
     *
     * Requirements:
     *
     * - `__type` The type of the token to mint.
     * - `__amount` The number of tokens to mint.
     */
    function mint(uint256 __type, uint256 __amount)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 usdTotal = _beforeMint(__type, __amount);

        require(
            _tokenContract.balanceOf(msg.sender) >= usdTotal,
            "Not enough points"
        );

        _tokenContract.redeem(msg.sender, usdTotal);

        _callMint(msg.sender, __type, __amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Pauses public sale.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses public sale.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
