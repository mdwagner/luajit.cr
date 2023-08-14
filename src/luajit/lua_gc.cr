module Luajit
  # Controls the Lua Garbage Collector
  struct LuaGC
    @ptr : Pointer(LibLuaJIT::State)

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    # Stops the garbage collector
    def stop : Nil
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTOP, 0)
    end

    # Restarts the garbage collector
    def restart : Nil
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCRESTART, 0)
    end

    # Performs a full garbage-collection cycle
    def collect : Nil
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOLLECT, 0)
    end

    # Returns the current amount of memory (in KBs) in use by Lua
    def count : Int32
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNT, 0)
    end

    # Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024
    def count_bytes : Int32
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNTB, 0)
    end

    # Performs an incremental step of garbage collection
    #
    # To control the step size, you must experimentally tune
    # the value of _size_.
    #
    # Returns 1 if the step finished a garbage-collection cycle.
    def step(size : Int32) : Int32
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTEP, size)
    end

    # Sets data as the new value for the pause of the collector
    #
    # Returns the previous value of the pause.
    def set_pause(data : Int32) : Int32
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETPAUSE, data)
    end

    # Sets data as the new value for the step multiplier of the collector
    #
    # Returns the previous value of the step multiplier.
    def set_step_multiplier(data : Int32) : Int32
      LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETSTEPMUL, data)
    end
  end
end
