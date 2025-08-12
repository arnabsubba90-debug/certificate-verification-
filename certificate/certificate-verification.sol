// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CertificateVerification
 * @dev A smart contract for storing and verifying educational/professional certificates
 */
contract CertificateVerification {
    
    // Structure to store certificate details
    struct Certificate {
        string recipientName;
        string institutionName;
        string courseName;
        string certificateHash; // IPFS hash or document hash
        uint256 issueDate;
        bool isValid;
        address issuer;
    }
    
    // Mapping from certificate ID to certificate details
    mapping(uint256 => Certificate) public certificates;
    
    // Mapping to track authorized issuers (institutions)
    mapping(address => bool) public authorizedIssuers;
    
    // Contract owner
    address public owner;
    
    // Certificate counter
    uint256 private certificateCounter;
    
    // Events
    event CertificateIssued(
        uint256 indexed certificateId,
        string recipientName,
        string institutionName,
        address indexed issuer
    );
    
    event CertificateRevoked(uint256 indexed certificateId, address indexed revokedBy);
    event IssuerAuthorized(address indexed issuer, string institutionName);
    event IssuerRevoked(address indexed issuer);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Only authorized issuers can issue certificates");
        _;
    }
    
    modifier validCertificate(uint256 _certificateId) {
        require(_certificateId > 0 && _certificateId <= certificateCounter, "Invalid certificate ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        certificateCounter = 0;
    }
    
    /**
     * @dev Authorize an institution to issue certificates
     * @param _issuer Address of the institution
     * @param _institutionName Name of the institution
     */
    function authorizeIssuer(address _issuer, string memory _institutionName) 
        external 
        onlyOwner 
    {
        require(_issuer != address(0), "Invalid issuer address");
        require(!authorizedIssuers[_issuer], "Issuer already authorized");
        
        authorizedIssuers[_issuer] = true;
        emit IssuerAuthorized(_issuer, _institutionName);
    }
    
    /**
     * @dev Issue a new certificate
     * @param _recipientName Name of the certificate recipient
     * @param _institutionName Name of the issuing institution
     * @param _courseName Name of the course/program
     * @param _certificateHash Hash of the certificate document (IPFS hash)
     */
    function issueCertificate(
        string memory _recipientName,
        string memory _institutionName,
        string memory _courseName,
        string memory _certificateHash
    ) external onlyAuthorizedIssuer returns (uint256) {
        require(bytes(_recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(_courseName).length > 0, "Course name cannot be empty");
        require(bytes(_certificateHash).length > 0, "Certificate hash cannot be empty");
        
        certificateCounter++;
        
        certificates[certificateCounter] = Certificate({
            recipientName: _recipientName,
            institutionName: _institutionName,
            courseName: _courseName,
            certificateHash: _certificateHash,
            issueDate: block.timestamp,
            isValid: true,
            issuer: msg.sender
        });
        
        emit CertificateIssued(certificateCounter, _recipientName, _institutionName, msg.sender);
        return certificateCounter;
    }
    
    /**
     * @dev Verify if a certificate is valid and get its details
     * @param _certificateId ID of the certificate to verify
     * @return recipientName Name of the certificate recipient
     * @return institutionName Name of the issuing institution
     * @return courseName Name of the course/program
     * @return certificateHash Hash of the certificate document
     * @return issueDate Timestamp when certificate was issued
     * @return isValid Whether the certificate is currently valid
     * @return issuer Address of the institution that issued the certificate
     */
    function verifyCertificate(uint256 _certificateId) 
        external 
        view 
        validCertificate(_certificateId)
        returns (
            string memory recipientName,
            string memory institutionName,
            string memory courseName,
            string memory certificateHash,
            uint256 issueDate,
            bool isValid,
            address issuer
        ) 
    {
        Certificate memory cert = certificates[_certificateId];
        return (
            cert.recipientName,
            cert.institutionName,
            cert.courseName,
            cert.certificateHash,
            cert.issueDate,
            cert.isValid,
            cert.issuer
        );
    }
    
    /**
     * @dev Revoke a certificate (only by issuer or owner)
     * @param _certificateId ID of the certificate to revoke
     */
    function revokeCertificate(uint256 _certificateId) 
        external 
        validCertificate(_certificateId)
    {
        Certificate storage cert = certificates[_certificateId];
        require(
            msg.sender == cert.issuer || msg.sender == owner,
            "Only issuer or owner can revoke certificate"
        );
        require(cert.isValid, "Certificate is already revoked");
        
        cert.isValid = false;
        emit CertificateRevoked(_certificateId, msg.sender);
    }
    
    /**
     * @dev Get total number of certificates issued
     * @return Total certificate count
     */
    function getTotalCertificates() external view returns (uint256) {
        return certificateCounter;
    }
}
