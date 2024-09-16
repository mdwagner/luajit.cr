require "../luajit"

class Luajit::Wrappers::Path < Luajit::LuaObject
  global_name "Path"
  metatable_name "__PATH__"

  # ---@field new fun(path: string?): Path
  def_class_method "new" do |state|
    instance =
      if state.is_none_or_nil?(1)
        new ::Path.new
      elsif state.is_string?(1)
        new ::Path.new(state.to_string(1))
      else
        state.raise_type_error!(1, "expected string or nil")
      end
    Luajit.setup_userdata(state, instance, self)
    1
  end

  # ---@field home fun(): Path
  def_class_method "home" do |state|
    Luajit.setup_userdata(state, new(::Path.home), self)
    1
  end

  # ---@field is_absolute fun(self): boolean
  def_instance_method "is_absolute" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)
    state.push instance.path.absolute?
    1
  end

  # ---@field basename fun(self, suffix: string?): string
  def_instance_method "basename" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)

    suffix =
      if state.is_none_or_nil?(2)
        nil
      elsif state.is_string?(2)
        state.to_string(2)
      else
        state.raise_type_error!(2, "expected string or nil")
      end

    state.push instance.path.basename(suffix)
    1
  end

  # ---@field dirname fun(self): string
  def_instance_method "dirname" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)
    state.push instance.path.dirname
    1
  end

  # ---@field each_parent fun(self, cb: fun(path: Path))
  def_instance_method "each_parent" do |state|
    state.assert_userdata!(1)
    state.assert_function!(2)

    instance = Luajit.userdata_value(state, self, 1)
    fn_index = 2

    state.get_global("Path")
    state.get_field(-1, "new")
    state.pcall(0, 1)
    temp_path_index = state.size
    temp_path = Luajit.userdata_value(state, self, temp_path_index)

    instance.path.each_parent do |path|
      temp_path.path = path

      state.push_value(fn_index)
      state.push_value(temp_path_index)
      state.pcall(1, 0)
    end
    0
  end

  # ---@field each_part fun(self, cb: fun(str: string))
  def_instance_method "each_part" do |state|
    state.assert_userdata!(1)
    state.assert_function!(2)

    instance = Luajit.userdata_value(state, self, 1)
    fn_index = 2

    instance.path.each_part do |component|
      state.push_value(fn_index)
      state.push(component)
      state.pcall(1, 0)
    end
    0
  end

  # ---@field ends_with_separator fun(self): boolean
  def_instance_method "ends_with_separator" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)
    state.push instance.path.ends_with_separator?
    1
  end

  # ---@class PathExpandOptions
  # ---@field base Path|string?
  # ---@field home Path|string|boolean?
  # ---@field expand_base boolean?
  #
  # ---@field expand fun(self, options: PathExpandOptions?): Path
  def_instance_method "expand" do |state|
    state.assert_userdata!(1)

    instance = Luajit.userdata_value(state, self, 1)

    state.get_global("Path")
    state.get_field(-1, "new")
    state.pcall(0, 1)
    new_path = Luajit.userdata_value(state, self, -1)
    new_path_index = state.size

    if state.is_none_or_nil?(2)
      new_path.path = instance.path.expand
      next 1
    end

    unless state.is_table?(2)
      state.raise_type_error!(2, "expected table or nil")
    end

    state.get_field(2, "base")
    base_index = state.size

    state.get_field(2, "home")
    home_index = state.size

    state.get_field(2, "expand_base")
    expand_base_index = state.size

    base =
      if state.is_string?(base_index)
        state.to_string(base_index)
      elsif state.is_userdata?(base_index)
        Luajit.userdata_value(state, self, base_index).path
      else
        Dir.current
      end

    home =
      if state.is_string?(home_index)
        state.to_string(home_index)
      elsif state.is_userdata?(home_index)
        Luajit.userdata_value(state, self, home_index).path
      elsif state.is_bool?(home_index)
        state.to_boolean(home_index)
      else
        false
      end

    expand_base =
      if state.is_bool?(expand_base_index)
        state.to_boolean(expand_base_index)
      else
        true
      end

    new_path.path = instance.path.expand(base: base, home: home, expand_base: expand_base)
    state.push_value(new_path_index)
    1
  end

  # ---@field extension fun(self): string
  def_instance_method "extension" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)
    state.push instance.path.extension
    1
  end

  # ---@field join fun(self, parts: string[]|string): Path
  def_instance_method "join" do |state|
    state.assert_userdata!(1)
    state.assert_any!(2)
    instance = Luajit.userdata_value(state, self, 1)

    if state.is_string?(2)
      state.get_global("Path")
      state.get_field(-1, "new")
      state.pcall(0, 1)
      new_path = Luajit.userdata_value(state, self, -1)
      new_path.path = instance.path.join(state.to_string(2))
      1
    elsif state.is_table?(2)
      state.get_global("Path")
      state.get_field(-1, "new")
      state.pcall(0, 1)
      new_path = Luajit.userdata_value(state, self, -1)
      new_path_index = state.size

      parts = [] of ::String

      any_parts = state.to_a(2)
      any_parts.each do |i|
        if value = i.as_s?
          parts << value
        else
          break
        end
      end
      state.clean(any_parts)

      new_path.path = instance.path.join(*parts)
      state.push_value(new_path_index)
      1
    else
      state.raise_type_error!(2, "expected table or string")
    end
  end

  # ---@field __tostring fun(self): string
  def_instance_method "__tostring" do |state|
    state.assert_userdata!(1)
    instance = Luajit.userdata_value(state, self, 1)
    state.push instance.path.to_s
    1
  end

  # ---@operator concat(): Path
  # op1 = Path, op2 = Path
  # op1 = Path, op2 = string
  def_instance_method "__concat" do |state|
    state.assert_userdata!(1)
    state.assert_any!(2)

    instance = Luajit.userdata_value(state, self, 1)

    if state.is_string?(2)
      op2 = state.to_string(2)
      op2_path = instance.path.join(op2)
    elsif state.is_userdata?(2)
      op2 = Luajit.userdata_value(state, self, 2)
      op2_path = instance.path.join(op2.path)
    else
      state.raise_type_error!(2, "expected Path or string")
    end

    state.get_global("Path")
    state.get_field(-1, "new")
    state.pcall(0, 1)
    new_path = Luajit.userdata_value(state, self, -1)
    new_path.path = op2_path
    1
  end

  def self.setup(state : Luajit::LuaState) : Nil
    Luajit.create_lua_object(state, self)
  end

  property path : ::Path

  def initialize(@path)
  end
end
