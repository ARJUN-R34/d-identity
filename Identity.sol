// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Destructible.sol";

contract DIdentity is Destructible {
    using SafeMath for uint256;

    // CONSTANTS
    uint256 constant public DOMAIN_NAME_PRICE = 0.1 ether;
    uint256 constant public DOMAIN_NAME_COST_SHORT_ADDITION = 0.001 ether;
    uint256 constant public DOMAIN_EXPIRATION_DATE = 365 days;
    uint256 constant public DOMAIN_NAME_MIN_LENGTH = 5;
    bytes8 constant public BYTES_DEFAULT_VALUE = bytes8(0x00);

    // struct to store the IdentityDetails
    struct IdentityDetails {
        string name;
        uint256 expiryDate;
    }

    // struct to store the renewal transaction details
    struct Receipt {
        uint256 timestamp;
        uint256 amountInWei;
        uint256 expiry;
    }

    // mapping to get the identity details using the public address
    mapping(address => IdentityDetails) public identityDetails;

    // mapping to get the receipt details using its hash
    mapping(bytes32 => Receipt) public receiptDetails;

    // mapping to get all the receipt hashes/keys/ids for certain address
    mapping(address => bytes32[]) public paymentReceipts;
    
    // modifier to check if the name is available
    modifier isAvailable(address owner) {
        require(identityDetails[owner].expiryDate > block.timestamp, "Identity is not available.");
        _;
    }

    // modifier to check if the amount paid is valid for the given name
    modifier collectDomainNamePayment(bytes memory name) {
        uint namePrice = getPrice(name);

        require(msg.value >= namePrice, "Insufficient amount.");
        _;
    }

    // modifier to check if the function caller is the name owner
    modifier isDomainOwner(string memory name) {
        require(identityDetails[msg.sender].name == name, "You are not the owner of this domain.");
        _;
    }
}