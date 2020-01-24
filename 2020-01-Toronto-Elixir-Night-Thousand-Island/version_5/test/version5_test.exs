defmodule Version5Test do
  use ExUnit.Case
  doctest Version5

  test "greets the world" do
    assert Version5.hello() == :world
  end
end
