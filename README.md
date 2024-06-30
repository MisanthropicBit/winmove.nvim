<div align="center">
  <br />
  <h1>winmove.nvim</h1>
  <p><i>Easily move and resize windows</i></p>
  <p>
    <img src="https://img.shields.io/badge/version-0.1.0-blue?style=flat-square" />
    <a href="https://luarocks.org/modules/misanthropicbit/winmove.nvim">
        <img src="https://img.shields.io/luarocks/v/misanthropicbit/winmove.nvim?logo=lua&color=purple&style=flat-square" />
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

<!-- panvimdoc-ignore-start -->

<div align="center">

🚧 **This plugin is under development** 🚧

</div>

- [Requirements](#requirements)
- [Installing](#installing)
- [Configuration](#configuration)
- [Autocommands](#autocommands)
- [Public API](#public-api)
- [Contributing](#contributing)
- [FAQ](#faq)
- [Showcase](#showcase)
- [Similar projects](#similar-projects)

<!-- panvimdoc-ignore-end -->

## Requirements

* Neovim 0.8.0+

## Installing

* **[vim-plug](https://github.com/junegunn/vim-plug)**

```vim
Plug 'MisanthropicBit/winmove.nvim'
```

* **[packer.nvim](https://github.com/wbthomason/packer.nvim)**

```lua
use 'MisanthropicBit/winmove.nvim'
```

## Configuration

If you are content with the defaults that are shown below, you don't need to
call the `configure` function. No default keymaps are set other than those
active during modes.

```lua
require('winmove').configure({
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
            left_botright = "<c-h>", -- Resize left with bottom-right anchor
            down_botright = "<c-j>", -- Resize down with bottom-right anchor
            up_botright = "<c-k>", -- Resize up with bottom-right anchor
            right_botright = "<c-l>", -- Resize right with bottom-right anchor
        },
    },
})
```

## Autocommands

You can define autocommands that trigger when a mode starts and ends.

```lua
vim.api.nvim_create_autocmd("WinmoveModeStart", {
    callback = function(event)
        vim.print("Started ".. event.data.mode .. " mode")
    end,
})

vim.api.nvim_create_autocmd("WinmoveModeEnd", {
    callback = function(event)
        vim.print("Ended ".. event.data.mode .. " mode")
    end,
})
```

## Public API

> [!WARNING]  
> Consider only the functions below part of the public API. All other functions
> are subject to change.

#### `winmove.configure`

Configure `winmove`. Also see [Configuration](#configuration).

#### `winmove.version`

Get the current version of `winmove`.

#### `winmove.current_mode`

Check which mode is currently active. Returns `"move"`, `"resize"`, or `nil`.

#### `winmove.start_mode`

Start a mode.

```lua
---@param mode winmove.Mode
winmove.start_mode(mode)

-- Example:
winmove.start_mode(winmove.Mode.Move)
winmove.start_mode("resize")
```

#### `winmove.stop_mode`

Stop the current mode. Fails if no mode is currently active.

#### `winmove.move_window`

Move a window (does not need to be the current window). See [a
showcase](#moving-around-windows).

```lua
---@param source_win_id integer
---@param dir winmove.Direction
winmove.move_window(source_win_id, dir)

-- Example:
winmove.move_window(1000, "k")
```

#### `winmove.split_into`

Split into a window (does not need to be the current window). See [a
showcase](#split-into-other-windows).

```lua
---@param source_win_id integer
---@param dir winmove.Direction
winmove.split_into(source_win_id, dir)

-- Example:
winmove.split_into(1000, "l")
```

#### `winmove.move_window_far`

Move a window as far as possible in a direction (does not need to be the current
window). See [a showcase](#moving-as-far-as-possible-in-a-direction).

```lua
---@param source_win_id integer
---@param dir winmove.Direction
winmove.move_window_far(source_win_id, dir)

-- Example:
winmove.move_window_far(1000, "h")
```

#### `winmove.resize_window`

Resize a window (does not need to be the current window). See a
[showcase](#moving-and-resizing-windows).

```lua
---@param win_id integer
---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.ResizeAnchor?
winmove.resize_window(win_id, dir, count, anchor)

-- Example:
winmove.resize_window(1000, "j", 3, winmove.ResizeAnchor.TopLeft)
winmove.resize_window(1000, "l", 1, winmove.ResizeAnchor.BottomRight)
```

## Contributing

See [here](/CONTRIBUTING.md).

## FAQ

#### **Q**: Why create this project?

**A**: There are [already a few projects](#similar-projects) for moving windows
but none of them felt intuitive to me so I did the only rational thing a
developer would do in this situation and created my own plugin. If any of the
others suit your needs then by all means use them.

## Showcase

### Moving around windows

> [!IMPORTANT]  
> Moving windows takes into account the cursor position of the current window
> relative to the target window in the direction you are moving.
>
> For example, if your cursor position is closest to the bottom of one window in
> the target direction, the window will be moved below that window. See
> [this example](#moving-using-relative-cursor-position) for a visual explanation.

### Moving and resizing windows

### Moving as far as possible in a direction

### Move between tabs

### Moving using relative cursor position

### Toggle help

### Split as far as possible in a direction

### Split into other windows

### Works with asynchronous output

## Similar projects

* [winshift.nvim](https://github.com/sindrets/winshift.nvim)
* [vim-tradewinds](https://github.com/andymass/vim-tradewinds)
