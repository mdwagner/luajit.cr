module Luajit
  record LuaRef, ref : Int32, type : LuaType do
    def inspect(io : IO) : Nil
      io << "LuaRef" << "("
      case type
      when .boolean?
        io << "Bool"
      when .number?
        io << "Number"
      when .string?
        io << "String"
      when .table?
        io << "Table"
      when .function?
        io << "Function"
      when .userdata?
        io << "Userdata"
      when .light_userdata?
        io << "LightUserdata"
      when .thread?
        io << "Thread"
      else
        io << "Nil"
      end
      io << ")[" << ref << "]"
    end

    def to_s(io : IO) : Nil
      io << ref
    end
  end
end
