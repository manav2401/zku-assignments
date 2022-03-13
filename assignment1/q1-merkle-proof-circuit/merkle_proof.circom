pragma circom 2.0.0;

include "./mimcsponge.circom";

// Hash calculates the hash of given set of nodes at a particular height.
template Hash(length) {
  // input signal: the nodes
  signal input in[2 * length];
  // output signal: the hash of set of the given nodes
  signal output out[length];
  // create a component for MiMCSponge hash mechanism
  component mimc[length];

  for (var i = 0; i < length; i++) {
    mimc[i] = MiMCSponge(2, 220, 1);
    mimc[i].ins[0] <== in[i * 2];
    mimc[i].ins[1] <== in[i * 2 + 1];
    mimc[i].k <== 0;
    out[i] <== mimc[i].outs[0];
  }
}

// MerkleProof calculates the merkle root of a tree from given lead nodes.
template MerkleProof(height) {
  // input signal: the leaf nodes, of length 2^height of tree
  signal input leaves[1 << height];
  // output signal: the merkle proof calculated from the leaf nodes
  signal output merkleProof;

  // the tree itself of height `height`
  component tree[height];

  // iterate until we have the root hash
  for (var i = height - 1; i >= 0; i--) {
    var length = 1 << i;
    tree[i] = Hash(length); // create a component for the hash of the current level
    for (var j = 0; j < length; j++) {
      tree[i].in[j * 2] <==  i == height-1 ? leaves[j * 2] : tree[i + 1].out[j * 2]; // write the j*2-th input of the current level
      tree[i].in[(j * 2) + 1] <== i == height-1 ? leaves[(j * 2) + 1] : tree[i + 1].out[(j * 2) + 1]; // write the j*2+1-th input of the current level
    }
  }
  // write the result (root hash) to output signal
  // if height is 0, then the result is the first leaf node itself
  // if height > 0, then write the first (and only) output of tree[0]
  merkleProof <== height == 0 ? leaves[0] : tree[0].out[0];
}

component main {public [leaves] } = MerkleProof(3);
