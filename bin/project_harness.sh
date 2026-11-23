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

# Every .cpp under src/ is compiled; CONFIGURE_DEPENDS picks up new files on the next build.
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp)
add_executable(${project_name} \${SOURCES})
target_include_directories(${project_name} PRIVATE include)
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
# Usage: ./build.sh [debug|release]   (default: debug)
set -e
cd "$(dirname "$0")"
type=${1:-debug}
cmake -B "build/$type" -DCMAKE_BUILD_TYPE="${type^}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build "build/$type" -j "$(nproc)"
ln -sf "build/$type/compile_commands.json" .   # for clangd'

RUN_CONTENT="#!/usr/bin/env bash
# Usage: ./run.sh [--release] [program args...]
set -e
cd \"\$(dirname \"\$0\")\"
type=debug
if [[ \${1:-} == --release ]]; then type=release; shift; fi
./build.sh \$type
./build/\$type/${project_name} \"\$@\""

DEBUG_CONTENT="#!/usr/bin/env bash
# Usage: ./debug.sh [program args...]
set -e
cd \"\$(dirname \"\$0\")\"
./build.sh debug
# LeakSanitizer can't run under gdb; abort_on_error makes gdb stop on sanitizer errors.
export ASAN_OPTIONS=detect_leaks=0:abort_on_error=1 UBSAN_OPTIONS=abort_on_error=1
gdb -q -ex run --args ./build/debug/${project_name} \"\$@\""

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

mkdir -p src include
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
