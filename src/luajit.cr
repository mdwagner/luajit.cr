require "./luajit/version"
require "./luajit/trackable"
require "./luajit/*"

module Luajit
  alias Alloc = LibLuaJIT::Alloc

  # Allocates from default LuaJIT allocator
  def self.new_lua_state : LuaState
    LuaState.new(LibLuaJIT.luaL_newstate)
  end

  # Allocates from Crystal GC (recommended)
  def self.new_state : LuaState
    proc = Alloc.new do |_, ptr, osize, nsize|
      if nsize == 0
        GC.free(ptr)
        Pointer(Void).null
      else
        GC.realloc(ptr, nsize)
      end
    end
    LuaState.new(LibLuaJIT.lua_newstate(proc, nil))
  end

  def self.run(&block : LuaState ->) : Nil
    state = new_state
    begin
      state.open_library(:all)
      status = state.c_pcall do |s|
        block.call(s)
        0
      end
      case status
      when .ok?, .yield?
        # pass
      when .runtime_error?
        raise LuaRuntimeError.new
      when .memory_error?
        raise LuaMemoryError.new
      when .handler_error?
        raise LuaHandlerError.new
      else
        raise LuaError.new(state)
      end
    ensure
      state.close
    end
  end
end
