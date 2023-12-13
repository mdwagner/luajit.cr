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
    version: ~> 0.3.1
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
