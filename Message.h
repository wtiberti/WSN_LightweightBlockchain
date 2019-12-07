#ifndef WSN_BLOCKCHAIN_H
#define WSN_BLOCKCHAIN_H

#include <stdio.h>
#include <stdlib.h>

#define NONCE_SIZE 4
#define MAX_PAYLOAD 32
#define HASH_SIZE 32
#define TOSH_DATA_LENGTH (6+NONCE_SIZE+MAX_PAYLOAD+HASH_SIZE)

typedef struct InnerBlockChainMsg {
	uint8_t nonce[NONCE_SIZE];
	uint8_t payload[MAX_PAYLOAD];
	uint8_t prevHash[HASH_SIZE];
	uint32_t ts_delta;
} InnerBlockChainMsg;

typedef struct BlockChainMsg {
	uint16_t node_id;
	InnerBlockChainMsg content;
} BlockChainMsg;


void printhex(uint8_t *data, size_t size)
{
	int i;
	for (i = 0; i < size; ++i)
		printf("%02x", data[i]);
	printf("\r\n");
}

// TODO - for sake of demonstration, we use the
// following naïve algorithm as symmetric cipher
void crypt(uint8_t *data, size_t size)
{
	int i;
	// TODO - for sake of demonstration,
	// we suppose a fixed, pre-programmed key
	uint8_t key = 0x42;
	for (i = 0; i < size; ++i)
		data[i] ^= key;
}

#endif // WSN_BLOCKCHAIN_H
