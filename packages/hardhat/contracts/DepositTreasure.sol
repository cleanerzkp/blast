// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DepositTreasure {
	using SafeERC20 for IERC20;

	enum DepositStatus {
		ACTIVE,
		CLOSED
	}

	event DepositCreated(uint _depositID, uint _amount, uint _startTime);
	event DepositWithdrawn(uint _depositID, uint _amount, uint _endTime);

	struct Deposit {
		uint value;
		uint startTime;
		DepositStatus status;
	}

	address USDBAddress = 0x4200000000000000000000000000000000000022; // USDB address
	uint FIVE_YEARS = 5 * 365 days;

	mapping(uint _id => Deposit _deposit) public depositIDToDeposit;
	mapping(uint _id => address _depositor) public depositIDToDepositor;

	uint public depositID = 0;

	/// @notice Deposit the USDB
	/// @param _amount The amount of USDB to deposit
	function deposit(uint _amount) public {
		require(
			IERC20(USDBAddress).balanceOf(msg.sender) >= _amount,
			"Less tokens owned than specified _amount"
		);

		IERC20(USDBAddress).safeTransferFrom(
			msg.sender,
			address(this),
			_amount
		);

		Deposit memory _deposit = Deposit(
			_amount,
			block.timestamp,
			DepositStatus.ACTIVE
		);

		depositID++;
		depositIDToDeposit[depositID] = _deposit;
		depositIDToDepositor[depositID] = msg.sender;

		emit DepositCreated(depositID, _amount, block.timestamp);
	}

	/// @notice Withdraw the deposit
	/// @param _depositID The ID of the deposit
	function withdraw(uint _depositID) public {
		// Check if the sender is the depositor
		require(
			depositIDToDepositor[_depositID] == msg.sender,
			"Not the depositor"
		);
		// Check if the deposit is active
		require(
			depositIDToDeposit[_depositID].status == DepositStatus.ACTIVE,
			"Deposit is not active"
		);

		// Check if five years have passed
		bool _eligibleForWithdrawal = block.timestamp -
			depositIDToDeposit[_depositID].startTime <
			FIVE_YEARS;

		require(
			_eligibleForWithdrawal,
			"Not eligible for withdrawal (5 years)"
		);

		IERC20(USDBAddress).safeTransfer(
			depositIDToDepositor[_depositID],
			depositIDToDeposit[_depositID].value
		);

		depositIDToDeposit[_depositID].status = DepositStatus.CLOSED;

		emit DepositWithdrawn(
			_depositID,
			depositIDToDeposit[_depositID].value,
			block.timestamp
		);
	}
}
