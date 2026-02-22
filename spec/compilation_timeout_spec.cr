require "spec"

# Tests for the compilation timeout fiber leak fix.
#
# Bug: When compilation exceeds the 120s timeout, the `select/when timeout`
# fires and stops receiving from the channel. But the compilation fiber's
# `ensure` block still tries to `sync_channel.send(result)` on an unbuffered
# channel with no receiver — it blocks forever, leaking the fiber.
#
# Fix: Use a buffered channel of capacity 1 so the send never blocks
# even when no receiver is waiting.

describe "Buffered channel for compilation sync" do
  it "unbuffered channel blocks sender when no receiver" do
    ch = Channel(Int32?).new
    sent = false

    spawn do
      ch.send(42)
      sent = true
    end

    # Give the fiber a chance to run
    sleep 10.milliseconds
    # The sender is blocked because no one is receiving
    sent.should eq(false)

    # Clean up: receive to unblock
    ch.receive
    sleep 1.milliseconds
    sent.should eq(true)
  end

  it "buffered(1) channel allows sender to complete without receiver" do
    ch = Channel(Int32?).new(1)
    sent = false

    spawn do
      ch.send(42)
      sent = true
    end

    # Give the fiber a chance to run
    sleep 10.milliseconds
    # The sender should have completed because the buffer absorbs it
    sent.should eq(true)

    # Clean up
    ch.receive
  end

  it "buffered(1) channel works normally with receiver" do
    ch = Channel(Int32?).new(1)

    spawn do
      ch.send(42)
    end

    received = select
    when value = ch.receive
      value
    when timeout 1.seconds
      nil
    end

    received.should eq(42)
  end

  it "buffered(1) channel handles nil values" do
    ch = Channel(Int32?).new(1)
    sent = false

    spawn do
      ch.send(nil)
      sent = true
    end

    sleep 10.milliseconds
    sent.should eq(true)

    result = ch.receive
    result.should be_nil
  end

  it "simulates timeout scenario without fiber leak" do
    ch = Channel(String?).new(1)
    sender_completed = false

    # Simulate: sender runs in background (like the compilation fiber)
    spawn do
      sleep 50.milliseconds # simulate slow work
      ch.send("done")
      sender_completed = true
    end

    # Simulate: receiver times out before sender finishes
    select
    when ch.receive
      fail "Should have timed out"
    when timeout 10.milliseconds
      # Timed out as expected
    end

    # With unbuffered channel, the sender would be stuck forever.
    # With buffered(1), the sender completes after its work is done.
    sleep 100.milliseconds
    sender_completed.should eq(true)
  end
end
