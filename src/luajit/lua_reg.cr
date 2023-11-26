module Luajit
  struct LuaReg
    getter name : String
    getter function : LuaCFunction

    # Raises exception if passed block is a closure
    def self.new(name : String, &block : LuaCFunction)
      raise "block cannot be a closure" if block.closure?
      new(name, block)
    end

    protected def initialize(@name, @function)
    end
  end
end
