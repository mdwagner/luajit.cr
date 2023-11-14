require "./lua_any"

module Luajit
  # :nodoc:
  alias TablePair = Tuple(String | Float64, LuaAny)

  # :nodoc:
  class LuaTableIterator
    include Iterator(TablePair)

    KEY   = -2
    VALUE = -1

    @table_idx : Int32

    def initialize(@state : LuaState)
      #raise "Not a table" unless @state.is_table?(-1)
      unless @state.is_table?(-1)
        raise "invalid type: expected 'table', got '#{@state.type_name_at(-1)}'"
      end
      @table_idx = @state.size
      @state.push(nil)
    end

    def next
      result : TablePair? = nil
      expected_break = false

      while @state.next(@table_idx)
        key_type = @state.get_type(KEY)
        value_type = @state.get_type(VALUE)

        key = (
          case key_type
          in .string?
            @state.to_string(KEY)
          in .number?
            @state.to_f(KEY)
          in .boolean?, .light_userdata?, .function?, .userdata?, .thread?, .table?, .none?, LuaType::Nil
            @state.pop(1)
            next
          end
        )

        value = (
          case value_type
          in .number?
            @state.to_f(VALUE)
          in .boolean?
            @state.to_boolean(VALUE)
          in .string?
            @state.to_string(VALUE)
          in .light_userdata?, .function?, .userdata?, .thread?
            @state.push_value(VALUE)
            LuaRef.new(@state.create_registry_ref, value_type)
          in .table?
            LuaTableIterator.new(@state).to_h
          in .none?, LuaType::Nil
            @state.pop(1)
            next
          end
        )

        result = {key, LuaAny.new(value)}

        @state.pop(1)
        expected_break = true
        break
      end

      if expected_break
        result || stop
      else
        stop
      end
    end
  end
end
