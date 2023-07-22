module Luajit
  class VM
    include Base

    # `ptr : Pointer(Void), old_size : UInt64, new_size : UInt64 -> Pointer(Void)`
    alias Allocator = Pointer(Void), UInt64, UInt64 -> Pointer(Void)

    # :nodoc:
    @box : Pointer(Void)

    # :nodoc:
    @ptr : Pointer(LibLuaJIT::State)

    # Allocates from custom allocator
    def self.alloc(&block : Allocator) : VM
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Alloc.new do |ud, ptr, osize, nsize|
        Box(typeof(block)).unbox(ud).call(ptr, osize, nsize)
      end
      new(LibLuaJIT.lua_newstate(proc, box), box)
    end

    # Allocates from default LuaJIT allocator
    def self.default : VM
      new(LibLuaJIT.luaL_newstate, Pointer(Void).null)
    end

    # Allocates from Crystal GC
    def self.new : VM
      alloc do |ptr, _osize, nsize|
        if nsize == 0
          GC.free(ptr)
          Pointer(Void).null
        else
          GC.realloc(ptr, nsize)
        end
      end
    end

    private def initialize(@ptr, @box)
    end

    def to_unsafe
      @ptr
    end

    # :nodoc:
    def finalize
      LibLuaJIT.lua_close(self)
    end

    def open_libs : Nil
      LibLuaJIT.luaL_openlibs(self)
    end

    def execute(code : String) : Nil
      if (r = LibLuaJIT.luaL_loadstring(self, code)) != 0
        raise "Error(#{r}): Failed to load code into VM"
      end
      case LibLuaJIT.lua_pcall(self, 0, LibLuaJIT::LUA_MULTRET, 0)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end

    def execute(path : Path) : Nil
      if (r = LibLuaJIT.luaL_loadfile(self, path.to_s)) != 0
        raise "Error(#{r}): Failed to load file into VM"
      end
      case LibLuaJIT.lua_pcall(self, 0, LibLuaJIT::LUA_MULTRET, 0)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end

    def to_coroutine(index : Int32) : Coroutine
      Coroutine.new(LibLuaJIT.lua_tothread(self, index))
    end

    def gc(what : LuaGC, data : Int32) : Int32
      case what
      in .stop?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTOP, data)
      in .restart?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCRESTART, data)
      in .collect?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOLLECT, data)
      in .count?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNT, data)
      in .count_bytes?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNTB, data)
      in .step?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTEP, data)
      in .set_pause?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETPAUSE, data)
      in .set_step_multiplier?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETSTEPMUL, data)
      end
    end
  end
end
