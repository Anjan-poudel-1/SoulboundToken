// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./AccessControl.sol";
pragma solidity ^0.8.6;

/// @title Contract to distribute acheivements

contract DistributeTokens is ERC1155, CommonAccessControl {
    string public name;
    uint totalTokensMinted;

    uint public numberOfAvailableTokens;

    struct Token {
        uint tokenId;
        string tokenUri;
        bool isActive;
    }

    event UserEligibleToMint(address user, uint tokenId);
    event RevokedUserEligibility(address user, uint tokenId);
    event TokenMinted(address user, uint tokenId);
    event AddedNewToken(uint tokenId, string uri);
    event PermanentURI(string _value, uint256 indexed _id);

    mapping(uint => Token) public availableTokens;

    //Token id maps to number of tokens minted
    mapping(uint => uint) public tokensMinted;

    //maps tokenId to user that are eligible or not
    mapping(uint => mapping(address => bool)) public eligibleAddresses;

    // maps tokenId to user that have claimed the token;
    mapping(uint => mapping(address => bool)) public claimedAddresses;

    modifier tokenExists(uint _tokenId) {
        Token memory _tokenToCheck = availableTokens[_tokenId];
        require(_tokenToCheck.isActive, "Token not available");
        _;
    }

    constructor(
        string memory _uri,
        string memory _name
    ) ERC1155(_uri) CommonAccessControl(msg.sender) {
        owner = msg.sender;
        name = _name;
    }

    /**
     * @dev function to add user eligible to claim the token
     * @param _tokenId Id of the token
     * @param _user address of the user
     */
    function addEligibleUser(
        uint _tokenId,
        address _user
    ) public only_admin tokenExists(_tokenId) {
        require(!eligibleAddresses[_tokenId][_user], "Already Eligible user");
        eligibleAddresses[_tokenId][_user] = true;
        emit UserEligibleToMint(_user, _tokenId);
    }

    /**
     * @dev function to revoke user eligible to claim the token
     * @param _tokenId Id of the token
     * @param _user address of the user
     */
    function revokeUserEligibility(
        uint _tokenId,
        address _user
    ) public only_admin tokenExists(_tokenId) {
        require(eligibleAddresses[_tokenId][_user], "User not eligible");
        require(
            !claimedAddresses[_tokenId][_user],
            "User already claimed token"
        );
        eligibleAddresses[_tokenId][_user] = false;
        emit RevokedUserEligibility(_user, _tokenId);
    }

    /**
     * @dev function to look at metadata of the token
     * @param id Id of the token
     */
    function uri(uint256 id) public view override returns (string memory) {
        Token memory _displayToken = availableTokens[id];
        return _displayToken.tokenUri;
    }

    /**
     * @dev function to add new token by admin.
     *  uri of the token will be added and mapped to token ID
     * @param _uri URI of the token
     */
    function addNewToken(string memory _uri) public only_owner {
        numberOfAvailableTokens++;

        Token memory _toAddToken = Token(numberOfAvailableTokens, _uri, true);

        availableTokens[numberOfAvailableTokens] = _toAddToken;
        emit AddedNewToken(numberOfAvailableTokens, _uri);
        emit PermanentURI(_uri, numberOfAvailableTokens);
    }

    /**
     * @dev function that checks every time before transfer of the token
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        // Custom logic here, e.g., checking special conditions
        require(from == address(0), "Err: token transfer is BLOCKED");
        super._update(from, to, ids, amounts);
    }

    /**
     * @dev function to mint token, to be called by user
     * @param _tokenId Id of the token to mint
     */
    function mintToken(uint _tokenId) public tokenExists(_tokenId) {
        require(
            eligibleAddresses[_tokenId][msg.sender],
            "Cannot mint the token"
        );
        require(
            !claimedAddresses[_tokenId][msg.sender],
            "Already Claimed the token"
        );

        _mint(msg.sender, _tokenId, 1, "");
        totalTokensMinted++;
        tokensMinted[_tokenId]++;
        claimedAddresses[_tokenId][msg.sender] = true;

        emit TokenMinted(msg.sender, _tokenId);
    }
}
