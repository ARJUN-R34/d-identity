// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Destructible.sol";

contract DIdentity is Destructible {
    using SafeMath for uint256;

    // CONSTANTS
    uint256 constant public DID_NAME_PRICE = 0.1 ether;
    uint256 constant public DID_NAME_COST_SHORT_ADDITION = 0.001 ether;
    uint256 constant public DID_EXPIRATION_DATE = 365 days;
    uint256 constant public DID_NAME_MIN_LENGTH = 5;
    uint256 constant public DID_NAME_EXPENSIVE_LENGTH = 0.001 ether;
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
    modifier collectDIDNamePayment(string memory name) {
        uint256 namePrice = getPrice(name);

        require(msg.value >= namePrice, "Insufficient amount.");
        _;
    }

    // modifier to check if the function caller is the name owner
    modifier isDIDOwner(string memory name) {
        string memory IdName = identityDetails[msg.sender].name;

        require(keccak256(abi.encode(IdName)) == keccak256(abi.encode(name)), "You are not the owner of this name.");
        _;
    }

    // modifier to check if the name length is within the length
    modifier isDIDNameLengthAllowed(string memory name) {
        require(bytes(name).length >= DID_NAME_MIN_LENGTH, "Name is too short.");
        _;
    }

    // events
    event LogDomainNameRegistered(uint256 indexed timestamp, string name);
    event LogReceipt(uint256 indexed timestamp, string name, uint256 amountInWei, uint256 expires);
    event LogNameRenewed(uint256 indexed timestamp, string name, address indexed owner);
    event LogDIDEdited(uint256 indexed timestamp, string name, address owner);
    event LogDIDTransferred(uint256 indexed timestamp, string name, address indexed owner, address newOwner);

    // function to get the receipt hash
    function getReceiptKey(string memory name) public view returns(bytes32) {
        return keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
    }

    // function to get the price
    function getPrice(string memory name) public pure returns(uint256) {
        if (bytes(name).length < DID_NAME_EXPENSIVE_LENGTH) {
            return DID_NAME_PRICE + DID_NAME_COST_SHORT_ADDITION;
        }

        return DID_NAME_PRICE;
    }

    // function to register the name
    function register(string memory name) public payable isDIDNameLengthAllowed(name) isAvailable(msg.sender) collectDIDNamePayment(name) {

        IdentityDetails memory newID = IdentityDetails(
            {
                name: name,
                expiryDate: block.timestamp + DID_EXPIRATION_DATE
            }
        );

        identityDetails[msg.sender] = newID;
        
        Receipt memory newReceipt = Receipt(
            {
                amountInWei: DID_NAME_PRICE,
                timestamp: block.timestamp,
                expiry: block.timestamp + DID_EXPIRATION_DATE
            }
        );

        bytes32 receiptKey = getReceiptKey(name);
        
        paymentReceipts[msg.sender].push(receiptKey);
        
        receiptDetails[receiptKey] = newReceipt;

        emit LogReceipt(block.timestamp, name, DID_NAME_PRICE, block.timestamp + DID_EXPIRATION_DATE);
    
        emit LogDomainNameRegistered(block.timestamp, name);
    }

    // function to renew the name
    function renewDomainName(string memory name) public payable isDIDOwner(name) collectDIDNamePayment(name) {

        identityDetails[msg.sender].expiryDate += 365 days;
        
        Receipt memory newReceipt = Receipt(
            {
                amountInWei: DID_NAME_PRICE,
                timestamp: block.timestamp,
                expiry: block.timestamp + DID_EXPIRATION_DATE
            }
        );

        bytes32 receiptKey = getReceiptKey(name);
        
        paymentReceipts[msg.sender].push(receiptKey);

        receiptDetails[receiptKey] = newReceipt;

        emit LogNameRenewed(block.timestamp, name, msg.sender);

        emit LogReceipt(block.timestamp, name, DID_NAME_PRICE, block.timestamp + DID_EXPIRATION_DATE);
    }

    // function to edit the name
    function edit(string memory oldName, string memory newName) public isDIDOwner(oldName) {
        identityDetails[msg.sender].name = newName;

        emit LogDIDEdited(block.timestamp, newName, msg.sender);
    }

    // function to transfer the name
    function transferDomain(string memory name, address newOwner) public isDIDOwner(name) {
        require(newOwner != address(0));
        
        identityDetails[newOwner] = identityDetails[msg.sender];
        
        emit LogDIDTransferred(block.timestamp, name, msg.sender, newOwner);
    }

    // function to get the name
    function getIP() public view returns (string memory) {
        return identityDetails[msg.sender].name;
    }

    // function to get the payment receipts
    function getReceiptList() public view returns (bytes32[] memory) {
        return paymentReceipts[msg.sender];
    }

    // function to get a receipt details
    function getReceipt(bytes32 receiptKey) public view returns (uint256, uint256, uint256) {
        return (receiptDetails[receiptKey].amountInWei, receiptDetails[receiptKey].timestamp, receiptDetails[receiptKey].expiry);
    }

    // function to withdraw the funds
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}