<div align="center">
  <br />
  <h1>winmove.nvim</h1>
  <p><i>Easily move, swap, and resize windows</i></p>
  <p>
    <img src="https://img.shields.io/badge/version-0.1.1-blue?style=flat-square" />
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

https://github.com/user-attachments/assets/417023dd-9d5d-4ae9-891d-514e0f3038d5

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

* Neovim 0.9.0+

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

> [!NOTE]  
> For mode highlight groups that only have a foreground color, `winmove` will
> automatically use the foreground color as a background color for the given
> mode so you do not have to create a custom highlight group yourself.

```lua
require('winmove').configure({
    keymaps = {
        help = "?", -- Open floating window with help for the current mode
        help_close = "q", -- Close the floating help window
        quit = "q", -- Quit current mode
        toggle_mode = "<tab>", -- Toggle between modes when in a mode
    },
    modes = {
        move = {
            highlight = "Visual", -- Highlight group for move mode
            at_edge = {
                horizontal = at_edge.AtEdge.None, -- Behaviour at horizontal edges
                vertical = at_edge.AtEdge.None, -- Behaviour at vertical edges
            },
            keymaps = {
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
        },
        swap = {
            highlight = "Substitute", -- Highlight group for swap mode
            at_edge = {
                horizontal = at_edge.AtEdge.None, -- Behaviour at horizontal edges
                vertical = at_edge.AtEdge.None, -- Behaviour at vertical edges
            },
            keymaps = {
                left = "h", -- Swap left
                down = "j", -- Swap down
                up = "k", -- Swap up
                right = "l", -- Swap right
            },
        },
        resize = {
            highlight = "Todo", -- Highlight group for resize mode
            default_resize_count = 3, -- Default amount to resize windows
            keymaps = {
                -- When resizing, the anchor is in the top-left corner of the window by default
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
    },
})
```

There are three behaviour when moving or swapping towards an edge of the editor:

* `winmove.AtEdge.None`: Do nothing.
* `winmove.AtEdge.Wrap`: Wrap around to the opposite edge.
* `winmove.AtEdge.MoveToTab`: Move to the previous/next tab if possible.

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

Check which mode is currently active. Returns `"move"` (`winmove.Mode.Move`),
`"swap"` (`winmove.Mode.Swap`), `"resize"` (`winmove.Mode.Resize`), or `nil`.

#### `winmove.start_mode`

Start a mode.

```lua
---@param mode winmove.Mode
winmove.start_mode(mode)

-- Example:
winmove.start_mode(winmove.Mode.Move)
winmove.start_mode("swap")
winmove.start_mode("move")
winmove.start_mode(winmove.Mode.Resize)
```

#### `winmove.stop_mode`

Stop the current mode. Fails if no mode is currently active.

#### `winmove.move_window`

Move a window (does not need to be the current window). See [this
showcase](#moving-around-windows). This takes the cursor position in the window
[into account](#moving-using-relative-cursor-position) when moving.

```lua
---@param win_id integer
---@param dir winmove.Direction
winmove.move_window(win_id, dir)

-- Example:
winmove.move_window(1000, "k")
```

#### `winmove.split_into`

Split into a window (does not need to be the current window). See [this showcase](#split-into-other-windows). This takes the cursor position in the window
[into account](#moving-using-relative-cursor-position) when splitting into.

```lua
---@param win_id integer
---@param dir winmove.Direction
winmove.split_into(win_id, dir)

-- Example:
winmove.split_into(1000, "l")
```

#### `winmove.move_window_far`

Move a window as far as possible in a direction (does not need to be the current
window). See [this showcase](#moving-as-far-as-possible-in-a-direction).

```lua
---@param win_id integer
---@param dir winmove.Direction
winmove.move_window_far(win_id, dir)

-- Example:
winmove.move_window_far(1000, "h")
```

#### `winmove.swap_window_in_direction`

Swap a window in a given direction (does not need to be the current window). This takes the cursor position in the window [into account](#moving-using-relative-cursor-position) when swapping.

```lua
---@param win_id integer
---@param dir winmove.Direction
winmove.swap_window_in_direction(win_id, dir)

-- Example:
winmove.swap_window_in_direction(1000, "j")
winmove.swap_window_in_direction(1000, "l")
```

#### `winmove.swap_window`

Swap a window (does not need to be the current window). When called the first
time, highlights the selected window for swapping. When called the second time
with another window will swap the two selected windows.

```lua
---@param win_id integer
---@param dir winmove.Direction
winmove.swap_window(win_id, dir)

-- Example:
winmove.swap_window(1000)
winmove.swap_window(1000)
```

#### `winmove.resize_window`

Resize a window (does not need to be the current window). The window can be
resized relative to an anchor in the top-left or bottom-right corner of the
window.

Resizing respects the global `winwidth`/`winminwidth` and
`winheight`/`winminheight` options respectively, with the largest value taking
priority. If a window being resized would shrink another window's size beyond
the values of those options, the whole row/column of windows are adjusted except
if all windows in the direction of resizing are as small as they can get.

See [this showcase](#moving-and-resizing-windows).

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

> [!IMPORTANT]  
> Moving and swapping windows takes into account the cursor position of the
> current window relative to the target window in the direction you are moving
> or swapping.
>
> For example, if your cursor position is closest to the bottom of one window in
> the target direction, the window will be moved below that window. See 
> [this example](#moving-using-relative-cursor-position) for a visual explanation.

### Moving around windows

https://github.com/user-attachments/assets/417023dd-9d5d-4ae9-891d-514e0f3038d5

### Moving using relative cursor position

https://github.com/user-attachments/assets/7fce8ab8-4ba4-4869-8ab8-220f653541d8

### Splitting into windows

As opposed to moving windows, which will squeeze a window in between other
windows, splitting into a window will move it next to a target window.

https://github.com/user-attachments/assets/4bf49e27-d08b-4926-9f17-57bf2e702c64

### Swapping windows

https://github.com/user-attachments/assets/6d9986cb-0e18-4dc4-9b02-70ff5683a579

https://github.com/user-attachments/assets/195cde61-5382-4eea-9dcb-2eb012771d16

### Resizing windows

https://github.com/user-attachments/assets/8f77c9c4-dca1-4647-9049-8695e5351431

https://github.com/user-attachments/assets/8f1fff43-2830-48f5-a29b-0b1aa7d865b2

### Moving as far as possible in a direction

https://github.com/user-attachments/assets/b3550d2d-287b-4b5d-9ea9-3466ac47c0d1

### Move between tabs

https://github.com/user-attachments/assets/6d5bf9ca-3b8b-4a72-978a-520eb2db779b

### Works with asynchronous output

https://github.com/user-attachments/assets/88abfe11-55bb-4096-979e-7a5754feaa6a

## Similar projects

* [winshift.nvim](https://github.com/sindrets/winshift.nvim)
* [vim-tradewinds](https://github.com/andymass/vim-tradewinds)
