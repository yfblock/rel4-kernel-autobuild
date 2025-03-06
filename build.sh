#!/usr/bin/env bash

# Build and export seL4 target package
# Use rust-sel4 without compiling seL4
# Just download the package

export SEL4_INSTALL_DIR=$(realpath .)/build/seL4
export SEL4_PREFIX=$SEL4_INSTALL_DIR
export CC_aarch64_unknown_none=aarch64-linux-gnu-gcc

git clone https://github.com/seL4/seL4.git --config advice.detachedHead=false
cd seL4
git checkout cd6d3b8c25d49be2b100b0608cf0613483a6fffa

set -eux
mkdir -p ${SEL4_INSTALL_DIR}

pip install tools/python-deps
cmake \
    -DCROSS_COMPILER_PREFIX=aarch64-linux-gnu- \
    -DCMAKE_INSTALL_PREFIX=${SEL4_INSTALL_DIR} \
    -DKernelPlatform=qemu-arm-virt \
    -DKernelArmExportPCNTUser=ON \
    -DKernelArmHypervisorSupport=ON \
    -DKernelVerificationBuild=OFF \
    -DKernelAllowSMCCalls=ON \
    -DARM_CPU=cortex-a57 \
    -G Ninja \
    -S . \
    -B build

ninja -C build all
ninja -C build install

url="https://github.com/seL4/rust-sel4";
rev="1cd063a0f69b2d2045bfa224a36c9341619f0e9b";
common_args="--git $url --rev $rev --root $SEL4_INSTALL_DIR";

cargo install $common_args \
    sel4-kernel-loader-add-payload

cargo install \
    -Z build-std=core,compiler_builtins \
    -Z build-std-features=compiler-builtins-mem \
    --target aarch64-unknown-none \
    $common_args \
    sel4-kernel-loader;
