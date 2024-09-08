require "../../luajit"

class Luajit::Wrappers::IO < Luajit::LuaObject
  global_name "__IO__"

  property io : ::IO

  def initialize(@io)
  end
end
