module Luajit::AccessFunctions
  # lua_isnumber
  # [-0, +0, -]
  def is_number?(index : Int32) : Bool
    LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
  end

  # lua_isstring
  # [-0, +0, -]
  def is_string?(index : Int32) : Bool
    LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
  end

  # lua_iscfunction
  # [-0, +0, -]
  def is_c_function?(index : Int32) : Bool
    LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
  end

  # lua_isuserdata
  # [-0, +0, -]
  def is_userdata?(index : Int32) : Bool
    LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
  end

  # lua_type
  # [-0, +0, -]
  def get_type(index : Int32) : LuaType
    LuaType.new(LibLuaJIT.lua_type(self, index))
  end

  # lua_typename
  # [-0, +0, -]
  def type_name(lua_type : LuaType) : String
    String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
  end

  # :nodoc:
  LUA_EQUAL_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    index1 = -2
    index2 = -1
    state.push(LibLuaJIT.lua_equal(state, index1, index2) == true.to_unsafe)
    1
  end

  # lua_equal
  # [-0, +0, e]
  def eq(index1 : Int32, index2 : Int32) : Bool
    LibxLuaJIT.lua_pushcfunction(self, LUA_EQUAL_PROC)
    push_value(index1)
    push_value(index2)
    status = pcall(2, 1)
    unless status.ok?
      raise LuaAPIError.new
    end
    to_boolean(-1).tap do
      pop(1)
    end
  end

  # lua_rawequal
  # [-0, +0, -]
  def raw_eq(index1 : Int32, index2 : Int32) : Bool
    LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
  end

  # :nodoc:
  LUA_LESSTHAN_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    index1 = -2
    index2 = -1
    state.push(LibLuaJIT.lua_lessthan(state, index1, index2) == true.to_unsafe)
    1
  end

  # lua_lessthan
  # [-0, +0, e]
  def less_than(index1 : Int32, index2 : Int32) : Bool
    LibxLuaJIT.lua_pushcfunction(self, LUA_LESSTHAN_PROC)
    push_value(index1)
    push_value(index2)
    status = pcall(2, 1)
    unless status.ok?
      raise LuaAPIError.new
    end
    to_boolean(-1).tap do
      pop(1)
    end
  end

  # lua_tonumber
  # [-0, +0, -]
  def to_f64(index : Int32) : Float64
    LibLuaJIT.lua_tonumber(self, index)
  end

  # lua_tointeger
  # [-0, +0, -]
  def to_i64(index : Int32) : Int64
    LibLuaJIT.lua_tointeger(self, index)
  end

  # lua_toboolean
  # [-0, +0, -]
  def to_boolean(index : Int32) : Bool
    LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
  end

  # lua_tolstring
  # [-0, +0, m]
  def to_string(index : Int32, size : UInt64) : String
    String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
  end

  # lua_objlen
  # [-0, +0, -]
  def size_at(index : Int32) : UInt64
    LibLuaJIT.lua_objlen(self, index)
  end

  # lua_tocfunction
  # [-0, +0, -]
  def to_c_function?(index : Int32) : CFunction?
    proc = LibLuaJIT.lua_tocfunction(self, index)
    if proc.pointer
      proc
    end
  end

  # lua_touserdata
  # [-0, +0, -]
  def to_userdata?(index : Int32) : Pointer(Void)?
    if ptr = LibLuaJIT.lua_touserdata(self, index)
      ptr
    end
  end

  # lua_tothread
  # [-0, +0, -]
  def to_thread?(index : Int32) : LuaState?
    if ptr = LibLuaJIT.lua_tothread(self, index)
      LuaState.new(ptr)
    end
  end

  # lua_topointer
  # [-0, +0, -]
  def to_pointer?(index : Int32) : Pointer(Void)?
    if ptr = LibLuaJIT.lua_topointer(self, index)
      ptr
    end
  end
end
