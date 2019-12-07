#include "Ledger.h"

interface LedgerI {
	command void Init(WSNLedger *l);
	command void *ReadMessage(WSNLedger *l, BlockChainMsg *msg, uint32_t arrival_time);
}
