module Luajit
  module LuaBinding
    alias LuaState = Luajit::LuaState

    annotation LuaConfig
    end

    annotation LuaClass
    end

    annotation LuaInstance
    end

    # Defines a lua method binding (short-hand)
    #
    # Same type signature as `LuaState::Function`, but `LuaState` is accessed
    # via `__state`
    #
    # *method_name* starts with "self.": class method
    #
    # *method_name*: instance method
    macro def_lua(method_name, &)
      {% names = method_name.stringify.split(".") %}
      {% if names[0] == "self" %}
        @[Luajit::LuaBinding::LuaClass(name: {{names[1]}})]
      {% else %}
        @[Luajit::LuaBinding::LuaInstance(name: {{method_name.stringify}})]
      {% end %}
      def self.%method(__state : Luajit::LuaState) : Int32
        {{yield}}
      end
    end
  end

  macro global(raw_type)
    {% type = raw_type.resolve %}
    {% anno = type.annotation(Luajit::LuaBinding::LuaConfig) %}
    {% if anno && anno[:global] %}
      {{anno[:global]}}
    {% else %}
      {{type.stringify}}
    {% end %}
  end

  macro metatable(raw_type)
    {% type = raw_type.resolve %}
    {% anno = type.annotation(Luajit::LuaBinding::LuaConfig) %}
    {% if anno && anno[:metatable] %}
      {{anno[:metatable]}}
    {% elsif anno && anno[:global] %}
      {{anno[:global]}}
    {% else %}
      {{type.stringify}}
    {% end %}
  end

  # :nodoc:
  macro bind_class_method(lua, raw_type, name)
    {% type = raw_type.resolve %}
    {{lua}}.push_fn_closure do |%state|
      {{type}}.{{name.id}}(%state)
    end
  end

  # :nodoc:
  macro bind_instance_method(lua, raw_type, anno_name, name)
    {% type = raw_type.resolve %}
    {{lua}}.push_fn_closure do |%state|
      {% if type.class? %}
        {% if anno_name == "__gc" %}
          %state.untrack(%state.get_userdata(-1, Luajit.metatable({{type}})))
        {% end %}
      {% end %}
      {{type}}.{{name.id}}(%state)
    end
  end

  macro generate_lua_binding(lua, raw_type)
    {% type = raw_type.resolve %}

    {{lua}}.new_table
    %class_index = {{lua}}.size
    {{lua}}.push_value(%class_index)
    {{lua}}.set_global(Luajit.global({{type}}))

    {{lua}}.new_metatable(Luajit.metatable({{type}}))
    %instance_index = {{lua}}.size

    {% class_type = type.class %}
    {% for m in class_type.methods %}
      {% anno = m.annotation(Luajit::LuaBinding::LuaClass) %}
      {% if anno && anno[:name] %}
        {{lua}}.push({{anno[:name]}})
        Luajit.bind_class_method({{lua}}, {{type}}, {{m.name}})
        {{lua}}.set_table(%class_index)
      {% end %}

      {% anno = m.annotation(Luajit::LuaBinding::LuaInstance) %}
      {% if anno && anno[:name] %}
        {{lua}}.push({{anno[:name]}})
        Luajit.bind_instance_method({{lua}}, {{type}}, {{anno[:name]}}, {{m.name}})
        {{lua}}.set_table(%instance_index)
      {% end %}
    {% end %}

    {{lua}}.push_value(%instance_index)
    {{lua}}.set_field(%instance_index, "__index")
  end
end
