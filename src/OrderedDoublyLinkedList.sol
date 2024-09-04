// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library OrderedDoublyLinkedList {
    struct Node {
        uint256 value;
        uint256 prev;
        uint256 next;
    }

    struct List {
        uint256 head;
        uint256 tail;
        mapping(uint256 => Node) nodes;
    }

    function insert(
        List storage self,
        uint256 id,
        uint256 value,
        uint256 _nearestSpot
    ) internal {
        Node memory node = Node(value, 0, 0);
        uint256 _head = self.head;
        if (_head == 0) {
            self.head = id;
            self.tail = id;
        } else {
            uint256 _tail = self.tail;
            if (_nearestSpot == 0) {
                _nearestSpot = _head;
            }

            if (
                self.nodes[_nearestSpot].prev == 0 &&
                self.nodes[_nearestSpot].next == 0 &&
                self.nodes[_nearestSpot].value == 0
            ) {
                _nearestSpot = self.head;
            }

            while (
                _nearestSpot != _tail &&
                self.nodes[_nearestSpot].value < node.value
            ) {
                _nearestSpot = self.nodes[_nearestSpot].next;
            }

            while (
                _nearestSpot != _head &&
                self.nodes[_nearestSpot].value >= node.value
            ) {
                _nearestSpot = self.nodes[_nearestSpot].prev;
            }

            if (_nearestSpot == _head) {
                if (self.nodes[_nearestSpot].value >= node.value) {
                    node.next = _nearestSpot;
                    self.nodes[_nearestSpot].prev = id;
                    self.head = id;
                } else {
                    node.prev = _nearestSpot;
                    node.next = self.nodes[_nearestSpot].next;
                    self.nodes[_nearestSpot].next = id;
                    if (node.next != 0) {
                        self.nodes[node.next].prev = id;
                    } else {
                        self.tail = id;
                    }
                }
            } else if (_nearestSpot == _tail) {
                if (self.nodes[_nearestSpot].value < node.value) {
                    node.prev = _nearestSpot;
                    self.nodes[_nearestSpot].next = id;
                    self.tail = id;
                } else {
                    node.prev = self.nodes[_nearestSpot].prev;
                    node.next = _nearestSpot;
                    self.nodes[_nearestSpot].prev = id;
                    if (node.prev != 0) {
                        self.nodes[node.prev].next = id;
                    } else {
                        self.head = id;
                    }
                }
            } else {
                node.prev = _nearestSpot;
                node.next = self.nodes[_nearestSpot].next;
                self.nodes[_nearestSpot].next = id;
                self.nodes[node.next].prev = id;
            }
        }
        self.nodes[id] = node;
    }

    function checkIfExists(
        List storage self,
        uint256 id
    ) internal view returns (bool) {
        return (self.nodes[id].prev != 0 &&
            self.nodes[id].value != 0 &&
            self.nodes[id].next != 0);
    }

    function remove(
        List storage self,
        uint256 id
    ) internal returns (Node memory) {
        if (!checkIfExists(self, id)) {
            return Node(0, 0, 0);
        }
        Node memory node = self.nodes[id];
        if (node.prev == 0) {
            self.head = node.next;
        } else {
            self.nodes[node.prev].next = node.next;
        }
        if (node.next == 0) {
            self.tail = node.prev;
        } else {
            self.nodes[node.next].prev = node.prev;
        }
        delete self.nodes[id];
        return node;
    }

    function update(
        List storage self,
        uint256 id,
        uint256 value,
        uint256 _nearestSpot
    ) internal {
        Node memory node = remove(self, id);
        node.value = value;
        node.prev = 0;
        node.next = 0;
        insert(self, id, value, _nearestSpot);
    }

    function upsert(
        List storage self,
        uint256 id,
        uint256 value,
        uint256 _nearestSpot
    ) internal {
        if (!checkIfExists(self, id)) {
            insert(self, id, value, _nearestSpot);
        } else {
            update(self, id, value, _nearestSpot);
        }
    }

    function get(
        List storage self,
        uint256 id
    ) internal view returns (Node memory) {
        return self.nodes[id];
    }

    function getHead(List storage self) internal view returns (uint256) {
        return self.head;
    }

    function getTail(List storage self) internal view returns (uint256) {
        return self.tail;
    }

    function getNode(
        List storage self,
        uint256 id
    ) internal view returns (Node memory) {
        return self.nodes[id];
    }
}
