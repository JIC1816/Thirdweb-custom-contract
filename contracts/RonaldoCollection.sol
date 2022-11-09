// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract RonaldoCollection is ERC721Base, PermissionsEnumerable {
    /** STATE VARIABLES */

    uint256 public _price = 0.01 ether;
    bool public _paused = false;
    uint256 public _maxTokenIds = 10;
    uint256 public tokenIds;
    string public _baseTokenURI;
    uint8 public maxWhitelistedaddresses = 3;
    uint8 public numAddressesWhitelisted;
    mapping(address => bool) public whitelistedAddresses;
    bool public presaleStarted;
    uint256 public presaleEnded;

    /** CONSTRUCTOR */

    // As you can see, it's possible to set the baseURI when you first deploy this contract. This way, this contract
    // can be used in more than a deployment, because the baseURI isn't static.
    // I also made this function payable. This way, the contract can have an initial ETH balance when deployed.

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) payable ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseURI;
    }

    /** MODIFIERS */

    //I learned that this is an importante feature if you want to prevent a security problem from escalating.

    modifier onlyWhenNotPaused() {
        require(
            !_paused,
            "This contract is currently in pause. Please wait until we fix the issue."
        );
        _;
    }

    /** FUNCTIONS */

    // This function allows anyone to get the contract balance.
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // This function allows the owner to add an address to the whitelist mapping.
    function addToWhitelist(address whitelisted)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            numAddressesWhitelisted < maxWhitelistedaddresses,
            "You have reached the maximum number of whitelisted addresses."
        );
        whitelistedAddresses[whitelisted] = true;
        numAddressesWhitelisted++;
    }

    // Through this function you can check if an addresss is whitelisted or not.
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }

    // This function allows the owner to start the presale.
    function startPresale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleStarted = true;
        presaleEnded = block.timestamp + 15 minutes;
    }

    // Presale minting function.
    function presaleMint() public payable onlyWhenNotPaused {
        require(
            presaleStarted && block.timestamp < presaleEnded,
            "Presale has not started yet or has ended."
        );
        require(isWhitelisted(msg.sender), "You are not whitelisted.");
        require(tokenIds < _maxTokenIds, "Excendeed max tokenIds supply.");
        require(msg.value >= _price, "You need to send more ETH.");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    // Public minting function. Only available after presale ended.
    function mint() public payable onlyWhenNotPaused {
        require(
            presaleStarted && block.timestamp > presaleEnded,
            "Presale has not ended yet. Please wait."
        );
        require(tokenIds < _maxTokenIds, "Excendeed max tokenIds supply.");
        require(msg.value >= _price, "You need to send more ETH.");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    // This function returns the tokenURI for a given token.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // In case of emergency, we can pause the contract with this function.

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    // This function uses onlyOwner modifier and is useful to withdraw the ether obtained from minting.

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // As Solidity by example explains, this functions are required if some people make errors when sending transactions.
    // But also this functions are useful if someone wants to donate ETH directly to the contract without calling a function.

    receive() external payable {}

    fallback() external payable {}
}
