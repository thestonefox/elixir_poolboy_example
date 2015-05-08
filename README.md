# Elixir Poolboy Example

An example and brief explanation on how to use [Poolboy](https://github.com/devinus/poolboy)
to manage and pool workers in [Elixir](https://github.com/elixir-lang/elixir)

## Prerequisites

  * Erlang/OPT 17 [erts-6.4]
  * [Elixir 1.0.4](https://github.com/elixir-lang/elixir)

## Installation

To build a local version for use or development:
```
git clone https://github.com/thestonefox/elixir_poolboy_example.git
cd elixir_poolboy_example
mix deps.get
```

## Tutorial

The aim of this tutorial is to demonstrate a usage of [Poolboy](https://github.com/devinus/poolboy)
as a means of managing worker pools to ensure processes do not take up more resources than available.

### Use Case

The purpose of the tutorial is to show how to run parallel processes
without flooding the available resources and is based upon the blog
post at [http://www.theerlangelist.com/2013/04/parallelizing-independent-tasks.html]

The use case will be around running a simple mathematical operation of
squaring a given range of numbers but doing it in parallel without
using up all available resources by pooling the processes into
manageable chunks using Poolboy workers.

### Step One

The first step is to build a simple module that can be given a number,
square it and return the results. A module called `Squarer` is created
with one function that does just this.

  * See [ElixirPoolboyExample.Squarer](https://github.com/thestonefox/elixir_poolboy_example/blob/0791752f0ac9b13d97ccb4d654603f578751d73c/lib/elixir_poolboy_example/squarer.ex)

The Elixir app is also set up to run as a supervisor which will enable
the running of the application and the basis of how Poolboy will work.

It's possible to auto generate the supervisor code at project creation
using:

`mix new <project-name> --sup`

but for the purposes of the tutorial, it will be created step by step.

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/0791752f0ac9b13d97ccb4d654603f578751d73c) shows the basic set up of the supervisor and creation
of the Squarer module that will be used for the parallel tasks.

To check the current code is working, simply run:

```
iex -S mix
ElixirPoolboyExample.Squarer.square(5)

# expected output: 25
```

That's as much as it does so far, next is to implement Poolboy!

### Step Two

Now there is a basic app that performs an operation that can be run
in parallel, it's time to implement Poolboy to aid parallel running.

Poolboy is an Erlang library maintained on GitHub and is available on [Hex.pm](https://hex.pm/packages/poolboy)
so including it as a dependency is simply a case of adding it to the [Mixfile](https://github.com/thestonefox/elixir_poolboy_example/blob/1fe2c9df6a3c7c51df07a36c4dd93f437fc84426/mix.exs#L34)

```
defp deps do
  [
    { :poolboy, "~> 1.5" }
  ]
```

Poolboy also needs adding as a dependency to the applications list
within the [Mixfile](https://github.com/thestonefox/elixir_poolboy_example/blob/1fe2c9df6a3c7c51df07a36c4dd93f437fc84426/mix.exs#L19)
otherwise a failure will occur when attempting to build an OTP release.

```
def application do
  [
    mod: {ElixirPoolboyExample, []},
    applications: [:logger, :poolboy]
  ]
end
```

Because an addition has been added to the Mixfile, the dependencies
will need to be fetched with `mix deps.get` and this will pull down
and compile the specified version of Poolboy from Hex.

To get Poolboy running, it just needs setting up to run as a child
of the supervisor that has already been created. Poolboy also needs
some configuring like so:

```
poolboy_config = [
  {:name, {:local, pool_name()}},
  {:worker_module, ElixirPoolboyExample.Worker},
  {:size, 2},
  {:max_overflow, 1}
]
```

The config options are:

  * **Name** - a sub-config tuple
    * **Location** (`:global` or `:local`) - to determine where the pool is run
    * **Pool Name** - an atom (constant) to provide a unique name for the pool to reference it for use
  * **Worker Module** - the name of the module that will act as the Poolboy worker for dealing with requests
  * **Size** - the number of workers that can be running at any given time
  * **Max Overflow** - the number of backup workers that can be used if existing workers are being utilised

As the pool name will be required to be constant across all calls to
Poolboy, a basic function is implemented to return an atom that is the
reference to the pool. This just makes it easier to change the name of
the pool in one place rather than in a number of places.

```
defp pool_name() do
  :example_pool
end
```

With Poolboy configured, it will allow for 2 workers with 1 additional
worker to run the specified process at any one time. In this example,
only 3 `Worker` processes will be able to run in parallel. In reality,
this number would be much higher to meet the demands of the hardware.

This is the updated Elixir [supervisor](https://github.com/thestonefox/elixir_poolboy_example/blob/1fe2c9df6a3c7c51df07a36c4dd93f437fc84426/lib/elixir_poolboy_example.ex)

The worker that is specified in the Poolboy configuration is simply a
GenServer that PoolBoy uses to communicate to and basically works as a
GenPool for all of the GenServer Workers it is using.

At this point, a basic Worker implementation has been added that does
not do anything other than satisfy the requirements of the Poolboy
configuration within the supervisor. This is the current [Worker](https://github.com/thestonefox/elixir_poolboy_example/blob/1fe2c9df6a3c7c51df07a36c4dd93f437fc84426/lib/elixir_poolboy_example/worker.ex)

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/1fe2c9df6a3c7c51df07a36c4dd93f437fc84426) shows the set up required to make Poolboy a dependency
and implement it as a child of the application supervisor.
