# luajit.cr

LuaJIT bindings for Crystal

## Installation

1. Install [LuaJIT](https://luajit.org)
    - [Linux](https://www.google.com/search?q=install+luajit+linux)
    - [Mac](https://www.google.com/search?q=install+luajit+mac)
        - `brew install luajit`
    - [Windows](https://www.google.com/search?q=install+luajit+windows)
        - [See below](#windows)

2. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  luajit:
    github: mdwagner/luajit.cr
    version: ~> 0.4.0
```

3. Run `shards install`

### Windows

#### Simple

1. Run `.\scripts\build.ps1`
2. Check output for `--link-flags`
3. Add `--link-flags` to existing `crystal` commands

Example (powershell):

```
.\scripts\build.ps1
# ...build output...
# Add the following to any crystal commands:
#   --link-flags=/LIBPATH:C:\Lua
crystal run --link-flags=/LIBPATH:C:\Lua src\example.cr
```

#### Advanced

There are a couple ways to avoid needing to add linker flags on every command,
but they require a little more work.

- Modify `.\scripts\build.ps1` to install to a more global directory (e.g. `C:\Lua`)
    - Add global directory to environment variable `CRYSTAL_LIBRARY_PATH`
        - NOTE: make sure to still include Crystal's compiler directory as well (can be found by running `crystal env CRYSTAL_LIBRARY_PATH`)
    - Add global directory to PATH
        - This isn't completely necessary, but if you plan to leverage `-Dpreview_dll` it's required
- Modify `.\scripts\build.ps1` to install to Crystal's compiler directory (e.g. where stdlib lives)
    - This has the benefit of not modifying any environment variables
    - However, newer versions of Crystal might require a reinstall

## Usage

```crystal
require "luajit"

# Basic Hello World
Luajit.run do |state|
  state.execute! <<-'LUA'
  print("Hello World!")
  LUA
end

# Crystal type to Lua object
class Account < Luajit::LuaObject
  def_class_method "new" do |state|
    _self = new
    Luajit.setup_userdata(state, _self, self)
    1
  end

  def_instance_method "deposit" do |state|
    _self = Luajit.userdata_value(state, self, 1)
    value = state.to_i(2)
    _self.deposit(value)
    0
  end

  def_instance_method "withdraw" do |state|
    _self = Luajit.userdata_value(state, self, 1)
    value = state.to_i(2)
    _self.withdraw(value)
    0
  end

  def_instance_method "get_balance" do |state|
    _self = Luajit.userdata_value(state, self, 1)
    state.push(_self.balance)
    1
  end

  property balance : Int32 = 0

  def deposit(value : Int32)
    self.balance += value
  end

  def withdraw(value : Int32)
    self.balance -= value
  end
end

Luajit.run do |state|
  Luajit.create_lua_object(state, Account)

  state.execute! <<-'LUA'
  local account = Account.new()
  account:deposit(2000)
  account:withdraw(100)
  assert(account:get_balance() == 1900)
  LUA
end
```

## Development

- [x] LuaJIT bindings
- [x] Works on Windows (+build script)
- [x] Safe wrappers
- [x] Better tests
- [x] Better docs + readme
- [x] Crystal to Lua object wrapper

If you encounter any bugs, feel free to open an issue!

## Contributing

1. Fork it (<https://github.com/mdwagner/luajit.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Michael Wagner](https://github.com/mdwagner) - creator and maintainer
