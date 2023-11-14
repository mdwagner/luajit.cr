module Luajit::BasicStackManipulation
  # lua_gettop
  # [-0, +0, -]
  def size : Int32
    LibLuaJIT.lua_gettop(self)
  end

  # lua_settop
  # [-?, +?, -]
  def set_top(index : Int32) : Nil
    LibLuaJIT.lua_settop(self, index)
  end

  # lua_pushvalue
  # [-0, +1, -]
  def push_value(index : Int32) : Nil
    LibLuaJIT.lua_pushvalue(self, index)
  end

  # lua_remove
  # [-1, +0, -]
  def remove(index : Int32) : Nil
    LibLuaJIT.lua_remove(self, index)
  end

  # lua_insert
  # [-1, +1, -]
  def insert(index : Int32) : Nil
    LibLuaJIT.lua_insert(self, index)
  end

  # lua_replace
  # [-1, +0, -]
  def replace(index : Int32) : Nil
    LibLuaJIT.lua_replace(self, index)
  end

  # lua_xmove
  # [-?, +?, -]
  def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
    LibLuaJIT.lua_xmove(from, to, n)
  end
end
