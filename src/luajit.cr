require "./luajit/version"
require "./luajit/lib_luajit"
require "./luajit/lua_c_function"
require "./luajit/lua_type"
require "./luajit/lua_ref"
require "./luajit/lua_any"
require "./luajit/*"

module Luajit
  def self.new(stdlib = true) : LuaState
    LuaState.create.tap do |state|
      state.open_library(:all) if stdlib
    end
  end

  def self.close(state : LuaState) : Nil
    LuaState.destroy(state)
  end

  def self.once(stdlib = true, & : LuaState ->) : Nil
    state = new(stdlib)
    begin
      yield state
    ensure
      close(state)
    end
  end
end
