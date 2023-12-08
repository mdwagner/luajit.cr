module Luajit
  # Controls the Lua Garbage Collector
  struct LuaGC
    @state : LuaState

    protected def initialize(@state)
    end

    # Stops the garbage collector
    #
    # Raises `LuaError` if operation fails
    def stop : Nil
      push_fn__stop
      @state.pcall(0, 0) do |status|
        raise LuaError.default_handler(@state, status)
      end
    end

    # Restarts the garbage collector
    #
    # Raises `LuaError` if operation fails
    def restart : Nil
      push_fn__restart
      @state.pcall(0, 0) do |status|
        raise LuaError.default_handler(@state, status)
      end
    end

    # Performs a full garbage-collection cycle
    #
    # Raises `LuaError` if operation fails
    def collect : Nil
      push_fn__collect
      @state.pcall(0, 0) do |status|
        raise LuaError.default_handler(@state, status)
      end
    end

    # Returns the current amount of memory (in KBs) in use by Lua
    #
    # Raises `LuaError` if operation fails
    def count : Int32
      push_fn__count
      @state.pcall(0, 1) do |status|
        raise LuaError.default_handler(@state, status)
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024
    #
    # Raises `LuaError` if operation fails
    def count_bytes : Int32
      push_fn__count_bytes
      @state.pcall(0, 1) do |status|
        raise LuaError.default_handler(@state, status)
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Performs an incremental step of garbage collection
    #
    # To control the step size, you must experimentally tune
    # the value of _size_.
    #
    # Returns 1 if the step finished a garbage-collection cycle.
    #
    # Raises `LuaError` if operation fails
    def step(size : Int32) : Int32
      push_fn__step
      @state.push(size)
      @state.pcall(1, 1) do |status|
        raise LuaError.default_handler(@state, status)
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Sets data as the new value for the pause of the collector
    #
    # Returns the previous value of the pause.
    #
    # Raises `LuaError` if operation fails
    def set_pause(data : Int32) : Int32
      push_fn__set_pause
      @state.push(data)
      @state.pcall(1, 1) do |status|
        raise LuaError.default_handler(@state, status)
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Sets data as the new value for the step multiplier of the collector
    #
    # Returns the previous value of the step multiplier.
    #
    # Raises `LuaError` if operation fails
    def set_step_multiplier(data : Int32) : Int32
      push_fn__set_step_multiplier
      @state.push(data)
      @state.pcall(1, 1) do |status|
        raise LuaError.default_handler(@state, status)
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    private macro push_fn__stop
      @state.push_fn do |%lua_state|
        LibLuaJIT.lua_gc(%lua_state, LibLuaJIT::LUA_GCSTOP, 0)
        0
      end
    end

    private macro push_fn__restart
      @state.push_fn do |%lua_state|
        LibLuaJIT.lua_gc(%lua_state, LibLuaJIT::LUA_GCRESTART, 0)
        0
      end
    end

    private macro push_fn__collect
      @state.push_fn do |%lua_state|
        LibLuaJIT.lua_gc(%lua_state, LibLuaJIT::LUA_GCCOLLECT, 0)
        0
      end
    end

    private macro push_fn__count
      @state.push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %state.push(LibLuaJIT.lua_gc(%state, LibLuaJIT::LUA_GCCOUNT, 0))
        1
      end
    end

    private macro push_fn__count_bytes
      @state.push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %state.push(LibLuaJIT.lua_gc(%state, LibLuaJIT::LUA_GCCOUNTB, 0))
        1
      end
    end

    private macro push_fn__step
      @state.push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %step_size = %state.to_i(-1)
        %state.pop(1)
        %state.push(LibLuaJIT.lua_gc(%state, LibLuaJIT::LUA_GCSTEP, %step_size))
        1
      end
    end

    private macro push_fn__set_pause
      @state.push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %data = %state.to_i(-1)
        %state.pop(1)
        %state.push(LibLuaJIT.lua_gc(%state, LibLuaJIT::LUA_GCSETPAUSE, %data))
        1
      end
    end

    private macro push_fn__set_step_multiplier
      @state.push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %data = %state.to_i(-1)
        %state.pop(1)
        %state.push(LibLuaJIT.lua_gc(%state, LibLuaJIT::LUA_GCSETSTEPMUL, %data))
        1
      end
    end
  end
end
