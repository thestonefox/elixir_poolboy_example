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
end
