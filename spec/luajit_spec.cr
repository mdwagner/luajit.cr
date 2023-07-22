require "./spec_helper"

describe Luajit do
  it "works" do
    true.should be_true
  end

  #it "works" do
    #vm = Luajit::VM.new
    #vm.execute <<-LUA
    #x = { name = "Michael" }
    #LUA

    #vm.get_global("x")
    #vm.is?(:table, -1).should be_true

    #vm.get_field(-1, "name")
    #vm.is?(:string, -1).should be_true

    #name = vm.to_string(-1)
    #name.should eq("Michael")
  #end

  #it "generate secret key" do
    #vm = Luajit::VM.new
    #vm.open_libs

    #proc = ->(l : Luajit::LibLuajit::State*) : Int32 {
      #Luajit::LibLuajit.lua_pushstring(l, Random::Secure.base64(32))
      #1
    #}
    #box = Box(typeof(proc)).box(proc)
    #vm << box
    #Luajit::LibLuajit.lua_pushcclosure(vm, ->(l : Luajit::LibLuajit::State*) : Int32 {
      #ptr = Luajit::LibLuajit.lua_touserdata(l, Luajit::VM.upvalueindex(1))
      #Box(typeof(proc)).unbox(ptr).call(l)
    #}, 1)
    #Luajit::LibLuajit.lua_setfield(vm, Luajit::LibLuajit::LUA_GLOBALSINDEX, "secret_key")

    #vm.execute <<-LUA
    #print("Secret key: " .. secret_key())
    #LUA
  #end
end

#Luajit::Coroutine # fibers
#Luajit::VM < Coroutine # main fiber
#Luajit::Function # closure

# Proc(Function, Int32)
#vm.push_function do |fn|
  #0
#end

#def push_closure(&cb : CFunction -> Int32) : Nil
  #box = Box(typeof(cb)).box(cb)
  #vm << box
#end

#def push_function(&cb : Function -> Int32) : Nil
  #push_c_function do |state_ptr|
    #cb.call(Function.new(state_ptr))
  #end
#end

#vm.push_function do |fn|
  #fn << "hello"
  #1
#end
