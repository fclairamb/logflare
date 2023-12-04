defmodule Logflare.Cluster.CacheWarmer do
  @moduledoc """
  Performs cross-node cache warming, by retrieving all cache data from the other node and setting it on the cache.


  """
  use Cachex.Warmer
  import Cachex.Spec

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(args) do
    opts = Enum.into(args, %{cache: nil})
    {:ok, opts}
  end

  def handle_info({:batch, cache, pairs}, state) do
    Cachex.import(cache, pairs)
    {:noreply, state}
  end

  # only on startup
  @impl Cachex.Warmer
  def interval, do: :timer.hours(24 * 365)
  @impl Cachex.Warmer
  def execute(cache) do
    # stream all data from the cache
    target =
      Node.list()
      |> Enum.map(fn node ->
        case :rpc.call(node, Cachex, :count, [cache]) do
          {:ok, count} when count > 0 -> node
          _ -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
      |> List.first()

    if target do
      pid = self()

      # don't block the caller, using :rpc.async_call results in crashloop due to key message handling.
      Task.start(fn ->
        :rpc.call(target, __MODULE__, :stream_to_node, [pid, cache])
      end)
    end

    {:ok, []}
  end

  # stream entries to the provided target node
  def stream_to_node(pid, cache) do
    # send message to CacheWarmer process on that node
    Cachex.stream!(cache)
    |> Stream.chunk_every(250)
    |> Stream.each(fn chunk ->
      send(pid, {:batch, cache, chunk})
    end)
    |> Stream.run()

    :ok
  end

  def warmer_spec(mod) do
    warmer(module: __MODULE__, state: mod)
  end
end
