rockspec_format = "3.0"
package = 'winmove.nvim'
version = 'scm-1'

description = {
  summary = 'Easily move and resize windows',
  detailed = [[]],
  labels = {
    'neovim',
    'plugin',
    'window',
    'resize',
  },
  homepage = 'https://github.com/MisanthropicBit/winmove.nvim',
  issues_url = 'https://github.com/MisanthropicBit/winmove.nvim/issues',
  license = 'BSD 3-Clause',
}

dependencies = {
  'lua == 5.1',
}

source = {
   url = 'git+https://github.com/MisanthropicBit/winmove.nvim',
}

build = {
   type = 'builtin',
   copy_directories = {
     'doc',
     'plugin',
   },
}

test = {
    type = "command",
    command = "./tests/run_tests.sh",
}
