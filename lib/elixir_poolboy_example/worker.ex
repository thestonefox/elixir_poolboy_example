defmodule ElixirPoolboyExample.Worker do
  use GenServer

  def start_link([]) do
    :gen_server.start_link(__MODULE__, [], [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(data, from, state) do
    :timer.sleep(2000)
    result = ElixirPoolboyExample.Squarer.square(data)
    IO.puts "Worker Reports: #{data} * #{data} = #{result}"
    {:reply, [result], state}
  end
end
