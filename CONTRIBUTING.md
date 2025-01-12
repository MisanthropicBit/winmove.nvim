# Contributing

1. Fork this repository.
2. Make changes.
3. Install [luarocks](https://luarocks.org/).
4. Set up testing environment.

   ```shell
    > luarocks init
    > luarocks config --scope project lua_version 5.1
   ```

4. Add tests.
5. Run tests and make sure they pass.

   ```shell
    > luarocks test tests
   ```

6. Install [stylua](https://github.com/JohnnyMorganz/StyLua) and check styling using `stylua --check lua/ tests/`. Omit `--check` in order to fix styling.
7. Submit a pull request.
8. Get it approved.
