defmodule PrivateModuleTest do
  use ExUnit.Case
  doctest PrivateModule

  test "greets the world" do
    assert PrivateModule.hello() == :world
  end
end
