#include <Timer.h>
#include "../Message.h"
#include "mda100.h"

module WSNBlockchainClientM {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	//uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface HashFunctionI;
	uses interface Random;
	uses interface Read<uint16_t> as LightSensor;
	uses interface LocalTime<TMicro>;
}

implementation {
	uint16_t counter;
	message_t pkt;
	bool busy = FALSE;

	// Node prevHash tables
	uint8_t prevHash[HASH_SIZE];
	uint32_t prevTimestamp;

	event void Boot.booted() {
		call Leds.set(0);
		memset(prevHash, 0, HASH_SIZE);
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Leds.led0On();
			busy = FALSE;
			call Timer0.startPeriodic(1000);
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

	event void Timer0.fired() {
		call Leds.led2On();
		call LightSensor.read();
	}

	event void LightSensor.readDone(error_t success, uint16_t value) {
		int i;
		call Leds.led2Off();
		if (!busy) {
			BlockChainMsg* msg = call Packet.getPayload(&pkt, sizeof(BlockChainMsg));
			if (msg == NULL)
				return;
			call Leds.led1On();
			msg->node_id = TOS_NODE_ID;
			msg->content.payload[0] = value & 0xFF;
			msg->content.payload[1] = value >> 8;
			//msg->content.payload[0] = 0x77;
			//msg->content.payload[1] = 0x99;
			memset(&msg->content.payload[2], 0, MAX_PAYLOAD-2);
			//memset(msg->content.nonce, 0, NONCE_SIZE);
			setNonce(msg->content.nonce, NONCE_SIZE);
			msg->content.ts_delta = call LocalTime.get();
			memcpy(msg->content.prevHash, prevHash, HASH_SIZE);

			//crypt((uint8_t*)&msg->content, sizeof(InnerBlockChainMsg));

			if (call AMSend.send(0, &pkt, sizeof(BlockChainMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}

	event void AMSend.sendDone(message_t* tmsg, error_t err) {
		if (&pkt == tmsg) {
			if (err == SUCCESS) {
				BlockChainMsg* msg = call Packet.getPayload(&pkt, sizeof(BlockChainMsg));
				call HashFunctionI.getDigest(prevHash, msg, sizeof(BlockChainMsg));
				printhex(prevHash, HASH_SIZE);
			}
			busy = FALSE;
			call Leds.led1Off();
		}
	}
}
