#!/usr/bin/env bash
# Sets up a minimal C++ CMake project in the current directory.
# Usage: project_harness.sh <project_name>
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <project_name>" >&2
    exit 1
fi
project_name=$1

CMAKELISTS_CONTENT="cmake_minimum_required(VERSION 3.20)
project(${project_name} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(${project_name} src/main.cpp)
target_compile_options(${project_name} PRIVATE -Wall -Wextra -Wpedantic -Wshadow -Wconversion)

# Debug builds: catch memory errors and undefined behaviour at runtime.
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(SANITIZERS -fsanitize=address,undefined -fno-sanitize-recover=all)
    target_compile_options(${project_name} PRIVATE -g3 -fno-omit-frame-pointer \${SANITIZERS})
    target_link_options(${project_name} PRIVATE \${SANITIZERS})
endif()"

MAINCPP_CONTENT="#include <iostream>

int main(int argc, char* argv[]) {
    std::cout << \"Hello from ${project_name}!\n\";
    for (int i = 1; i < argc; ++i) {
        std::cout << \"  arg \" << i << \": \" << argv[i] << '\n';
    }
    return 0;
}"

BUILD_CONTENT='#!/usr/bin/env bash
set -e
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build -j "$(nproc)"'

RUN_CONTENT="#!/usr/bin/env bash
set -e
./build.sh
./build/${project_name} \"\$@\""

DEBUG_CONTENT="#!/usr/bin/env bash
set -e
./build.sh
# LeakSanitizer can't run under gdb; abort_on_error makes gdb stop on sanitizer errors.
export ASAN_OPTIONS=detect_leaks=0:abort_on_error=1 UBSAN_OPTIONS=abort_on_error=1
gdb -q -ex run --args ./build/${project_name} \"\$@\""

GITIGNORE_CONTENT="# build output
build/
.cache/
compile_commands.json

# objects and binaries
*.o
*.a
*.so
*.out

# core dumps
core
core.[0-9]*

# editors
*.swp
*~
*.un~
.vscode/
.idea/"

# write_file FILE CONTENT: create FILE with CONTENT, unless it already exists.
write_file() {
    if [[ -e $1 ]]; then
        echo "skipped $1 (already exists)"
    else
        echo "$2" > "$1"
        echo "created $1"
    fi
}

mkdir -p src
write_file CMakeLists.txt "$CMAKELISTS_CONTENT"
write_file src/main.cpp "$MAINCPP_CONTENT"
write_file build.sh "$BUILD_CONTENT"
write_file run.sh "$RUN_CONTENT"
write_file debug.sh "$DEBUG_CONTENT"
write_file .gitignore "$GITIGNORE_CONTENT"
chmod +x build.sh run.sh debug.sh

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    git init -q && echo "initialised git repository"
fi
