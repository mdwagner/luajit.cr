require "./luajit/version"
require "./luajit/lib_luajit"
require "./luajit/lua_type"
require "./luajit/lua_ref"
require "./luajit/lua_any"
require "./luajit/*"

module Luajit
  alias Config = LuaBinding::LuaConfig

  # Same as `LuaState.create`
  def self.new : LuaState
    LuaState.create
  end

  # Same as `.new`, but also opens all Lua libraries
  def self.new_with_defaults : LuaState
    new.tap do |state|
      state.open_library(:all)
    end
  end

  # Same as `LuaState.destroy`
  def self.close(state : LuaState) : Nil
    LuaState.destroy(state)
  end

  # Yields a new `LuaState` and closes it at end of block
  def self.run(& : LuaState ->) : Nil
    state = new_with_defaults
    begin
      yield state
    ensure
      close(state)
    end
  end
end
