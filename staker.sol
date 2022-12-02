pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC721.sol";

contract ExampleExternalContract {
    event RecievedEther(uint _amount);
    receive() external payable {
        emit RecievedEther(msg.value);
    }
}

contract StakerTierNFT is ERC721 {
    address private _owner;
    uint private _currentTokenId;

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _owner= msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == _owner);
        _;
    }

    function award(address to) public onlyOwner {
        _mint(to, _currentTokenId++);
    }
}

contract Staker {
    StakerTierNFT public goldenNFT;
    StakerTierNFT public silverNFT;
    StakerTierNFT public bronzeNFT;

    bool public fundingComplete;
    mapping (address => uint) private _balances;
    address[] private _users;

    uint public immutable threshold;
    uint public immutable deadline;
    uint public stakerBalance;

    address payable public _externalContract;

    constructor (address payable externalContract_, uint threshold_, uint deadline_){
        goldenNFT = new StakerTierNFT("Staker Gold Tier", "SGT");
        silverNFT = new StakerTierNFT("Staker Silver Tier", "SST");
        bronzeNFT = new StakerTierNFT("Staker Bronze Tier", "SBT");

        _externalContract = externalContract_;
        threshold = threshold_;
        deadline = deadline_;
    }

    modifier stakingOpen {
        require(!fundingComplete, "Staking closed");
        _;
    }

    modifier stakingClosed {
        require(fundingComplete, "Staking still open");
        _;
    }

    function stake() public payable stakingOpen {
        require(msg.value > 0, "Stake value must be > 0 ETH");
        if (_balances[msg.sender] == 0){
            _users.push(msg.sender);
        }
        _balances[msg.sender] += msg.value;
        stakerBalance += msg.value;
    }

    function withdraw() public stakingClosed {
        require(stakerBalance < threshold, "Threshold reached, withdrawal closed");
        require(_balances[msg.sender] > 0, "Balance for requested address is zero");
        uint balance = _balances[msg.sender];
        _balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function _complete() internal {
        fundingComplete = true;
    }

    function _mintNFTs() internal {
        for (uint i = 0; i < _users.length; i++){
            address user = _users[i];
            uint balance = _balances[user];
            if (balance > 1 ether) {
                goldenNFT.award(user);
            } else if (balance > 0.05 ether) {
                silverNFT.award(user);
            } else {
                bronzeNFT.award(user);
            }
        }
    }

    function closeICO() public stakingOpen {
        require(block.timestamp >= deadline, "Deadline not reached");
        if (stakerBalance >= threshold){
            _externalContract.transfer(stakerBalance);
            _mintNFTs();
        }
        _complete();
    }
}
