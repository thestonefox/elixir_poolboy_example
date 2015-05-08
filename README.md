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
