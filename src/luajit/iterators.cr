module Luajit
  # :nodoc:
  alias TablePair = Tuple(String | Float64, LuaAny)

  # :nodoc:
  class LuaTableIterator
    include Iterator(TablePair)

    KEY   = -2
    VALUE = -1

    @index : Int32 # Table index

    def initialize(@state : LuaState)
      @state.assert_table?(-1)
      @index = @state.size
      @state.push(nil)
    end

    def next
      result : TablePair? = nil

      while @state.next!(@index)
        key = case @state.get_type(KEY)
              when .string?
                @state.to_string(KEY)
              when .number?
                @state.to_f(KEY)
              else
                @state.pop(1)
                next
              end

        value = if any_value = @state.to_any?(VALUE)
                  any_value
                else
                  @state.pop(1)
                  next
                end

        result = {key, value}

        @state.pop(1)
        break
      end

      result || stop
    end
  end
end
