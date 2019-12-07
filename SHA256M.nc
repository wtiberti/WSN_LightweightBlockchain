#include <stdlib.h>
#include <stdint.h>

module SHA256M {
	provides interface HashFunctionI;
}

implementation {
	#include "sha256.h"

	command int HashFunctionI.getDigest(void *result, void *data, size_t size)
	{
		sha256_digest(result, data, size);
		return 0;
	}

	command uint8_t HashFunctionI.getHashLength()
	{
		return 32;
	}

	void sha256_transform(struct SHA256_Context *ctx, const uint8_t *data)
	{
		uint32_t workvars[8];
		uint32_t t1;
		uint32_t t2;
		uint32_t m[64];
		size_t i;
		uint32_t temp;

		for (i = 0; i < 16; ++i) {
			int j = i << 2;
			temp = data[j];
			temp <<= 8;
			temp |= data[j + 1];
			temp <<= 8;
			temp |= data[j + 2];
			temp <<= 8;
			temp |= data[j + 3];
			m[i] = temp;
		}
		for ( ; i < 64; ++i) {
			m[i] =  SMALLSIGMA1(m[i - 2]) + m[i - 7] +
				SMALLSIGMA0(m[i - 15]) + m[i - 16];
		}

		memcpy(workvars, ctx->state, sizeof(uint32_t) * 8);
		for (i = 0; i < 64; ++i) {
			t1 = workvars[7] +
				SIGMA1(workvars[4]) +
				CH(workvars[4], workvars[5], workvars[6]) +
				k[i] +
				m[i];
			t2 = SIGMA0(workvars[0]) +
				MAJ(workvars[0], workvars[1], workvars[2]);
			workvars[7] = workvars[6];
			workvars[6] = workvars[5];
			workvars[5] = workvars[4];
			workvars[4] = workvars[3] + t1;
			workvars[3] = workvars[2];
			workvars[2] = workvars[1];
			workvars[1] = workvars[0];
			workvars[0] = t1 + t2;
		}
		for (i = 0; i < 8; i++)
			ctx->state[i] += workvars[i];
	}

	void sha256_init(struct SHA256_Context *ctx)
	{
		ctx->datalen = 0;
		ctx->bitlen = 0;
		ctx->state[0] = 0x6a09e667;
		ctx->state[1] = 0xbb67ae85;
		ctx->state[2] = 0x3c6ef372;
		ctx->state[3] = 0xa54ff53a;
		ctx->state[4] = 0x510e527f;
		ctx->state[5] = 0x9b05688c;
		ctx->state[6] = 0x1f83d9ab;
		ctx->state[7] = 0x5be0cd19;
	}

	void sha256_update(struct SHA256_Context *ctx, const uint8_t *data, size_t len)
	{
		uint32_t i;

		for (i = 0; i < len; ++i) {
			ctx->data[ctx->datalen] = data[i];
			ctx->datalen++;
			if (ctx->datalen == 64) {
				sha256_transform(ctx, ctx->data);
				ctx->bitlen += 512;
				ctx->datalen = 0;
			}
		}
	}

	void sha256_compute(struct SHA256_Context *ctx, uint8_t *hash)
	{
		uint32_t i = ctx->datalen;
		if (ctx->datalen < 56) {
			ctx->data[i++] = 0x80;
			while (i < 56)
				ctx->data[i++] = 0x00;
		}
		else {
			ctx->data[i++] = 0x80;
			while (i < 64)
				ctx->data[i++] = 0x00;
			sha256_transform(ctx, ctx->data);
			memset(ctx->data, 0, 56);
		}

		ctx->bitlen += ctx->datalen * 8;
		ctx->data[63] = (uint8_t)(ctx->bitlen & 0xFF);
		ctx->data[62] = (uint8_t)((ctx->bitlen >>  8) & 0xFF);
		ctx->data[61] = (uint8_t)((ctx->bitlen >> 16) & 0xFF);
		ctx->data[60] = (uint8_t)((ctx->bitlen >> 24) & 0xFF);
		ctx->data[59] = (uint8_t)((ctx->bitlen >> 32) & 0xFF);
		ctx->data[58] = (uint8_t)((ctx->bitlen >> 40) & 0xFF);
		ctx->data[57] = (uint8_t)((ctx->bitlen >> 48) & 0xFF);
		ctx->data[56] = (uint8_t)((ctx->bitlen >> 56) & 0xFF);
		sha256_transform(ctx, ctx->data);

		for (i = 0; i < 4; ++i) {
			hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0xFF;
			hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0xFF;
			hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0xFF;
			hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0xFF;
			hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0xFF;
			hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0xFF;
			hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0xFF;
			hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0xFF;
		}
	}

	void sha256_digest(uint8_t *result, uint8_t *data, size_t datasize)
	{
		struct SHA256_Context ctx;
		sha256_init(&ctx);
		sha256_update(&ctx, data, datasize);
		sha256_compute(&ctx, result);
	}
}
