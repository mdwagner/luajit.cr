module Luajit::PushFunctions
  # lua_pushnil
  # [-0, +1, -]
  def push(_x : Nil) : Nil
    LibLuaJIT.lua_pushnil(self)
  end

  # lua_pushnumber
  # [-0, +1, -]
  def push(x : Float64) : Nil
    LibLuaJIT.lua_pushnumber(self, x)
  end

  # lua_pushinteger
  # [-0, +1, -]
  def push(x : Int64) : Nil
    LibLuaJIT.lua_pushinteger(self, x)
  end

  # lua_pushstring
  # [-0, +1, m]
  def push(x : String) : Nil
    LibLuaJIT.lua_pushstring(self, x)
  end

  # lua_pushcclosure
  # [-n, +1, m]
  def push(&block : Function) : Nil
    box = Box(typeof(block)).box(block)
    track(box)
    proc = CFunction.new do |l|
      state = LuaState.new(l)
      ud = state.to_userdata(state.upvalue_at(1))
      begin
        Box(typeof(block)).unbox(ud).call(state)
      rescue err
        state.raise_error(err.inspect)
        0
      end
    end
    push(box)
    LibLuaJIT.lua_pushcclosure(self, proc, 1)
  end

  # lua_pushboolean
  # [-0, +1, -]
  def push(x : Bool) : Nil
    LibLuaJIT.lua_pushboolean(self, x)
  end

  # lua_pushlightuserdata
  # [-0, +1, -]
  def push(x : Pointer(Void)) : Nil
    LibLuaJIT.lua_pushlightuserdata(self, x)
  end

  # lua_pushthread
  # [-0, +1, -]
  def push_thread(x : LuaState) : ThreadStatus
    if LibLuaJIT.lua_pushthread(x) == 1
      ThreadStatus::Main
    else
      ThreadStatus::Coroutine
    end
  end
end
