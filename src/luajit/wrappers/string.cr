require "../../luajit"

class Luajit::Wrappers::String < Luajit::LuaObject
  global_name "__STRING__"

  # ---@field split fun(str: string, sep: string): string[]
  def_class_method "split" do |state|
    state.assert_string!(1)
    state.assert_string!(2)

    str = state.to_string(1)
    sep = state.to_string(2)

    state.push str.split(sep)
    1
  end

  property str : ::String

  def initialize(@str)
  end
end
