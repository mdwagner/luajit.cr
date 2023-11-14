module Luajit
  class LuaError < Exception
    def self.check!(state : LuaState, status : LuaStatus? = nil)
      case status || state.status
      when .runtime_error?
        raise new(state, cause: LuaRuntimeError.new)
      when .memory_error?
        raise new(state, cause: LuaMemoryError.new)
      when .handler_error?
        raise new(state, cause: LuaHandlerError.new)
      when .syntax_error?
        raise new(state, cause: LuaSyntaxError.new)
      when .file_error?
        raise new(state, cause: LuaFileError.new)
      end
    end

    def initialize(state : LuaState, cause : Exception? = nil)
      if state.is_string?(-1)
        super(state.to_string(-1), cause: cause)
      else
        super("Unknown error", cause: cause)
      end
    end
  end

  class LuaAPIError < Exception
  end

  class LuaRuntimeError < Exception
    def initialize(message = "Lua runtime error")
      super(message)
    end
  end

  class LuaMemoryError < Exception
    def initialize(message = "Lua memory allocation error")
      super(message)
    end
  end

  class LuaHandlerError < Exception
    def initialize(message = "Failed to run Lua error handler function")
      super(message)
    end
  end

  class LuaSyntaxError < Exception
    def initialize(message = "Lua syntax error during pre-compilation")
      super(message)
    end
  end

  class LuaFileError < Exception
    def initialize(message = "Lua file error")
      super(message)
    end
  end
end
