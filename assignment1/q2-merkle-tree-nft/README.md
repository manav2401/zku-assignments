### Assignment 1: Question 2: Minting an NFT and committing the mint data to a Merkle Tree

- The `mint` function of the ERC721 contract can be used to mint an NFT to any address with a particular name and description. 
- The hash of the data (msg.sender, receiver address, tokenId, and tokenURI) is committed to a Merkle tree using the `insert` function. 
- The `insert` operation is a O(height) complexity operation.
- The `getProofs` and `verify` function are for checking if a particular hash is in the tree or not. (Both are O(height) complexity operations) 
