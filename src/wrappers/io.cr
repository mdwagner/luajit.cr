require "../luajit"

class Luajit::Wrappers::IO < Luajit::LuaObject
  global_name "IO"
  metatable_name "__IO__"

  def self.setup(state : Luajit::LuaState) : Nil
    Luajit.create_lua_object(state, self)
  end
end
