defmodule ExBank.EventManager.StatisticsTest do
  use ExUnit.Case

  alias ExBank.EventManager
  alias ExBank.EventManager.Statistics

  describe "statistics" do
    setup do
      assert {:ok, _pid} = EventManager.start_link()
      assert {:ok, _pid} = Statistics.start_link()
      :ok
    end

    test "about deposit, withdraw and transfer" do
      assert [avg_transfer_amount: 0] == Statistics.get_stats()
      assert :ok == EventManager.notify({:deposit, 10})
      assert :ok == EventManager.notify({:withdraw, 10})

      #  Transferring 333 it should average to 111
      assert :ok == EventManager.notify({:transfer, 300})
      assert :ok == EventManager.notify({:transfer, 30})
      assert :ok == EventManager.notify({:transfer, 3})

      Process.sleep(200)

      assert [
               avg_transfer_amount: 111.0,
               deposit: 1,
               total_transfer_amount: 333,
               transfer: 3,
               withdraw: 1
             ] == Enum.sort(Statistics.get_stats())
    end

    test "blocked and unblocked" do
      assert [avg_transfer_amount: 0] == Statistics.get_stats()
      assert :ok == EventManager.notify({:account_blocked, 100})

      Process.sleep(200)

      assert [
               account_blocked: 1,
               avg_transfer_amount: 0
             ] == Enum.sort(Statistics.get_stats())

      assert :ok == EventManager.notify({:account_unblocked, 100})

      Process.sleep(200)

      assert [
               account_blocked: 1,
               account_unblocked: 1,
               avg_transfer_amount: 0
             ] == Enum.sort(Statistics.get_stats())
    end
  end
end
