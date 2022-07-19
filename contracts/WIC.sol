// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Tier {
    uint256 cost;
    string uri;
}

contract WIC is ERC721, ERC721URIStorage, AccessControl {
    
    uint256 public tokenIdCounter;
    uint256 public tierIdCounter;

    //Roles
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant FUND_MANAGER = keccak256("FUND_MANAGER");

    address public acceptedToken;

    //tierId => Tier mapping
    mapping(uint256 => Tier) public tiersById;

    constructor(
        address _acceptedToken
    ) ERC721("Watch Investment Club", "WIC") {
        acceptedToken = _acceptedToken;

         // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(uint256 tier, address to, address from) public {
        require(tier < tierIdCounter);
        IERC20 token = IERC20(acceptedToken);
        token.transferFrom(from, address(this), tiersById[tier].cost);
        _safeMint(to, tokenIdCounter);
        _setTokenURI(tokenIdCounter, tiersById[tier].uri);

        tokenIdCounter++;
    }

    function newTier(uint256 cost, string calldata uri) public{
        require(hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        Tier memory tier;
        tier.cost = cost;
        tier.uri = uri;

        tiersById[tierIdCounter] = tier;
        tierIdCounter++;
    }

    function modifyTier(uint256 tierId, uint256 cost, string calldata uri, bool modCost, bool modUri) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        if(modUri){
            tiersById[tierId].uri = uri;
        }
        if(modCost){
            tiersById[tierId].cost = cost;
        }
    }

    function withdraw(address tokenAddr, uint256 amount) public {
        require(hasRole(FUND_MANAGER, msg.sender) || hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        IERC20 token = IERC20(tokenAddr);
        token.approve(msg.sender, amount);
        token.transferFrom(address(this), msg.sender, amount);
    }

    function setAcceptedToken(address token) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        acceptedToken = token;
    }

    function modifyAdmin(address addr, bool setRole) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        if(setRole){
            _grantRole(ADMIN, addr);
        }
        else{
            _revokeRole(ADMIN, addr);
        }
        
    }

    function modifyFundManager(address addr, bool setRole) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        if(setRole){
            _grantRole(FUND_MANAGER, addr);
        }
        else{
            _revokeRole(FUND_MANAGER, addr);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

        function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
