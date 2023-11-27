module Luajit
  struct LuaAny
    alias Type = Bool | String | Float64 | LuaRef

    getter raw : Type

    def initialize(@raw)
    end

    def as_bool : Bool
      @raw.as(Bool)
    end

    def as_bool? : Bool?
      as_bool if @raw.is_a?(Bool)
    end

    def as_s : String
      @raw.as(String)
    end

    def as_s? : String?
      as_s if @raw.is_a?(String)
    end

    def as_f : Float64
      @raw.as(Float64)
    end

    def as_f? : Float64?
      as_f if @raw.is_a?(Float64)
    end

    def as_ref : LuaRef
      @raw.as(LuaRef)
    end

    def as_ref? : LuaRef?
      as_ref if @raw.is_a?(LuaRef)
    end

    def inspect(io : IO) : Nil
      @raw.inspect(io)
    end

    def to_s(io : IO) : Nil
      @raw.to_s(io)
    end

    # :nodoc:
    def pretty_print(pp)
      @raw.pretty_print(pp)
    end

    def ==(other : JSON::Any)
      raw == other.raw
    end

    def ==(other)
      raw == other
    end

    def_hash raw
  end
end
