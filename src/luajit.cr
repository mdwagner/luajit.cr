require "./luajit/version"
require "./luajit/lib_luajit"
require "./luajit/lua_c_function"
require "./luajit/lua_type"
require "./luajit/lua_ref"
require "./luajit/lua_any"
require "./luajit/*"

module Luajit
  def self.new : LuaState
    LuaState.create
  end

  def self.new_with_defaults : LuaState
    new.tap do |state|
      state.open_library(:all)
    end
  end

  def self.close(state : LuaState) : Nil
    LuaState.destroy(state)
  end

  def self.run(& : LuaState ->) : Nil
    state = new_with_defaults
    begin
      yield state
    ensure
      close(state)
    end
  end
end
