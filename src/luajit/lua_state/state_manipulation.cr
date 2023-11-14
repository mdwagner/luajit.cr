module Luajit::StateManipulation
  # lua_close
  # [-0, +0, -]
  def close : Nil
    LibLuaJIT.lua_close(self)
  end

  # lua_newthread
  # [-0, +1, m]
  def new_thread : LuaState
    LuaState.new(LibLuaJIT.lua_newthread(self))
  end

  # lua_atpanic
  # [-0, +0, -]
  def at_panic(&cb : CFunction) : CFunction
    LibLuaJIT.lua_atpanic(self, cb)
  end
end
