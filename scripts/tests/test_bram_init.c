#include "../bram_init.h"

#include <assert.h>
#include <inttypes.h>
#include <sys/stat.h>

static void make_path(char *out, size_t size, const char *dir, const char *name)
{
	assert(snprintf(out, size, "%s/%s", dir, name) < (int)size);
}

static void write_fixture(const char *path, const unsigned char *data, size_t len)
{
	FILE *fp = fopen(path, "wb");
	assert(fp != NULL);
	assert(fwrite(data, 1, len, fp) == len);
	assert(fclose(fp) == 0);
}

static unsigned hex_value(char c)
{
	if (c >= '0' && c <= '9')
		return (unsigned)(c - '0');
	if (c >= 'A' && c <= 'F')
		return (unsigned)(c - 'A' + 10);
	assert(c >= 'a' && c <= 'f');
	return (unsigned)(c - 'a' + 10);
}

static unsigned get_init_bit(const char *params, unsigned init, unsigned block,
			     unsigned lane, unsigned bit)
{
	char name[64];
	char *line;
	char *hex;
	unsigned nibble;
	unsigned nibble_bit;

	assert(snprintf(name, sizeof(name), "localparam INIT_%02X_%u_%u = 288'h",
			init, block, lane) < (int)sizeof(name));
	line = strstr(params, name);
	assert(line != NULL);
	hex = strchr(line, 'h');
	assert(hex != NULL);
	++hex;
	nibble = hex_value(hex[(287U - bit) / 4U]);
	nibble_bit = bit % 4U;
	return (nibble >> nibble_bit) & 1U;
}

static uint16_t decode_halfword(const char *params, unsigned word_address,
				unsigned lane)
{
	unsigned block = word_address / 2048U;
	unsigned within = word_address % 2048U;
	unsigned init = within / 16U;
	unsigned slot = within % 16U;
	unsigned base = slot * 18U;
	uint16_t half = 0;
	unsigned bit;
	for (bit = 0; bit < 8; ++bit) {
		half |= (uint16_t)(get_init_bit(params, init, block, lane,
						       base + bit) << bit);
		half |= (uint16_t)(get_init_bit(params, init, block, lane,
						       base + 9U + bit) << (8U + bit));
	}
	return half;
}

int main(int argc, char **argv)
{
	char valid_path[1024];
	char empty_path[1024];
	char short_path[1024];
	char invalid_path[1024];
	char long_path[1024];
	char nul_path[1024];
	char many_path[1024];
	char full_path[1024];
	const unsigned char valid[] = "  11223344\r\n\t55667788  \n";
	const unsigned char short_token[] = "1234567\n";
	const unsigned char invalid[] = "0000001g\n";
	const unsigned char embedded_nul[] = { '0','0','0','0','0','0','1','3',0,'\n' };
	const unsigned char long_token[] = "000000001\n";
	BramInitImage image;
	char *line;
	char *end;
	unsigned i;
	FILE *fp;

	assert(argc == 2 || argc == 3);
	make_path(valid_path, sizeof(valid_path), argv[1], "valid.hex");
	make_path(empty_path, sizeof(empty_path), argv[1], "empty.hex");
	make_path(short_path, sizeof(short_path), argv[1], "short.hex");
	make_path(invalid_path, sizeof(invalid_path), argv[1], "invalid.hex");
	make_path(long_path, sizeof(long_path), argv[1], "long.hex");
	make_path(nul_path, sizeof(nul_path), argv[1], "nul.hex");
	make_path(many_path, sizeof(many_path), argv[1], "many.hex");
	make_path(full_path, sizeof(full_path), argv[1], "full.hex");

	write_fixture(valid_path, valid, sizeof(valid) - 1);
	write_fixture(empty_path, (const unsigned char *)" \r\n\t", 4);
	write_fixture(short_path, short_token, sizeof(short_token) - 1);
	write_fixture(invalid_path, invalid, sizeof(invalid) - 1);
	write_fixture(long_path, long_token, sizeof(long_token) - 1);
	write_fixture(nul_path, embedded_nul, sizeof(embedded_nul));
	fp = fopen(many_path, "wb");
	assert(fp != NULL);
	for (i = 0; i < BRAM_INIT_WORDS + 1; ++i)
		assert(fputs("00000013\n", fp) >= 0);
	assert(fclose(fp) == 0);

	assert(bram_init_prepare(valid_path, &image) == 0);
	assert(image.word_count == 2);
	assert(image.sum32 == UINT32_C(0x6688aacc));
	assert(strncmp(image.words_hex, "11223344\n55667788\n00000013\n", 27) == 0);
	assert(strcmp(image.words_hex + (BRAM_INIT_WORDS - 1) * 9,
		      "00000013\n") == 0);
	line = strstr(image.params, "localparam INIT_00_0_0 = 288'h");
	assert(line != NULL);
	end = strchr(line, '\n');
	assert(end != NULL && end - 9 >= line);
	assert(strncmp(end - 10, "3BA206644", 9) == 0);
	assert(strstr(image.params, "localparam INIT_00 = { INIT_00_3_1, INIT_00_3_0,") != NULL);
	bram_init_free(&image);
	assert(image.params == NULL && image.words_hex == NULL);

	assert(bram_init_prepare(empty_path, &image) != 0);
	assert(bram_init_prepare(short_path, &image) != 0);
	assert(bram_init_prepare(invalid_path, &image) != 0);
	assert(bram_init_prepare(long_path, &image) != 0);
	assert(bram_init_prepare(nul_path, &image) != 0);
	assert(bram_init_prepare(many_path, &image) != 0);
	fp = fopen(full_path, "wb");
	assert(fp != NULL);
	for (i = 0; i < BRAM_INIT_WORDS; ++i) {
		uint32_t value = (UINT32_C(0x9e3779b9) * (i + 1U)) ^
				 ((uint32_t)i << 16);
		assert(fprintf(fp, "%08" PRIX32 "\n", value) > 0);
	}
	assert(fclose(fp) == 0);
	assert(bram_init_prepare(full_path, &image) == 0);
	assert(image.word_count == BRAM_INIT_WORDS);
	for (i = 0; i < BRAM_INIT_WORDS; ++i) {
		uint32_t source = (UINT32_C(0x9e3779b9) * (i + 1U)) ^
				  ((uint32_t)i << 16);
		uint32_t decoded = decode_halfword(image.params, i, 0) |
				   ((uint32_t)decode_halfword(image.params, i, 1) << 16);
		assert(decoded == source);
	}
	bram_init_free(&image);
	if (argc == 3) {
		assert(bram_init_prepare(argv[2], &image) == 0);
		assert(image.word_count == BRAM_INIT_WORDS);
		printf("verified image: %zu words, sum32=%08" PRIX32 "\n",
		       image.word_count, image.sum32);
		bram_init_free(&image);
	}

	puts("bram-init parser and vendor packing tests passed");
	return 0;
}
