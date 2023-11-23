module Luajit
  # Controls the Lua Garbage Collector
  struct LuaGC
    @state : LuaState

    def initialize(@state)
    end

    # :nodoc:
    LUA_GCSTOP_PROC = LibLuaJIT::CFunction.new do |l|
      LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCSTOP, 0)
      0
    end

    # Stops the garbage collector
    def stop : Nil
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCSTOP_PROC, 0)
      status = @state.pcall(0, 0)
      raise LuaProtectedError.new(@state, status, "LuaGC#stop") unless status.ok?
    end

    # :nodoc:
    LUA_GCRESTART_PROC = LibLuaJIT::CFunction.new do |l|
      LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCRESTART, 0)
      0
    end

    # Restarts the garbage collector
    def restart : Nil
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCRESTART_PROC, 0)
      status = @state.pcall(0, 0)
      raise LuaProtectedError.new(@state, status, "LuaGC#restart") unless status.ok?
    end

    # :nodoc:
    LUA_GCCOLLECT_PROC = LibLuaJIT::CFunction.new do |l|
      LibLuaJIT.lua_gc(l, LibLuaJIT::LUA_GCCOLLECT, 0)
      0
    end

    # Performs a full garbage-collection cycle
    def collect : Nil
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCCOLLECT_PROC, 0)
      status = @state.pcall(0, 0)
      raise LuaProtectedError.new(@state, status, "LuaGC#collect") unless status.ok?
    end

    # :nodoc:
    LUA_GCCOUNT_PROC = LibLuaJIT::CFunction.new do |l|
      state = LuaState.new(l)
      state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCCOUNT, 0))
      1
    end

    # Returns the current amount of memory (in KBs) in use by Lua
    def count : Int32
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCCOUNT_PROC, 0)
      status = @state.pcall(0, 1)
      raise LuaProtectedError.new(@state, status, "LuaGC#count") unless status.ok?
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # :nodoc:
    LUA_GCCOUNTB_PROC = LibLuaJIT::CFunction.new do |l|
      state = LuaState.new(l)
      state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCCOUNTB, 0))
      1
    end

    # Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024
    def count_bytes : Int32
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCCOUNTB_PROC, 0)
      status = @state.pcall(0, 1)
      raise LuaProtectedError.new(@state, status, "LuaGC#count_bytes") unless status.ok?
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # :nodoc:
    LUA_GCSTEP_PROC = LibLuaJIT::CFunction.new do |l|
      state = LuaState.new(l)
      size = state.to_i(-1)
      state.pop(1)
      state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSTEP, size))
      1
    end

    # Performs an incremental step of garbage collection
    #
    # To control the step size, you must experimentally tune
    # the value of _size_.
    #
    # Returns 1 if the step finished a garbage-collection cycle.
    def step(size : Int32) : Int32
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCSTEP_PROC, 0)
      @state.push(size)
      status = @state.pcall(1, 1)
      raise LuaProtectedError.new(@state, status, "LuaGC#step") unless status.ok?
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # :nodoc:
    LUA_GCSETPAUSE_PROC = LibLuaJIT::CFunction.new do |l|
      state = LuaState.new(l)
      data = state.to_i(-1)
      state.pop(1)
      state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSETPAUSE, data))
      1
    end

    # Sets data as the new value for the pause of the collector
    #
    # Returns the previous value of the pause.
    def set_pause(data : Int32) : Int32
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCSETPAUSE_PROC, 0)
      @state.push(data)
      status = @state.pcall(1, 1)
      raise LuaProtectedError.new(@state, status, "LuaGC#set_pause") unless status.ok?
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end

    # :nodoc:
    LUA_GCSETSTEPMUL_PROC = LibLuaJIT::CFunction.new do |l|
      state = LuaState.new(l)
      data = state.to_i(-1)
      state.pop(1)
      state.push(LibLuaJIT.lua_gc(state, LibLuaJIT::LUA_GCSETSTEPMUL, data))
      1
    end

    # Sets data as the new value for the step multiplier of the collector
    #
    # Returns the previous value of the step multiplier.
    def set_step_multiplier(data : Int32) : Int32
      LibLuaJIT.lua_pushcclosure(@state, LUA_GCSETSTEPMUL_PROC, 0)
      @state.push(data)
      status = @state.pcall(1, 1)
      raise LuaProtectedError.new(@state, status, "LuaGC#set_step_multiplier") unless status.ok?
      @state.to_i(-1).tap do
        @state.pop(1)
      end
    end
  end
end
