// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OrderedDoublyLinkedList.sol";

contract OrderedDoublyLinkedListTest is Test {
    using OrderedDoublyLinkedList for OrderedDoublyLinkedList.List;

    OrderedDoublyLinkedList.List private list;

    function setUp() public {
        // Setup is empty as the list is initialized in storage
    }

    function testInsert() public {
        list.insert(1, 10, 0);
        list.insert(2, 20, 0);
        list.insert(3, 15, 0);

        assertEq(list.getHead(), 1, "Head should be 1");
        assertEq(list.getTail(), 2, "Tail should be 2");

        OrderedDoublyLinkedList.Node memory node = list.getNode(3);
        assertEq(node.value, 15, "Node 3 value should be 15");
        assertEq(node.prev, 1, "Node 3 prev should be 1");
        assertEq(node.next, 2, "Node 3 next should be 2");
    }

    function testRemove() public {
        list.insert(1, 10, 0);
        list.insert(2, 20, 0);
        list.insert(3, 15, 0);

        OrderedDoublyLinkedList.Node memory removedNode = list.remove(3);
        assertEq(removedNode.value, 15, "Removed node value should be 15");

        assertEq(list.getHead(), 1, "Head should still be 1");
        assertEq(list.getTail(), 2, "Tail should still be 2");

        OrderedDoublyLinkedList.Node memory node1 = list.getNode(1);
        OrderedDoublyLinkedList.Node memory node2 = list.getNode(2);

        assertEq(node1.next, 2, "Node 1 next should be 2");
        assertEq(node2.prev, 1, "Node 2 prev should be 1");
    }

    function testUpdate() public {
        list.insert(1, 10, 0);
        list.insert(2, 20, 0);
        list.insert(3, 15, 0);

        list.update(3, 25, 0);

        OrderedDoublyLinkedList.Node memory updatedNode = list.getNode(3);
        assertEq(updatedNode.value, 25, "Updated node value should be 25");
        assertEq(updatedNode.prev, 2, "Updated node prev should be 2");
        assertEq(updatedNode.next, 0, "Updated node next should be 0");

        assertEq(list.getTail(), 3, "Tail should now be 3");
    }

    function testUpsert() public {
        list.upsert(1, 10, 0);
        list.upsert(2, 20, 0);
        list.upsert(3, 15, 0);

        // Test insert functionality
        OrderedDoublyLinkedList.Node memory node3 = list.getNode(3);
        assertEq(node3.value, 15, "Node 3 value should be 15");

        // Test update functionality
        //list.upsert(3, 25, 0);
        //node3 = list.getNode(3);
        //assertEq(node3.value, 25, "Node 3 value should be updated to 25");

        // Test inserting a new node with the same value
        list.upsert(4, 20, 0);
        OrderedDoublyLinkedList.Node memory node4 = list.getNode(4);
        assertEq(node4.value, 20, "Node 4 value should be 20");
        assertEq(node4.prev, 3, "Node 4 prev should be 3");
        assertEq(node4.next, 2, "Node 4 next should be 2");

        OrderedDoublyLinkedList.Node memory node2 = list.getNode(2);
        assertEq(node2.prev, 4, "Node 2 prev should now be 4");

        // Verify the order: 1 (10) -> 3 (15) -> 4 (20) -> 2 (20) -> 3 (25)
        assertEq(list.getHead(), 1, "Head should be 1");
        assertEq(list.getTail(), 2, "Tail should be 3");

        list.upsert(3, 25, 0);
        node3 = list.getNode(3);
        assertEq(node3.value, 25, "Node 3 value should be updated to 25");

        OrderedDoublyLinkedList.Node memory node1 = list.getNode(1);
        assertEq(node1.next, 4, "Node 1 next should be 3");
        assertEq(node3.prev, 2, "Node 3 prev should be 2");
        assertEq(node3.next, 0, "Node 3 next should be 0");
    }

    function testGetHeadAndTail() public {
        list.insert(1, 10, 0);
        list.insert(2, 20, 0);
        list.insert(3, 15, 0);

        assertEq(list.getHead(), 1, "Head should be 1");
        assertEq(list.getTail(), 2, "Tail should be 2");

        list.insert(4, 5, 0);
        assertEq(list.getHead(), 4, "Head should now be 4");

        list.insert(5, 30, 0);
        assertEq(list.getTail(), 5, "Tail should now be 5");
    }

    function testEmptyList() public {
        assertEq(list.getHead(), 0, "Head of empty list should be 0");
        assertEq(list.getTail(), 0, "Tail of empty list should be 0");

        OrderedDoublyLinkedList.Node memory emptyNode = list.getNode(1);
        assertEq(emptyNode.value, 0, "Value of non-existent node should be 0");
        assertEq(emptyNode.prev, 0, "Prev of non-existent node should be 0");
        assertEq(emptyNode.next, 0, "Next of non-existent node should be 0");
    }

    function testLargeNumberOfInserts() public {
        uint256 numInserts = 100;
        for (uint256 i = 1; i <= numInserts; i++) {
            list.insert(i, i * 10, 0);
        }

        assertEq(list.getHead(), 1, "Head should be 1");
        assertEq(list.getTail(), numInserts, "Tail should be 100");

        for (uint256 i = 1; i <= numInserts; i++) {
            OrderedDoublyLinkedList.Node memory node = list.getNode(i);
            assertEq(node.value, i * 10, "Node value should match");
            if (i > 1) {
                assertEq(node.prev, i - 1, "Prev should be correct");
            }
            if (i < numInserts) {
                assertEq(node.next, i + 1, "Next should be correct");
            }
        }
    }
}
