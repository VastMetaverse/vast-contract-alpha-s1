//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StarLedgerNFT is
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    string[] private _urisToMint;
    uint256 private _cost;
    bytes32 private _presaleListMerkleTreeRoot;
    bool private _presaleListMintEnabled;
    uint256 private _presaleListedTokensLimit;
    mapping(address => bool) private _admins;
    mapping(address => bool) private presaleListed;
    mapping(address => uint256) private _presaleListClaimedTokens;
    uint256 private _mintCount;

    constructor() ERC721("StarLedgerNFT", "STRLGR") {
        _admins[owner()] = true;
    }

    function adminMint(uint256 amount) external onlyAdmin {
        _callMint(amount);
    }

    function presaleListMint(uint256 amount)
        external
        payable
        withEnoughMetis(amount)
        nonReentrant
    {
        require(_presaleListMintEnabled, "Presale list minting disabled");
        require(
            _presaleListClaimedTokens[msg.sender] + amount <=
                _presaleListedTokensLimit,
            "Presale list tokens limit reached"
        );
        require(
            presaleListed[msg.sender],
            "caller is not presaleListed"
        );
        _presaleListClaimedTokens[msg.sender] += amount;
        _callMint(amount);
    }

    function mint(uint256 amount)
        public
        payable
        whenNotPaused
        withEnoughMetis(amount)
        nonReentrant
    {
        _callMint(amount);
    }

    function _callMint(uint256 amount) internal {
        require(amount > 0, "You can't mint 0 tokens");
        require(_urisToMint.length >= amount, "Not enough tokens to mint");
        uint256 currentSupply = totalSupply();
        for (uint256 i = 1; i <= amount; i++) {
            string memory nextStar = _urisToMint[_urisToMint.length - 1];
            _urisToMint.pop();
            uint256 nextTokenId = currentSupply + i;
            _safeMint(msg.sender, nextTokenId);
            _setTokenURI(nextTokenId, nextStar);
            _mintCount++;
        }
    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI)
        external
        onlyOwner
    {
        require(_exists(tokenId), "Token does not exist");

        _setTokenURI(tokenId, newTokenURI);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function urisToMint() external view onlyOwner returns (string[] memory) {
        return _urisToMint;
    }

    function addUrisToMint(string[] calldata uris) external onlyOwner {
        for (uint256 i = 0; i < uris.length; i++) {
            _urisToMint.push(uris[i]);
        }
    }

    function cost() external view returns (uint256) {
        return _cost;
    }

    function setCost(uint256 newCost) external onlyOwner {
        _cost = newCost;
    }

    function addToPresaleList(address[] memory addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            presaleListed[addresses[i]] = true;
        }
    }

    function removeFromPresaleList(address[] memory addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            delete presaleListed[addresses[i]];
        }
    }

    function isPresaleListed(address _user) external view returns (bool) {
        return presaleListed[_user];
    }

    function presaleListMintEnabled() external view returns (bool) {
        return _presaleListMintEnabled;
    }

    function setPresaleListMintEnabled(bool enabled) external onlyOwner {
        _presaleListMintEnabled = enabled;
    }

    function presaleListedTokensLimit() external view returns (uint256) {
        return _presaleListedTokensLimit;
    }

    function setPresaleListedTokensLimit(uint256 limit) external onlyOwner {
        _presaleListedTokensLimit = limit;
    }

    function addAdmin(address account) external onlyOwner {
        _admins[account] = true;
    }

    function removeAdmin(address account) external onlyOwner {
        delete _admins[account];
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Caller is not an admin");
        _;
    }

    modifier withEnoughMetis(uint256 amount) {
        require(msg.value >= _cost * amount, "Not enough Metis");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintCount() public view returns (uint256) {
        return _mintCount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
