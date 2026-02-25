# Optimistic Oracle V1

An expert-grade smart contract framework for optimistic data verification. This repository provides a secure way to bring off-chain data onto the blockchain by assuming honesty and incentivizing truth-telling through bonded stakes and dispute periods.

## Overview
Unlike standard oracles that push data every block, an Optimistic Oracle only verifies data when a dispute is raised. Proposers post a bond to submit data; if no one challenges the data within a "Liveness Period," the data is finalized. If a challenge occurs, a secondary resolution layer (or DAO) determines the winner, who then claims the loser's bond.

### Key Features
* **Bonded Proposals:** Requires collateral to prevent spam and ensure accountability.
* **Challenge Mechanism:** Anyone can dispute a proposal by providing a counter-stake.
* **Liveness Period:** Configurable window for community validation.
* **Economic Security:** Designed to make the cost of corruption higher than the potential gain.

## Technical Stack
* **Language:** Solidity ^0.8.20
* **Security:** OpenZeppelin Access Control
* **License:** MIT

## Workflow
1. **Propose:** A user calls `proposeData()` with a value and a bond.
2. **Wait:** The dispute window (e.g., 2 hours) begins.
3. **Dispute (Optional):** If the data is false, a challenger calls `disputeData()` and posts a bond.
4. **Settle:** If no dispute, `settle()` finalizes the value. If disputed, an admin or DAO resolves the winner.
