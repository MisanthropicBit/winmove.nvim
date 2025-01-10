rockspec_format = "3.0"
package = "winmove.nvim"
version = "scm-1"

description = {
  summary = "Easily move, swap, and resize windows",
  detailed = [[]],
  labels = {
    "neovim",
    "plugin",
    "window",
    "move",
    "swap",
    "resize",
  },
  homepage = "https://github.com/MisanthropicBit/winmove.nvim",
  issues_url = "https://github.com/MisanthropicBit/winmove.nvim/issues",
  license = "BSD 3-Clause",
}

dependencies = {
  "lua == 5.1",
}

source = {
   url = "git://github.com/MisanthropicBit/winmove.nvim",
}

build = {
   type = "builtin",
   copy_directories = {
     "doc",
     "plugin",
   },
}

test_dependencies = {
    "busted >= 2.2.0",
}

test = {
    type = "command",
    command = "nvim -l ./run-tests.lua",
}
