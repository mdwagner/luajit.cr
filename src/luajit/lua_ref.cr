module Luajit
  record LuaRef, ref : Int32, type : LuaType do
    def pcall(state : LuaState, nargs : Int32, nresults : Int32) : LuaStatus
      raise LuaError.new("Ref is not a function") unless type.function?
      state.get_ref_value(ref)
      state.insert(-(nargs + 1)) if nargs > 0
      state.pcall(nargs, nresults)
    end

    def inspect(io : IO) : Nil
      io << "LuaRef(@type=#{type.to_s}, @ref=#{ref})"
    end

    def to_s(io : IO) : Nil
      io << ref
    end
  end
end
