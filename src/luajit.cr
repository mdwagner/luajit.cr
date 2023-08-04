require "./luajit/version"
require "./luajit/*"

module Luajit
  macro lua_bind(lua_state, type)
    {% begin %}
    {% klass = type.resolve %}
    {% static_methods = klass.class.methods.select(&.annotation(Luajit::Function)) %}
      {% for static_method in static_methods %}
        {% anno = static_method.annotation(Luajit::Function) %}
        ::Luajit::LibxLuaJIT.lua_pushcfunction({{lua_state}}, ->(x : ::Luajit::LibLuaJIT::State*) : Int32 {
          {{klass}}.{{static_method.name.id}}(::Luajit::LuaState.new(x))
        })
        {% if anno.named_args[:name] %}
          {{lua_state}}.set_global({{anno.named_args[:name]}})
        {% else %}
          {{lua_state}}.set_global({{static_method.name.stringify}})
        {% end %}
      {% end %}
    {% end %}
  end

  #macro bind_class(l, Class)
    # static methods
    # instance methods (Mutable)
  #end

  #macro bind_struct(l, Struct)
    # static methods
    # instance methods (Immutable)
  #end

  #macro bind_module(l, Luajit)
    # static methods
  #end
end
