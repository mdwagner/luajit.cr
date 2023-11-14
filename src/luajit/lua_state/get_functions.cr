module Luajit::GetFunctions
  # :nodoc:
  LUA_GETTABLE_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    index = state.to_i(-1)
    LibLuaJIT.lua_gettable(state, index)
    1
  end

  # lua_gettable
  # [-1, +1, e]
  def get_table(index : Int32) : Nil
    LibxLuaJIT.lua_pushcfunction(self, LUA_GETTABLE_PROC)
    push(index)
    status = pcall(1, 1)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # :nodoc:
  LUA_GETFIELD_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    index = state.to_i(-2)
    name = state.to_string(-1)
    LibLuaJIT.lua_getfield(state, index, name)
    1
  end

  # lua_getfield
  # [-0, +1, e]
  def get_field(index : Int32, name : String)
    LibxLuaJIT.lua_pushcfunction(self, LUA_GETFIELD_PROC)
    push(index)
    push(name)
    status = pcall(2, 1)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # lua_rawget
  # [-1, +1, -]
  def raw_get(index : Int32) : Nil
    LibLuaJIT.lua_rawget(self, index)
  end

  # lua_rawgeti
  # [-0, +1, -]
  def raw_get_index(index : Int32, n : Int32) : Nil
    LibLuaJIT.lua_rawgeti(self, index, n)
  end

  # lua_createtable
  # [-0, +1, m]
  def create_table(narr : Int32, nrec : Int32) : Nil
    LibLuaJIT.lua_createtable(self, narr, nrec)
  end

  # lua_newuserdata
  # [-0, +1, m]
  def new_userdata(size : UInt64) : Pointer(Void)
    LibLuaJIT.lua_newuserdata(self, size)
  end

  # lua_getmetatable
  # [-0, +(0|1), -]
  def get_metatable(index : Int32) : Bool
    LibLuaJIT.lua_getmetatable(self, index) != 0
  end

  # lua_getfenv
  # [-0, +1, -]
  def get_fenv(index : Int32) : Nil
    LibLuaJIT.lua_getfenv(self, index)
  end
end
