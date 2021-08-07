defmodule Logflare.CacheBuster do
  @moduledoc """
    Monitors our Postgres replication log and busts the cache accordingly.
  """

  use GenServer

  require Logger

  alias Logflare.ContextCache
  alias Cainophile.Changes.{NewRecord, UpdatedRecord, DeletedRecord, Transaction}

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(state) do
    Cainophile.Adapters.Postgres.subscribe(Logflare.PgPublisher, self())
    {:ok, state}
  end

  def handle_info(%Transaction{changes: changes}, state) do
    for record <- changes do
      handle_record(record)
    end

    {:noreply, state}
  end

  defp handle_record(%UpdatedRecord{
         relation: {"public", "sources"},
         record: %{"id" => id}
       })
       when is_binary(id) do
    ContextCache.bust_keys(Logflare.Sources, String.to_integer(id))
  end

  defp handle_record(%UpdatedRecord{
         relation: {"public", "users"},
         record: %{"id" => id}
       })
       when is_binary(id) do
    ContextCache.bust_keys(Logflare.Users, String.to_integer(id))
  end

  defp handle_record(%UpdatedRecord{
         relation: {"public", "billing_accounts"},
         record: %{"id" => id}
       })
       when is_binary(id) do
    ContextCache.bust_keys(Logflare.BillingAccounts, String.to_integer(id))
  end

  defp handle_record(%UpdatedRecord{
         relation: {"public", "plans"},
         record: %{"id" => id}
       })
       when is_binary(id) do
    ContextCache.bust_keys(Logflare.Plans, String.to_integer(id))
  end

  defp handle_record(%UpdatedRecord{
         relation: {"public", "source_schemas"},
         record: %{"id" => id}
       })
       when is_binary(id) do
    ContextCache.bust_keys(Logflare.SourceSchemas, String.to_integer(id))
  end

  defp handle_record(%NewRecord{
         relation: {"public", "billing_accounts"},
         record: %{"id" => _id}
       }) do
    # When new records are created they were previously cached as `nil` so we need to bust the :not_found keys
    ContextCache.bust_keys(Logflare.BillingAccounts, :not_found)
  end

  defp handle_record(%NewRecord{
         relation: {"public", "source_schemas"},
         record: %{"id" => _id}
       }) do
    # When new records are created they were previously cached as `nil` so we need to bust the :not_found keys
    ContextCache.bust_keys(Logflare.SourceSchemas, :not_found)
  end

  defp handle_record(%NewRecord{
         relation: {"public", "sources"},
         record: %{"id" => _id}
       }) do
    # When new records are created they were previously cached as `nil` so we need to bust the :not_found keys
    ContextCache.bust_keys(Logflare.Sources, :not_found)
  end

  defp handle_record(%NewRecord{
         relation: {"public", "users"},
         record: %{"id" => _id}
       }) do
    # When new records are created they were previously cached as `nil` so we need to bust the :not_found keys
    ContextCache.bust_keys(Logflare.Users, :not_found)
  end

  defp handle_record(%DeletedRecord{
         relation: {"public", "billing_accounts"},
         old_record: %{"id" => id}
       }) do
    ContextCache.bust_keys(Logflare.BillingAccounts, String.to_integer(id))
  end

  defp handle_record(%DeletedRecord{
         relation: {"public", "sources"},
         old_record: %{"id" => id}
       }) do
    ContextCache.bust_keys(Logflare.Sources, String.to_integer(id))
  end

  defp handle_record(%DeletedRecord{
         relation: {"public", "source_schemas"},
         old_record: %{"id" => id}
       }) do
    ContextCache.bust_keys(Logflare.SourceSchemas, String.to_integer(id))
  end

  defp handle_record(%DeletedRecord{
         relation: {"public", "users"},
         old_record: %{"id" => id}
       }) do
    ContextCache.bust_keys(Logflare.Users, String.to_integer(id))
  end

  defp handle_record(_record) do
    :noop
  end
end