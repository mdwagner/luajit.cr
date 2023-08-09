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
    {{lua_state}}.push_value(-1)
    {{lua_state}}.set_global({{klass.name.stringify}})

    {% for method in table_methods %}
      {% anno = method.annotation(Luajit::Function) %}

      ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
        {{klass}}.{{method.name.id}}(::Luajit::LuaState.new(x))
      })

      {{lua_state}}.set_field(-2, {{anno.named_args[:name] || method.name.stringify}})
    {% end %}

    {{lua_state}}.new_metatable({{lua_state}}.raw_metatable_name({{klass}}))

    {% unless has_gc_meta %}
      ::Luajit::LibLuaJIT.lua_pushstring({{lua_state}}, "__gc")

      ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
        _state = ::Luajit::LuaState.new(x)
        _instance = _state.to_userdata({{klass}}, -1).value
        _state.remove_trackable(_instance.object_id)
        0
      })

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, -3)
    {% end %}

    {% unless has_index_meta %}
      ::Luajit::LibLuaJIT.lua_pushstring({{lua_state}}, "__index")

      {{lua_state}}.push_value(-3)

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, -3)
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

      ::Luajit::LibLuaJIT.lua_settable({{lua_state}}, -3)
    {% end %}

    {% end %}
  end
end
