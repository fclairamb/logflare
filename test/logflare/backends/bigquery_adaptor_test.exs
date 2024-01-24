defmodule Logflare.Backends.BigQueryAdaptorTest do
  use Logflare.DataCase, async: false

  alias Logflare.Backends.Adaptor
  alias Logflare.Source.RecentLogsServer, as: RLS

  @subject Logflare.Backends.Adaptor.BigQueryAdaptor

  doctest @subject

  @moduletag skip: "Not yet fully implemented"

  setup_all do
    client_mod = GoogleApi.BigQuery.V2.Connection
    old_config = Application.get_env(:tesla, client_mod)

    :ok =
      Application.put_env(
        :tesla,
        client_mod,
        adapter: Tesla.Mock
      )

    on_exit(fn ->
      Application.put_env(:tesla, client_mod, old_config)
    end)
  end

  setup do
    config = %{}

    source = insert(:source, user: insert(:user))

    source_backend =
      insert(:source_backend,
        type: :bigquery,
        source: source,
        config: config
      )

    _rls = start_supervised %{
      start: {RLS, :start_link, %RLS{source_id: source.token}}
    }

    adaptor = start_supervised! Adaptor.child_spec(source_backend)

    {:ok, source: source, source_backend: source_backend, adaptor: adaptor}
  end

  test "plain ingest", %{adaptor: adaptor, source_backend: source_backend} do
    log_event = build(:log_event, source: source_backend.source, test: "data")

    assert :for_sure_it_will_fail == @subject.ingest(adaptor, [%{data: log_event}])
  end
end
