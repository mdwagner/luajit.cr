require "./luajit/version"
require "./luajit/*"

module Luajit
  alias Alloc = LibLuaJIT::Alloc

  # Collection of pointers to track within Crystal to avoid GC
  TRACKABLES = [] of Pointer(Void)

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

  # Adds a pointer to be tracked
  def self.add_trackable(ptr : Pointer(Void)) : Nil
    TRACKABLES << ptr
  end

  # Removes a reference pointer from being tracked
  def self.remove_trackable(ref : Reference) : Nil
    TRACKABLES.reject! do |ptr|
      ptr.address == ref.object_id
    end
  end

  # Removes a pointer from being tracked
  def self.remove_trackable(ptr_to_remove : Pointer(Void)) : Nil
    TRACKABLES.reject! { |ptr| ptr == ptr_to_remove }
  end

  # Removes all reference pointers from being tracked
  #
  # WARNING: Only do this when no other LuaState objects exist!
  def self.clear_trackables : Nil
    TRACKABLES.clear
  end
end
