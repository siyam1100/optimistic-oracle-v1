// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OptimisticOracle
 * @dev A professional-grade optimistic data oracle with dispute logic.
 */
contract OptimisticOracle is Ownable, ReentrancyGuard {
    
    struct Proposal {
        address proposer;
        bytes32 data;
        uint256 timestamp;
        uint256 bond;
        bool settled;
        bool disputed;
        address challenger;
    }

    uint256 public constant LIVENESS_PERIOD = 2 hours;
    uint256 public constant MIN_BOND = 0.1 ether;

    mapping(bytes32 => Proposal) public proposals;

    event DataProposed(address indexed proposer, bytes32 indexed identifier, bytes32 data);
    event DataDisputed(address indexed challenger, bytes32 indexed identifier);
    event DataSettled(bytes32 indexed identifier, bytes32 data);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Proposes a data point with a required bond.
     */
    function proposeData(bytes32 identifier, bytes32 data) external payable nonReentrant {
        require(msg.value >= MIN_BOND, "Bond too low");
        require(proposals[identifier].proposer == address(0), "Proposal already exists");

        proposals[identifier] = Proposal({
            proposer: msg.sender,
            data: data,
            timestamp: block.timestamp,
            bond: msg.value,
            settled: false,
            disputed: false,
            challenger: address(0)
        });

        emit DataProposed(msg.sender, identifier, data);
    }

    /**
     * @dev Disputes a proposal within the liveness period.
     */
    function disputeData(bytes32 identifier) external payable nonReentrant {
        Proposal storage proposal = proposals[identifier];
        require(proposal.proposer != address(0), "No proposal found");
        require(!proposal.disputed, "Already disputed");
        require(block.timestamp < proposal.timestamp + LIVENESS_PERIOD, "Liveness period ended");
        require(msg.value >= proposal.bond, "Challenger bond must match proposer bond");

        proposal.disputed = true;
        proposal.challenger = msg.sender;

        emit DataDisputed(msg.sender, identifier);
    }

    /**
     * @dev Settles the proposal if no dispute was raised.
     */
    function settle(bytes32 identifier) external nonReentrant {
        Proposal storage proposal = proposals[identifier];
        require(!proposal.settled, "Already settled");
        require(!proposal.disputed, "Proposal is disputed and requires resolution");
        require(block.timestamp >= proposal.timestamp + LIVENESS_PERIOD, "Liveness period not over");

        proposal.settled = true;
        payable(proposal.proposer).transfer(proposal.bond);

        emit DataSettled(identifier, proposal.data);
    }

    /**
     * @dev Administrative resolution for disputed data.
     */
    function resolveDispute(bytes32 identifier, bool proposerWon) external onlyOwner {
        Proposal storage proposal = proposals[identifier];
        require(proposal.disputed, "Not disputed");
        require(!proposal.settled, "Already settled");

        proposal.settled = true;
        uint256 totalBond = proposal.bond * 2;

        if (proposerWon) {
            payable(proposal.proposer).transfer(totalBond);
        } else {
            payable(proposal.challenger).transfer(totalBond);
        }
    }
}
