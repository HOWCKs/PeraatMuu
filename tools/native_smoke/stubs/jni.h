// Stub JNI funcional para smoke test em host Linux (não-Android)
#ifndef JNI_H_STUB
#define JNI_H_STUB
#include <string>
#include <vector>
#include <cstring>
class _jobject {};
class _jclass : public _jobject {};
class _jstring : public _jobject { public: std::string s; _jstring(const char* c): s(c) {} };
class _jarray : public _jobject { public: std::vector<char> data; int unit = 1; };
class _jintArray : public _jarray { public: _jintArray() { unit = 4; } };
class _jbyteArray : public _jarray { public: _jbyteArray() { unit = 1; } };
typedef _jobject* jobject;
typedef _jclass* jclass;
typedef _jstring* jstring;
typedef _jarray* jarray;
typedef _jintArray* jintArray;
typedef _jbyteArray* jbyteArray;
typedef int jint;
typedef long long jlong;
typedef jint jsize;
typedef double jdouble;
typedef unsigned char jboolean;
typedef signed char jbyte;
#define JNI_TRUE 1
#define JNI_FALSE 0
#define JNIEXPORT
#define JNICALL
struct JNIEnv {
    const char* GetStringUTFChars(jstring s, jboolean*) { return s->s.c_str(); }
    void ReleaseStringUTFChars(jstring, const char*) {}
    jsize GetArrayLength(jarray a) { return (jsize)(a->data.size() / a->unit); }
    void SetIntArrayRegion(jintArray a, jsize start, jsize len, const jint* src) {
        std::memcpy(a->data.data() + start * 4, src, len * 4);
    }
    void* GetDirectBufferAddress(jobject buf) { return buf; }
    jlong GetDirectBufferCapacity(jobject) { return (jlong)64 * 1024 * 1024; }
    void SetByteArrayRegion(jbyteArray a, jsize start, jsize len, const jbyte* src) {
        std::memcpy(a->data.data() + start, src, len);
    }
};
#endif
