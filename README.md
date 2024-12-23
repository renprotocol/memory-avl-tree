# `🎄 memory-avl-tree`

MemoryAVLTree is a Solidity library that provides an in-memory self-balancing binary search tree
implementation. Insertions and lookups guarantee O(log n) complexity without requiring storage. The tree is persisted in memory until the end of the transaction.

## Primary Use Case

One of the primary use cases for the MemoryAVLTree library is to cheaply and pseudo-randomly sort a
list of items using a seed like the blockhash. This can be particularly useful when dealing with
arrays of addresses that need to be sorted in a deterministic but unpredictable manner.

### Example: Sorting an `address[]` using MemoryAVLTree

Suppose you have an `address[]` that needs to be pseudo-randomly sorted:

```solidity
address[] public participants = [
0x1234567890123456789012345678901234567890,
0x2345678901234567890123456789012345678901,
0x3456789012345678901234567890123456789012,
...
];
```

To sort this array using MemoryAVLTree, you can follow these steps:

1. Create a new instance of the MemoryAVLTree:

    ```solidity
    using MemoryAVLTree for MemoryAVLTree.Tree;
    MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();
    ```

2. Generate a pseudo-random seed using the blockhash:

    ```solidity
    bytes32 seed = blockhash(block.number - 1);
    ```

3. Iterate through the `participants` array and insert each address into the tree, using the hash of
   the address concatenated with the seed as the key:

    ```solidity
    for (uint256 i = 0; i < participants.length; i++) {
        bytes32 key = keccak256(abi.encodePacked(participants[i], seed));
        tree.insert(key, bytes32(uint256(uint160(participants[i]))));
    }
    ```

4. Perform an inorder traversal of the tree to retrieve the sorted addresses:
    ```solidity
    bytes32[] memory sortedKeys = tree.inorderTraversal();
    address[] memory sortedParticipants = new address[](sortedKeys.length);
    for (uint256 i = 0; i < sortedKeys.length; ++i) {
        sortedParticipants[i] = address(uint160(uint256(sortedKeys[i])));
    }
    ```

By using MemoryAVLTree, the sorting operation is performed entirely in memory with a time
complexity of O(n log n), which is significantly cheaper than using storage operations. The
resulting sorted array is deterministic based on the chosen seed but unpredictable without knowing
the seed in advance.

## Testing

The MemoryAVLTree library comes with a comprehensive test suite located in the `test` directory.
The tests cover various scenarios, including:

-   Creating an empty tree
-   Inserting and finding elements
-   Updating existing keys
-   Performing rotations (left, right, left-right, right-left)
-   Stress testing with a large number of elements
-   Verifying the inorder traversal produces a sorted output

To run the tests, you can use the Foundry testing framework.

## API

The MemoryAVLTree library provides the following main functions:

-   `createTree()`: Creates a new empty AVL tree.
-   `insert(Tree memory self, bytes32 key, bytes32 value)`: Inserts a key-value pair into the tree.
-   `find(Tree memory self, bytes32 key)`: Finds a value in the tree by its key.
-   `inorderTraversal(Tree memory self)`: Performs an inorder traversal of the tree, returning the
    keys in sorted order.

For more details on the library's implementation and usage, please refer to the source code and
inline documentation.

## License

The MemoryAVLTree library is released under the MIT License.
