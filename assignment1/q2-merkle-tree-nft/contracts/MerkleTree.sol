// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title MerkleTree contract
/// @author Manav Darji
/// @notice Merkle tree implementation with insert and verify functionality
contract MerkleTree {
    // denotes total height of tree
    uint256 internal height;

    // denotes the root hash of tree
    bytes32 public rootHash;

    // denotes the total number of leaves in the tree
    uint256 internal leaves;

    // the tree itself
    bytes32[][] internal tree;

    // leaf node to index mapping
    mapping(bytes32 => uint256) internal dataToLeafIndex;

    ///@notice Initializes an empty tree with zero leafes with given height
    ///@param _height height of the tree
    constructor(uint256 _height) {
        height = _height;
        leaves = 0;
        bytes32 initialHash = bytes32(0);

        // iterate over the height and fill in the initial hashes
        for (int256 i = int256(_height); i >= 0; i--) {
            uint256 length = 2**uint256(i);
            bytes32[] memory level = new bytes32[](length);
            for (uint256 j = 0; j < length; j++) {
                level[j] = initialHash;
            }
            tree.push(level); // push a row in tree
            initialHash = keccak256(abi.encode(initialHash, initialHash)); // update the hash
        }
        rootHash = initialHash; // write the root hash
    }

    ///@notice Inserts a leaf into the tree
    ///@param _hash hash of the leaf to be inserted
    function insert(bytes32 _hash) external {
        require(leaves <= 2**height, "tree overflow"); // see if we can accomodate new leafes
        _insert(_hash); // call the internal functions
        dataToLeafIndex[_hash] = leaves + 1; // adding by incrementing so that we can check for invalid index
        leaves++; // increment the number of leaves
    }

    ///@notice Inserts a leaf into the tree
    ///@dev Internal function
    ///@dev complexity O(height)
    ///@param _hash hash of the leaf to be inserted
    function _insert(bytes32 _hash) internal {
        uint256 _leaves = leaves;
        uint256 _height = height;
        uint256 _index = 1;
        tree[0][_leaves] = _hash; // insert the leaf itself first

        // this will loop over tree and update the hashes
        while (_height > 0) {
            if (_leaves % 2 == 0) {
                tree[_index][_leaves / 2] = keccak256(
                    abi.encode(
                        tree[_index - 1][_leaves],
                        tree[_index - 1][_leaves + 1]
                    )
                );
            } else {
                tree[_index][_leaves / 2] = keccak256(
                    abi.encode(
                        tree[_index - 1][_leaves - 1],
                        tree[_index - 1][_leaves]
                    )
                );
            }
            _leaves = _leaves / 2;
            _index++;
            _height--;
        }
        rootHash = tree[_index - 1][0]; // update the root hash
    }

    /// @notice getProofs will return the merkle proofs required to verify the given `_leaf`
    /// @param _leaf The leaf whose proofs is required
    /// @return proofs The list of merkle proofs
    function getProofs(bytes32 _leaf) public view returns (bytes32[] memory) {
        uint256 _index = dataToLeafIndex[_leaf]; // fetch the leaf index
        require(_index > 0, "invalid leaf"); // check if the leaf if present in tree
        _index--;
        bytes32[] memory proofs = new bytes32[](height);
        uint256 _height = height;

        // this will loop over tree and append the sibling hashes to the proofs array
        while (_height > 0) {
            if (_index % 2 == 0) {
                proofs[height - _height] = tree[height - _height][_index + 1];
            } else {
                proofs[height - _height] = tree[height - _height][_index - 1];
            }
            _index = _index / 2;
            _height--;
        }
        return proofs;
    }

    /// @notice verify will verify the given `_leaf`, given the merkle proofs
    /// @param _leaf The leaf/data to verify
    /// @param _proofs The list of merkle proofs
    /// @param generateProof If true, it will call `getProofs` internally and use that set of proofs
    function verify(
        bytes32 _leaf,
        bytes32[] memory _proofs,
        bool generateProof
    ) public view returns (bool) {
        // check if we have to generate proofs. If yes, call and get those
        if (generateProof) {
            _proofs = getProofs(_leaf);
        }
        uint256 _index = dataToLeafIndex[_leaf]; // fetch the leaf index
        if (!generateProof) {
            require(_index > 0, "invalid leaf"); // check if the leaf if present in tree
        }
        _index--;
        uint256 _height = height;
        bytes32 hash;

        // iterate over the proofs and calculate the root hash
        for (uint256 i = 0; i < _proofs.length; i++) {
            if (_index % 2 == 0) {
                hash = keccak256(
                    abi.encode(tree[height - _height][_index], _proofs[i])
                );
            } else {
                hash = keccak256(
                    abi.encode(_proofs[i], tree[height - _height][_index])
                );
            }
            _index = _index / 2;
            _height--;
        }
        // check if our calculated hash matches with the tree's root hash
        // if it matches, then the leaf is present in the tree, else not
        return rootHash == hash;
    }
}
