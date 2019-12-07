#include <Timer.h>
#include "../Message.h"
#include "../Ledger.h"

#define SAMPLES 16

module WSNBlockchainPPM {
	uses interface Boot;
	uses interface Leds;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface HashFunctionI;
	uses interface LocalTime<TMicro>;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Random;
	uses interface Read<uint16_t> as LightSensor;
	uses interface LedgerI;
}

implementation {
	uint16_t counter;
	message_t pkt;
	bool busy = FALSE;
	WSNLedger l;
	uint8_t prevHash[HASH_SIZE];
	uint32_t prevTimestamp;

	uint32_t PERF = 0;
	uint32_t PERF2 = 0;
	uint8_t n_samples = 0;

	void newIteration();
	void setNonce(uint8_t *data, size_t size);

	event void Boot.booted() {
		call Leds.set(0);
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call LedgerI.Init(&l);
			call Leds.led0On();
			if (TOS_NODE_ID == 0)
				newIteration();
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) { }

	void setNonce(uint8_t *data, size_t size)
	{
		int i;
		for (i = 0; i < size; i += 2) {
			uint16_t v = call Random.rand16();
			data[i] = v & 0xFF;
			data[i+1] = v >> 8;
		}
	}

	void newIteration() {
		//printf("Starting iteration\r\n");
		// -----
		atomic{PERF = call LocalTime.get();}
		// -----
		call Leds.led2On();
		call LightSensor.read();
	}

	event void LightSensor.readDone(error_t success, uint16_t value) {
		call Leds.led2Off();
		if (!busy) {
			BlockChainMsg* msg = call Packet.getPayload(&pkt, sizeof(BlockChainMsg));
			if (msg == NULL)
				return;
			msg->node_id = TOS_NODE_ID;
			msg->content.payload[n_samples*2 + 0] = value & 0xFF;
			msg->content.payload[n_samples*2 + 1] = value >> 8;
			n_samples++;
			if (n_samples < SAMPLES)
				call LightSensor.read();
			else {
				call Leds.led1On();
				memset(&msg->content.payload[n_samples*2], 0, MAX_PAYLOAD-n_samples*2);
				setNonce(msg->content.nonce, NONCE_SIZE);
				msg->content.ts_delta = call LocalTime.get();
				memcpy(msg->content.prevHash, prevHash, HASH_SIZE);

				//crypt((uint8_t*)&msg->content, sizeof(InnerBlockChainMsg));

				if (call AMSend.send(TOS_NODE_ID ^ 1, &pkt, sizeof(BlockChainMsg)) == SUCCESS) {
					busy = TRUE;
				}
			}
		}
	}

	event void AMSend.sendDone(message_t* tmsg, error_t err) {
		n_samples = 0;
		if (&pkt == tmsg) {
			if (err == SUCCESS) {
				BlockChainMsg* msg = call Packet.getPayload(&pkt, sizeof(BlockChainMsg));
				call HashFunctionI.getDigest(prevHash, msg, sizeof(BlockChainMsg));
			}
			busy = FALSE;
			call Leds.led1Off();
		}
	}

	event message_t* Receive.receive(message_t* tmsg, void* payload, uint8_t len){
		uint32_t arrival_time = call LocalTime.get();
		if (len == sizeof(BlockChainMsg)) {
			BlockChainMsg* msg = (BlockChainMsg*) payload;
			//printf("[%lu] Message Incoming from node %d\r\n", arrival_time, msg->node_id);
			call LedgerI.ReadMessage(&l, msg, arrival_time);
		}
		// -----
		atomic{
			PERF2 = call LocalTime.get();
			//printf("%lu - %lu = \x1b[93m%lu\x1b[0m\r\n", PERF2, PERF, PERF2-PERF);
			printf("%lu\r\n", PERF2-PERF);
		}
		// -----
		newIteration();
		return tmsg;
	}
}
