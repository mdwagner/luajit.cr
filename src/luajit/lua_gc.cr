module Luajit
  # Controls the Lua Garbage Collector
  struct LuaGC
    @state : LuaState

    protected def initialize(@state)
    end

    # Stops the garbage collector
    def stop! : Nil
      @state.push_fn do |l|
        LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCSTOP, 0)
        0
      end
      @state.pcall(0, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#stop!")
        end
      end
    end

    # Restarts the garbage collector
    def restart! : Nil
      @state.push_fn do |l|
        LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCRESTART, 0)
        0
      end
      @state.pcall(0, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#restart!")
        end
      end
    end

    # Performs a full garbage-collection cycle
    def collect! : Nil
      @state.push_fn do |l|
        LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCCOLLECT, 0)
        0
      end
      @state.pcall(0, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#collect!")
        end
      end
    end

    # Returns the current amount of memory (in KBs) in use by Lua
    def count! : Int32
      @state.push_fn do |l|
        state = LuaState.new(l)
        state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCCOUNT, 0))
        1
      end
      @state.pcall(0, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#count!")
        end
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024
    def count_bytes! : Int32
      @state.push_fn do |l|
        state = LuaState.new(l)
        state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCCOUNTB, 0))
        1
      end
      @state.pcall(0, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#count_bytes!")
        end
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
    def step!(size : Int32) : Int32
      @state.push_fn do |l|
        state = LuaState.new(l)
        step_size = state.to_i(-1)
        state.pop(1)
        state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSTEP, step_size))
        1
      end
      @state.push(size)
      @state.pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#step!")
        end
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Sets data as the new value for the pause of the collector
    #
    # Returns the previous value of the pause.
    def set_pause!(data : Int32) : Int32
      @state.push_fn do |l|
        state = LuaState.new(l)
        d = state.to_i(-1)
        state.pop(1)
        state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSETPAUSE, d))
        1
      end
      @state.push(data)
      @state.pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#set_pause!")
        end
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # Sets data as the new value for the step multiplier of the collector
    #
    # Returns the previous value of the step multiplier.
    def set_step_multiplier!(data : Int32) : Int32
      @state.push_fn do |l|
        state = LuaState.new(l)
        d = state.to_i(-1)
        state.pop(1)
        state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSETSTEPMUL, d))
        1
      end
      @state.push(data)
      @state.pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(@state, status, "LuaGC#set_step_multiplier!")
        end
      end
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end
  end
end
