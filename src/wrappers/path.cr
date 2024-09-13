require "../luajit"

class Luajit::Wrappers::Path < Luajit::LuaObject
  global_name "Path"
  metatable_name "__PATH__"

  # ---@field new fun(path: string?): self
  def_class_method "new" do |state|
    if state.is_none?(1)
      _self = new(::Path.new)
    elsif state.is_string?(1)
      _self = new(::Path.new(state.to_string(1)))
    else
      state.raise_type_error!(1, "expected string or nil")
    end
    Luajit.setup_userdata(state, _self, self)
    1
  end

  # ---@field home fun(): self
  def_class_method "home" do |state|
    _self = new(::Path.home)
    Luajit.setup_userdata(state, _self, self)
    1
  end

  # ---@field is_absolute fun(self): boolean
  def_instance_method "is_absolute" do |state|
    state.assert_userdata!(1)
    _self = Luajit.userdata_value(state, self, 1)
    state.push _self.path.absolute?
    1
  end

  # ---@field anchor fun(self): self?
  def_instance_method "anchor" do |state|
    state.assert_userdata!(1)
    _self = Luajit.userdata_value(state, self, 1)

    new_path = _self.path.anchor

    unless new_path
      state.push(nil)
      next 1
    end

    state.get_global("__PATH__")
    state.get_field(-1, "new")
    state.pcall(0, 1)
    __self = Luajit.userdata_value(state, self, -1)
    __self.path = new_path
    1
  end

  # ---@operator tostring(self): string
  def_instance_method "__tostring" do |state|
    state.assert_userdata!(1)
    _self = Luajit.userdata_value(state, self, 1)
    state.push _self.path.to_s
    1
  end

  def self.setup(state : Luajit::LuaState) : Nil
    Luajit.create_lua_object(state, self)
  end

  property path : ::Path

  def initialize(@path)
  end
end
