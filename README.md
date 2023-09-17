<div align="center">
  <br />
  <h1>winmove.nvim</h1>
  <p><i>Easily move and resize windows</i></p>
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

See the [showcase](#showcase) for recordings of using `winmove`.

## Requirements

* Neovim 0.5.0+

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

If you are content with the defaults, you don't need to call the `setup`
function. Otherwise, either call `winmove.setup` with your desired options or
set `vim.g.winmove` to your desired options. Defaults are shown below. Refer to
the [docs](doc/winmove.txt) for more help.

```lua
require('winmove').setup({ -- Or pass the table to vim.g.winmove
    highlights = {
        move = "Search", -- Highlight group for move mode
        resize = "Substitute", -- Highlight group for resize mode
    },
    wrap_around = true, -- Wrap around edges when moving windows
    default_resize_count = 3, -- Default amount to resize windows
    keymaps = {
        help = "?", -- Open floating window with help for the current mode
        help_close = "q", -- Close the floating help window
        quit = "q", -- Quit current mode
        toggle_mode = "<tab>", -- Toggle between move and resize modes
        move = {
            left = "h", -- Move window left
            down = "j", -- Move window down
            up = "k", -- Move window up
            right = "l", -- Move window right
            far_left = "H", -- Move window far left and maximize it
            far_down = "J", -- Move window down and maximize it
            far_up = "K", -- Move window up and maximize it
            far_right = "L", -- Move window right and maximize it
            split_left = "sh", -- Create a split with the window on the left
            split_down = "sj", -- Create a split with the window below
            split_up = "sk", -- Create a split with the window above
            split_right = "sl", -- Create a split with the window on the right
        },
        resize = {
            -- When resizing, the anchor is in the top-left corner of the window
            left = "h", -- Resize to the left
            down = "j", -- Resize down
            up = "k", -- Resize up
            right = "l", -- Resize to the right
        },
    },
})
```

## Commands

The easiest way to start a mode is through the `Winmove` command: `:Winmove
move` or `:Winmove resize`.

> [!IMPORTANT]  
> Moving windows takes into account the cursor position of the current window
> relative to the target window in the direction you are moving.
>
> For example, if your cursor position is closest to the bottom of one window in
> the target direction, the window will be moved below that window. See
> [this example](#moving-using-relative-cursor-position) for a visual explanation.

The `Winmove` command also takes arguments for moving windows that correspond to
the `config.keymaps.move` key passed to the `setup` function, e.g. `:Winmove
far_right`. You can also quit the current mode using `:Winmove quit`.

## Autocommands

You can define autocommands for when modes start and end.

* `"WinmoveMoveModeStart"`
* `"WinmoveMoveModeEnd"`
* `"WinmoveResizeModeStart"`
* `"WinmoveResizeModeEnd"`

```lua
vim.api.nvim_create_autocmd("WinmoveMoveModeStart", {
    callback = function()
        vim.notify("Move mode started", vim.log.levels.INFO)
    end,
})
```

## Public API

Consider only the functions below part of the official API. All other functions
are subject to change.

Setup `winmove`.

```lua
winmove.setup({ ... })
```

Get the current version of `winmove`. You can also execute `:Winmove
version`.

```lua
winmove.version()
```

Check which mode is currently active. Returns `"move"`, `"resize"`, or `"none"`.

```lua
winmove.current_mode()
```

## FAQ

#### **Q**: Why create this project?

**A**: There are [already a few projects](#similar-projects) for moving windows
but none of them suited me so I did the only rational thing a developer would do
in this situtation and created my own plugin.

## Showcase

### Moving around windows

### Moving and resizing windows

### Moving using relative cursor position

### Toggle help

### Split as far as possible in a direction

### Split into other windows

### Works with asynchronous output
