module Luajit
  struct LuaReg
    getter name : String
    getter function : LuaCFunction

    def initialize(@name, @function)
      raise "block cannot be a closure" if @function.closure?
    end
  end
end
