require "./luajit/version"
require "./luajit/*"

include Luajit

enum LuaType
  None          = -1
  Null          =  0
  Boolean
  LightUserdata
  Number
  String
  Table
  Function
  Userdata
  Thread
end

def lua_pop(l, n)
  LibLuajit.lua_settop(l, -(n) - 1)
end

def lua_newtable(l)
  LibLuajit.lua_createtable(l, 0, 0)
end

def lua_setglobal(l, name)
  LibLuajit.lua_setfield(l, LibLuajit::LUA_GLOBALSINDEX, name)
end

def lua_getglobal(l, name)
  LibLuajit.lua_getfield(l, LibLuajit::LUA_GLOBALSINDEX, name)
end

def lua_pushcfunction(l, f)
  LibLuajit.lua_pushcclosure(l, f, 0)
end

def lua_strlen(l, i)
  LibLuajit.lua_objlen(l, i)
end

def lua_register(l, name, f)
  lua_pushcfunction(l, f)
  lua_setglobal(l, name)
end

def lua_tostring(l, i)
  LibLuajit.lua_tolstring(l, i, nil)
end

def lua_pushliteral(l, s)
  LibLuajit.lua_pushlstring(l, s, s.size)
end

def lua_open
  LibLuajit.luaL_newstate
end

def lua_getregistry(l)
  LibLuajit.lua_pushvalue(l, LibLuajit::LUA_REGISTRYINDEX)
end

def lua_getgccount(l)
  LibLuajit.lua_gc(l, LibLuajit::LUA_GCCOUNT, 0)
end

def lua_type(l, n)
  LuaType.from_value(LibLuajit.lua_type(l, n))
end

def luaL_dostring(l, str)
  r = LibLuajit.luaL_loadstring(l, str)
  return LibLuajit.lua_pcall(l, 0, LibLuajit::LUA_MULTRET, 0) if r == 0
  r
end

l = LibLuajit.luaL_newstate
LibLuajit.luaL_openlibs(l)

lua_register(l, "basicCFunc", ->(state : LibLuajit::State*) : Int32 {
  puts "This is my c function called from lua"
  0
})

luaL_dostring(l, <<-LUA)
print("hello from lua")
basicCFunc()
LUA

LibLuajit.lua_close(l)
