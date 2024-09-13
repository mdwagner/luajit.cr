require "../luajit"

class Luajit::Wrappers::String < Luajit::LuaObject
  global_name "String"
  metatable_name "__STRING__"

  # ---@field split fun(str: string, sep: string): string[]
  def_class_method "split" do |state|
    state.assert_string!(1)
    state.assert_string!(2)

    str = state.to_string(1)
    sep = state.to_string(2)

    state.push str.split(sep)
    1
  end

  def self.setup(state : Luajit::LuaState) : Nil
    Luajit.create_lua_object(state, self)
  end
end
