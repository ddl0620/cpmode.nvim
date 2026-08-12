# cpmode.nvim

A Neovim plugin for competitive programming: a split layout with dedicated
input/output panes, one-key compile-and-run, and a C++ debugger that stays out
of the STL.

## ✨ Features

- 🎯 **Split Layout**: Dedicated panes for code (left) and I/O (right: input top, output bottom)
- ⚡ **Quick Execution**: Run your code with `:Cpru` - no need for `freopen()` in your code
- 🐞 **Debugging**: `:Cpdb` builds a `-g -O0` binary and starts a gdb DAP session that feeds the input pane to stdin
- 📝 **Templates**: Insert competitive programming templates with `:Cpt`
- 🔄 **Temporary I/O**: Input/output buffers are temporary - no cluttered files
- 🌲 **Smart Navigation**: Files opened from anywhere always land in the code pane
- 🎨 **Multi-language**: Support for C++, C, Java, and Python

Runs asynchronously, so a long-running or infinite-looping program never
freezes the editor.

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "ddl0620/cpmode.nvim",
  dependencies = { "mfussenegger/nvim-dap" }, -- optional, for :Cpdb
  opts = {
    io_pane_width = 38,  -- Width of I/O pane (percentage)
    input_height = 50,   -- Height of input pane (percentage)
    timeout = 5,         -- Execution timeout in seconds
  },
}
```

## 🚀 Quick Start

1. Open a `.cpp` file
2. Run `:Cpt` to insert a competitive programming template
3. Run `:Cpm` to activate the split layout
4. Write your solution in the left pane
5. Type your test input in the top-right pane
6. Run `:Cpru` to execute, and read the output in the bottom-right pane

## 📝 Commands

| Command | Description |
|---------|-------------|
| `:Cpm`  | Toggle competitive programming layout |
| `:Cpru` | Compile and run the current file, using the input pane as stdin |
| `:Cpdb` | Build a debug binary and start a debugging session |
| `:Cpt`  | Insert language-specific template at cursor |
| `:Cpre` | Clear input and output buffers |
| `:Cpi`  | Jump to the input pane |

## 🐞 Debugging

`:Cpdb` compiles the current file with `-g -O0 -D_GLIBCXX_ASSERTIONS`, writes
the contents of the input pane to a file next to your source, and launches a
[nvim-dap](https://github.com/mfussenegger/nvim-dap) session against
`gdb -i dap`.

Two details make this usable for contest work:

**Variables read like C++, not like memory.** gdb ships the libstdc++ pretty
printers, so the variables panel shows `std::vector of length 3, capacity 3 =
{10, 20, 30}` rather than a heap pointer. This is the main reason the plugin
uses gdb rather than codelldb.

**Stepping stays in your code.** STL headers are templates instantiated into
your binary, so they carry debug info and a plain "step into" would descend
into `std::vector::operator[]`. The plugin loads
[`gdb/cpmode-skip.gdb`](gdb/cpmode-skip.gdb) into gdb, which skips
`/usr/include/c++/**` and anything matching `^std::`, `^__gnu_cxx::`, or
`^__gnu_debug::`.

### How stdin reaches the program

gdb's DAP implementation has no `stdinFile` parameter. It assigns the DAP
`args` field straight to gdb's `inferior.arguments`, and gdb shell-quotes each
element of a *list* — so passing `{"<", "in.txt"}` makes `<` a literal argv
entry. Passing `args` as a single *string* is used verbatim instead, which
means it goes through gdb's startup shell and the redirection works. That is
why the launch config sends `args = "< /path/to/input"`.

The debug build and the input snapshot are written next to your source as
`<name>_dbg` and `.<name>.cpmode.in`. Add these to `.gitignore` if you keep
contest folders under version control.

## ⚙️ Configuration

```lua
require('cpmode').setup({
  io_pane_width = 38,
  input_height = 50,
  timeout = 5,

  compile_commands = {
    cpp = "g++ -std=c++17 -O2 -Wall %s -o %s",
    c = "gcc -std=c11 -O2 -Wall %s -o %s",
    java = "javac %s",
    python = nil,
  },

  -- Used by :Cpdb. -O0 keeps the line table honest so the highlighted
  -- line matches the statement actually executing.
  debug_compile_commands = {
    cpp = "g++ -std=c++17 -g -O0 -Wall -D_GLIBCXX_ASSERTIONS %s -o %s",
    c = "gcc -std=c11 -g -O0 -Wall %s -o %s",
  },

  debug_suffix = "_dbg",
  debugger = "gdb",
  debug_stop_at_main = true,  -- break at main() automatically

  run_commands = {
    cpp = "./%s",
    c = "./%s",
    java = "java %s",
    python = "python3 %s",
  },
})
```

### Custom Templates

```lua
require('cpmode').setup({
  templates = {
    cpp = [[
#include <iostream>
using namespace std;

int main() {
    // Your code here
    return 0;
}]],
  },
})
```

## 🔧 Requirements

- Neovim >= 0.10 (uses `vim.system`)
- `g++` / `gcc` for C and C++
- For `:Cpdb`: `gdb` >= 14 (for the built-in `-i dap` interpreter) and
  [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- Unix-like system

## 📄 License

MIT
