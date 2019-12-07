#ifndef WSN_LEDGER_H
#define WSN_LEDGER_H

#include "Message.h" // MAC payload definition
#include "Config.h" // application configuration

/*
 * BlockchainWindow
 *
 * Data structure for storing a limited number of blocks
 */
typedef struct BlockchainWindow {
	uint8_t head;
	BlockChainMsg msgs[BC_WIN_SIZE];
} BlockchainWindow;

/*
 * NodeInfo structure
 *
 * Contains all the required fields (for a single node) for checking the blocks
 * validity
 */
typedef struct NodeInfo {
	uint8_t prevHash[HASH_SIZE]; // Hash of the plaintext of the last message from node n
	uint32_t lastTimestamp; // local timestamp of the last message from node n
} NodeInfo;

/*
 * WSNBlockChain structure
 *
 * Data for a single blockchain. It contains the nodes last values and the
 * collection of the stored blocks
 */
typedef struct WSNBlockChain {
	NodeInfo nodeInfo[NUM_OF_NODES];
	BlockchainWindow blocks[NUM_OF_NODES];
} WSNBlockChain;

// Special chains

// Initial (unassigned) chain (valid only at boot time)
#define CHAIN_NONE 0
// Virtual blockchain for discarding data from VERY unrealiable nodes
#define CHAIN_DENIED 0xFF

/*
 * WSNLedger
 *
 * Ledger containing all the blockchains and additional data for
 * tracking the WSN nodes behavior
 */
typedef struct WSNLedger {
	WSNBlockChain chains[NUM_OF_CHAINS];
	uint8_t currentChainForNode[NUM_OF_NODES]; // current blockchain

	/*
	 * The reliability points determine in which blockchain the message is appended.
	 * The point increment/decrement happen after every received message
	 */
	uint8_t nodesReliability[NUM_OF_NODES]; // reliability points (0->0xFF)
} WSNLedger;

/*
 * Thresholds multiplier to switch to a different blockchain
 * example THRESH_MULTIPLIER = 3
 * from CHAIN 1 to CHAIN 2, 3 points are needed
 * from CHAIN 1 to CHAIN 3, 3+3=6 point are needed
 * ...
 * from CHAIN 1 to CHAIN n, 3*n point are needed
 *
 * After that, CHAIN_DENIED occurs
 */
#define THRESH_MULTIPLIER 10

// Number of microseconds after which a timestamp is considered wrong
#define TS_THRESHOLD 50000U

// Reasons and relative point increase/decrease
#define RELPOINTS_WRONG_HASH THRESH_MULTIPLIER*2
#define RELPOINTS_WRONG_TS 1
#define RELPOINTS_GOOD_HASH 1
#define RELPOINTS_GOOD_TS 0 // No increase


#endif // WSN_LEDGER_H
