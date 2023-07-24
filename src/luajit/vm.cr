module Luajit
  class VM
    # `ptr : Pointer(Void), old_size : UInt64, new_size : UInt64 -> Pointer(Void)`
    alias Allocator = Pointer(Void), UInt64, UInt64 -> Pointer(Void)

    getter state : LuaState

    # :nodoc:
    @box : Pointer(Void)

    # Allocates from custom allocator
    def self.alloc(&block : Allocator) : VM
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Alloc.new do |ud, ptr, osize, nsize|
        Box(typeof(block)).unbox(ud).call(ptr, osize, nsize)
      end
      state = LuaState.new(LibLuaJIT.lua_newstate(proc, box))
      new(state, box)
    end

    # Allocates from default LuaJIT allocator
    def self.default : VM
      state = LuaState.new(LibLuaJIT.luaL_newstate)
      box = Pointer(Void).null
      new(state, box)
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

    private def initialize(@state, @box)
    end

    def to_unsafe
      @state.to_unsafe
    end

    def finalize
      LibLuaJIT.lua_close(self)
    end

    def open_library(type : LuaLibrary) : Nil
      case type
      in .base?
        LibLuaJIT.luaopen_base(self)
      in .table?
        LibLuaJIT.luaopen_table(self)
      in .io?
        LibLuaJIT.luaopen_io(self)
      in .os?
        LibLuaJIT.luaopen_os(self)
      in .string?
        LibLuaJIT.luaopen_string(self)
      in .math?
        LibLuaJIT.luaopen_math(self)
      in .debug?
        LibLuaJIT.luaopen_debug(self)
      in .package?
        LibLuaJIT.luaopen_package(self)
      in .bit?
        LibLuaJIT.luaopen_bit(self)
      in .ffi?
        LibLuaJIT.luaopen_ffi(self)
      in .jit?
        LibLuaJIT.luaopen_jit(self)
      in .all?
        LibLuaJIT.luaL_openlibs(self)
      end
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
