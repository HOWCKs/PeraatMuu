cmake_minimum_required(VERSION 3.22.1)
project(retrobridge LANGUAGES CXX)

# Ponte JNI que carrega núcleos libretro (.so) via dlopen e alimenta
# vídeo/áudio/entrada para a camada Kotlin (GameActivity/GLSurfaceView).
add_library(retrobridge SHARED retrobridge.cpp)

find_library(log-lib log)
find_library(egl-lib EGL)

target_link_libraries(retrobridge ${log-lib} ${egl-lib} dl)

set_target_properties(retrobridge PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON)

target_compile_options(retrobridge PRIVATE -O2 -fvisibility=default)
