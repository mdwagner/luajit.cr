module Luajit
  class LuaRuntimeError < Exception
    def initialize
      super("Lua runtime error")
    end
  end

  class LuaMemoryError < Exception
    def initialize
      super("Lua memory allocation error")
    end
  end

  class LuaSyntaxError < Exception
    def initialize
      super("Lua syntax error during pre-compilation")
    end
  end

  class LuaHandlerError < Exception
    def initialize
      super("Failed to run Lua error handler function")
    end
  end

  class LuaError < Exception
    def initialize(state : LuaState)
      msg = "Unknown error"
      if state.is_string?(-1)
        msg = state.to_string(-1)
      end
      super(msg)
    end
  end
end
