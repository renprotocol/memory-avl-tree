// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Memory AVL Tree Library
/// @notice Provides an in-memory self-balancing binary search tree implementation
/// @dev All operations are performed in memory and state is not persisted
library MemoryAVLTree {
    // Memory layout for a node (160 bytes total):
    // - bytes32 key        [0:32]
    // - bytes32 value      [32:64]
    // - uint256 height     [64:96]
    // - uint256 left ptr   [96:128]
    // - uint256 right ptr  [128:160]
    uint256 private constant NODE_SIZE = 160;

    /// @notice Structure representing an AVL tree
    /// @dev Contains only the root pointer, all other data is stored in memory
    struct Tree {
        uint256 root; // Pointer to root node in memory
    }

    /// @notice Creates a new empty AVL tree
    /// @return A new Tree struct with a null root pointer
    function createTree() internal pure returns (Tree memory) {
        return Tree({root: 0});
    }

    /// @notice Inserts a key-value pair into the tree
    /// @param self The tree to insert into
    /// @param key The key to insert
    /// @param value The value to associate with the key
    /// @return The modified tree
    /// @dev Maintains AVL balance property through rotations
    function insert(Tree memory self, bytes32 key, bytes32 value) internal pure returns (Tree memory) {
        self.root = _insert(self, self.root, key, value);
        return self;
    }

    /// @notice Finds a value in the tree by its key
    /// @param self The tree to search in
    /// @param key The key to search for
    /// @return The value associated with the key, or zero if not found
    function find(Tree memory self, bytes32 key) internal pure returns (bytes32) {
        return _find(self.root, key);
    }

    /// @notice Performs an inorder traversal of the tree
    /// @param self The tree to traverse
    /// @return keys Array of keys in sorted order
    function inorderTraversal(Tree memory self) internal pure returns (bytes32[] memory keys) {
        uint256 size = _getSize(self.root);
        keys = new bytes32[](size);
        uint256[] memory stack = new uint256[](size);
        uint256 stackTop = 0;
        uint256 current = self.root;
        uint256 index = 0;

        while (stackTop > 0 || current != 0) {
            // Traverse to leftmost node
            while (current != 0) {
                stack[stackTop++] = current;
                assembly {
                    current := mload(add(current, 96)) // Get left child
                }
            }

            // Process current node and move to right child
            current = stack[--stackTop];
            assembly {
                mstore(add(keys, mul(add(index, 1), 32)), mload(current))
            }
            index++;

            assembly {
                current := mload(add(current, 128)) // Get right child
            }
        }

        return keys;
    }

    /// @dev Recursive helper function for find
    /// @param nodePtr Pointer to the current node
    /// @param key The key to search for
    /// @return The value if found, zero otherwise
    function _find(uint256 nodePtr, bytes32 key) private pure returns (bytes32) {
        // Base case: key not found
        if (nodePtr == 0) return bytes32(0);

        bytes32 currentKey;
        bytes32 value;
        uint256 leftPtr;
        uint256 rightPtr;

        // Load all node data at once for efficiency
        assembly {
            currentKey := mload(nodePtr)
            value := mload(add(nodePtr, 32))
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Example tree structure:
        //       20
        //      /  \
        //     10   30
        //    /  \
        //   5    15

        // Standard binary search tree traversal
        if (key < currentKey) {
            // Search left subtree
            return _find(leftPtr, key);
        } else if (key > currentKey) {
            // Search right subtree
            return _find(rightPtr, key);
        }

        // Key found - return associated value
        return value;
    }

    /// @dev Recursive helper function for insert
    /// @param self The tree being modified
    /// @param nodePtr Pointer to the current node
    /// @param key The key to insert
    /// @param value The value to insert
    /// @return Pointer to the root of the modified subtree
    function _insert(Tree memory self, uint256 nodePtr, bytes32 key, bytes32 value) private pure returns (uint256) {
        // Create new node if we've reached a null pointer
        if (nodePtr == 0) {
            return _createNode(key, value);
        }

        bytes32 currentKey;
        uint256 leftPtr;
        uint256 rightPtr;

        // Load node data from memory
        assembly {
            currentKey := mload(nodePtr)
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Recursively insert into appropriate subtree
        if (key < currentKey) {
            leftPtr = _insert(self, leftPtr, key, value);
            assembly {
                mstore(add(nodePtr, 96), leftPtr)
            }
        } else if (key > currentKey) {
            rightPtr = _insert(self, rightPtr, key, value);
            assembly {
                mstore(add(nodePtr, 128), rightPtr)
            }
        } else {
            // Update value if key already exists
            assembly {
                mstore(add(nodePtr, 32), value)
            }
            return nodePtr;
        }

        // Update height and rebalance after insertion
        _updateHeight(nodePtr);
        return _rebalance(nodePtr);
    }

    /// @dev Creates a new node in memory
    /// @param key The key for the new node
    /// @param value The value for the new node
    /// @return nodePtr Pointer to the newly created node
    function _createNode(bytes32 key, bytes32 value) private pure returns (uint256 nodePtr) {
        assembly {
            // Get free memory pointer
            nodePtr := mload(0x40)
            // Update free memory pointer
            // Each node requires NODE_SIZE (160) bytes:
            // - 32 bytes for key
            // - 32 bytes for value
            // - 32 bytes for height
            // - 32 bytes for left pointer
            // - 32 bytes for right pointer
            mstore(0x40, add(nodePtr, NODE_SIZE))

            // Initialize node data
            mstore(nodePtr, key) // Store key at base offset
            mstore(add(nodePtr, 32), value) // Store value at offset 32
            mstore(add(nodePtr, 64), 1) // Set initial height to 1
            mstore(add(nodePtr, 96), 0) // Initialize left pointer to null
            mstore(add(nodePtr, 128), 0) // Initialize right pointer to null
        }
    }

    /// @dev Gets the height of a node
    /// @param nodePtr Pointer to the node
    /// @return height The height of the node (0 for null nodes)
    function _getHeight(uint256 nodePtr) private pure returns (uint256 height) {
        if (nodePtr == 0) return 0;
        assembly {
            height := mload(add(nodePtr, 64))
        }
    }

    /// @dev Calculates the balance factor of a node
    /// @param nodePtr Pointer to the node
    /// @return balance Balance factor (left height - right height)
    function _getBalance(uint256 nodePtr) private pure returns (int256 balance) {
        if (nodePtr == 0) return 0;

        uint256 leftPtr;
        uint256 rightPtr;

        assembly {
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Example balance factors:
        //    +2:        10          -2:        10
        //             /                          \
        //            5                           20
        //           /                             \
        //          1                              30
        balance = int256(_getHeight(leftPtr)) - int256(_getHeight(rightPtr));
    }

    /// @dev Updates the height of a node based on its children
    /// @param nodePtr Pointer to the node to update
    function _updateHeight(uint256 nodePtr) private pure {
        uint256 leftPtr;
        uint256 rightPtr;

        assembly {
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Example height updates after insertion:
        //    Before:     After inserting 7:
        //      10 (h=2)     10 (h=3)
        //     /            /
        //    5 (h=1)     5 (h=2)
        //                  \
        //                   7 (h=1)

        uint256 height = 1 + _max(_getHeight(leftPtr), _getHeight(rightPtr));

        assembly {
            mstore(add(nodePtr, 64), height)
        }
    }

    /// @dev Rebalances a node if its balance factor becomes invalid
    /// @param nodePtr Pointer to the node to rebalance
    /// @return Pointer to the root of the rebalanced subtree
    function _rebalance(uint256 nodePtr) private pure returns (uint256) {
        int256 balance = _getBalance(nodePtr);
        uint256 leftPtr;
        uint256 rightPtr;

        assembly {
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Left heavy (balance > 1)
        if (balance > 1) {
            if (_getBalance(leftPtr) < 0) {
                // Left-Right case
                leftPtr = _leftRotate(leftPtr);
                assembly {
                    mstore(add(nodePtr, 96), leftPtr)
                }
            }
            return _rightRotate(nodePtr);
        }

        // Right heavy (balance < -1)
        if (balance < -1) {
            if (_getBalance(rightPtr) > 0) {
                // Right-Left case
                rightPtr = _rightRotate(rightPtr);
                assembly {
                    mstore(add(nodePtr, 128), rightPtr)
                }
            }
            return _leftRotate(nodePtr);
        }

        return nodePtr;
    }

    /// @dev Performs a left rotation
    /// @param nodePtr Pointer to the root of the subtree to rotate
    /// @return newRoot Pointer to the new root of the rotated subtree
    function _leftRotate(uint256 nodePtr) private pure returns (uint256 newRoot) {
        uint256 rightChild;
        uint256 rightLeftChild;

        // Example left rotation:
        //     Before:           After:
        //        10             20
        //          \          /  \
        //          20   ->  10   30
        //            \
        //            30

        assembly {
            rightChild := mload(add(nodePtr, 128))
            rightLeftChild := mload(add(rightChild, 96))

            // Perform rotation
            mstore(add(nodePtr, 128), rightLeftChild)
            mstore(add(rightChild, 96), nodePtr)

            newRoot := rightChild
        }

        // Update heights
        _updateHeight(nodePtr); // Original root first (now lower)
        _updateHeight(newRoot); // New root last (now higher)
    }

    /// @dev Performs a right rotation
    /// @param nodePtr Pointer to the root of the subtree to rotate
    /// @return newRoot Pointer to the new root of the rotated subtree
    function _rightRotate(uint256 nodePtr) private pure returns (uint256 newRoot) {
        uint256 leftChild;
        uint256 leftRightChild;

        // Example right rotation:
        //     Before:           After:
        //        30             20
        //       /             /  \
        //      20     ->    10   30
        //     /
        //    10

        assembly {
            leftChild := mload(add(nodePtr, 96))
            leftRightChild := mload(add(leftChild, 128))

            // Original node adopts left child's right subtree
            mstore(add(nodePtr, 96), leftRightChild)
            // Left child adopts original node as its right child
            mstore(add(leftChild, 128), nodePtr)

            newRoot := leftChild
        }

        // Update heights after rotation
        _updateHeight(nodePtr); // Original root first (now lower)
        _updateHeight(newRoot); // New root last (now higher)
    }

    /// @dev Returns the maximum of two uint256 values
    /// @param a First value
    /// @param b Second value
    /// @return The larger of a and b
    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev Gets the total number of nodes in the tree
    /// @param nodePtr Pointer to the root node
    /// @return size The number of nodes in the tree
    function _getSize(uint256 nodePtr) private pure returns (uint256 size) {
        // Base case: empty subtree
        if (nodePtr == 0) return 0;

        uint256 leftPtr;
        uint256 rightPtr;

        assembly {
            leftPtr := mload(add(nodePtr, 96))
            rightPtr := mload(add(nodePtr, 128))
        }

        // Example size calculation:
        //      20        size = 1 + size(left) + size(right)
        //     /  \       size = 1 + 2 + 1 = 4
        //    10   30
        //   /
        //  5

        // Recursively calculate total size
        return 1 + _getSize(leftPtr) + _getSize(rightPtr);
    }
}
