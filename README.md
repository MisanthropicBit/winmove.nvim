<div align="center">
  <br />
  <h1>winmove.nvim</h1>
  <p><i>A plugin that makes it easy to rearrange and resize windows ([showcase](#showcase))</i></p>
  <p>
    <img src="https://img.shields.io/badge/version-0.1.0-blue?style=flat-square" />
    <a href="https://luarocks.org/modules/MisanthropicBit/winmove.nvim">
        <img src="https://img.shields.io/luarocks/v/MisanthropicBit/winmove.nvim?logo=lua&color=purple" />
    </a>
    <a href="/.github/workflows/tests.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/MisanthropicBit/winmove.nvim/tests.yml?branch=master&style=flat-square" />
    </a>
    <a href="/LICENSE">
        <img src="https://img.shields.io/github/license/MisanthropicBit/winmove.nvim?style=flat-square" />
    </a>
  </p>
  <br />
</div>

## Installing

* **[vim-plug](https://github.com/junegunn/vim-plug)**

```vim
Plug 'MisanthropicBit/winmove.nvim'
```

* **[packer.nvim](https://github.com/wbthomason/packer.nvim)**

```lua
use 'MisanthropicBit/winmove.nvim'
```

## Setup

Setup using `winmove.setup` unless you are content with the defaults which are
shown below. Refer to the [docs](doc/winmove.txt) for more help.

```lua
require('winmove').setup({
    hl_group = "Search", -- Highlight group for highlighting windows in move mode
    mappings = {
        left = "h",
        down = "j",
        up = "k",
        right = "l",
        far_left = "H",
        far_down = "J",
        far_up = "K",
        far_right = "L",
        split_left = "sh",
        split_down = "sj",
        split_up = "sk",
        split_right = "sl",
        help = "?",
        quit = "q",
    },
})
```

## Autocommands

You can define autocommands for when move mode starts (`"WinmoveModeStart"`) and
ends (`"WinmoveModeEnd"`).

```lua

```

## API

Consider only the functions below part of the official API.

```lua
winmove.version()
```

You can call `winmove.move_mode_activated` to check if move mode is currently
active.

```lua
winmove.move_mode_activated()
```

## FAQ

## Showcase

### Works with asynchronous output
