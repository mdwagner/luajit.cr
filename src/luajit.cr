require "./luajit/version"
require "./luajit/*"

module Luajit
  macro bind_class(lua_state, type)
    {% begin %}
    {%
     klass = type.resolve
     _static_methods = klass.class.methods
     _anno_methods = _static_methods.select(&.annotation(Luajit::Function))
     meta_methods = _anno_methods.select do |m|
       args = m.annotation(Luajit::Function).named_args
       !args[:name].empty? && args[:meta]
     end
     table_methods = _anno_methods.reject(&.annotation(Luajit::Function).named_args[:meta])
     has_gc_meta = meta_methods.any? do |m|
       m.annotation(Luajit::Function).named_args[:name] == "gc"
     end
     has_index_meta = meta_methods.any? do |m|
       m.annotation(Luajit::Function).named_args[:name] == "index"
     end
     %}

    {% raise "only Class is supported" unless klass.class? %}

    {{lua_state}}.new_table
    _table_index = {{lua_state}}.size
    {{lua_state}}.push_value(_table_index)
    {{lua_state}}.set_global({{klass.name.stringify}})

    {% for method in table_methods %}
      {% anno = method.annotation(Luajit::Function) %}

      ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
        {{klass}}.{{method.name.id}}(::Luajit::LuaState.new(x))
      })

      {% if anno.named_args[:name] %}
        {{lua_state}}.set_field(_table_index, {{anno.named_args[:name]}})
      {% else %}
        {{lua_state}}.set_field(_table_index, {{method.name.stringify}})
      {% end %}
    {% end %}


    {{lua_state}}.new_metatable({{lua_state}}.raw_metatable_name({{klass}}))
    _metatable_index = {{lua_state}}.size

    {% unless has_gc_meta %}
      ::Luajit::LibLuaJIT.lua_pushstring({{lua_state}}, "__gc")

      ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
        _state = ::Luajit::LuaState.new(x)
        _instance = _state.to_userdata({{klass}}, -1).value
        _state.remove_trackable(_instance.object_id)
        0
      })

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, _metatable_index)
    {% end %}

    {% unless has_index_meta %}
      ::Luajit::LibLuaJIT.lua_pushstring({{lua_state}}, "__index")

      {{lua_state}}.push_value(_table_index)

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, _metatable_index)
    {% end %}

    {% for method in meta_methods %}
      {% anno = method.annotation(Luajit::Function) %}

      ::Luajit::LibLuaJIT.lua_pushstring({{lua_state}}, "__{{anno.named_args[:name].id}}")

      {% if anno.named_args[:name] == "gc" %}
        ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
          _state = ::Luajit::LuaState.new(x)
          _instance = _state.to_userdata({{klass}}, -1).value
          _state.remove_trackable(_instance.object_id)
          {{klass}}.{{method.name.id}}(_state)
          0
        })
      {% else %}
        ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
          {{klass}}.{{method.name.id}}(::Luajit::LuaState.new(x))
        })
      {% end %}

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, _metatable_index)
    {% end %}

    {% end %}
  end
end
