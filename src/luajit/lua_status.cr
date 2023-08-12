module Luajit
  enum LuaStatus
    Ok           = LibLuaJIT::LUA_OK
    Yield        = LibLuaJIT::LUA_YIELD
    RuntimeError = LibLuaJIT::LUA_ERRRUN
    SyntaxError  = LibLuaJIT::LUA_ERRSYNTAX
    MemoryError  = LibLuaJIT::LUA_ERRMEM
    HandlerError = LibLuaJIT::LUA_ERRERR
    FileError    = LibLuaJIT::LUA_ERRFILE
  end
end
