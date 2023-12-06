# luajit.cr

LuaJIT bindings for Crystal

## Installation

1. Install [LuaJIT](https://luajit.org)
    - [Linux](https://www.google.com/search?q=install+luajit+linux)
        - Install with package manager
    - [Mac](https://www.google.com/search?q=install+luajit+mac)
        - Install with brew
    - [Windows](https://www.google.com/search?q=install+luajit+windows)
        - Run `.\scripts\build_luajit.bat` to clone, build, and install LuaJIT library into `ext/` directory

2. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  luajit:
    github: mdwagner/luajit.cr
    version: ~> 0.1.0
```

3. Run `shards install`

## Usage

```crystal
require "luajit"

# Basic Hello World
Luajit.run do |state|
  state.execute! <<-'LUA'
  print("Hello World!")
  LUA
end
```

## Development

- [x] LuaJIT bindings
- [x] Works on Windows (+build script)
- [x] Safe wrappers
- [x] Better tests
- [x] Better docs + readme

If you encounter any bugs, feel free to open an issue!

## Contributing

1. Fork it (<https://github.com/mdwagner/luajit.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Michael Wagner](https://github.com/mdwagner) - creator and maintainer
