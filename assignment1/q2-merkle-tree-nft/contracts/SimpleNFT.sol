// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "./../node_modules/@openzeppelin/contracts/utils/Base64.sol";
import "./MerkleTree.sol";

/// @title SimpleNFT contract
/// @author Manav Darji
/// @notice A simple NFT store, which allows users to mint NFT's and stores the hash in a merkle tree.
contract SimpleNFT is ERC721URIStorage {
    // Using open zeppelin's counters for security and gas optimization
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // The merkle tree
    MerkleTree private tree;

    // Initializing the ERC721 parent contract with given name
    constructor(uint256 _height) ERC721("Manav Darji", "MAD") {
        tree = new MerkleTree(_height);
    }

    /// @notice mint will mint a new NFT for `user` address with given metedata
    /// @dev Uses base64 encoding on `name` and `description` fields to generate tokenURI
    /// @dev Adds the hash of id and metadata to a merkle tree
    /// @param user The user address against which the NFT is minted
    /// @param name The name field in metadata
    /// @param description The description field in metadata
    /// @return id The tokenID of the NFT
    /// @return hash The hash of the data (msg.sender, user, id, tokenURI)
    function mint(
        address user,
        string memory name,
        string memory description
    ) public returns (uint256, bytes32) {
        // Increment the tokenID for new minting and fetch it
        _tokenIds.increment();
        uint256 id = _tokenIds.current();

        // Mint the NFT with fetched id against the `user` address using parent contract's function
        _mint(user, id);

        // The token URI is stringified version of base64 encoding
        // of `name: description` format.
        string memory tokenURI = string(
            abi.encode(
                "data:application/json;base64,",
                Base64.encode(abi.encode(name, ": ", description))
            )
        );

        // set the tokenURI for the same using the parent contract's function
        _setTokenURI(id, tokenURI);

        // calculate the hash of data using Keccak256
        // Also, it uses abi.encode instead abi.encodePacked
        // for collision prevention as we have multiple dynamic data types.
        bytes32 hash = keccak256(abi.encode(msg.sender, user, id, tokenURI));

        // Add the hash to the merkle tree
        tree.insert(hash);

        // return the tokenID
        return (id, hash);
    }

    /// @notice getProofs will return the merkle proofs required to verify the given `_leaf`
    /// @dev calls parent function
    /// @param _leaf The leaf whose proofs is required
    /// @return proofs The list of merkle proofs
    function getProofs(bytes32 _leaf) public view returns (bytes32[] memory) {
        return tree.getProofs(_leaf);
    }

    /// @notice verify will verify the given `_leaf`, given the merkle proofs
    /// @dev calls parent function
    /// @param _leaf The leaf/data to verify
    /// @param _proofs The list of merkle proofs
    /// @param generateProof If true, it will call `getProofs` internally and use that set of proofs
    function verify(
        bytes32 _leaf,
        bytes32[] memory _proofs,
        bool generateProof
    ) public view returns (bool) {
        return tree.verify(_leaf, _proofs, generateProof);
    }
}
