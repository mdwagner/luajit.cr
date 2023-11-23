module Luajit
  record LuaRef, ref : Int32, type : LuaType do
    def inspect(io : IO) : Nil
      io << "LuaRef(" << type.to_s << ")[" << ref << "]"
    end

    def to_s(io : IO) : Nil
      io << ref
    end
  end
end
