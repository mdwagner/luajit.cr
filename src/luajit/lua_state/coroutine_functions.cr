module Luajit::CoroutineFunctions
  # lua_yield
  # [-?, +?, -]
  def co_yield(nresults : Int32) : Int32
    LibLuaJIT.lua_yield(self, nresults)
  end

  # lua_resume
  # [-?, +?, -]
  def co_resume(narg : Int32) : Int32
    LibLuaJIT.lua_resume(self, narg)
  end

  # lua_status
  # [-0, +0, -]
  def status : LuaStatus
    LuaStatus.new(LibLuaJIT.lua_status(self))
  end
end
