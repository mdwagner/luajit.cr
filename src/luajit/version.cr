module Luajit
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
  class_getter pointers = [] of Pointer(Void)
end
