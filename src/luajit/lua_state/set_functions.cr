module Luajit::SetFunctions
  # :nodoc:
  LUA_SETTABLE_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    LibLuaJIT.lua_settable(state, -3)
    0
  end

  # lua_settable
  # [-2, +0, e]
  def set_table(index : Int32) : Nil
    push_value(index)
    insert(-3)
    LibxLuaJIT.lua_pushcfunction(self, LUA_SETTABLE_PROC)
    insert(-4)
    status = pcall(3, 0)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # :nodoc:
  LUA_SETFIELD_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    key = state.to_string(-1)
    state.pop(1)
    LibLuaJIT.lua_setfield(state, -2, key)
    0
  end

  # lua_setfield
  # [-1, +0, e]
  def set_field(index : Int32, k : String) : Nil
    case index
    when LibLuaJIT::LUA_GLOBALSINDEX
      return set_global(k)
    when LibLuaJIT::LUA_REGISTRYINDEX
      return set_registry(k)
    when LibLuaJIT::LUA_ENVIRONINDEX
      return set_environment(k)
    end

    push_value(index)
    insert(-2)
    LibxLuaJIT.lua_pushcfunction(self, LUA_SETFIELD_PROC)
    insert(-3)
    push(k)
    status = pcall(3, 0)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # :nodoc:
  LUA_SETGLOBAL_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    key = state.to_string(-1)
    state.pop(1)
    LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_GLOBALSINDEX, key)
    0
  end

  # lua_setglobal
  # [-1, +0, e]
  def set_global(name : String) : Nil
    LibxLuaJIT.lua_pushcfunction(self, LUA_SETGLOBAL_PROC)
    insert(-2)
    push(name)
    status = pcall(2, 0)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # :nodoc:
  LUA_SETREGISTRY_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    key = state.to_string(-1)
    state.pop(1)
    LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_REGISTRYINDEX, key)
    0
  end

  # [-1, +0, e]
  def set_registry(name : String) : Nil
    LibxLuaJIT.lua_pushcfunction(self, LUA_SETREGISTRY_PROC)
    insert(-2)
    push(name)
    status = pcall(2, 0)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # :nodoc:
  LUA_SETENVIRONMENT_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    key = state.to_string(-1)
    state.pop(1)
    LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_ENVIRONINDEX, key)
    0
  end

  # [-1, +0, e]
  def set_environment(name : String) : Nil
    LibxLuaJIT.lua_pushcfunction(self, LUA_SETENVIRONMENT_PROC)
    insert(-2)
    push(name)
    status = pcall(2, 0)
    unless status.ok?
      raise LuaAPIError.new
    end
  end

  # lua_rawset
  # [-2, +0, m]
  def raw_set(index : Int32) : Nil
    LibLuaJIT.lua_rawset(self, index)
  end

  # lua_rawseti
  # [-1, +0, m]
  def raw_set_index(index : Int32, n : Int32) : Nil
    LibLuaJIT.lua_rawseti(self, index, n)
  end

  # lua_setmetatable
  # [-1, +0, -]
  def set_metatable(index : Int32) : Int32
    LibLuaJIT.lua_setmetatable(self, index)
  end

  # lua_setfenv
  # [-1, +0, -]
  def set_fenv(index : Int32) : Int32
    LibLuaJIT.lua_setfenv(self, index)
  end
end
