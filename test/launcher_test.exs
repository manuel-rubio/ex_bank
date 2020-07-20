defmodule ExBank.LauncherTest do
  use ExUnit.Case

  @server {:global, :atm_launcher}

  describe "launching: " do
    setup do
      assert {:ok, _pid} = ExBank.Launcher.start_link()
      :ok
    end

    test "launch an ATM" do
      assert {:ok, pid} = GenServer.call(@server, {:start_atm, self()})
      Process.sleep(100)
      assert Process.alive?(pid)
      assert :ok == GenServer.call(pid, :stop)
    end

    test "launch several ATMs" do
      pids =
        Enum.map(1..5, fn _ ->
          {:ok, pid} = GenServer.call(@server, {:start_atm, self()})
          pid
        end)

      assert Enum.all?(pids, &Process.alive?(&1))
      Enum.each(pids, &GenServer.call(&1, :stop))
    end
  end
end
