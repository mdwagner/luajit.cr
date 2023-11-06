module Luajit
  struct LuaAny
    alias Type = Bool | String | Float64 | LuaRef | Hash(String | Float64, LuaAny)

    getter raw : Type

    def self.to_a(hash : Hash(String | Float64, LuaAny)) : Array(LuaAny)
      total = hash.keys.count { |k| k.is_a?(Float64) && k > 0 && k % 1 == 0 }
      Array(LuaAny).new(total).tap do |arr|
        total.times do |n|
          i = n + 1
          if value = hash[i]?
            arr << value
          else
            break
          end
        end
      end
    end

    def initialize(@raw)
    end

    def [](key : String | Float64) : LuaAny
      case object = @raw
      when Hash
        object[key]
      else
        raise "Expected Hash for #[](key : String | Float64), not #{object.class}"
      end
    end

    def []?(key : String | Float64) : LuaAny?
      case object = @raw
      when Hash
        object[key]?
      else
        raise "Expected Hash for #[]?(key : String | Float64), not #{object.class}"
      end
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

    def as_a : Array(LuaAny)
      LuaAny.to_a(as_h)
    end

    def as_a? : Array(LuaAny)?
      as_a if @raw.is_a?(Hash)
    end

    def as_h : Hash(String | Float64, LuaAny)
      @raw.as(Hash)
    end

    def as_h? : Hash(String | Float64, LuaAny)?
      as_h if @raw.is_a?(Hash)
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
