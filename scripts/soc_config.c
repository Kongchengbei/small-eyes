/* Native configuration backend for the SoC Kconfig frontend.
 * This program deliberately does not invoke a shell, Python, or an expression
 * evaluator. It parses the small numeric Verilog-preprocessor subset used by
 * soc_addr_map.vh and writes generated artifacts beneath the requested output.
 */
#define _POSIX_C_SOURCE 200809L
#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define MAX_DEFS 512
#define NAME_CAP 128
#define EXPR_CAP 1024
#define LINE_CAP 4096
#define PATH_CAP 4096

typedef struct {
    char name[NAME_CAP];
    char expr[EXPR_CAP];
    uint64_t value;
    int state; /* 0 unresolved, 1 resolving, 2 resolved */
} Definition;

typedef struct {
    Definition items[MAX_DEFS];
    size_t count;
    char error[1024];
} Definitions;

typedef struct {
    const char *text;
    size_t pos;
    Definitions *defs;
} ExprParser;

typedef struct {
    char profile[16];
    char firmware[PATH_CAP];
    uint64_t flash_base;
    uint64_t image_bytes;
    bool preprocess;
    bool uart_remote;
} Config;

static const char *editable_names[] = {
    "SOC_CPU_MEM_BRAM", "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE",
    "SOC_ENABLE_DDR", "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS",
    "SOC_FLASH_BASE", "SOC_BOOT_IMAGE_BYTES", "SOC_UART_TX_FPIOA"
};

static char *trim(char *s) {
    while (isspace((unsigned char)*s)) ++s;
    size_t n = strlen(s);
    while (n && isspace((unsigned char)s[n - 1])) s[--n] = '\0';
    return s;
}

static int read_file(const char *path, char **out, size_t *length) {
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return -1; }
    long n = ftell(f);
    if (n < 0 || fseek(f, 0, SEEK_SET) != 0) { fclose(f); return -1; }
    char *buf = malloc((size_t)n + 1);
    if (!buf) { fclose(f); errno = ENOMEM; return -1; }
    size_t got = fread(buf, 1, (size_t)n, f);
    int failed = ferror(f);
    fclose(f);
    if (failed || got != (size_t)n) { free(buf); errno = EIO; return -1; }
    buf[got] = '\0';
    *out = buf;
    if (length) *length = got;
    return 0;
}

static int write_all(FILE *f, const char *s, size_t n) {
    return fwrite(s, 1, n, f) == n ? 0 : -1;
}

static int atomic_write(const char *path, const char *data, size_t len) {
    struct stat old_st;
    bool had_old = stat(path, &old_st) == 0;
    char tmp[PATH_CAP + 32];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp.XXXXXX", path) >= (int)sizeof(tmp)) {
        errno = ENAMETOOLONG; return -1;
    }
    int fd = mkstemp(tmp);
    if (fd < 0) return -1;
    if (had_old && fchmod(fd, old_st.st_mode & 07777) != 0) {
        int saved = errno;
        close(fd); unlink(tmp); errno = saved; return -1;
    }
    FILE *f = fdopen(fd, "wb");
    if (!f) { close(fd); unlink(tmp); return -1; }
    int bad = write_all(f, data, len) || fflush(f) || fsync(fd);
    if (fclose(f) != 0) bad = 1;
    if (!bad && rename(tmp, path) == 0) return 0;
    int saved = errno;
    unlink(tmp);
    errno = saved;
    return -1;
}

static int mkdir_p(const char *path) {
    char copy[PATH_CAP];
    if (strlen(path) >= sizeof(copy)) { errno = ENAMETOOLONG; return -1; }
    strcpy(copy, path);
    for (char *p = copy + 1; *p; ++p) {
        if (*p == '/') {
            *p = '\0';
            if (mkdir(copy, 0777) != 0 && errno != EEXIST) return -1;
            *p = '/';
        }
    }
    if (mkdir(copy, 0777) != 0 && errno != EEXIST) return -1;
    return 0;
}

static void parser_error(ExprParser *p, const char *message) {
    if (!p->defs->error[0]) {
        snprintf(p->defs->error, sizeof(p->defs->error),
                 "unsupported or invalid expression near '%.120s': %s",
                 p->text + p->pos, message);
    }
}

static void skip_space(ExprParser *p) {
    while (isspace((unsigned char)p->text[p->pos])) ++p->pos;
}

static Definition *find_def(Definitions *d, const char *name) {
    for (size_t i = 0; i < d->count; ++i)
        if (strcmp(d->items[i].name, name) == 0) return &d->items[i];
    return NULL;
}

static int resolve_def(Definitions *d, Definition *def, uint64_t *out);

static bool parse_uint_digits(const char *s, size_t *pos, unsigned base,
                              uint64_t *out, bool allow_underscores) {
    bool any = false;
    uint64_t value = 0;
    for (;;) {
        unsigned char c = (unsigned char)s[*pos];
        if (c == '_' && allow_underscores) { ++*pos; continue; }
        unsigned digit;
        if (c >= '0' && c <= '9') digit = c - '0';
        else if (c >= 'a' && c <= 'f') digit = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') digit = c - 'A' + 10;
        else break;
        if (digit >= base) break;
        if (value > (UINT64_MAX - digit) / base) return false;
        value = value * base + digit;
        any = true;
        ++*pos;
    }
    if (!any) return false;
    *out = value;
    return true;
}

static bool parse_number(ExprParser *p, uint64_t *out) {
    size_t start = p->pos, q = start;
    uint64_t value = 0;
    if (isdigit((unsigned char)p->text[q])) {
        size_t digits = q;
        while (isdigit((unsigned char)p->text[q])) ++q;
        if (p->text[q] == '\'' || (p->text[q] == '\'' && p->text[q + 1])) {
            uint64_t width = 0;
            size_t w = digits;
            if (!parse_uint_digits(p->text, &w, 10, &width, false)) return false;
            ++q; /* apostrophe */
            if (p->text[q] == 's' || p->text[q] == 'S') ++q;
            char b = (char)tolower((unsigned char)p->text[q++]);
            unsigned base = b == 'b' ? 2 : b == 'o' ? 8 : b == 'd' ? 10 : b == 'h' ? 16 : 0;
            if (!base) { parser_error(p, "invalid Verilog literal base"); return false; }
            size_t dpos = q;
            for (size_t k = q; p->text[k] && !isspace((unsigned char)p->text[k]) &&
                              p->text[k] != ')' && p->text[k] != '+' && p->text[k] != '-'; ++k) {
                if (tolower((unsigned char)p->text[k]) == 'x' ||
                    tolower((unsigned char)p->text[k]) == 'z' || p->text[k] == '?') {
                    parser_error(p, "unknown/high-impedance Verilog digit is not supported");
                    return false;
                }
            }
            if (!parse_uint_digits(p->text, &dpos, base, &value, true)) {
                parser_error(p, "invalid Verilog literal digits"); return false;
            }
            if (p->text[dpos] && !isspace((unsigned char)p->text[dpos]) &&
                p->text[dpos] != ')' && p->text[dpos] != '+' && p->text[dpos] != '-') {
                parser_error(p, "invalid Verilog literal suffix"); return false;
            }
            if (width && width < 64) value &= (UINT64_C(1) << width) - 1;
            p->pos = dpos;
            *out = value;
            return true;
        }
        if (p->text[start] == '0' && (p->text[start + 1] == 'x' || p->text[start + 1] == 'X')) {
            q = start + 2;
            if (!parse_uint_digits(p->text, &q, 16, &value, true)) {
                parser_error(p, "invalid hexadecimal literal"); return false;
            }
        } else {
            q = start;
            if (!parse_uint_digits(p->text, &q, 10, &value, false)) return false;
        }
        p->pos = q;
        *out = value;
        return true;
    }
    return false;
}

static bool parse_sum(ExprParser *p, uint64_t *out);

static bool parse_primary(ExprParser *p, uint64_t *out) {
    skip_space(p);
    if (p->text[p->pos] == '(') {
        ++p->pos;
        if (!parse_sum(p, out)) return false;
        skip_space(p);
        if (p->text[p->pos] != ')') { parser_error(p, "missing closing parenthesis"); return false; }
        ++p->pos;
        return true;
    }
    if (parse_number(p, out)) return true;
    if (p->defs->error[0]) return false;
    if (p->text[p->pos] == '`') ++p->pos;
    if (isalpha((unsigned char)p->text[p->pos]) || p->text[p->pos] == '_') {
        char name[NAME_CAP]; size_t n = 0;
        while (isalnum((unsigned char)p->text[p->pos]) || p->text[p->pos] == '_') {
            if (n + 1 >= sizeof(name)) { parser_error(p, "macro name is too long"); return false; }
            name[n++] = p->text[p->pos++];
        }
        name[n] = '\0';
        Definition *d = find_def(p->defs, name);
        if (!d) {
            snprintf(p->defs->error, sizeof(p->defs->error), "undefined macro %s", name);
            return false;
        }
        return resolve_def(p->defs, d, out) == 0;
    }
    parser_error(p, "expected a number, macro reference, or parenthesized expression");
    return false;
}

static bool parse_sum(ExprParser *p, uint64_t *out) {
    uint64_t value;
    if (!parse_primary(p, &value)) return false;
    for (;;) {
        skip_space(p);
        char op = p->text[p->pos];
        if (op != '+' && op != '-') break;
        ++p->pos;
        uint64_t rhs;
        if (!parse_primary(p, &rhs)) return false;
        if (op == '+') {
            if (UINT64_MAX - value < rhs) { parser_error(p, "addition overflows 64 bits"); return false; }
            value += rhs;
        } else {
            if (rhs > value) { parser_error(p, "negative expression values are unsupported"); return false; }
            value -= rhs;
        }
    }
    *out = value;
    return true;
}

static int eval_expr(Definitions *d, const char *expr, uint64_t *out) {
    ExprParser p = { .text = expr, .pos = 0, .defs = d };
    d->error[0] = '\0';
    if (!parse_sum(&p, out)) return -1;
    skip_space(&p);
    if (p.text[p.pos]) { parser_error(&p, "trailing tokens are not supported"); return -1; }
    return d->error[0] ? -1 : 0;
}

static int resolve_def(Definitions *d, Definition *def, uint64_t *out) {
    if (def->state == 2) { *out = def->value; return 0; }
    if (def->state == 1) {
        snprintf(d->error, sizeof(d->error), "cyclic macro alias/expression involving %s", def->name);
        return -1;
    }
    def->state = 1;
    uint64_t value;
    if (eval_expr(d, def->expr, &value) != 0) {
        if (strstr(d->error, "undefined macro") == NULL && strstr(d->error, "cyclic") == NULL) {
            char detail[sizeof(d->error)]; strcpy(detail, d->error);
            snprintf(d->error, sizeof(d->error), "%.120s: %.800s", def->name, detail);
        }
        def->state = 0;
        return -1;
    }
    def->value = value;
    def->state = 2;
    *out = value;
    return 0;
}

static int parse_definitions_text(const char *text, Definitions *d) {
    memset(d, 0, sizeof(*d));
    char *copy = strdup(text);
    if (!copy) return -1;
    char *save = NULL;
    size_t line_no = 0;
    for (char *line = strtok_r(copy, "\n", &save); line; line = strtok_r(NULL, "\n", &save)) {
        ++line_no;
        char *comment = strstr(line, "//");
        if (comment) *comment = '\0';
        char *p = trim(line);
        if (strncmp(p, "`define", 7) != 0 || !isspace((unsigned char)p[7])) continue;
        p = trim(p + 7);
        char name[NAME_CAP]; size_t n = 0;
        while ((isalnum((unsigned char)*p) || *p == '_') && n + 1 < sizeof(name)) name[n++] = *p++;
        name[n] = '\0';
        p = trim(p);
        if (!n || !*p) continue;
        if (find_def(d, name)) {
            snprintf(d->error, sizeof(d->error), "duplicate definition %s at line %zu", name, line_no);
            free(copy); return -1;
        }
        if (d->count == MAX_DEFS || strlen(p) >= EXPR_CAP) {
            snprintf(d->error, sizeof(d->error), "too many definitions or expression too long");
            free(copy); return -1;
        }
        Definition *def = &d->items[d->count++];
        strcpy(def->name, name); strcpy(def->expr, p);
    }
    free(copy);
    for (size_t i = 0; i < d->count; ++i) {
        uint64_t value;
        if (resolve_def(d, &d->items[i], &value) != 0) return -1;
    }
    return 0;
}

static int load_defs(const char *path, Definitions *d, char **source_text) {
    size_t n;
    if (read_file(path, source_text, &n) != 0) return -1;
    if (parse_definitions_text(*source_text, d) != 0) {
        fprintf(stderr, "soc_config: %s: %s\n", path, d->error);
        return -2;
    }
    return 0;
}

static bool get_value(Definitions *d, const char *name, uint64_t *value) {
    Definition *def = find_def(d, name);
    if (!def) {
        fprintf(stderr, "soc_config: missing required definition %s\n", name);
        return false;
    }
    *value = def->value;
    return true;
}

static bool validate_defs(Definitions *d) {
    static const char *required[] = {
        "SOC_CPU_MEM_BRAM", "SOC_FLASH_BASE", "SOC_FLASH_ADDRESS_BYTES",
        "SOC_BOOT_IMAGE_BYTES", "SOC_IRAM_BASE", "SOC_IRAM_BYTES",
        "SOC_DRAM_BASE", "SOC_DRAM_BYTES", "SOC_UART_TX_FPIOA",
        "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR",
        "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS", "SOC_DDR_BASE", "SOC_DDR_BYTES"
    };
    uint64_t v[sizeof(required) / sizeof(required[0])];
    for (size_t i = 0; i < sizeof(required) / sizeof(required[0]); ++i)
        if (!get_value(d, required[i], &v[i])) return false;
#define V(name) (find_def(d, name)->value)
    if (V("SOC_CPU_MEM_BRAM") > 1) { fprintf(stderr, "soc_config: SOC_CPU_MEM_BRAM must be 0 or 1\n"); return false; }
    const char *bools[] = { "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR", "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS" };
    for (size_t i = 0; i < sizeof(bools)/sizeof(bools[0]); ++i)
        if (V(bools[i]) > 1) { fprintf(stderr, "soc_config: %s must be 0 or 1\n", bools[i]); return false; }
    uint64_t expected_hw = V("SOC_CPU_MEM_BRAM") ? 0 : 1;
    const char *hw[] = { "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR", "SOC_ENABLE_CAMERA" };
    for (size_t i = 0; i < sizeof(hw)/sizeof(hw[0]); ++i)
        if (V(hw[i]) != expected_hw) { fprintf(stderr, "soc_config: %s=%" PRIu64 " is unsupported for %s profile\n", hw[i], V(hw[i]), expected_hw ? "full DDR" : "BRAM"); return false; }
    if (V("SOC_CPU_MEM_BRAM") && V("SOC_ENABLE_PREPROCESS")) { fprintf(stderr, "soc_config: BRAM profile requires preprocessing disabled\n"); return false; }
    if (V("SOC_UART_TX_FPIOA") != 0 && V("SOC_UART_TX_FPIOA") != 31) { fprintf(stderr, "soc_config: SOC_UART_TX_FPIOA must be 0 or 31\n"); return false; }
    uint64_t flash = V("SOC_FLASH_BASE"), flash_bytes = V("SOC_FLASH_ADDRESS_BYTES"), image = V("SOC_BOOT_IMAGE_BYTES");
    if (flash % 4) { fprintf(stderr, "soc_config: SOC_FLASH_BASE must be 4-byte aligned\n"); return false; }
    if (!image) { fprintf(stderr, "soc_config: SOC_BOOT_IMAGE_BYTES must be nonzero without a selected BIN\n"); return false; }
    if (image % 4) { fprintf(stderr, "soc_config: SOC_BOOT_IMAGE_BYTES must be a multiple of 4 bytes; manually pad/align the image length\n"); return false; }
    if (flash >= flash_bytes || image > flash_bytes - flash) { fprintf(stderr, "soc_config: flash image range exceeds 24-bit flash address space\n"); return false; }
    uint64_t ib = V("SOC_IRAM_BASE"), is = V("SOC_IRAM_BYTES"), db = V("SOC_DRAM_BASE"), ds = V("SOC_DRAM_BYTES");
    if (ib % 4 || !is || is % 4 || db % 4 || !ds || ds % 4) { fprintf(stderr, "soc_config: IRAM/DRAM base and size must be nonzero and 4-byte aligned\n"); return false; }
    if (ib > UINT32_MAX || is > UINT32_MAX || db > UINT32_MAX || ds > UINT32_MAX || ib + is > UINT64_C(0x100000000) || db + ds > UINT64_C(0x100000000)) { fprintf(stderr, "soc_config: IRAM/DRAM range overflows 32-bit address space\n"); return false; }
    if (ib + is != db) { fprintf(stderr, "soc_config: BRAM layout must be contiguous (IRAM end must equal DRAM base)\n"); return false; }
    uint64_t ddrb = V("SOC_DDR_BASE"), ddrs = V("SOC_DDR_BYTES");
    if (ddrb + ddrs < ddrb || ib < ddrb || db + ds > ddrb + ddrs) { fprintf(stderr, "soc_config: IRAM/DRAM layout exceeds DDR address window\n"); return false; }
    if (V("SOC_CPU_MEM_BRAM")) {
        if (image > is + ds) { fprintf(stderr, "soc_config: BRAM profile can hold at most IRAM+DRAM bytes\n"); return false; }
    } else if (image > ddrs) { fprintf(stderr, "soc_config: boot image exceeds configured DDR capacity\n"); return false; }
#undef V
    return true;
}

static char *find_arg(int argc, char **argv, const char *name) {
    for (int i = 2; i + 1 < argc; ++i) if (strcmp(argv[i], name) == 0) return argv[i + 1];
    return NULL;
}

static int parse_cli_number(const char *s, const char *label, uint64_t *out) {
    if (!s || !*s) { fprintf(stderr, "soc_config: %s is missing\n", label); return -1; }
    errno = 0; char *end = NULL;
    unsigned long long v = strtoull(s, &end, 0);
    if (errno || !end || *trim(end) != '\0' || s[0] == '-') { fprintf(stderr, "soc_config: invalid %s: %s\n", label, s); return -1; }
    *out = (uint64_t)v; return 0;
}

static int config_get(const char *text, const char *key, char *value, size_t cap) {
    char line[LINE_CAP];
    const char *p = text;
    size_t keylen = strlen(key);
    while (*p) {
        size_t n = 0; while (p[n] && p[n] != '\n' && n + 1 < sizeof(line)) { line[n] = p[n]; ++n; }
        line[n] = '\0'; p += n; if (*p == '\n') ++p;
        char *t = trim(line);
        if (!strncmp(t, key, keylen) && t[keylen] == '=') {
            char *v = trim(t + keylen + 1);
            if (*v == '"') {
                ++v; size_t j = 0;
                while (*v && *v != '"') {
                    if (*v == '\\' && v[1]) ++v;
                    if (j + 1 >= cap) return -1;
                    value[j++] = *v++;
                }
                if (*v != '"') return -1;
                value[j] = '\0'; return 1;
            }
            if (strlen(v) >= cap) return -1;
            strcpy(value, v); return 1;
        }
    }
    return 0;
}

static bool config_bool(const char *text, const char *key, bool *out) {
    char v[32]; int found = config_get(text, key, v, sizeof(v));
    if (found == 1) { *out = !strcmp(v, "y") || !strcmp(v, "1"); return !strcmp(v, "y") || !strcmp(v, "n") || !strcmp(v, "1") || !strcmp(v, "0"); }
    char unset[160]; snprintf(unset, sizeof(unset), "# %s is not set", key);
    if (strstr(text, unset)) { *out = false; return true; }
    return false;
}

static int parse_config(const char *path, Config *c) {
    char *text = NULL;
    if (read_file(path, &text, NULL) != 0) { fprintf(stderr, "soc_config: cannot read config %s: %s\n", path, strerror(errno)); return -1; }
    bool full, bram, local, remote, preprocess;
    if (!config_bool(text, "CONFIG_SOC_PROFILE_FULL", &full) || !config_bool(text, "CONFIG_SOC_PROFILE_BRAM", &bram) || full == bram ||
        !config_bool(text, "CONFIG_SOC_UART_LOCAL", &local) || !config_bool(text, "CONFIG_SOC_UART_REMOTE", &remote) || local == remote) {
        fprintf(stderr, "soc_config: config must select exactly one profile and UART option\n"); free(text); return -1;
    }
    /* bool symbols that Kconfig omits are disabled. */
    if (!config_bool(text, "CONFIG_SOC_ENABLE_PREPROCESS", &preprocess)) preprocess = false;
    char number[128], firmware[PATH_CAP];
    if (config_get(text, "CONFIG_SOC_FLASH_BASE", number, sizeof(number)) != 1 || parse_cli_number(number, "SOC_FLASH_BASE", &c->flash_base) != 0 ||
        config_get(text, "CONFIG_SOC_BOOT_IMAGE_BYTES", number, sizeof(number)) != 1 || parse_cli_number(number, "SOC_BOOT_IMAGE_BYTES", &c->image_bytes) != 0) {
        fprintf(stderr, "soc_config: config must define SOC_FLASH_BASE and SOC_BOOT_IMAGE_BYTES\n"); free(text); return -1;
    }
    if (config_get(text, "CONFIG_SOC_FIRMWARE_BIN", firmware, sizeof(firmware)) != 1) firmware[0] = '\0';
    strcpy(c->profile, bram ? "bram" : "full");
    strcpy(c->firmware, firmware); c->preprocess = preprocess; c->uart_remote = remote;
    free(text); return 0;
}

static int seed_config(const char *source, const char *config) {
    struct stat st;
    if (stat(config, &st) == 0) { printf("Preserved existing config %s\n", config); return 0; }
    if (errno != ENOENT) { fprintf(stderr, "soc_config: cannot inspect %s: %s\n", config, strerror(errno)); return 2; }
    Definitions d; char *src = NULL;
    int rc = load_defs(source, &d, &src);
    if (rc) { free(src); return 2; }
    if (!validate_defs(&d)) { free(src); return 2; }
    uint64_t pin = find_def(&d, "SOC_UART_TX_FPIOA")->value;
    uint64_t fl = find_def(&d, "SOC_FLASH_BASE")->value;
    uint64_t len = find_def(&d, "SOC_BOOT_IMAGE_BYTES")->value;
    char buf[2048]; int n = snprintf(buf, sizeof(buf),
        "# Generated by soc_config seed; Kconfig will preserve user choices.\n"
        "%s\n%s\n"
        "%s\n"
        "%s\n"
        "CONFIG_SOC_FIRMWARE_BIN=\"\"\n"
        "CONFIG_SOC_FLASH_BASE=0x%" PRIX64 "\n"
        "CONFIG_SOC_BOOT_IMAGE_BYTES=%" PRIu64 "\n",
        find_def(&d, "SOC_CPU_MEM_BRAM")->value ? "# CONFIG_SOC_PROFILE_FULL is not set" : "CONFIG_SOC_PROFILE_FULL=y",
        find_def(&d, "SOC_CPU_MEM_BRAM")->value ? "CONFIG_SOC_PROFILE_BRAM=y" : "# CONFIG_SOC_PROFILE_BRAM is not set",
        pin == 31 ? "CONFIG_SOC_UART_REMOTE=y\n# CONFIG_SOC_UART_LOCAL is not set" : "CONFIG_SOC_UART_LOCAL=y\n# CONFIG_SOC_UART_REMOTE is not set",
        find_def(&d, "SOC_ENABLE_PREPROCESS")->value ? "CONFIG_SOC_ENABLE_PREPROCESS=y" : "# CONFIG_SOC_ENABLE_PREPROCESS is not set",
        fl, len);
    free(src);
    if (n < 0 || (size_t)n >= sizeof(buf)) { fprintf(stderr, "soc_config: seed config overflow\n"); return 2; }
    char *parent = strdup(config); if (!parent) return 2;
    char *slash = strrchr(parent, '/'); if (slash) { *slash = '\0'; if (*parent && mkdir_p(parent) != 0) { perror(parent); free(parent); return 2; } }
    free(parent);
    if (atomic_write(config, buf, (size_t)n) != 0) { fprintf(stderr, "soc_config: cannot write %s: %s\n", config, strerror(errno)); return 2; }
    return 0;
}

static void append(char *buf, size_t cap, size_t *len, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(buf + *len, cap - *len, fmt, ap); va_end(ap);
    if (n > 0 && (size_t)n < cap - *len) *len += (size_t)n;
}

static char *render_header(Definitions *d) {
    size_t cap = 128 + d->count * 80, len = 0; char *s = malloc(cap); if (!s) return NULL;
    append(s, cap, &len, "/* Generated from soc/soc_addr_map.vh by scripts/soc_config.c. */\n/* Do not edit; regenerate from the Verilog source. */\n#ifndef SOC_DEFS_H\n#define SOC_DEFS_H\n#include <stdint.h>\n\n");
    for (size_t i = 0; i < d->count; ++i) append(s, cap, &len, "#define %-34s UINT32_C(0x%08" PRIX64 ")\n", d->items[i].name, d->items[i].value);
    append(s, cap, &len, "\n#endif\n"); return s;
}

static char *render_asm(Definitions *d) {
    size_t cap = 96 + d->count * 64, len = 0; char *s = malloc(cap); if (!s) return NULL;
    append(s, cap, &len, "/* Generated from soc/soc_addr_map.vh by scripts/soc_config.c; do not edit. */\n");
    for (size_t i = 0; i < d->count; ++i) append(s, cap, &len, ".equ %s, 0x%" PRIX64 "\n", d->items[i].name, d->items[i].value);
    return s;
}

static bool same_header_values(const char *path, Definitions *defs, bool asm_mode) {
    char *text = NULL;
    if (read_file(path, &text, NULL) != 0) { fprintf(stderr, "soc_config: cannot read generated header %s: %s\n", path, strerror(errno)); return false; }
    bool ok = true;
    for (size_t i = 0; i < defs->count && ok; ++i) {
        char key[NAME_CAP + 32]; snprintf(key, sizeof(key), asm_mode ? ".equ %s," : "#define %s", defs->items[i].name);
        char *linecopy = strdup(text); if (!linecopy) { ok = false; break; }
        char *save = NULL; bool found = false;
        for (char *line = strtok_r(linecopy, "\n", &save); line; line = strtok_r(NULL, "\n", &save)) {
            char *p = trim(line);
            size_t keylen = strlen(key);
            if (strncmp(p, key, keylen) == 0 &&
                (isspace((unsigned char)p[keylen]) || p[keylen] == ',')) {
                char *v;
                if (asm_mode) {
                    v = p + keylen;
                    while (*v == ',' || isspace((unsigned char)*v)) ++v;
                } else {
                    v = strstr(p + keylen, "UINT32_C(");
                    if (!v) break;
                    v += strlen("UINT32_C(");
                }
                errno = 0;
                char *end = NULL;
                unsigned long long actual = strtoull(v, &end, 0);
                found = errno == 0 && end != v &&
                        (asm_mode || *end == ')') &&
                        (uint64_t)actual == defs->items[i].value;
                break;
            }
        }
        free(linecopy);
        if (!found) { fprintf(stderr, "soc_config: generated %s is stale or missing %s\n", asm_mode ? "assembler include" : "C header", defs->items[i].name); ok = false; }
    }
    free(text); return ok;
}

static bool editable(const char *name) {
    for (size_t i = 0; i < sizeof(editable_names)/sizeof(editable_names[0]); ++i)
        if (!strcmp(name, editable_names[i])) return true;
    return false;
}

static char *rewrite_source_text(const char *text, Definitions *defs) {
    size_t cap = strlen(text) + 1024, outlen = 0; char *out = malloc(cap); if (!out) return NULL;
    const char *p = text;
    while (*p) {
        const char *e = strchr(p, '\n'); size_t n = e ? (size_t)(e - p) + 1 : strlen(p);
        char line[LINE_CAP]; size_t body_n = n && e ? n - 1 : n;
        if (body_n >= sizeof(line)) { free(out); return NULL; }
        memcpy(line, p, body_n); line[body_n] = '\0';
        char *comment = strstr(line, "//"); if (comment) *comment = '\0';
        char *t = trim(line); bool changed = false;
        if (!strncmp(t, "`define", 7) && isspace((unsigned char)t[7])) {
            t = trim(t + 7); char name[NAME_CAP]; size_t k = 0;
            while ((isalnum((unsigned char)*t) || *t == '_') && k + 1 < sizeof(name)) name[k++] = *t++;
            name[k] = '\0';
            if (editable(name)) {
                Definition *d = find_def(defs, name);
                if (!d) { free(out); return NULL; }
                char *orig = (char *)p; const char *line_end = p + body_n;
                const char *name_at = strstr(orig, name);
                const char *value_at = name_at ? name_at + strlen(name) : NULL;
                while (value_at && value_at < line_end && isspace((unsigned char)*value_at)) ++value_at;
                const char *comment_at = strstr(orig, "//"); if (!comment_at || comment_at > line_end) comment_at = line_end;
                size_t prefix_n = value_at ? (size_t)(value_at - orig) : body_n;
                size_t suffix_n = (size_t)(line_end - comment_at);
                char value[64];
                if (!strcmp(name, "SOC_FLASH_BASE")) snprintf(value, sizeof(value), "24'h%06" PRIX64, d->value);
                else if (!strcmp(name, "SOC_BOOT_IMAGE_BYTES")) snprintf(value, sizeof(value), "32'd%" PRIu64, d->value);
                else snprintf(value, sizeof(value), "%" PRIu64, d->value);
                if (outlen + prefix_n + strlen(value) + suffix_n + 2 > cap) { cap = (outlen + prefix_n + strlen(value) + suffix_n + 2) * 2; char *b = realloc(out, cap); if (!b) { free(out); return NULL; } out = b; }
                memcpy(out + outlen, orig, prefix_n); outlen += prefix_n;
                size_t vn = strlen(value); memcpy(out + outlen, value, vn); outlen += vn;
                memcpy(out + outlen, comment_at, suffix_n); outlen += suffix_n;
                if (e) out[outlen++] = '\n';
                changed = true;
            }
        }
        if (!changed) {
            if (outlen + n + 1 > cap) { cap = (outlen + n + 1) * 2; char *b = realloc(out, cap); if (!b) { free(out); return NULL; } out = b; }
            memcpy(out + outlen, p, n); outlen += n;
        }
        p += n;
    }
    out[outlen] = '\0';
    for (size_t i = 0; i < sizeof(editable_names)/sizeof(editable_names[0]); ++i) {
        unsigned found = 0;
        static const char define_kw[] = { 0x60, 'd', 'e', 'f', 'i', 'n', 'e', '\0' };
        size_t wanted = strlen(editable_names[i]);
        for (const char *q = out; (q = strstr(q, define_kw)); ++q) {
            if (!isspace((unsigned char)q[7])) continue;
            const char *name = q + 7;
            while (isspace((unsigned char)*name)) ++name;
            if (strncmp(name, editable_names[i], wanted) == 0 &&
                isspace((unsigned char)name[wanted])) ++found;
        }
        if (found != 1) { fprintf(stderr, "soc_config: expected exactly one editable definition %s, found %u\n", editable_names[i], found); free(out); return NULL; }
    }
    return out;
}

static int file_size(const char *path, uint64_t *size) {
    struct stat st; if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) return -1;
    *size = (uint64_t)st.st_size; return 0;
}

static void json_escape(const char *s, char *out, size_t cap) {
    size_t j = 0;
    for (size_t i = 0; s[i] && j + 7 < cap; ++i) {
        unsigned char c = (unsigned char)s[i];
        if (c == '"' || c == '\\') { out[j++] = '\\'; out[j++] = (char)c; }
        else if (c == '\n') { out[j++] = '\\'; out[j++] = 'n'; }
        else if (c == '\r') { out[j++] = '\\'; out[j++] = 'r'; }
        else if (c == '\t') { out[j++] = '\\'; out[j++] = 't'; }
        else if (c < 0x20) { j += (size_t)snprintf(out + j, cap - j, "\\u%04x", c); }
        else out[j++] = (char)c;
    }
    out[j] = '\0';
}

static int copy_or_pad(const char *src, const char *dst, uint64_t target) {
    struct stat src_st, dst_st;
    if (stat(src, &src_st) != 0) return -1;
    if (strcmp(src, dst) == 0 ||
        (stat(dst, &dst_st) == 0 &&
         src_st.st_dev == dst_st.st_dev && src_st.st_ino == dst_st.st_ino)) {
        errno = EINVAL;
        return -1;
    }
    FILE *in = fopen(src, "rb"); if (!in) return -1;
    FILE *out = fopen(dst, "wb"); if (!out) { fclose(in); return -1; }
    unsigned char buf[65536]; uint64_t copied = 0; int bad = 0;
    for (;;) { size_t n = fread(buf, 1, sizeof(buf), in); if (n && fwrite(buf, 1, n, out) != n) { bad = 1; break; } copied += n; if (n < sizeof(buf)) { if (ferror(in)) bad = 1; break; } }
    if (!bad && target > copied) { memset(buf, 0xff, sizeof(buf)); uint64_t remain = target - copied; while (remain) { size_t n = remain < sizeof(buf) ? (size_t)remain : sizeof(buf); if (fwrite(buf, 1, n, out) != n) { bad = 1; break; } remain -= n; } }
    if (fclose(in) != 0) bad = 1;
    if (fclose(out) != 0) bad = 1;
    return bad ? -1 : 0;
}

static char *make_manifest(const char *source, const char *bin,
                           const char *profile, uint64_t fl, uint64_t image,
                           uint64_t bin_size, const char *padded_path) {
    char esource[PATH_CAP * 2], ebin[PATH_CAP * 2], epadded[PATH_CAP * 2];
    char bin_json[PATH_CAP * 2 + 4], padded_json[PATH_CAP * 2 + 4], end[64];
    json_escape(source, esource, sizeof(esource));
    if (bin) json_escape(bin, ebin, sizeof(ebin)); else ebin[0] = '\0';
    if (bin) snprintf(bin_json, sizeof(bin_json), "\"%s\"", ebin);
    else strcpy(bin_json, "null");
    strcpy(padded_json, "null");
    if (padded_path) {
        json_escape(padded_path, epadded, sizeof(epadded));
        snprintf(padded_json, sizeof(padded_json), "\"%s\"", epadded);
    }
    snprintf(end, sizeof(end), "0x%06" PRIX64, fl + image);
    size_t cap = PATH_CAP * 7 + 1024;
    char *s = malloc(cap);
    if (!s) return NULL;
    snprintf(s, cap,
        "{\n  \"format\": \"soc-flash-burn-manifest-v1\",\n"
        "  \"profile\": \"%s\",\n  \"address_source\": \"%s\",\n"
        "  \"flash_start_address\": \"0x%06" PRIX64 "\",\n"
        "  \"input_bin\": %s,\n  \"input_bin_bytes\": %" PRIu64 ",\n"
        "  \"loader_image_bytes\": %" PRIu64 ",\n  \"padded_bin\": %s,\n"
        "  \"padding\": {\"fill_byte\": \"0xFF\", \"bytes\": %" PRIu64 "},\n"
        "  \"flash_end_exclusive\": \"%s\",\n"
        "  \"action\": \"Use the listed BIN artifact and address in the PDS Flash burn flow; this tool does not invoke PDS.\"\n}\n",
        profile, esource, fl, bin_json, bin_size, image, padded_json, image - bin_size, end);
    return s;
}

static int validate_bin(Config *c, Definitions *d, uint64_t *image, uint64_t *bin_size) {
    uint64_t length = c->image_bytes;
    if (c->firmware[0]) {
        if (file_size(c->firmware, bin_size) != 0) { fprintf(stderr, "soc_config: cannot stat firmware BIN '%s': %s\n", c->firmware, strerror(errno)); return -1; }
        if (!*bin_size) { fprintf(stderr, "soc_config: selected BIN is empty\n"); return -1; }
        if (!length) length = *bin_size;
        if (*bin_size > length) { fprintf(stderr, "soc_config: configured boot length is smaller than BIN length; refusing truncation\n"); return -1; }
        if (length % 4) { fprintf(stderr, "soc_config: selected BIN/boot length is not 4-byte aligned; manually pad/align it\n"); return -1; }
    } else {
        *bin_size = 0;
        if (!length) { fprintf(stderr, "soc_config: select a BIN or configure a nonzero boot image length\n"); return -1; }
    }
    c->image_bytes = length;
    Definition *boot = find_def(d, "SOC_BOOT_IMAGE_BYTES");
    boot->value = length;
    if (!validate_defs(d)) return -1;
    *image = length; return 0;
}

static int emit_headers(const char *source, const char *outdir, Definitions *defs) {
    if (mkdir_p(outdir) != 0) { fprintf(stderr, "soc_config: cannot create %s: %s\n", outdir, strerror(errno)); return -1; }
    char *h = render_header(defs), *a = render_asm(defs); if (!h || !a) { free(h); free(a); return -1; }
    char path[PATH_CAP]; snprintf(path, sizeof(path), "%s/soc_defs.h", outdir);
    int rc = atomic_write(path, h, strlen(h)); free(h); if (rc) { fprintf(stderr, "soc_config: cannot write %s: %s\n", path, strerror(errno)); free(a); return -1; }
    snprintf(path, sizeof(path), "%s/soc_defs_asm.inc", outdir);
    rc = atomic_write(path, a, strlen(a)); free(a); if (rc) { fprintf(stderr, "soc_config: cannot write %s: %s\n", path, strerror(errno)); return -1; }
    (void)source; return 0;
}

static int command_apply(const char *source, const char *config_path, const char *outdir) {
    Config c = {0}; if (parse_config(config_path, &c) != 0) return 2;
    Definitions defs; char *source_text = NULL;
    if (load_defs(source, &defs, &source_text) != 0) { free(source_text); return 2; }
    static const char *needed[] = {
        "SOC_CPU_MEM_BRAM", "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR",
        "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS", "SOC_FLASH_BASE",
        "SOC_BOOT_IMAGE_BYTES", "SOC_UART_TX_FPIOA", "SOC_FLASH_ADDRESS_BYTES",
        "SOC_IRAM_BASE", "SOC_IRAM_BYTES", "SOC_DRAM_BASE", "SOC_DRAM_BYTES",
        "SOC_DDR_BASE", "SOC_DDR_BYTES"
    };
    for (size_t i = 0; i < sizeof(needed) / sizeof(needed[0]); ++i) {
        if (!find_def(&defs, needed[i])) {
            fprintf(stderr, "soc_config: missing required definition %s\n", needed[i]);
            free(source_text);
            return 2;
        }
    }
    const bool bram = !strcmp(c.profile, "bram");
    uint64_t *profile_values[] = { &find_def(&defs, "SOC_CPU_MEM_BRAM")->value,
        &find_def(&defs, "SOC_ENABLE_ICACHE")->value, &find_def(&defs, "SOC_ENABLE_DCACHE")->value,
        &find_def(&defs, "SOC_ENABLE_DDR")->value, &find_def(&defs, "SOC_ENABLE_CAMERA")->value,
        &find_def(&defs, "SOC_ENABLE_PREPROCESS")->value, &find_def(&defs, "SOC_FLASH_BASE")->value,
        &find_def(&defs, "SOC_UART_TX_FPIOA")->value };
    *profile_values[0] = bram; *profile_values[1] = !bram; *profile_values[2] = !bram;
    *profile_values[3] = !bram; *profile_values[4] = !bram;
    *profile_values[5] = c.preprocess; *profile_values[6] = c.flash_base;
    *profile_values[7] = c.uart_remote ? 31 : 0;
    if (bram && c.preprocess) { fprintf(stderr, "soc_config: BRAM profile requires preprocessing disabled\n"); free(source_text); return 2; }
    uint64_t image, bin_size;
    if (validate_bin(&c, &defs, &image, &bin_size) != 0) { free(source_text); return 2; }
    char *rewritten = rewrite_source_text(source_text, &defs); free(source_text);
    if (!rewritten) { fprintf(stderr, "soc_config: unable to prepare atomic soc_addr_map.vh update\n"); return 2; }
    Definitions checkdefs;
    if (parse_definitions_text(rewritten, &checkdefs) != 0 || !validate_defs(&checkdefs)) {
        fprintf(stderr, "soc_config: proposed source update failed validation\n"); free(rewritten); return 2;
    }
    if (mkdir_p(outdir) != 0) { fprintf(stderr, "soc_config: cannot create output directory %s: %s\n", outdir, strerror(errno)); free(rewritten); return 2; }
    char *h = render_header(&checkdefs), *a = render_asm(&checkdefs);
    if (!h || !a) { free(h); free(a); free(rewritten); return 2; }
    char hpath[PATH_CAP], apath[PATH_CAP], mpath[PATH_CAP], padded[PATH_CAP];
    snprintf(hpath, sizeof(hpath), "%s/soc_defs.h", outdir);
    snprintf(apath, sizeof(apath), "%s/soc_defs_asm.inc", outdir);
    snprintf(mpath, sizeof(mpath), "%s/flash_manifest.json", outdir);
    const char *artifact = NULL, *padded_for_json = NULL;
    if (c.firmware[0]) {
        const char *base = strrchr(c.firmware, '/'); base = base ? base + 1 : c.firmware;
        if (image > bin_size) {
            const char *dot = strrchr(base, '.');
            size_t stemlen = dot ? (size_t)(dot - base) : strlen(base);
            snprintf(padded, sizeof(padded), "%s/%.*s.padded-%" PRIu64 ".bin",
                     outdir, (int)stemlen, base, image);
            artifact = padded;
            padded_for_json = padded;
        }
    }
    char *manifest = NULL;
    manifest = make_manifest(source, c.firmware[0] ? c.firmware : NULL,
                             c.profile, c.flash_base, image, bin_size, padded_for_json);
    if (!manifest) { free(h); free(a); free(rewritten); return 2; }
    /* Stage artifacts and validate all inputs before replacing the authority. */
    if (artifact && copy_or_pad(c.firmware, artifact, image) != 0) { fprintf(stderr, "soc_config: cannot stage BIN artifact: %s\n", strerror(errno)); free(h); free(a); free(rewritten); free(manifest); return 2; }
    if (atomic_write(hpath, h, strlen(h)) || atomic_write(apath, a, strlen(a)) ||
        atomic_write(mpath, manifest, strlen(manifest))) {
        fprintf(stderr, "soc_config: cannot write generated artifacts: %s\n", strerror(errno)); free(h); free(a); free(rewritten); free(manifest); return 2;
    }
    free(h); free(a); free(manifest);
    if (atomic_write(source, rewritten, strlen(rewritten)) != 0) {
        fprintf(stderr, "soc_config: cannot atomically update %s: %s\n", source, strerror(errno)); free(rewritten); return 2;
    }
    free(rewritten);
    printf("Updated %s\nGenerated %s and %s\n", source, hpath, apath);
    if (c.firmware[0]) printf("Generated %s (image %" PRIu64 " bytes at 0x%06" PRIX64 ")\n", mpath, image, c.flash_base);
    return 0;
}

static void usage(FILE *f) {
    fprintf(f, "Usage:\n"
        "  soc_config seed --source PATH --config PATH\n"
        "  soc_config apply --source PATH --config PATH --output-dir PATH\n"
        "  soc_config check --source PATH [--bin PATH] [--header PATH] [--asm PATH]\n"
        "  soc_config generate-header --source PATH --output-dir PATH\n");
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(stderr); return 2; }
    const char *command = argv[1];
    char *source = find_arg(argc, argv, "--source");
    if (!source) { usage(stderr); return 2; }
    if (!strcmp(command, "seed")) {
        char *config = find_arg(argc, argv, "--config"); if (!config) { usage(stderr); return 2; }
        return seed_config(source, config);
    }
    if (!strcmp(command, "apply")) {
        char *config = find_arg(argc, argv, "--config"), *outdir = find_arg(argc, argv, "--output-dir");
        if (!config || !outdir) { usage(stderr); return 2; }
        return command_apply(source, config, outdir);
    }
    if (!strcmp(command, "generate-header")) {
        char *outdir = find_arg(argc, argv, "--output-dir"); if (!outdir) { usage(stderr); return 2; }
        Definitions d; char *text = NULL; if (load_defs(source, &d, &text) != 0) { free(text); return 2; }
        free(text); if (!validate_defs(&d) || emit_headers(source, outdir, &d) != 0) return 2;
        return 0;
    }
    if (!strcmp(command, "check")) {
        Definitions d; char *text = NULL; if (load_defs(source, &d, &text) != 0) { free(text); return 2; }
        free(text); if (!validate_defs(&d)) return 2;
        char *bin = find_arg(argc, argv, "--bin"), *header = find_arg(argc, argv, "--header"), *asm = find_arg(argc, argv, "--asm");
        if (bin) { uint64_t size; if (file_size(bin, &size) != 0) { fprintf(stderr, "soc_config: cannot stat BIN '%s': %s\n", bin, strerror(errno)); return 2; }
            if (!size || size > find_def(&d, "SOC_BOOT_IMAGE_BYTES")->value) { fprintf(stderr, "soc_config: BIN is empty or exceeds SOC_BOOT_IMAGE_BYTES; refusing truncation\n"); return 2; }
        }
        if (header && !same_header_values(header, &d, false)) return 2;
        if (asm && !same_header_values(asm, &d, true)) return 2;
        printf("Configuration valid: %zu definitions; flash 0x%06" PRIX64 "+%" PRIu64 " bytes\n", d.count, find_def(&d, "SOC_FLASH_BASE")->value, find_def(&d, "SOC_BOOT_IMAGE_BYTES")->value);
        return 0;
    }
    usage(stderr); return 2;
}
