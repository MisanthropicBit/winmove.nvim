local _MODREV, _SPECREV = 'scm', '-1'
rockspec_format = "3.0"
package = 'nvim-dap'
version = _MODREV .. _SPECREV

description = {
  summary = 'Easily move and resize windows',
  detailed = [[]],
  labels = {
    'neovim',
    'plugin',
    'debug-adapter-protocol',
    'debugger',
  },
  homepage = 'https://github.com/MisanthropicBit/winmove.nvim',
  license = 'BSD 3-Clause',
}

dependencies = {
  'lua == 5.1',
}

source = {
   url = 'git://github.com/MisanthropicBit/winmove.nvim',
}

build = {
   type = 'builtin',
   copy_directories = {
     'doc',
     'plugin',
   },
}
