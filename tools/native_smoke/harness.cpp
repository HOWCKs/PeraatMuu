// Smoke test em host Linux da ponte retrobridge (dlopen -> run -> vídeo/áudio/input/saves)
#include "jni.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <thread>
#include <string>

extern "C" {
jint Java_com_peraatmuu_app_emulator_RetroBridge_nativeInit(JNIEnv*, jclass, jstring, jstring, jstring);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadGame(JNIEnv*, jclass, jstring);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeStart(JNIEnv*, jclass);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeStop(JNIEnv*, jclass);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeUnload(JNIEnv*, jclass);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeReset(JNIEnv*, jclass);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeSetButtons(JNIEnv*, jclass, jint);
void Java_com_peraatmuu_app_emulator_RetroBridge_nativeFrameInfo(JNIEnv*, jclass, jintArray);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeCopyFrame(JNIEnv*, jclass, jobject);
jint Java_com_peraatmuu_app_emulator_RetroBridge_nativeReadAudio(JNIEnv*, jclass, jbyteArray, jint);
jint Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetSampleRate(JNIEnv*, jclass);
jdouble Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetFps(JNIEnv*, jclass);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveState(JNIEnv*, jclass, jstring);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadState(JNIEnv*, jclass, jstring);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveRam(JNIEnv*, jclass, jstring);
jboolean Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadRam(JNIEnv*, jclass, jstring);
}

static int failures = 0;
#define CHECK(cond) do { if (cond) { printf("  PASS  %s\n", #cond); } else { printf("  FAIL  %s\n", #cond); failures++; } } while (0)

int main(int argc, char** argv) {
    printf("== PeraatMuu native smoke test ==\n");
    std::string base = argc > 1 ? argv[1] : "/tmp/smoke";
    JNIEnv* env = new JNIEnv();
    jclass cls = nullptr;

    jstring core = new _jstring((base + "/fakecore.so").c_str());
    jstring sys = new _jstring((base + "/sys").c_str());
    jstring sav = new _jstring((base + "/sav").c_str());
    jstring rom = new _jstring((base + "/rom.bin").c_str());

    jint rc = Java_com_peraatmuu_app_emulator_RetroBridge_nativeInit(env, cls, core, sys, sav);
    CHECK(rc == 0);

    jboolean loaded = Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadGame(env, cls, rom);
    CHECK(loaded == JNI_TRUE);

    double fps = Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetFps(env, cls);
    jint rate = Java_com_peraatmuu_app_emulator_RetroBridge_nativeGetSampleRate(env, cls);
    CHECK(fps == 60.0);
    CHECK(rate == 44100);

    // Botões: A(8) + START(3)
    Java_com_peraatmuu_app_emulator_RetroBridge_nativeSetButtons(env, cls, (1 << 8) | (1 << 3));

    Java_com_peraatmuu_app_emulator_RetroBridge_nativeStart(env, cls);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    jintArray info = new _jintArray();
    info->data.assign(16, 0);
    Java_com_peraatmuu_app_emulator_RetroBridge_nativeFrameInfo(env, cls, info);
    jint* v = reinterpret_cast<jint*>(info->data.data());
    printf("  frameInfo: w=%d h=%d updated=%d aspectMilli=%d\n", v[0], v[1], v[2], v[3]);
    CHECK(v[0] == 320 && v[1] == 240);
    CHECK(v[3] == 1333); // 4/3

    void* raw = malloc((size_t)320 * 240 * 4);
    jobject buf = reinterpret_cast<jobject>(raw);
    jboolean copied = Java_com_peraatmuu_app_emulator_RetroBridge_nativeCopyFrame(env, cls, buf);
    CHECK(copied == JNI_TRUE);

    // Verifica conversão RGB565 -> RGBA8888: alpha deve ser 0xFF e conteúdo não-nulo
    uint8_t* px = static_cast<uint8_t*>(raw);
    CHECK(px[3] == 0xFF);
    bool hasColor = false;
    for (size_t i = 0; i < (size_t)320 * 240 * 4; i += 4)
        if (px[i] | px[i + 1] | px[i + 2]) { hasColor = true; break; }
    CHECK(hasColor);
    free(raw);

    jbyteArray audio = new _jbyteArray();
    audio->data.assign(16384, 0);
    int totalAudio = 0;
    for (int i = 0; i < 64; i++) totalAudio += Java_com_peraatmuu_app_emulator_RetroBridge_nativeReadAudio(env, cls, audio, 16384);
    printf("  bytes de audio lidos: %d\n", totalAudio);
    CHECK(totalAudio > 0);

    Java_com_peraatmuu_app_emulator_RetroBridge_nativeReset(env, cls);

    std::string stateFile = base + "/state.st";
    jstring statePath = new _jstring(stateFile.c_str());
    jstring sramPath = new _jstring((base + "/sram.srm").c_str());
    CHECK(Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveState(env, cls, statePath) == JNI_TRUE);
    CHECK(Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadState(env, cls, statePath) == JNI_TRUE);
    CHECK(Java_com_peraatmuu_app_emulator_RetroBridge_nativeSaveRam(env, cls, sramPath) == JNI_TRUE);
    CHECK(Java_com_peraatmuu_app_emulator_RetroBridge_nativeLoadRam(env, cls, sramPath) == JNI_TRUE);

    FILE* f = fopen(stateFile.c_str(), "rb");
    char stBuf[9] = {0};
    if (f) { (void)fread(stBuf, 1, 8, f); fclose(f); }
    CHECK(strcmp(stBuf, "FAKECORE") == 0);

    Java_com_peraatmuu_app_emulator_RetroBridge_nativeStop(env, cls);
    Java_com_peraatmuu_app_emulator_RetroBridge_nativeUnload(env, cls);

    printf("== %s ==\n", failures == 0 ? "SMOKE TEST OK" : "SMOKE TEST COM FALHAS");
    return failures == 0 ? 0 : 1;
}
