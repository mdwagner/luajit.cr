module Luajit::DebuggerFunctions
  # lua_getstack
  # [-0, +0, -]
  def get_stack(level : Int32) : Tuple(Bool, LibLuaJIT::Debug)
    result = LibLuaJIT.lua_getstack(self, level, out ar)
    {result == true.to_unsafe, ar}
  end

  # lua_getinfo
  # [-(0|1), +(0|1|2), m]
  def get_info(what : String, ar : LibLuaJIT::Debug) : Tuple(Bool, LibLuaJIT::Debug)
    result = LibLuaJIT.lua_getinfo(self, what, pointerof(ar))
    {result != 0, ar}
  end

  # lua_getlocal
  # [-0, +(0|1), -]
  def get_local(ar : LibLuaJIT::Debug, n : Int32 = 1) : String?
    if ptr = LibLuaJIT.lua_getlocal(self, pointerof(ar), n)
      String.new(ptr)
    end
  end

  # lua_setlocal
  # [-(0|1), +0, -]
  def set_local(ar : LibLuaJIT::Debug, n : Int32 = 1) : String?
    if ptr = LibLuaJIT.lua_setlocal(self, pointerof(ar), n)
      String.new(ptr)
    end
  end

  # lua_getupvalue
  # [-0, +(0|1), -]
  def get_up_value(fn_index : Int32, n : Int32) : String?
    if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
      String.new(ptr)
    end
  end

  # lua_setupvalue
  # [-(0|1), +0, -]
  def set_up_value(fn_index : Int32, n : Int32) : String?
    if ptr = LibLuaJIT.lua_setupvalue(self, fn_index, n)
      String.new(ptr)
    end
  end

  # lua_sethook
  # [-0, +0, -]
  def set_hook(f : LibLuaJIT::Hook, mask : Int32, count : Int32) : Nil
    LibLuaJIT.lua_sethook(self, f, mask, count)
  end

  # lua_gethook
  # [-0, +0, -]
  def get_hook : LibLuaJIT::Hook
    LibLuaJIT.lua_gethook(self)
  end

  # lua_gethookmask
  # [-0, +0, -]
  def get_hook_mask : Int32
    LibLuaJIT.lua_gethookmask(self)
  end

  # lua_gethookcount
  # [-0, +0, -]
  def get_hook_count : Int32
    LibLuaJIT.lua_gethookcount(self)
  end
end
