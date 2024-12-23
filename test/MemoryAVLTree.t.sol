// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MemoryAVLTree.sol";

contract MemoryAVLTreeTest is Test {
    using MemoryAVLTree for MemoryAVLTree.Tree;

    function setUp() public {}

    function testCreateEmptyTree() public pure {
        // Create empty tree and verify root is null
        // Tree: (empty)
        //   root = 0x0
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();
        assertEq(tree.root, 0, "New tree should have null root");
    }

    function testInsertAndFind() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Insert single node:
        //    1
        //   value: 100
        bytes32 key = bytes32(uint256(1));
        bytes32 value = bytes32(uint256(100));

        tree = tree.insert(key, value);
        bytes32 found = tree.find(key);

        assertEq(found, value, "Retrieved value should match inserted value");
    }

    function testFindNonexistentKey() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Tree state:
        //    2
        //   value: 200
        //
        // Searching for key 1 (doesn't exist)
        bytes32 found = tree.find(bytes32(uint256(1)));
        assertEq(found, bytes32(0), "Non-existent key should return zero");
    }

    function testUpdateExistingKey() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Initial insert:
        //    1
        //   value: 100
        //
        // After update:
        //    1
        //   value: 200
        bytes32 key = bytes32(uint256(1));
        bytes32 value1 = bytes32(uint256(100));
        bytes32 value2 = bytes32(uint256(200));

        tree = tree.insert(key, value1);
        tree = tree.insert(key, value2);
        bytes32 found = tree.find(key);

        assertEq(found, value2, "Value should be updated for existing key");
    }

    function testLeftRotation() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Step 1: Initial insert
        //    10 (h=1)
        //    balance = 0
        //
        // Step 2: Insert 20
        //    10 (h=2)
        //      \
        //      20 (h=1)
        //    balance = -1
        //
        // Step 3: Insert 30, triggers left rotation
        //    10 (h=3)                     20 (h=2)
        //      \                         /  \
        //      20 (h=2)      ->       10   30
        //        \                    (h=1) (h=1)
        //        30 (h=1)
        //    balance = -2              balance = 0
        tree = tree.insert(bytes32(uint256(10)), bytes32(uint256(10)));
        tree = tree.insert(bytes32(uint256(20)), bytes32(uint256(20)));
        tree = tree.insert(bytes32(uint256(30)), bytes32(uint256(30)));

        bytes32[] memory keys = tree.inorderTraversal();
        assertEq(uint256(keys[0]), 10, "First key should be 10");
        assertEq(uint256(keys[1]), 20, "Second key should be 20");
        assertEq(uint256(keys[2]), 30, "Third key should be 30");
    }

    function testRightRotation() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Step 1: Initial insert
        //      30 (h=1)
        //      balance = 0
        //
        // Step 2: Insert 20
        //      30 (h=2)
        //     /
        //    20 (h=1)
        //    balance = 1
        //
        // Step 3: Insert 10, triggers right rotation
        //      30 (h=3)                    20 (h=2)
        //     /                           /  \
        //    20 (h=2)         ->       10    30
        //   /                         (h=1)  (h=1)
        //  10 (h=1)
        //  balance = 2                  balance = 0
        tree = tree.insert(bytes32(uint256(30)), bytes32(uint256(30)));
        tree = tree.insert(bytes32(uint256(20)), bytes32(uint256(20)));
        tree = tree.insert(bytes32(uint256(10)), bytes32(uint256(10)));

        bytes32[] memory keys = tree.inorderTraversal();
        assertEq(uint256(keys[0]), 10, "First key should be 10");
        assertEq(uint256(keys[1]), 20, "Second key should be 20");
        assertEq(uint256(keys[2]), 30, "Third key should be 30");
    }

    function testLeftRightRotation() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Step 1: Initial tree
        //    30 (h=2)
        //   /
        //  10 (h=1)
        //  balance = 1
        //
        // Step 2: Insert 20, triggers left-right rotation
        // First rotation (left):           Then rotation (right):
        //    30 (h=3)                        30 (h=3)                      20 (h=2)
        //   /                               /                             /  \
        //  10 (h=2)         ->           20 (h=2)           ->        10    30
        //    \                          /                           (h=1)  (h=1)
        //    20 (h=1)                10 (h=1)
        //  balance = -1             balance = 1                    balance = 0
        tree = tree.insert(bytes32(uint256(30)), bytes32(uint256(30)));
        tree = tree.insert(bytes32(uint256(10)), bytes32(uint256(10)));
        tree = tree.insert(bytes32(uint256(20)), bytes32(uint256(20)));

        bytes32[] memory keys = tree.inorderTraversal();
        assertEq(uint256(keys[0]), 10, "First key should be 10");
        assertEq(uint256(keys[1]), 20, "Second key should be 20");
        assertEq(uint256(keys[2]), 30, "Third key should be 30");
    }

    function testRightLeftRotation() public pure {
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Step 1: Initial tree
        //    10 (h=2)
        //      \
        //      30 (h=1)
        //      balance = -1
        //
        // Step 2: Insert 20, triggers right-left rotation
        // First rotation (right):          Then rotation (left):
        //    10 (h=3)                        10 (h=3)                      20 (h=2)
        //      \                              \                           /  \
        //      30 (h=2)         ->           20 (h=2)         ->       10    30
        //     /                                \                     (h=1)  (h=1)
        //    20 (h=1)                         30 (h=1)
        //    balance = 1                    balance = -1              balance = 0
        tree = tree.insert(bytes32(uint256(10)), bytes32(uint256(10)));
        tree = tree.insert(bytes32(uint256(30)), bytes32(uint256(30)));
        tree = tree.insert(bytes32(uint256(20)), bytes32(uint256(20)));

        bytes32[] memory keys = tree.inorderTraversal();
        assertEq(uint256(keys[0]), 10, "First key should be 10");
        assertEq(uint256(keys[1]), 20, "Second key should be 20");
        assertEq(uint256(keys[2]), 30, "Third key should be 30");
    }

    function testInsertFindManyItems() public pure {
        uint256 numItems = 5000;
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Insert numItems unique key-value pairs
        // key = hash(i), value = hash(hash(i))
        for (uint256 i = 0; i < numItems; i++) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 value = keccak256(abi.encode(key));

            tree = tree.insert(key, value);
            assertEq(tree.find(key), value, "Each inserted value should be immediately retrievable");
        }

        // Verify all values are still retrievable after complete insertion
        for (uint256 i = 0; i < numItems; i++) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 value = keccak256(abi.encode(key));
            assertEq(tree.find(key), value, "All values should be retrievable after complete insertion");
        }
    }

    function testInorderTraversalIsSorted() public pure {
        uint256 numItems = 5000;
        MemoryAVLTree.Tree memory tree = MemoryAVLTree.createTree();

        // Insert numItems unique key-value pairs
        for (uint256 i = 0; i < numItems; i++) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 value = keccak256(abi.encode(key));
            tree = tree.insert(key, value);
        }

        // Verify inorder traversal produces sorted output
        bytes32[] memory traversal = tree.inorderTraversal();
        assertEq(traversal.length, numItems, "Traversal should contain all inserted items");

        for (uint256 i = 1; i < traversal.length; i++) {
            assertTrue(traversal[i - 1] < traversal[i], "Inorder traversal must be sorted");
        }
    }
}
