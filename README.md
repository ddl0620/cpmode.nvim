# cpmode.nvim

A Neovim plugin for competitive programming that provides a streamlined coding environment with automatic I/O handling.

## ✨ Features

- 🎯 **Split Layout**: Dedicated panes for code (left) and I/O (right: input top, output bottom)
- ⚡ **Quick Execution**: Run your code with `:Cpru` - no need for `freopen()` in your code
- 📝 **Templates**: Insert competitive programming templates with `:Cpt`
- 🔄 **Temporary I/O**: Input/output buffers are temporary - no cluttered files
- 🌲 **Smart Navigation**: Files from nvim-tree always open in the code pane
- 🎨 **Multi-language**: Support for C++, C, Java, and Python

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "yourusername/cpmode.nvim",
  config = function()
    require('cpmode').setup({
      io_pane_width = 40,  -- Width of I/O pane (percentage)
      input_height = 50,   -- Height of input pane (percentage)
      timeout = 5,         -- Execution timeout in seconds
    })
  end,
  keys = {
    { "<leader>cp", "<cmd>Cpm<cr>", desc = "Toggle CP Mode" },
    { "<leader>cr", "<cmd>Cpru<cr>", desc = "Run CP Program" },
    { "<leader>cx", "<cmd>Cpre<cr>", desc = "Reset CP I/O" },
    { "<leader>ct", "<cmd>Cpt<cr>", desc = "Insert CP Template" },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'yourusername/cpmode.nvim',
  config = function()
    require('cpmode').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'yourusername/cpmode.nvim'

lua << EOF
require('cpmode').setup()
EOF
```

## 🚀 Quick Start

1. Open a `.cpp` file (or other supported language)
2. Run `:Cpt` to insert a competitive programming template
3. Run `:Cpm` to activate the split layout
4. Write your code in the left pane
5. Add test input in the top-right pane
6. Run `:Cpru` to execute and see output in the bottom-right pane

## 📝 Commands

| Command | Description |
|---------|-------------|
| `:Cpm` | Toggle competitive programming layout |
| `:Cpru` | Compile and run the current file with I/O |
| `:Cpt` | Insert language-specific template at cursor |
| `:Cpre` | Clear input and output buffers |

## ⚙️ Configuration

### Default Configuration
```lua
require('cpmode').setup({
  -- Width of the I/O pane (percentage of screen)
  io_pane_width = 40,
  
  -- Height of input pane relative to I/O pane (percentage)
  input_height = 50,
  
  -- Program execution timeout (seconds)
  timeout = 5,
  
  -- Compilation commands
  compile_commands = {
    cpp = "g++ -std=c++17 -O2 -Wall %s -o %s",
    c = "gcc -std=c11 -O2 -Wall %s -o %s",
    java = "javac %s",
    python = nil,
  },
  
  -- Run commands
  run_commands = {
    cpp = "./%s",
    c = "./%s",
    java = "java %s",
    python = "python3 %s",
  },
})
```

### Custom Templates

You can customize templates for each language:
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
    python = [[
def solve():
    # Your code here
    pass

if __name__ == "__main__":
    solve()
]],
  },
})
```

## 🎯 Workflow Example
```bash
# 1. Create/open a C++ file
nvim solution.cpp

# 2. Insert template
:Cpt

# 3. Activate CP mode
:Cpm

# 4. Write your solution in the left pane
# 5. Add test input in the top-right pane
# 6. Run your code
:Cpru

# 7. View output in the bottom-right pane
```

## 🔧 Requirements

- Neovim >= 0.8.0
- Compiler/interpreter for your language:
  - C++: `g++` or `clang++`
  - C: `gcc` or `clang`
  - Java: `javac` and `java`
  - Python: `python3`
- Unix-like system (Linux, macOS) or Windows with proper PATH setup
- For timeout feature: `timeout` command (Unix) or equivalent

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by competitive programming workflows
- Built for the Neovim community

## 📮 Support

If you encounter any issues or have suggestions, please [open an issue](https://github.com/yourusername/cpmode.nvim/issues).

---

**Note**: This plugin works best with [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) and [alpha-nvim](https://github.com/goolord/alpha-nvim), but they are not required.
```

### `LICENSE`
```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### `.gitignore`
```
# Lua
*.lua~

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~

# Testing
/test/