require "./luajit/version"
require "./luajit/*"

# https://lua-users.org/wiki/ErrorHandlingBetweenLuaAndCplusplus
module Luajit
  # LuaState (pointer address) => tracked pointers used within LuaState
  #
  # Used to avoid garbage collecting in-use pointers inside LuaState
  TRACKABLES = Hash(String, Array(Pointer(Void))).new

  def self.new : LuaState
    LuaState.new_state
  end

  def self.close(state : LuaState) : Nil
    clear_trackables(LuaState.pointer_address(state))
    state.close
  end

  def self.run(& : LuaState ->) : Nil
    state = new
    begin
      state.open_library(:all)
      yield state
    ensure
      close(state)
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
