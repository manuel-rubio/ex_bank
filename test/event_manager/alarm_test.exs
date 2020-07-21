defmodule ExBank.EventManager.AlarmTest do
  use ExUnit.Case, async: false

  alias ExBank.EventManager
  alias ExBank.EventManager.Alarm

  describe "alarms" do
    setup do
      Application.ensure_all_started(:sasl)
      assert {:ok, _pid} = EventManager.start_link()
      assert {:ok, _pid} = Alarm.start_link()
      :ok
    end

    test "triggering / clearing an alarm" do
      assert [] == :alarm_handler.get_alarms()
      assert :ok == EventManager.notify({:account_blocked, 100})

      Process.sleep(200)

      assert [{100, :account_blocked}] == :alarm_handler.get_alarms()
      assert :ok == EventManager.notify({:account_unblocked, 100})

      Process.sleep(500)

      assert [] == :alarm_handler.get_alarms()
    end
  end
end
