defmodule ElixirPoolboyExample do
  use Application

  defp pool_name() do
    :example_pool
  end

  def start(_type, _args) do
    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, ElixirPoolboyExample.Worker},
      {:size, 2},
      {:max_overflow, 1}
    ]

    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: ElixirPoolboyExample.Supervisor
    ]

    Supervisor.start_link(children, options)
  end

  def basic_pool(x) do
    pool_square(x)
  end

  def parallel_pool(range) do
    Enum.each(
      range,
      fn(x) -> spawn( fn() -> pool_square(x) end ) end
    )
  end

  defp pool_square(x) do
    :poolboy.transaction(
      pool_name(),
      fn(pid) -> ElixirPoolboyExample.Worker.square(pid, x) end,
      :infinity
    )
  end
end
