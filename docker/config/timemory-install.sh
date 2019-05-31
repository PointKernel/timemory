#!/bin/bash -le

# function for running command verbosely
run-verbose()
{
    echo -e "\n\t##### Running : '$@'... #####\n"
    eval $@
}

export PATH=/opt/conda/bin:/usr/local/cuda/bin:${PATH}

export CC=$(which cc)
export CXX=$(which c++)
export CUDACXX=$(which nvcc)

ROOT_DIR=${PWD}
: ${TIMEMORY_BRANCH:="master"}

run-verbose git clone -b ${TIMEMORY_BRANCH} https://github.com/jrmadsen/TiMemory.git timemory-source
run-verbose cd timemory-source

SOURCE_DIR=${PWD}
run-verbose mkdir timemory-build
run-verbose cd timemory-build

BINARY_DIR=${PWD}
run-verbose cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPYTHON_EXECUTABLE=$(which python) -DTIMEMORY_BUILD_LTO=ON ${SOURCE_DIR} -G Ninja
run-verbose ninja
run-verbose ninja install

cd ${ROOT_DIR}

run-verbose rm -rf ${BINARY_DIR} ${SOURCE_DIR}