module Luajit
  class Library
    property name : String
    property store = {} of String => LuaState::Function

    def initialize(@name)
    end

    def register(fn_name : String, &block : LuaState::Function) : Nil
      store[fn_name] = block
    end
  end
end
