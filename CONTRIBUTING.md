# Contributing

1. Fork this repository.
2. Make changes.
3. Make sure tests and styling checks are passing.
   * Run tests by running `./tests/run_tests.sh` in the root directory. Running the tests requires [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim). You may need to update the paths in `./tests/minimal_init.lua` to match those of your local installations to be able to run the tests.
   * Install [stylua](https://github.com/JohnnyMorganz/StyLua) and check styling using `stylua --check lua/ tests/`. Omit `--check` in order to fix styling.
4. Submit a pull request.
5. Get it approved.
