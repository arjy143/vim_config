# Vim config

To run:

run `install_dependencies.sh`, which will install:
- clangd, clang-format
- ripgrep
- glow
- build essentials

The script will then automatically link the local vimrc to this one, and install the plugins.

`bin/project_harness.sh <project_name>` sets up a minimal C++ CMake project in the current directory.