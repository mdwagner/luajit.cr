module Luajit
  struct LuaReg
    getter name : String
    getter function : LuaCFunction

    def initialize(@name, @function)
      raise "block cannot be a closure" if @function.closure?
    end
  end

  class LuaReg::Library
    getter name : String
    getter regs = [] of LuaReg

    def initialize(@name)
    end

    # Raises exception if passed block is a closure
    def register(name : String, &block : LuaCFunction) : self
      regs << LuaReg.new(name, block)
      self
    end
  end
end
