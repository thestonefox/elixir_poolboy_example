# Elixir Poolboy Example

An example and brief explanation on how to use [Poolboy](https://github.com/devinus/poolboy)
to manage and pool workers in [Elixir](https://github.com/elixir-lang/elixir)

## Prerequisites

  * Erlang/OTP  17 [erts-6.4]
  * [Elixir 1.0.4](https://github.com/elixir-lang/elixir)

## Installation

To build a local version for use or development:
```
git clone https://github.com/thestonefox/elixir_poolboy_example.git
cd elixir_poolboy_example
mix deps.get
```

## Running

To run the two provided tutorial functions:

#### Sequential with response
```
iex -S mix

iex(1)> ElixirPoolboyExample.basic_pool(5)

# expected output: [25]

```

#### Parallel in background
```
iex -S mix

iex(1)> ElixirPoolboyExample.parallel_pool(1..5)

# expected output:
# 1 * 1 = 1
# 3 * 3 = 9
# 5 * 5 = 25
# 4 * 4 = 16
# 2 * 2 = 4
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

### Step Three

Integrating the Squarer module into the Poolboy worker is very easy
as it just needs to be called from within the worker's `handle_call`
function using the data parameter as the number to square.

```
def handle_call(data, from, state) do
  result = ElixirPoolboyExample.Squarer.square(data)
  {:reply, [result], state}
end
```

The Square.square function is now called and the result is returned
as the reply from the worker.

This is the updated [Worker](https://github.com/thestonefox/elixir_poolboy_example/blob/06636639c9e8f61ea21770b3f8ee53c1cc609eef/lib/elixir_poolboy_example/worker.ex)

When a Poolboy transaction is now created for the `:example_pool`,
it will pass the given data to the `Squarer.square` function.

Poolboy can be called within iex to test this worker is performing:

```
:poolboy.transaction(:example_pool, fn(pid) -> :gen_server.call(pid, 5) end)

# expected output: [25]
```

This is how a Poolboy transaction is performed, which denotes which
pool is to receive the message and a function that calls the GenServer
passing in the message data as the second parameter.

If a Poolboy worker is available to run the process then it will and
return the results.

To make things easier, this transaction function is wrapped in a helper
function within the main application called `pool_square(x)` which
simply takes a number and passes it off to Poolboy to process it with
the `Squarer.square` implemented in the Poolboy worker.

Now it is possible to write functions that initiate the process
utilising Poolboy to manage the total number of desired processes.

```
def basic_pool(x) do
  pool_square(x)
end
```

The above function is a very simple implementation of squaring a number
and it can be executed in iex like this:

```
ElixirPoolboyExample.basic_pool(5)

# expected output: [25]
```

This function goes through a Poolboy transaction and displays the
response, which is the square to the original given number.

This is the updated Elixir [supervisor](https://github.com/thestonefox/elixir_poolboy_example/blob/06636639c9e8f61ea21770b3f8ee53c1cc609eef/lib/elixir_poolboy_example.ex)

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/06636639c9e8f61ea21770b3f8ee53c1cc609eef) shows how to implement the `Squarer.square` function
call within the worker and provides a way to execute the function
through a Poolboy transaction.

### Step Four

To run the `Squarer.square` function in parallel and in the background,
it just needs to have the Poolboy transaction call spawned in a new
process.

However, as the transaction call is running in a spawned process, the
result will no longer be returned.

This is ideal for tasks that are long running and need to be run in the
background where the response is not required by the calling function.

To ensure the example still outputs something meaningful to show the
code is working, the Worker has been updated to print out the current
operation the function is performing with this line:

```
IO.puts "Worker Reports: #{data} * #{data} = #{result}"
```

This is the updated [Worker](https://github.com/thestonefox/elixir_poolboy_example/blob/6d94ccd668f8ec200a61c2d17c1ed1dc9905142e/lib/elixir_poolboy_example/worker.ex)

The implementation of the parallel method simply loops over a range of
numbers in a given list and for each one calls the `pool_square`
function in a newly spawned process like so:

```
def parallel_pool(range) do
  Enum.each(
    range,
    fn(x) -> spawn( fn() -> pool_square(x) end ) end
  )
end
```

This is the updated Elixir [supervisor](https://github.com/thestonefox/elixir_poolboy_example/blob/6d94ccd668f8ec200a61c2d17c1ed1dc9905142e/lib/elixir_poolboy_example.ex)

This newly implemented function will now perform the calculations in
parallel utilising the Poolboy workers to ensure system resources are
not overloaded. Executing the new function in iex produces:

```
ElixirPoolboyExample.parallel_pool(1..5)

# expected output:
# 1 * 1 = 1
# 3 * 3 = 9
# 5 * 5 = 25
# 4 * 4 = 16
# 2 * 2 = 4
```

The expected output is not sequential because all requests to the
`Squarer.square` function are done in parallel and it depends on which
request gets picked up by a worker to be processed first and as there
are only 3 maximum workers in the current configuration, not all
requests will be made in parallel.

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/6d94ccd668f8ec200a61c2d17c1ed1dc9905142e) shows how the `Squarer.square` can be run in parallel
utilising Poolboy to limit the number of parallel processes.

  > #### Warning
  > If too many requests are made to Poolboy, such as an extremely
  > high range is given `paralell_pool(1..1000000)` and there are
  > not enough workers available to process the requests, then
  > Poolboy will timeout after a default 5 seconds and no longer
  > accept any new requests. This may be desirable to ensure locked
  > or long running tasks don't lock up all of the workers.

If Poolboy timing out is causing issues and the desired outcome is to
have Poolboy just wait until free workers are available then that is
possible and this will be covered in the next step of the tutorial.

### Step Five

To prevent Poolboy timing out, a third parameter can be passed to the
`:poolboy.transaction` function that sets the default timeout for
Poolboy. The parameter is given in milliseconds but also takes the
`:infinity` atom to ensure that Poolboy never times out.

  > #### Warning
  > Using `:infinity` is not advised and is bad practice as it can
  > cause your processes to wait indefinitely and lock up completely.
  > It is advised to just enter a high number which will eventually
  > time out. This step is just to show it can be done for the
  > purpose of science :)

```
:poolboy.transaction(
  pool_name(),
  fn(pid) -> :gen_server.call(pid, x) end,
  :infinity
)
```

This is the updated Elixir [supervisor](https://github.com/thestonefox/elixir_poolboy_example/blob/065b7461fc4f54c25a63b519e5c368c440ffb1c9/lib/elixir_poolboy_example.ex)

To highlight the issue of a slow running process, the Poolboy worker
now has a sleep added to ensure each process uses at least 2 seconds
of each worker.

This is the updated [Worker](https://github.com/thestonefox/elixir_poolboy_example/blob/065b7461fc4f54c25a63b519e5c368c440ffb1c9/lib/elixir_poolboy_example/worker.ex)

These additions to the code will highlight that Poolboy can now wait
indefinitely for a worker and executing the code in iex shows the
Poolboy workers are now working in batches of 3 processes at a time.

```
ElixirPoolboyExample.parallel_pool(1..5)

# expected output:
# 1 * 1 = 1
# 3 * 3 = 9
# 5 * 5 = 25

# <pause waiting for workers to become available>

# 4 * 4 = 16
# 2 * 2 = 4
```

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/065b7461fc4f54c25a63b519e5c368c440ffb1c9) shows how to ensure Poolboy waits infinitely for an available worker.

### Step Six

Now everthing is working as expected, it's worth reviewing the code
and cleaning it up where possible. A closer inspection of the Elixir [supervisor](https://github.com/thestonefox/elixir_poolboy_example/blob/065b7461fc4f54c25a63b519e5c368c440ffb1c9/lib/elixir_poolboy_example.ex#L42)
shows that the `:gen_server.call/2` is actually coupling the client
code (the supervisor) to the communication protocol for the worker.

It would look cleaner if the supervisor could just call a function
on the worker that had no knowledge of it using a `GenServer`.

This is a simple case of creating a wrapper function in the worker
module that handles the `:gen_server.call/2` function and then
the supervisor can just call that function instead.

The new wrapper function within `ElixirPoolboyExample.Worker` module
looks like this:

```
def square(pid, value) do
  :gen_server.call(pid, value)
end
```

It simply encapsulates the `:gen_server.call/2` function inside the
module that has the `GenServer` dependency.

Now within the `ElixirPoolboyExample` module the new worker wrapper
function can be called:

```
defp pool_square(x) do
  :poolboy.transaction(
    pool_name(),
    fn(pid) -> ElixirPoolboyExample.Worker.square(pid, x) end,
    :infinity
  )
end
```

This is common practice and provides a decoupled approach to the
modules.

This [commit](https://github.com/thestonefox/elixir_poolboy_example/commit/435588606bdca3bad271805a4ada9a499f5edc80) shows how to decouple the client from the worker communication protocol.
