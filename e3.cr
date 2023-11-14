require "./src/luajit/lib_luajit"
include Luajit

state = LibLuaJIT.luaL_newstate

def debug_stack(l)
  count = -1
  size = LibLuaJIT.lua_gettop(l)
  size.downto(1) do |index|
    puts "(#{count}) [#{index}]: #{String.new(LibLuaJIT.lua_typename(l, LibLuaJIT.lua_type(l, index)) || Bytes[])}"
    count -= 1
  end
end

proc = LibLuaJIT::CFunction.new do |l|
  LibLuaJIT.lua_settop(l, -(1) - 1) # pop userdata

  #puts LibLuaJIT.lua_gettop(l)
  #puts String.new(LibLuaJIT.lua_typename(l, LibLuaJIT.lua_type(l, 1)) || Bytes[])

  #LibLuaJIT.lua_pushnumber(l, 1.0) # 1
  #LibLuaJIT.lua_pushnumber(l, 2.0) # 2
  #LibLuaJIT.lua_pushboolean(l, true) # 3

  #debug_stack(l)
  #puts

  #LibLuaJIT.lua_insert(l, 1)

  #debug_stack(l)
  #puts

  LibLuaJIT.lua_gettable(l, LibLuaJIT::LUA_GLOBALSINDEX)

  debug_stack(l)

  0
end
status = LibLuaJIT.lua_cpcall(state, proc, nil)
pp! status

at_exit { LibLuaJIT.lua_close(state) }
