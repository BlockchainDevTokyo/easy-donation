// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SeedlessWallet {
	address public owner;
	address[] public guardians;
	mapping(address => bool) public isGuardian;

	uint public guardianApprovalCount;
	uint public recoveryThreshold;
	bool public isRecoveryInProgress;
	address public newOwner;

	event WalletCreated(address indexed owner, uint recoveryThreshold);
	event GuardianAdded(address indexed guardian);
	event GuardianRemoved(address indexed guardian);
	event RecoveryInitiated(address indexed proposedNewOwner);
	event RecoveryApproved(
		address indexed guardian,
		address indexed proposedNewOwner
	);
	event RecoveryFinalized(address indexed newOwner);

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner can call this function");
		_;
	}

	modifier onlyGuardian() {
		require(
			isGuardian[msg.sender],
			"Only guardians can call this function"
		);
		_;
	}

	constructor(address[] memory _guardians, uint _recoveryThreshold) {
		require(
			_guardians.length >= _recoveryThreshold,
			"Guardians count must be greater than or equal to recovery threshold"
		);
		owner = msg.sender;
		guardians = _guardians;
		recoveryThreshold = _recoveryThreshold;

		for (uint i = 0; i < _guardians.length; i++) {
			isGuardian[_guardians[i]] = true;
			emit GuardianAdded(_guardians[i]);
		}

		emit WalletCreated(owner, recoveryThreshold);
	}

	function addGuardian(address _guardian) public onlyOwner {
		require(!isGuardian[_guardian], "Address is already a guardian");
		guardians.push(_guardian);
		isGuardian[_guardian] = true;
		emit GuardianAdded(_guardian);
	}

	function removeGuardian(address _guardian) public onlyOwner {
		require(isGuardian[_guardian], "Address is not a guardian");
		isGuardian[_guardian] = false;
		for (uint i = 0; i < guardians.length; i++) {
			if (guardians[i] == _guardian) {
				guardians[i] = guardians[guardians.length - 1];
				guardians.pop();
				break;
			}
		}
		emit GuardianRemoved(_guardian);
	}

	function initiateRecovery(address _newOwner) public onlyGuardian {
		require(!isRecoveryInProgress, "Recovery is already in progress");
		newOwner = _newOwner;
		guardianApprovalCount = 0;
		isRecoveryInProgress = true;
		emit RecoveryInitiated(_newOwner);
	}

	function approveRecovery() public onlyGuardian {
		require(isRecoveryInProgress, "No recovery in progress");
		require(newOwner != address(0), "No new owner proposed");
		guardianApprovalCount++;

		emit RecoveryApproved(msg.sender, newOwner);

		if (guardianApprovalCount >= recoveryThreshold) {
			finalizeRecovery();
		}
	}

	function finalizeRecovery() internal {
		require(
			guardianApprovalCount >= recoveryThreshold,
			"Not enough approvals for recovery"
		);
		owner = newOwner;
		newOwner = address(0);
		isRecoveryInProgress = false;
		emit RecoveryFinalized(owner);
	}

	function executeTransaction(
		address payable _to,
		uint _value,
		bytes memory _data
	) public onlyOwner {
		require(address(this).balance >= _value, "Insufficient balance");
		(bool success, ) = _to.call{ value: _value }(_data);
		require(success, "Transaction failed");
	}

	receive() external payable {}

	function getGuardians() public view returns (address[] memory) {
		return guardians;
	}
}
