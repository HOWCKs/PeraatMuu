// Núcleo libretro FAKE para smoke test: gera vídeo RGB565 + áudio senoidal.
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cmath>

extern "C" {

typedef bool (*env_t)(unsigned, void*);
typedef void (*video_t)(const void*, unsigned, unsigned, size_t);
typedef void (*audio_t)(int16_t, int16_t);
typedef size_t (*audio_batch_t)(const int16_t*, size_t);
typedef void (*poll_t)(void);
typedef int16_t (*input_t)(unsigned, unsigned, unsigned, unsigned);

static env_t g_env;
static video_t g_video;
static audio_batch_t g_audio_batch;
static input_t g_input;
static unsigned g_frame_no = 0;
static uint16_t g_fb[320 * 240];
static uint8_t g_sram[128];

void retro_set_environment(env_t cb) { g_env = cb; }
void retro_set_video_refresh(video_t cb) { g_video = cb; }
void retro_set_audio_sample(audio_t) {}
void retro_set_audio_sample_batch(audio_batch_t cb) { g_audio_batch = cb; }
void retro_set_input_poll(poll_t) {}
void retro_set_input_state(input_t cb) { g_input = cb; }
unsigned retro_api_version(void) { return 1; }
void retro_init(void) { memset(g_sram, 0xA5, sizeof(g_sram)); }
void retro_deinit(void) {}
void retro_set_controller_port_device(unsigned, unsigned) {}
void retro_reset(void) { g_frame_no = 0; }

struct SysInfo { const char* name; const char* version; const char* exts; bool need_fullpath; bool block_extract; };
void retro_get_system_info(SysInfo* info) {
    info->name = "FakeCore-CI"; info->version = "1.0"; info->exts = "bin";
    info->need_fullpath = true; info->block_extract = false;
}

struct Geom { unsigned bw, bh, mw, mh; float aspect; };
struct Timing { double fps; double rate; };
struct AvInfo { Geom geom; Timing timing; };
void retro_get_system_av_info(AvInfo* av) {
    av->geom.bw = 320; av->geom.bh = 240; av->geom.mw = 640; av->geom.mh = 480;
    av->geom.aspect = 4.0f / 3.0f;
    av->timing.fps = 60.0; av->timing.rate = 44100.0;
}

struct GameInfo { const char* path; const void* data; size_t size; const char* meta; };
bool retro_load_game(const GameInfo* info) {
    printf("[fakecore] load_game: %s\n", info->path);
    unsigned fmt = 2; // RGB565
    if (!g_env(10, &fmt)) { printf("[fakecore] SET_PIXEL_FORMAT rejeitado!\n"); return false; }
    const char* sys = nullptr; g_env(9, &sys);
    const char* sav = nullptr; g_env(31, &sav);
    printf("[fakecore] sysdir=%s savedir=%s\n", sys, sav);
    const char* var_key = "fakeopt";
    struct Var { const char* key; const char* value; } v = { var_key, nullptr };
    g_env(15, &v); // GET_VARIABLE — deve retornar false sem quebrar
    bool dupe = false; g_env(3, &dupe); // GET_CAN_DUPE
    return true;
}

void retro_unload_game(void) {}

void retro_run(void) {
    g_frame_no++;
    for (unsigned y = 0; y < 240; y++)
        for (unsigned x = 0; x < 320; x++) {
            uint8_t r = (uint8_t)((x + g_frame_no) & 0x1F);
            uint8_t g = (uint8_t)((y + g_frame_no) & 0x3F);
            uint8_t b = (uint8_t)((x ^ y) & 0x1F);
            g_fb[y * 320 + x] = (uint16_t)((r << 11) | (g << 5) | b);
        }
    g_video(g_fb, 320, 240, 320 * 2);

    int16_t pcm[735 * 2];
    for (int i = 0; i < 735; i++) {
        double t = (g_frame_no * 735 + i) / 44100.0;
        int16_t s = (int16_t)(sin(2 * 3.14159265 * 440.0 * t) * 3000);
        pcm[i * 2] = s; pcm[i * 2 + 1] = s;
    }
    g_audio_batch(pcm, 735);

    // Lê botões para exercitar o callback de entrada
    int pressed = 0;
    for (unsigned id = 0; id < 12; id++) pressed |= g_input(0, 1, 0, id) ? (1 << id) : 0;
    if (g_frame_no == 2) printf("[fakecore] botoes lidos: 0x%04x\n", pressed);
}

size_t retro_serialize_size(void) { return 8; }
bool retro_serialize(void* data, size_t size) { return size >= 8 && memcpy(data, "FAKECORE", 8) != nullptr; }
bool retro_unserialize(const void* data, size_t size) { return size == 8; }
unsigned retro_get_region(void) { return 0; }
void* retro_get_memory_data(unsigned id) { return id == 0 ? g_sram : nullptr; }
size_t retro_get_memory_size(unsigned id) { return id == 0 ? sizeof(g_sram) : 0; }

} // extern "C"
