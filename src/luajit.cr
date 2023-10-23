require "./luajit/version"
require "./luajit/*"

module Luajit
  # LuaState (pointer address) => tracked pointers used within LuaState
  #
  # Used to avoid garbage collecting in-use pointers inside LuaState
  TRACKABLES = Hash(String, Array(Pointer(Void))).new

  def self.new_state : LuaState
    LuaState.new(LibLuaJIT.luaL_newstate).tap do |state|
      LuaState.set_registry_address(state)
      state.at_panic do |l|
        s = LuaState.new(l)
        if msg = s.is_string?(-1)
          STDERR.puts msg
        end
        0
      end
    end
  end

  def self.new_state_with_cleanup : Tuple(LuaState, Proc(Nil))
    state = new_state
    state_address = LuaState.pointer_address(state)
    proc = -> {
      clear_trackables(state_address)
      state.close
    }
    {state, proc}
  end

  def self.run(&block : LuaState ->) : Nil
    state = new_state
    state_address = LuaState.pointer_address(state)
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
      when .syntax_error?
        raise LuaSyntaxError.new
      when .file_error?
        raise LuaFileError.new
      else
        raise LuaError.new(state)
      end
    ensure
      clear_trackables(state_address)
      state.close
    end
  end

  # Adds a pointer to be tracked
  def self.add_trackable(key : String, ptr : Pointer(Void)) : Nil
    if ptrs = TRACKABLES[key]?
      ptrs << ptr
    else
      TRACKABLES[key] = [] of Pointer(Void)
      TRACKABLES[key] << ptr
    end
  end

  # Removes a reference pointer from being tracked
  def self.remove_trackable(key : String, ref : Reference) : Nil
    if ptrs = TRACKABLES[key]?
      ptrs.reject! do |ptr|
        ptr.address == ref.object_id
      end
    end
  end

  # Removes a pointer from being tracked
  def self.remove_trackable(key : String, ptr_to_remove : Pointer(Void)) : Nil
    if ptrs = TRACKABLES[key]?
      ptrs.reject! { |ptr| ptr == ptr_to_remove }
    end
  end

  # Removes all reference pointers from being tracked
  #
  # WARNING: Only do this when no other LuaState objects exist!
  #
  # DEPRECATED: No longer needed since...and should use `#clear_trackables(String)` instead
  def self.clear_trackables : Nil
    TRACKABLES.clear
  end

  # Removes all reference pointers from being tracked by key
  def self.clear_trackables(key : String) : Nil
    TRACKABLES.delete(key)
  end
end
