defmodule Logflare.Source.RecentLogsServerTest do
  @moduledoc false
  use Logflare.DataCase
  alias Logflare.Source.RecentLogsServer
  alias Logflare.Sources.Counters
  alias Logflare.Sources.RateCounters
  alias Logflare.SystemMetrics.AllLogsLogged

  test "able to start supervision tree" do
    start_supervised!(AllLogsLogged)
    start_supervised!(Counters)
    start_supervised!(RateCounters)
    stub(Goth, :fetch, fn _mod -> {:ok, %Goth.Token{token: "auth-token"}} end)
    user = insert(:user)
    source = insert(:source, user_id: user.id)
    plan = insert(:plan)
    rls = %RecentLogsServer{source_id: source.token, source: source, plan: plan, user: user}
    start_supervised!({RecentLogsServer, rls})
    :timer.sleep(1000)
  end
end
