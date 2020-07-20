defmodule ExBank.EventManager.StolenTest do
  use ExUnit.Case

  alias ExBank.EventManager
  alias ExBank.EventManager.Stolen

  describe "blocked" do
    setup do
      assert {:ok, _pid} = EventManager.start_link()
      assert {:ok, _pid} = Stolen.start_link()
      :ok
    end

    test "by invalid pin" do
      assert [] == Stolen.blocklist()
      assert :ok == EventManager.notify({:invalid_pin, 100})
      assert :ok == EventManager.notify({:invalid_pin, 100})
      assert :ok == EventManager.notify({:invalid_pin, 100})

      Process.sleep(200)

      assert [100] == Stolen.blocklist()
    end

    test "by blocking event" do
      assert [] == Stolen.blocklist()
      assert :ok == EventManager.notify({:account_blocked, 100})

      Process.sleep(200)

      assert [100] == Stolen.blocklist()
    end
  end

  describe "unblocked" do
    setup do
      assert {:ok, _pid} = EventManager.start_link()
      assert {:ok, _pid} = Stolen.start_link()
      assert :ok == EventManager.notify({:invalid_pin, 100})
      assert :ok == EventManager.notify({:invalid_pin, 100})
      assert :ok == EventManager.notify({:invalid_pin, 100})
      Process.sleep(200)
      :ok
    end

    test "by valid pin" do
      assert [100] == Stolen.blocklist()
      assert :ok == EventManager.notify({:valid_pin, 100})

      Process.sleep(200)

      assert [] == Stolen.blocklist()
    end

    test "by unblocking event" do
      assert [100] == Stolen.blocklist()
      assert :ok == EventManager.notify({:account_unblocked, 100})

      Process.sleep(200)

      assert [] == Stolen.blocklist()
    end
  end
end
