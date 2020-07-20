defmodule ExBank.ApplicationTest do
  use ExUnit.Case

  describe "ex_bank application: " do
    setup do
      assert {:ok, apps} = Application.ensure_all_started(:ex_bank)

      on_exit(:cleanup, fn ->
        Enum.each(apps, fn app ->
          Application.stop(app)
          Application.unload(app)
        end)
      end)

      :ok
    end

    test "start/stop" do
      atm = Process.whereis(ExBank.Atm.Supervisor)
      assert is_pid(atm) and Process.alive?(atm)
      backend = :global.whereis_name(:backend)
      assert is_pid(backend) and Process.alive?(backend)
      launcher = :global.whereis_name(:atm_launcher)
      assert is_pid(launcher) and Process.alive?(launcher)

      Process.monitor(atm)
      Process.monitor(backend)
      Process.monitor(launcher)

      assert :ok = Application.stop(:ex_bank)
      assert :ok = Application.unload(:ex_bank)
      assert_receive {:DOWN, _ref, :process, ^atm, :shutdown}
      assert_receive {:DOWN, _ref, :process, ^backend, :shutdown}
      assert_receive {:DOWN, _ref, :process, ^launcher, :shutdown}

      assert nil == Process.whereis(ExBank.Atm.Supervisor)
      assert :undefined == :global.whereis_name(:backend)
      assert :undefined == :global.whereis_name(:atm_launcher)
    end

    test "supervisor restart all of the children" do
      atm = Process.whereis(ExBank.Atm.Supervisor)
      assert is_pid(atm) and Process.alive?(atm)
      backend = :global.whereis_name(:backend)
      assert is_pid(backend) and Process.alive?(backend)
      launcher = :global.whereis_name(:atm_launcher)
      assert is_pid(launcher) and Process.alive?(launcher)

      Process.monitor(atm)
      Process.monitor(backend)
      Process.monitor(launcher)

      Process.exit(backend, :kill)

      assert_receive {:DOWN, _ref, :process, ^atm, :shutdown}
      assert_receive {:DOWN, _ref, :process, ^backend, :killed}
      assert_receive {:DOWN, _ref, :process, ^launcher, :shutdown}

      Process.sleep(200)

      refute nil == Process.whereis(ExBank.Atm.Supervisor)
      refute atm == Process.whereis(ExBank.Atm.Supervisor)
      refute :undefined == :global.whereis_name(:backend)
      refute backend == :global.whereis_name(:backend)
      refute :undefined == :global.whereis_name(:atm_launcher)
      refute launcher == :global.whereis_name(:atm_launcher)
    end
  end
end
