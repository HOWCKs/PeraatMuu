//
// retrobridge.cpp — Ponte JNI <-> libretro
//
// Implementa um "frontend" libretro mínimo e real:
//   - dlopen() do núcleo (.so) oficial baixado do buildbot libretro
//   - resolução dos símbolos retro_* (ABI estável do libretro API v1)
//   - callbacks de vídeo (conversão para RGBA8888), áudio (PCM 16 bits estéreo),
//     entrada (joypad) e environment
//   - thread de emulação com limitação de FPS
//   - save states, SRAM e soft-reset
//
// Núcleos que exigem contexto de hardware (RETRO_ENVIRONMENT_SET_HW_RENDER),
// como N64/PSP, não são suportados nesta fase (o app os marca como "em breve").
//

#include <jni.h>
#include <dlfcn.h>
#include <android/log.h>

#include <atomic>
#include <chrono>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#define LOG_TAG "RetroBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ---------------------------------------------------------------------------
// ABI libretro (constantes e structs estáveis — não muda entre núcleos)
// ---------------------------------------------------------------------------

#define RETRO_API_VERSION 1

#define RETRO_DEVICE_JOYPAD 1

// Botões do joypad (ids)
enum {
    RETRO_DEVICE_ID_JOYPAD_B = 0,
    RETRO_DEVICE_ID_JOYPAD_Y = 1,
    RETRO_DEVICE_ID_JOYPAD_SELECT = 2,
    RETRO_DEVICE_ID_JOYPAD_START = 3,
    RETRO_DEVICE_ID_JOYPAD_UP = 4,
    RETRO_DEVICE_ID_JOYPAD_DOWN = 5,
    RETRO_DEVICE_ID_JOYPAD_LEFT = 6,
    RETRO_DEVICE_ID_JOYPAD_RIGHT = 7,
    RETRO_DEVICE_ID_JOYPAD_A = 8,
    RETRO_DEVICE_ID_JOYPAD_X = 9,
    RETRO_DEVICE_ID_JOYPAD_L = 10,
    RETRO_DEVICE_ID_JOYPAD_R = 11,
    RETRO_DEVICE_ID_JOYPAD_L2 = 12,
    RETRO_DEVICE_ID_JOYPAD_R2 = 13,
};

// Comandos do environment
constexpr unsigned RETRO_ENV_SET_ROTATION = 1;
constexpr unsigned RETRO_ENV_GET_OVERSCAN = 2;
constexpr unsigned RETRO_ENV_GET_CAN_DUPE = 3;
constexpr unsigned RETRO_ENV_SET_MESSAGE = 6;
constexpr unsigned RETRO_ENV_SHUTDOWN = 7;
constexpr unsigned RETRO_ENV_SET_PERFORMANCE_LEVEL = 8;
constexpr unsigned RETRO_ENV_GET_SYSTEM_DIRECTORY = 9;
constexpr unsigned RETRO_ENV_SET_PIXEL_FORMAT = 10;
constexpr unsigned RETRO_ENV_SET_INPUT_DESCRIPTORS = 11;
constexpr unsigned RETRO_ENV_SET_DISK_CONTROL_INTERFACE = 13;
constexpr unsigned RETRO_ENV_SET_HW_RENDER = 14;
constexpr unsigned RETRO_ENV_GET_VARIABLE = 15;
constexpr unsigned RETRO_ENV_SET_VARIABLES = 16;
constexpr unsigned RETRO_ENV_GET_VARIABLE_UPDATE = 17;
constexpr unsigned RETRO_ENV_SET_SUPPORT_NO_GAME = 18;
constexpr unsigned RETRO_ENV_GET_LIBRETRO_PATH = 19;
constexpr unsigned RETRO_ENV_SET_FRAME_TIME_CALLBACK = 21;
constexpr unsigned RETRO_ENV_SET_AUDIO_CALLBACK = 22;
constexpr unsigned RETRO_ENV_GET_RUMBLE_INTERFACE = 23;
constexpr unsigned RETRO_ENV_GET_INPUT_DEVICE_CAPABILITIES = 24;
constexpr unsigned RETRO_ENV_GET_LOG_INTERFACE = 27;
constexpr unsigned RETRO_ENV_GET_CONTENT_DIRECTORY = 30;
constexpr unsigned RETRO_ENV_GET_SAVE_DIRECTORY = 31;
constexpr unsigned RETRO_ENV_SET_GEOMETRY = 37;
constexpr unsigned RETRO_ENVIRONMENT_EXPERIMENTAL = 0x10000;

// Formatos de pixel
constexpr unsigned RETRO_PIXEL_FORMAT_0RGB1555 = 0;
constexpr unsigned RETRO_PIXEL_FORMAT_XRGB8888 = 1;
constexpr unsigned RETRO_PIXEL_FORMAT_RGB565 = 2;

// Tipos de memória
constexpr unsigned RETRO_MEMORY_SAVE_RAM = 0;

enum retro_log_level {
    RETRO_LOG_DEBUG = 0,
    RETRO_LOG_INFO = 1,
    RETRO_LOG_WARN = 2,
    RETRO_LOG_ERROR = 3,
};

struct retro_message {
    const char *msg;
    unsigned frames;
};

struct retro_variable {
    const char *key;
    const char *value;
};

typedef void (*retro_log_printf_t)(enum retro_log_level level, const char *fmt, ...);

struct retro_log_callback {
    retro_log_printf_t log;
};

struct retro_game_info {
    const char *path;
    const void *data;
    size_t size;
    const char *meta;
};

struct retro_game_geometry {
    unsigned base_width;
    unsigned base_height;
    unsigned max_width;
    unsigned max_height;
    float aspect_ratio;
};

struct retro_system_timing {
    double fps;
    double sample_rate;
};

struct retro_system_av_info {
    struct retro_game_geometry geometry;
    struct retro_system_timing timing;
};

struct retro_system_info {
    const char *library_name;
    const char *library_version;
    const char *valid_extensions;
    bool need_fullpath;
    bool block_extract;
};

// Assinaturas das funções exportadas pelos núcleos
typedef bool (*retro_environment_t)(unsigned cmd, void *data);
typedef void (*retro_video_refresh_t)(const void *data, unsigned width, unsigned height, size_t pitch);
typedef void (*retro_audio_sample_t)(int16_t left, int16_t right);
typedef size_t (*retro_audio_sample_batch_t)(const int16_t *data, size_t frames);
typedef void (*retro_input_poll_t)(void);
typedef int16_t (*retro_input_state_t)(unsigned port, unsigned device, unsigned index, unsigned id);

struct Core {
    void *handle = nullptr;
    void (*retro_set_environment)(retro_environment_t) = nullptr;
    void (*retro_set_video_refresh)(retro_video_refresh_t) = nullptr;
    void (*retro_set_audio_sample)(retro_audio_sample_t) = nullptr;
    void (*retro_set_audio_sample_batch)(retro_audio_sample_batch_t) = nullptr;
    void (*retro_set_input_poll)(retro_input_poll_t) = nullptr;
    void (*retro_set_input_state)(retro_input_state_t) = nullptr;
    void (*retro_init)(void) = nullptr;
    void (*retro_deinit)(void) = nullptr;
    unsigned (*retro_api_version)(void) = nullptr;
    void (*retro_get_system_info)(retro_system_info *) = nullptr;
    void (*retro_get_system_av_info)(retro_system_av_info *) = nullptr;
    void (*retro_set_controller_port_device)(unsigned, unsigned) = nullptr;
    void (*retro_reset)(void) = nullptr;
    void (*retro_run)(void) = nullptr;
    size_t (*retro_serialize_size)(void) = nullptr;
    bool (*retro_serialize)(void *, size_t) = nullptr;
    bool (*retro_unserialize)(const void *, size_t) = nullptr;
    void (*retro_cheat_reset)(void) = nullptr;
    void (*retro_cheat_set)(unsigned, bool, const char *) = nullptr;
    bool (*retro_load_game)(const retro_game_info *) = nullptr;
    void (*retro_unload_game)(void) = nullptr;
    unsigned (*retro_get_region)(void) = nullptr;
    void *(*retro_get_memory_data)(unsigned) = nullptr;
    size_t (*retro_get_memory_size)(unsigned) = nullptr;
};

// ---------------------------------------------------------------------------
// Estado global (uma sessão de emulação por vez)
// ---------------------------------------------------------------------------

static Core g_core;
static std::atomic<bool> g_running{false};
static std::atomic<bool> g_loaded{false};
static std::atomic<bool> g_should_quit{false};
static std::thread g_emu_thread;
static std::mutex g_run_mutex;   // serializa retro_run / save states / reset

static std::mutex g_video_mutex;
static std::vector<uint8_t> g_frame;  // RGBA8888 tight-packed
static unsigned g_frame_w = 0;
static unsigned g_frame_h = 0;
static unsigned g_max_w = 0;
static unsigned g_max_h = 0;
static std::atomic<bool> g_frame_updated{false};
static float g_aspect = 0.0f;
static double g_fps = 60.0;
static int g_pixel_format = RETRO_PIXEL_FORMAT_XRGB8888;

// Buffer de áudio com índice de leitura (ring lógico)
static std::mutex g_audio_mutex;
static std::vector<uint8_t> g_audio;
static size_t g_audio_head = 0;
static const size_t AUDIO_MAX_BYTES = 1 << 20;  // ~5,9s @ 44,1kHz estéreo

static std::atomic<uint32_t> g_buttons{0};

static std::string g_sys_dir;
static std::string g_save_dir;
static int g_sample_rate = 44100;

// ---------------------------------------------------------------------------
// Utilidades de arquivo
// ---------------------------------------------------------------------------

static bool write_file(const char *path, const void *data, size_t size) {
    FILE *f = fopen(path, "wb");
    if (!f) return false;
    bool ok = fwrite(data, 1, size, f) == size;
    fclose(f);
    return ok;
}

static bool read_file(const char *path, std::vector<uint8_t> &out) {
    FILE *f = fopen(path, "rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    if (size < 0) {
        fclose(f);
        return false;
    }
    fseek(f, 0, SEEK_SET);
    out.resize(static_cast<size_t>(size));
    bool ok = size == 0 || fread(out.data(), 1, static_cast<size_t>(size), f) == static_cast<size_t>(size);
    fclose(f);
    return ok;
}

// ---------------------------------------------------------------------------
// Callbacks entregues ao núcleo
// ---------------------------------------------------------------------------

static void core_log(enum retro_log_level level, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int prio = ANDROID_LOG_DEBUG;
    switch (level) {
        case RETRO_LOG_INFO: prio = ANDROID_LOG_INFO; break;
        case RETRO_LOG_WARN: prio = ANDROID_LOG_WARN; break;
        case RETRO_LOG_ERROR: prio = ANDROID_LOG_ERROR; break;
        default: break;
    }
    __android_log_vprint(prio, "LibretroCore", fmt, ap);
    va_end(ap);
}

static bool environment_cb(unsigned cmd, void *data) {
    switch (cmd & ~RETRO_ENVIRONMENT_EXPERIMENTAL) {
        case RETRO_ENV_GET_OVERSCAN:
            if (data) *static_cast<bool *>(data) = false;
            return true;
        case RETRO_ENV_GET_CAN_DUPE:
            if (data) *static_cast<bool *>(data) = true;
            return true;
        case RETRO_ENV_SET_MESSAGE: {
            auto *msg = static_cast<retro_message *>(data);
            if (msg && msg->msg) LOGI("[core] %s", msg->msg);
            return true;
        }
        case RETRO_ENV_SHUTDOWN:
            LOGI("Núcleo solicitou encerramento");
            g_should_quit = true;
            return true;
        case RETRO_ENV_SET_PERFORMANCE_LEVEL:
            return true;
        case RETRO_ENV_GET_SYSTEM_DIRECTORY:
            if (data) *static_cast<const char **>(data) = g_sys_dir.c_str();
            return true;
        case RETRO_ENV_GET_CONTENT_DIRECTORY:
        case RETRO_ENV_GET_SAVE_DIRECTORY:
            if (data) *static_cast<const char **>(data) = g_save_dir.c_str();
            return true;
        case RETRO_ENV_GET_LIBRETRO_PATH:
            return false;
        case RETRO_ENV_SET_PIXEL_FORMAT: {
            unsigned fmt = *static_cast<const unsigned *>(data);
            if (fmt > RETRO_PIXEL_FORMAT_RGB565) return false;
            g_pixel_format = static_cast<int>(fmt);
            LOGI("Formato de pixel: %u", fmt);
            return true;
        }
        case RETRO_ENV_SET_INPUT_DESCRIPTORS:
            return true;
        case RETRO_ENV_SET_HW_RENDER:
            LOGW("Núcleo pediu HW render (OpenGL) — não suportado nesta versão");
            return false;
        case RETRO_ENV_GET_VARIABLE: {
            auto *var = static_cast<retro_variable *>(data);
            if (var) var->value = nullptr;  // usa os padrões do núcleo
            return false;
        }
        case RETRO_ENV_SET_VARIABLES:
            return true;
        case RETRO_ENV_GET_VARIABLE_UPDATE:
            if (data) *static_cast<bool *>(data) = false;
            return true;
        case RETRO_ENV_SET_SUPPORT_NO_GAME:
            return true;
        case RETRO_ENV_SET_FRAME_TIME_CALLBACK:
        case RETRO_ENV_SET_AUDIO_CALLBACK:
        case RETRO_ENV_SET_DISK_CONTROL_INTERFACE:
        case RETRO_ENV_SET_GEOMETRY:
        case RETRO_ENV_SET_ROTATION:
            return true;
        case RETRO_ENV_GET_RUMBLE_INTERFACE:
        case RETRO_ENV_GET_INPUT_DEVICE_CAPABILITIES:
            return false;
        case RETRO_ENV_GET_LOG_INTERFACE: {
            auto *cb = static_cast<retro_log_callback *>(data);
            if (cb) cb->log = core_log;
            return true;
        }
        default:
            LOGI("environment cmd %u não tratado", cmd & ~RETRO_ENVIRONMENT_EXPERIMENTAL);
            return false;
    }
}

static inline uint8_t expand5(uint16_t v) { return static_cast<uint8_t>((v << 3) | (v >> 2)); }
static inline uint8_t expand6(uint16_t v) { return static_cast<uint8_t>((v << 2) | (v >> 4)); }

static void video_refresh_cb(const void *data, unsigned width, unsigned height, size_t pitch) {
    if (!data || data == reinterpret_cast<void *>(static_cast<intptr_t>(-1))) return;
    if (width == 0 || height == 0) return;
    if (width > g_max_w || height > g_max_h) {
        // Núcleo estourou a geometria máxima anunciada — descarta o quadro.
        return;
    }

    std::lock_guard<std::mutex> lock(g_video_mutex);
    if (width != g_frame_w || height != g_frame_h) {
        g_frame_w = width;
        g_frame_h = height;
        g_frame.assign(static_cast<size_t>(width) * height * 4, 0);
    }

    uint8_t *out = g_frame.data();
    switch (g_pixel_format) {
        case RETRO_PIXEL_FORMAT_XRGB8888: {
            const auto *src = static_cast<const uint8_t *>(data);
            for (unsigned y = 0; y < height; y++) {
                const auto *row = reinterpret_cast<const uint32_t *>(src + y * pitch);
                uint8_t *dst = out + static_cast<size_t>(y) * width * 4;
                for (unsigned x = 0; x < width; x++) {
                    uint32_t px = row[x];
                    dst[0] = static_cast<uint8_t>((px >> 16) & 0xFF);
                    dst[1] = static_cast<uint8_t>((px >> 8) & 0xFF);
                    dst[2] = static_cast<uint8_t>(px & 0xFF);
                    dst[3] = 0xFF;
                    dst += 4;
                }
            }
            break;
        }
        case RETRO_PIXEL_FORMAT_RGB565: {
            const auto *src = static_cast<const uint8_t *>(data);
            for (unsigned y = 0; y < height; y++) {
                const auto *row = reinterpret_cast<const uint16_t *>(src + y * pitch);
                uint8_t *dst = out + static_cast<size_t>(y) * width * 4;
                for (unsigned x = 0; x < width; x++) {
                    uint16_t v = row[x];
                    dst[0] = expand5((v >> 11) & 0x1F);
                    dst[1] = expand6((v >> 5) & 0x3F);
                    dst[2] = expand5(v & 0x1F);
                    dst[3] = 0xFF;
                    dst += 4;
                }
            }
            break;
        }
        default: {  // 0RGB1555
            const auto *src = static_cast<const uint8_t *>(data);
            for (unsigned y = 0; y < height; y++) {
                const auto *row = reinterpret_cast<const uint16_t *>(src + y * pitch);
                uint8_t *dst = out + static_cast<size_t>(y) * width * 4;
                for (unsigned x = 0; x < width; x++) {
                    uint16_t v = row[x];
                    dst[0] = expand5((v >> 10) & 0x1F);
                    dst[1] = expand5((v >> 5) & 0x1F);
                    dst[2] = expand5(v & 0x1F);
                    dst[3] = 0xFF;
                    dst += 4;
                }
            }
            break;
        }
    }
    g_frame_updated = true;
}

static void audio_sample_cb(int16_t left, int16_t right) {
    int16_t frames[2] = {left, right};
    std::lock_guard<std::mutex> lock(g_audio_mutex);
    const uint8_t *bytes = reinterpret_cast<const uint8_t *>(frames);
    g_audio.insert(g_audio.end(), bytes, bytes + 4);
}

static size_t audio_sample_batch_cb(const int16_t *data, size_t frames) {
    if (!data || frames == 0) return 0;
    std::lock_guard<std::mutex> lock(g_audio_mutex);
    size_t bytes = frames * 2 /*canais*/ * sizeof(int16_t);
    size_t used = g_audio.size() - g_audio_head;
    if (used + bytes > AUDIO_MAX_BYTES) {
        // Descarta o mais antigo para não acumular latência.
        size_t keep = AUDIO_MAX_BYTES > bytes ? AUDIO_MAX_BYTES - bytes : 0;
        if (used > keep) {
            g_audio_head += used - keep;
        }
    }
    const uint8_t *begin = reinterpret_cast<const uint8_t *>(data);
    g_audio.insert(g_audio.end(), begin, begin + bytes);
    return frames;
}

static void input_poll_cb(void) {}

static int16_t input_state_cb(unsigned port, unsigned device, unsigned index, unsigned id) {
    (void)index;
    if (port != 0) return 0;
    unsigned base_device = device & 0xFF;
    if (base_device != RETRO_DEVICE_JOYPAD) return 0;
    if (id > 15) return 0;
    uint32_t mask = g_buttons.load(std::memory_order_relaxed);
    return static_cast<int16_t>((mask >> id) & 1u);
}

// ---------------------------------------------------------------------------
// Thread de emulação
// ---------------------------------------------------------------------------

static void emu_thread_main() {
    using clock = std::chrono::steady_clock;
    const double target = g_fps > 1.0 ? 1.0 / g_fps : 1.0 / 60.0;

    while (g_running.load(std::memory_order_acquire) && !g_should_quit.load(std::memory_order_acquire)) {
        auto start = clock::now();
        {
            std::lock_guard<std::mutex> lock(g_run_mutex);
            g_core.retro_run();
        }
        double elapsed = std::chrono::duration<double>(clock::now() - start).count();
        if (elapsed < target) {
            // Além do limitador de FPS, o consumo do buffer de áudio pelo
            // AudioTrack mantém o ritmo correto a longo prazo.
            std::this_thread::sleep_for(std::chrono::duration<double>(target - elapsed));
        } else {
            std::this_thread::yield();
        }
    }
    LOGI("Thread de emulação finalizada");
}

// ---------------------------------------------------------------------------
// Carregamento do núcleo
// ---------------------------------------------------------------------------

#define LOAD_SYM(field, sym)                                                          \
    do {                                                                              \
        g_core.field = reinterpret_cast<decltype(g_core.field)>(dlsym(g_core.handle, sym)); \
        if (!g_core.field) {                                                          \
            LOGE("Símbolo ausente no núcleo: %s", sym);                               \
            dlclose(g_core.handle);                                                   \
            g_core.handle = nullptr;                                                  \
            return -3;                                                                \
        }                                                                             \
    } while (0)

static int load_core(const char *path) {
    g_core = Core{};
    g_core.handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (!g_core.handle) {
        LOGE("dlopen falhou: %s", dlerror());
        return -2;
    }

    LOAD_SYM(retro_set_environment, "retro_set_environment");
    LOAD_SYM(retro_set_video_refresh, "retro_set_video_refresh");
    LOAD_SYM(retro_set_audio_sample, "retro_set_audio_sample");
    LOAD_SYM(retro_set_audio_sample_batch, "retro_set_audio_sample_batch");
    LOAD_SYM(retro_set_input_poll, "retro_set_input_poll");
    LOAD_SYM(retro_set_input_state, "retro_set_input_state");
    LOAD_SYM(retro_init, "retro_init");
    LOAD_SYM(retro_deinit, "retro_deinit");
    LOAD_SYM(retro_api_version, "retro_api_version");
    LOAD_SYM(retro_get_system_info, "retro_get_system_info");
    LOAD_SYM(retro_get_system_av_info, "retro_get_system_av_info");
    LOAD_SYM(retro_set_controller_port_device, "retro_set_controller_port_device");
    LOAD_SYM(retro_reset, "retro_reset");
    LOAD_SYM(retro_run, "retro_run");
    LOAD_SYM(retro_serialize_size, "retro_serialize_size");
    LOAD_SYM(retro_serialize, "retro_serialize");
    LOAD_SYM(retro_unserialize, "retro_unserialize");
    LOAD_SYM(retro_load_game, "retro_load_game");
    LOAD_SYM(retro_unload_game, "retro_unload_game");
    LOAD_SYM(retro_get_region, "retro_get_region");
    LOAD_SYM(retro_get_memory_data, "retro_get_memory_data");
    LOAD_SYM(retro_get_memory_size, "retro_get_memory_size");

    unsigned api = g_core.retro_api_version();
    if (api != RETRO_API_VERSION) {
        LOGW("Versão da API libretro diferente (%u), continuando mesmo assim", api);
    }

    retro_system_info sys{};
    g_core.retro_get_system_info(&sys);
    LOGI("Núcleo carregado: %s %s", sys.library_name ? sys.library_name : "?",
         sys.library_version ? sys.library_version : "?");

    g_core.retro_set_environment(environment_cb);
    g_core.retro_set_video_refresh(video_refresh_cb);
    g_core.retro_set_audio_sample(audio_sample_cb);
    g_core.retro_set_audio_sample_batch(audio_sample_batch_cb);
    g_core.retro_set_input_poll(input_poll_cb);
    g_core.retro_set_input_state(input_state_cb);
    g_core.retro_init();
    return 0;
}

// ---------------------------------------------------------------------------
// Helpers JNI
// ---------------------------------------------------------------------------

namespace {

struct JStr {
    JNIEnv *env;
    jstring str;
    const char *ptr;
    JStr(JNIEnv *e, jstring s) : env(e), str(s), ptr(s ? e->GetStringUTFChars(s, nullptr) : nullptr) {}
    ~JStr() {
        if (ptr) env->ReleaseStringUTFChars(str, ptr);
    }
    const char *c() const { return ptr ? ptr : ""; }
};

} // namespace

// ---------------------------------------------------------------------------
// API JNI — com.peraatmuu.app.emulator.RetroBridge
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jint JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeInit(
        JNIEnv *env, jclass clazz, jstring corePath, jstring sysDir, jstring saveDir) {
    (void)env;
    (void)clazz;
    JStr core(env, corePath);
    JStr sys(env, sysDir);
    JStr save(env, saveDir);
    g_sys_dir = sys.c();
    g_save_dir = save.c();

    if (g_running.load()) {
        // Sessão anterior ainda ativa
        return -10;
    }

    int rc = load_core(core.c());
    if (rc != 0) return rc;

    {
        std::lock_guard<std::mutex> lock(g_audio_mutex);
        g_audio.clear();
        g_audio_head = 0;
    }
    g_buttons = 0;
    g_frame_updated = false;
    g_should_quit = false;
    g_loaded = false;
    return 0;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadGame(
        JNIEnv *env, jclass clazz, jstring romPath) {
    (void)clazz;
    if (!g_core.handle) return JNI_FALSE;
    JStr rom(env, romPath);

    retro_game_info info{};
    info.path = rom.c();
    info.data = nullptr;
    info.size = 0;
    info.meta = nullptr;

    if (!g_core.retro_load_game(&info)) {
        LOGE("retro_load_game falhou para %s", rom.c());
        return JNI_FALSE;
    }

    retro_system_av_info av{};
    g_core.retro_get_system_av_info(&av);
    g_fps = av.timing.fps > 1.0 ? av.timing.fps : 60.0;
    g_sample_rate = av.timing.sample_rate > 0 ? static_cast<int>(av.timing.sample_rate) : 44100;
    g_aspect = av.geometry.aspect_ratio;
    g_max_w = av.geometry.max_width ? av.geometry.max_width : av.geometry.base_width;
    g_max_h = av.geometry.max_height ? av.geometry.max_height : av.geometry.base_height;
    if (g_max_w < 1) g_max_w = 1024;
    if (g_max_h < 1) g_max_h = 1024;

    {
        std::lock_guard<std::mutex> lock(g_video_mutex);
        g_frame.assign(static_cast<size_t>(g_max_w) * g_max_h * 4, 0);
        g_frame_w = 0;
        g_frame_h = 0;
    }

    LOGI("Jogo carregado: %.2f fps | %d Hz | %ux%u", g_fps, g_sample_rate, g_max_w, g_max_h);
    g_loaded = true;
    return JNI_TRUE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeStart(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    if (!g_core.handle || !g_loaded) return;
    if (g_running.exchange(true)) return;  // já rodando
    g_emu_thread = std::thread(emu_thread_main);
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeStop(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    if (!g_running.exchange(false)) return;
    if (g_emu_thread.joinable()) g_emu_thread.join();
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeUnload(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    Java_com_peraatmuu_app_emulator_RetroBridge_nativeStop(env, clazz);
    if (g_core.handle) {
        if (g_loaded) g_core.retro_unload_game();
        g_core.retro_deinit();
        dlclose(g_core.handle);
        g_core.handle = nullptr;
    }
    g_loaded = false;
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeReset(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    if (!g_core.handle || !g_loaded) return;
    std::lock_guard<std::mutex> lock(g_run_mutex);
    g_core.retro_reset();
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeSetButtons(JNIEnv *env, jclass clazz, jint mask) {
    (void)env;
    (void)clazz;
    g_buttons.store(static_cast<uint32_t>(mask), std::memory_order_relaxed);
}

extern "C" JNIEXPORT void JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeFrameInfo(
        JNIEnv *env, jclass clazz, jintArray out) {
    (void)clazz;
    if (env->GetArrayLength(out) < 4) return;
    jint vals[4];
    {
        std::lock_guard<std::mutex> lock(g_video_mutex);
        vals[0] = static_cast<jint>(g_frame_w);
        vals[1] = static_cast<jint>(g_frame_h);
        vals[2] = g_frame_updated.load(std::memory_order_acquire) ? 1 : 0;
        vals[3] = static_cast<jint>(g_aspect * 1000.0f);
    }
    env->SetIntArrayRegion(out, 0, 4, vals);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeCopyFrame(
        JNIEnv *env, jclass clazz, jobject buffer) {
    (void)clazz;
    void *addr = env->GetDirectBufferAddress(buffer);
    jlong capacity = env->GetDirectBufferCapacity(buffer);
    if (!addr || capacity <= 0) return JNI_FALSE;

    std::lock_guard<std::mutex> lock(g_video_mutex);
    if (g_frame_w == 0 || g_frame_h == 0) return JNI_FALSE;
    size_t need = static_cast<size_t>(g_frame_w) * g_frame_h * 4;
    if (static_cast<size_t>(capacity) < need) return JNI_FALSE;
    memcpy(addr, g_frame.data(), need);
    bool updated = g_frame_updated.exchange(false, std::memory_order_acq_rel);
    return updated ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeReadAudio(
        JNIEnv *env, jclass clazz, jbyteArray dest, jint maxBytes) {
    (void)clazz;
    if (maxBytes <= 0) return 0;
    std::lock_guard<std::mutex> lock(g_audio_mutex);
    size_t used = g_audio.size() - g_audio_head;
    size_t n = used < static_cast<size_t>(maxBytes) ? used : static_cast<size_t>(maxBytes);
    if (n == 0) return 0;
    env->SetByteArrayRegion(dest, 0, static_cast<jsize>(n),
                            reinterpret_cast<const jbyte *>(g_audio.data() + g_audio_head));
    g_audio_head += n;
    if (g_audio_head > (1 << 19)) {
        g_audio.erase(g_audio.begin(), g_audio.begin() + static_cast<long>(g_audio_head));
        g_audio_head = 0;
    }
    return static_cast<jint>(n);
}

extern "C" JNIEXPORT jint JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetSampleRate(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    return g_sample_rate;
}

extern "C" JNIEXPORT jdouble JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetFps(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    return g_fps;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveState(
        JNIEnv *env, jclass clazz, jstring path) {
    (void)clazz;
    if (!g_core.handle || !g_loaded) return JNI_FALSE;
    JStr p(env, path);
    std::lock_guard<std::mutex> lock(g_run_mutex);
    size_t size = g_core.retro_serialize_size();
    if (size == 0) return JNI_FALSE;
    std::vector<uint8_t> buf(size);
    if (!g_core.retro_serialize(buf.data(), size)) return JNI_FALSE;
    return write_file(p.c(), buf.data(), buf.size()) ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadState(
        JNIEnv *env, jclass clazz, jstring path) {
    (void)clazz;
    if (!g_core.handle || !g_loaded) return JNI_FALSE;
    JStr p(env, path);
    std::vector<uint8_t> buf;
    if (!read_file(p.c(), buf) || buf.empty()) return JNI_FALSE;
    std::lock_guard<std::mutex> lock(g_run_mutex);
    return g_core.retro_unserialize(buf.data(), buf.size()) ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveRam(
        JNIEnv *env, jclass clazz, jstring path) {
    (void)clazz;
    if (!g_core.handle || !g_loaded) return JNI_FALSE;
    JStr p(env, path);
    std::lock_guard<std::mutex> lock(g_run_mutex);
    void *data = g_core.retro_get_memory_data(RETRO_MEMORY_SAVE_RAM);
    size_t size = g_core.retro_get_memory_size(RETRO_MEMORY_SAVE_RAM);
    if (!data || size == 0) return JNI_FALSE;
    return write_file(p.c(), data, size) ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadRam(
        JNIEnv *env, jclass clazz, jstring path) {
    (void)clazz;
    if (!g_core.handle || !g_loaded) return JNI_FALSE;
    JStr p(env, path);
    std::vector<uint8_t> buf;
    if (!read_file(p.c(), buf) || buf.empty()) return JNI_FALSE;
    std::lock_guard<std::mutex> lock(g_run_mutex);
    void *data = g_core.retro_get_memory_data(RETRO_MEMORY_SAVE_RAM);
    size_t size = g_core.retro_get_memory_size(RETRO_MEMORY_SAVE_RAM);
    if (!data || size == 0) return JNI_FALSE;
    size_t n = buf.size() < size ? buf.size() : size;
    memcpy(data, buf.data(), n);
    return JNI_TRUE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_peraatmuu_app_emulator_RetroBridge_nativeShouldQuit(JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    return g_should_quit.load() ? JNI_TRUE : JNI_FALSE;
}
