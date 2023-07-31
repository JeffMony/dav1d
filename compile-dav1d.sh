#!/bin/bash

# Author : JeffMony
# E-mail : jeffmony@163.com

# compile dav1d

:<<EOF
  执行结果为构建出 arm64-v8a、armeabi-v7a、x86_64、x86 架构的库文件
  参数说明：对应的数字表示构建出的平台架构的库文件
  1：arm64-v8a
  2：armeabi-v7a
  3：x86_64
  4：x86
EOF

# 构建的最低支持 API 等级
ANDROID_API=22
# 在什么系统上构建，mac：darwin，linux：linux，windows：windows
OS_TYPE=darwin
# 自己本机 NDK 所在目录
NDK_ROOT=/Users/jefflee/tools/android-ndk-r22b
# 交叉编译工具链所在目录
TOOLCHAIN_PATH=${NDK_ROOT}/toolchains/llvm/prebuilt/${OS_TYPE}-x86_64
CROSS_PREFIX=${TOOLCHAIN_PATH}/bin

# 当前目录
CURRENT_DIR=$(pwd)

ARCH_TRIPLET=

ARCH_TRIPLET_VARIANT=

ABI=

CPU_FAMILY=

ARCH_CFLAGS=

ARCH_LDFLAGS=

B_ARCH=

B_ADDRESS_MODEL=

init_arm() {
    echo "构建平台为：armeabi-v7a"
    ARCH_TRIPLET='arm-linux-androideabi'
    ARCH_TRIPLET_VARIANT='armv7a-linux-androideabi'
    ABI='armeabi-v7a'
    CPU_FAMILY='arm'
    ARCH_CFLAGS='-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb'
    ARCH_LDFLAGS='-march=armv7-a -Wl,--fix-cortex-a8'
    B_ARCH='arm'
    B_ADDRESS_MODEL=32
}

init_arm64() {
    echo "构建平台为：arm64-v8a"
    ARCH_TRIPLET='aarch64-linux-android'
    ARCH_TRIPLET_VARIANT=$ARCH_TRIPLET
    ABI='arm64-v8a'
    CPU_FAMILY='aarch64'
    B_ARCH='arm'
    B_ADDRESS_MODEL=64
}

build() {
    echo "Generating toolchain description..."
    user_config=android_cross_${ABI}.txt
    rm -f $user_config

cat > $user_config << EOF
    [binaries]
    name = 'android'
    c     = '${CROSS_PREFIX}/${ARCH_TRIPLET_VARIANT}${ANDROID_API}-clang'
    cpp   = '${CROSS_PREFIX}/${ARCH_TRIPLET_VARIANT}${ANDROID_API}-clang++'
    ar    = '${CROSS_PREFIX}/llvm-ar'
    ld    = '${CROSS_PREFIX}/${ARCH_TRIPLET}-ld'
    strip = '${CROSS_PREFIX}/${ARCH_TRIPLET}-strip'

    [properties]
    needs_exe_wrapper = true

    [host_machine]
    system = 'linux'
    cpu_family = '${CPU_FAMILY}'
    cpu = '${CPU_FAMILY}'
    endian = 'little'
EOF

    if [ ! -d "${CURRENT_DIR}/output" ]; then
        mkdir ${CURRENT_DIR}/output
    fi
    if [ ! -d "${CURRENT_DIR}/output/build-${ABI}" ]; then
        mkdir ${CURRENT_DIR}/output/build-${ABI}
    fi

    rm -rf ${CURRENT_DIR}/build/*
    rm -rf ${CURRENT_DIR}/output/build-${ABI}/*


    echo "Build: calling meson..."
    meson --buildtype release --default-library static --cross-file ./android_cross_${ABI}.txt -Denable_tools=false -Denable_tests=false ${CURRENT_DIR}/output/build-${ABI}

    echo "Building with Ninja"
    ninja -C  ${CURRENT_DIR}/output/build-${ABI}

    echo "Done!"
}


case "$1" in
    armv7a)
        init_arm
        build
    ;;
    arm64)
        init_arm64
        build
    ;;
    clean)
        rm -rf ${CURRENT_DIR}/build/*
        rm -rf ${CURRENT_DIR}/output/*
    ;;
esac
