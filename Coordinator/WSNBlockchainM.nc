#include <Timer.h>
#include "../Message.h"
#include "../Ledger.h"

module WSNBlockchainM {
	uses interface Boot;
	uses interface Leds;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface HashFunctionI;
	uses interface LocalTime<TMicro>;
	uses interface LedgerI;
}

implementation {
	uint16_t counter;
	message_t pkt;
	bool busy = FALSE;
	WSNLedger l;

	event void Boot.booted() {
		call Leds.set(0);
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call LedgerI.Init(&l);
			call Leds.led0On();
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) { }

	event message_t* Receive.receive(message_t* tmsg, void* payload, uint8_t len){
		uint32_t arrival_time = call LocalTime.get();
		if (len == sizeof(BlockChainMsg)) {
			BlockChainMsg* msg = (BlockChainMsg*) payload;
			printf("[%lu] Message Incoming from node %d\r\n", arrival_time, msg->node_id);
			call LedgerI.ReadMessage(&l, msg, arrival_time);
		}
		return tmsg;
	}
}
