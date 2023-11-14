module Luajit::OtherFunctions
  # :nodoc:
  LUA_NEXT_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    result = LibLuaJIT.lua_next(state, -2)
    if result != 0
      state.push(true)
    else
      state.push(nil)
      state.push(nil)
      state.push(false)
    end
    3
  end

  # lua_next
  # [-1, +(2|0), e]
  def next(index : Int32) : Bool
    push_value(index)
    insert(-2)
    LibxLuaJIT.lua_pushcfunction(self, LUA_NEXT_PROC)
    insert(-3)
    status = pcall(2, 3)
    unless status.ok?
      raise LuaAPIError.new
    end
    to_boolean(-1).tap do |result|
      pop(1)
      pop(2) unless result
    end
  end

  # :nodoc:
  LUA_CONCAT_PROC = CFunction.new do |l|
    state = LuaState.new(l)
    n = state.size
    LibLuaJIT.lua_concat(state, n)
    1
  end

  # lua_concat
  # [-n, +1, e]
  def concat(n : Int32) : Nil
    if n < 1
      return push("")
    elsif n == 1
      return
    end

    LibxLuaJIT.lua_pushcfunction(self, LUA_CONCAT_PROC)
    insert(-(n) - 1)
    status = pcall(n, 1)
    unless status.ok?
      raise LuaAPIError.new
    end
  end
end
