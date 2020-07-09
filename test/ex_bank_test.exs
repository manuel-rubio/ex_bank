defmodule ExBankTest do
  use ExUnit.Case
  doctest ExBank

  test "greets the world" do
    assert ExBank.hello() == :world
  end
end
