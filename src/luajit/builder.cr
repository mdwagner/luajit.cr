module Luajit
  class Builder
    # :nodoc:
    record Event, name : String, index : Int32

    @state : LuaState

    @events = {} of String => Event

    def initialize(@state)
    end

    def global_table(name : String, attach_meta : Bool = false) : self
      @state.new_table
      @events["table"] = Event.new(name, @state.size)
      @state.push_value(@events["table"].index)
      @state.set_global(@events["table"].name)

      if attach_meta
        metatable_name = LuaState.metatable_name(@events["table"].name)
        @state.new_metatable(metatable_name)
        @events["metatable"] = Event.new(metatable_name, @state.size)
      end

      self
    end

    def method(name : String, &block : LuaState::Function) : self
      if @events["table"]?
        @state.push(&block)
        @state.set_field(@events["table"].index, name)
      end

      self
    end

    def meta_method(name : String, &block : LuaState::Function) : self
      if @events["metatable"]?
        @state.push(name)
        @state.push(&block)
        @state.raw_set(@events["metatable"].index)
      end

      self
    end

    def meta_property(name : String, &) : self
      if @events["metatable"]?
        @state.push(name)
        yield
        @state.raw_set(@events["metatable"].index)
      end

      self
    end

    def create_lifecycle(_type : U.class, &block : LuaState -> U) : self forall U
      if @events["table"]?
        method("new") do |s|
          instance = block.call(s)
          s.create_userdata(instance, @events["table"].name)
          1
        end

        meta_method("__gc") do |s|
          s.assert_args_eq(1)
          s.assert_userdata?(1)

          instance = s.get_userdata(U, 1)
          s.destroy_userdata(instance)
          0
        end
      end

      self
    end

    # Needed for this behavior: `<instance>:<method>(...)`
    #
    # Otherwise it's this: `<table>.<method>(<instance>, ...)`
    def default_index : self
      if @events["table"]?
        meta_property("__index") do
          @state.push_value(@events["table"].index)
        end
      end

      self
    end
  end
end
