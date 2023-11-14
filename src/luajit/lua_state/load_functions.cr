module Luajit::LoadFunctions
  # lua_pcall
  # [-(nargs + 1), +(nresults|1), -]
  def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
    LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
  end

  # lua_cpcall
  # [-0, +(0|1), -]
  def c_pcall(&block : Function) : LuaStatus
    box = Box(typeof(block)).box(block)
    proc = CFunction.new do |l|
      state = LuaState.new(l)
      ud = state.to_userdata(-1)
      state.remove(-1)
      begin
        Box(typeof(block)).unbox(ud).call(state)
      rescue err
        state.raise_error(err.to_s)
        0
      end
    end
    LuaStatus.new(LibLuaJIT.lua_cpcall(self, proc, box))
  end

  # lua_load
  # [-0, +1, -]
  def load(chunk_name : String, &block : Loader) : LuaStatus
    box = Box(typeof(block)).box(block)
    proc = LibLuaJIT::Reader.new do |l, data, size|
      state = LuaState.new(l)
      Box(typeof(block)).unbox(data).call(state, size)
    end
    result = LuaStatus.new(LibLuaJIT.lua_load(self, proc, box, chunk_name))
    LuaError.check!(self, result)
    result
  end

  # lua_dump
  # [-0, +0, m]
  def dump(&block : Unloader) : Int32
    box = Box(typeof(block)).box(block)
    proc = LibLuaJIT::Writer.new do |l, ptr, size, ud|
      state = LuaState.new(l)
      Box(typeof(block)).unbox(ud).call(state, ptr, size)
    end
    LibLuaJIT.lua_dump(self, proc, box)
  end
end
