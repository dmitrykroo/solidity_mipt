pragma solidity >=0.7.0 <0.9.0;


contract University{
    struct Student{
        string name;
        uint age;
    }

    uint numGroups = 0;
    Student[] students;
    uint[] groups;

    constructor (uint _numGroups) public {
        numGroups = _numGroups;
    }

    function addStudent(string memory name, uint age) public {
        students.push(Student(name, age));
        groups.push(uint(keccak256(abi.encodePacked(block.number, name, age))) % numGroups);
    }
}
