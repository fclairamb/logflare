defmodule Logflare.Alerting.AlertQuery do
  @moduledoc false
  use TypedEctoSchema
  import Ecto.Changeset
  alias Logflare.Endpoints.Query

  @derive {Jason.Encoder,
           only: [
             :id,
             :token,
             :cron,
             :name,
             :description,
             :language,
             :query,
             :webhook_notification_url,
             :slack_hook_url
           ]}
  typed_schema "alert_queries" do
    field :name, :string
    field :description, :string
    field(:language, Ecto.Enum, values: [:bq_sql, :pg_sql, :lql], default: :bq_sql)
    field :query, :string
    field :cron, :string
    field :source_mapping, :map
    field :token, Ecto.UUID, autogenerate: true
    field :slack_hook_url, :string
    field :webhook_notification_url, :string
    belongs_to :user, Logflare.User

    timestamps()
  end

  @doc false
  def changeset(alert_query, attrs) do
    alert_query
    |> cast(attrs, [
      :name,
      :description,
      :language,
      :query,
      :cron,
      :slack_hook_url,
      :webhook_notification_url
    ])
    |> validate_required([:name, :query, :cron, :language])
    # this source mapping logic is for any generic changeset
    # we implement the same columns for now,
    # can consider migrating to separate table in future.
    |> Query.update_source_mapping()
  end
end
