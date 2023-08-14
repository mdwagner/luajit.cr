module Luajit
  enum LuaType
    None          = LibLuaJIT::LUA_TNONE
    Nil           = LibLuaJIT::LUA_TNIL
    Boolean       = LibLuaJIT::LUA_TBOOLEAN
    LightUserdata = LibLuaJIT::LUA_TLIGHTUSERDATA
    Number        = LibLuaJIT::LUA_TNUMBER
    String        = LibLuaJIT::LUA_TSTRING
    Table         = LibLuaJIT::LUA_TTABLE
    Function      = LibLuaJIT::LUA_TFUNCTION
    Userdata      = LibLuaJIT::LUA_TUSERDATA
    Thread        = LibLuaJIT::LUA_TTHREAD
  end
end
