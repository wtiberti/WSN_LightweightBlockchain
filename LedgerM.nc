#include <stdio.h>

#include "Ledger.h"

module LedgerM {
	provides interface LedgerI;
	uses interface HashFunctionI;
}

implementation {
	// Function prototypes
	uint8_t SelectNewChain(uint8_t currentReliability);
	uint8_t DecreaseReliability(WSNLedger *l, uint8_t node_id, int reason);
	uint8_t IncreaseReliability(WSNLedger *l, uint8_t node_id, int reason);
	void SwitchBlockchain(WSNLedger *l, uint8_t newChain, uint8_t node_id, uint8_t *prevHash, uint32_t prev_ts);
	void StoreBlock(WSNLedger *l, BlockChainMsg *msg, uint8_t chain);

	/*
	 * Ledger_init
	 *
	 * Initialize a WSNLedger structure for first time use
	 */
	command void LedgerI.Init(WSNLedger *l)
	{
		int i, c, n;
		for (i = 0; i < NUM_OF_NODES; ++i) {
			l->currentChainForNode[i] = CHAIN_NONE; // all nodes to CHAIN_NODE
			l->nodesReliability[i] = 0; // starting reliability to 0
		}
		// Set to 000..00 the initial hash and timestamp of every nodes
		for (c = 0; c < NUM_OF_CHAINS; ++c) {
			for (n = 0; n < NUM_OF_NODES; ++n) {
				memset(l->chains[c].nodeInfo[n].prevHash, 0, HASH_SIZE);
				l->chains[c].nodeInfo[n].lastTimestamp = 0;

				l->chains[c].blocks[n].head = 0;
				for (i = 0; i < BC_WIN_SIZE; ++i)
					memset(&l->chains[c].blocks[n].msgs[i], 0, sizeof(BlockChainMsg));
			}
		}
	}

	/*
	 * Ledger_ReadMessage
	 *
	 * Parse and check the validity of a BlockChainMsg, eventually switching to a
	 * different blockchain
	 */
	command void *LedgerI.ReadMessage(WSNLedger *l, BlockChainMsg *msg, uint32_t arrival_time)
	{
		uint8_t *_prevHash;
		uint8_t current_chain;
		uint8_t new_chain;
		uint32_t delta;

		// Retrieve the node current blockchain
		current_chain = l->currentChainForNode[msg->node_id];
		// Retrieve a pointer to the current prevHash
		_prevHash = l->chains[current_chain].nodeInfo[msg->node_id].prevHash;

		// If the chain is CHAIN_DENIED, the message is discarded without any other processing
		if (current_chain == CHAIN_DENIED) {
			//printf("Message refused \x1b[91m(CHAIN DENIED)\x1b[0m\r\n");
			return NULL;
		}

		//printf("Stored hash: "); printhex(_prevHash, HASH_SIZE);
		//printf("Received hash: "); printhex(msg->content.prevHash, HASH_SIZE);
		//printf("Checking block integrity...");

		/* HASH CHECK */

		// Check if the chain is CHAIN_NONE (not yet assigned) or the comparison with the stored prevHash is successful
		if((memcmp(_prevHash, msg->content.prevHash, HASH_SIZE) == 0) || current_chain == CHAIN_NONE) {
			// Ok, valid hash!
			//printf("\x1b[92m" "HASH OK!\r\n" "\x1b[0m");
			// Increase reliability of the node and eventually update the new_chain
			new_chain = IncreaseReliability(l, msg->node_id, RELPOINTS_GOOD_HASH);
		} else {
			// NO, invalid hash!
			//printf("\x1b[91m" "WRONG HASH :(\r\n" "\x1b[0m");
			// Decrease reliability of the node and eventually update the new_chain
			new_chain = DecreaseReliability(l, msg->node_id, RELPOINTS_WRONG_HASH);
		}

		/* TIMESTAMP (delta) CHECK */

		// Compute the time passed (in timer ticks) between this message and the last
		delta = abs(l->chains[current_chain].nodeInfo[msg->node_id].lastTimestamp - arrival_time);
		delta = abs(delta - msg->content.ts_delta);

		// Check if the difference is less than the threshold
		if(delta < TS_THRESHOLD) {
			// OK, valid TS
			//printf("\x1b[92m" "Timestamp check OK!\r\n" "\x1b[0m");
			// Increase reliability of the node and eventually update the new_chain
			new_chain = IncreaseReliability(l, msg->node_id, RELPOINTS_GOOD_TS);
		} else {
			// NO, invalid TS
			//printf("\x1b[91mTimestap check FAILED :( [delta=%lu]\r\n\x1b[0m", delta);
			// Decrease reliability of the node and eventually update the new_chain
			new_chain = DecreaseReliability(l, msg->node_id, RELPOINTS_WRONG_TS);
		}

		/* BLOCKCHAIN SWITCH */

		// Check if the chain changed
		if (new_chain != current_chain) {
			// Switch to the new blockchain
			//printf("Switching from chain %d to %d\r\n", current_chain, new_chain);
			SwitchBlockchain(l, new_chain, msg->node_id, _prevHash, delta);
		}

		// Re-compute the pointer to the prevHash (needed since the chain could have been changed)
		_prevHash = l->chains[l->currentChainForNode[msg->node_id]].nodeInfo[msg->node_id].prevHash;

		// Check if the new chain is CHAIN_DENIED
		if (new_chain != CHAIN_DENIED) {
			// if not, retrieve the payload
			//printf("Payload[%d]: ", MAX_PAYLOAD);
			//printhex((uint8_t*)msg->content.payload, MAX_PAYLOAD);

			// Store the block
			StoreBlock(l, msg, l->currentChainForNode[msg->node_id]);

			// Pre-compute next prevHash
			//printf("New block hash:"); printhex(_prevHash, HASH_SIZE);
			call HashFunctionI.getDigest(_prevHash, msg, sizeof(BlockChainMsg));
			return msg->content.payload;
		}
		return NULL;
	}

	/*
	 * SelectNewChain
	 *
	 * Given reliability points, determine which is the right blockchain
	 */
	uint8_t SelectNewChain(uint8_t currentReliability)
	{
		int i;

		// After the last chain, all goes to CHAIN_DENIED (discarding all future messages)
		if (currentReliability >= THRESH_MULTIPLIER * NUM_OF_CHAINS)
			return CHAIN_DENIED;

		// search the right chain from the lower-reliability chain to the
		// high-reliable chain
		for (i = NUM_OF_CHAINS-1; i > CHAIN_NONE; i--) {
			if (currentReliability >= THRESH_MULTIPLIER * i)
				return i+1;
		}
		return 1;
	}

	/* DecreaseReliability
	 *
	 * Compute the new reliability points and the new chain from the current
	 * node status and an event (=reason)
	 */
	uint8_t DecreaseReliability(WSNLedger *l, uint8_t node_id, int reason)
	{
		// Retrieve and assign the new reliability
		uint8_t *r = &l->nodesReliability[node_id];
		if (*r + reason > 0xFF)
			*r = 0xFF;
		else
			*r += reason;
		// Select the right chain
		return SelectNewChain(*r);
	}

	uint8_t IncreaseReliability(WSNLedger *l, uint8_t node_id, int reason)
	{
		// Retrieve and assign the new reliability
		uint8_t *r = &l->nodesReliability[node_id];
		if (*r < reason)
			*r = 0;
		else
			*r -= reason;
		// Select the right chain
		return SelectNewChain(*r);
	}

	/*
	 * SwitchBlockchain
	 *
	 * Change the blockchain associated with a node, preparing it for the next
	 * messages
	 */
	void SwitchBlockchain(WSNLedger *l, uint8_t newChain, uint8_t node_id, uint8_t *prevHash, uint32_t prev_ts)
	{
		if (newChain == CHAIN_NONE)
			return; // invalid chain
		if (l->currentChainForNode[node_id] == newChain)
			return; // No need to change
		l->currentChainForNode[node_id] = newChain;
		if (l->currentChainForNode[node_id] != CHAIN_DENIED) {
			memcpy(l->chains->nodeInfo[node_id].prevHash, prevHash, HASH_SIZE);
			l->chains->nodeInfo[node_id].lastTimestamp = prev_ts;
		}
	}

	void StoreBlock(WSNLedger *l, BlockChainMsg *msg, uint8_t chain)
	{
		uint8_t *head = &l->chains[chain].blocks[msg->node_id].head;
		memcpy(&l->chains[chain].blocks[msg->node_id].msgs[*head], msg, sizeof(BlockChainMsg));
		*head = (*head + 1) % BC_WIN_SIZE;
	}
}
