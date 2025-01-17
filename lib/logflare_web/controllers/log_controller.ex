defmodule LogflareWeb.LogController do
  use LogflareWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Logflare.Logs.Processor

  alias LogflareWeb.OpenApi.Created
  alias LogflareWeb.OpenApi.ServerError
  alias LogflareWeb.OpenApiSchemas.LogsCreated

  action_fallback(LogflareWeb.Api.FallbackController)

  tags(["Public"])

  plug(
    CORSPlug,
    [
      origin: "*",
      max_age: 1_728_000,
      headers: [
        "Authorization",
        "Content-Type",
        "Content-Length",
        "X-Requested-With"
      ],
      methods: ["POST", "OPTIONS"],
      send_preflight_response?: true
    ]
    when action in [:browser_reports, :generic_json, :create]
  )

  alias Logflare.Logs

  @message "Logged!"

  operation(:create,
    summary: "Create log event",
    description:
      "Full details are available in the [ingestion documentation](https://docs.logflare.app/concepts/ingestion/)",
    parameters: [
      source: [
        in: :query,
        description: "Source UUID",
        type: :string,
        example: "a040ae88-3e27-448b-9ee6-622278b23193",
        required: false
      ],
      source_name: [
        in: :query,
        description: "Source name",
        type: :string,
        example: "MyApp.MySource",
        required: false
      ]
    ],
    responses: %{
      201 => Created.response(LogsCreated),
      500 => ServerError.response()
    }
  )

  def create(%{assigns: %{source: source}} = conn, %{"batch" => batch}) when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def create(%{assigns: %{source: source}} = conn, %{"_json" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def create(%{assigns: %{source: source}} = conn, _slog_params) do
    conn.body_params
    |> Map.drop(~w[timestamp id])
    |> List.wrap()
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def cloudflare(%{assigns: %{source: source}} = conn, %{"batch" => batch}) when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def cloudflare(%{assigns: %{source: source}} = conn, log_params) when is_map(log_params) do
    log_params
    |> Map.drop(["source", "timestamp", "id"])
    |> List.wrap()
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def syslog(%{assigns: %{source: source}} = conn, %{"batch" => batch}) when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def generic_json(%{assigns: %{source: source}} = conn, %{"_json" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.GenericJson, source)
    |> handle(conn)
  end

  def generic_json(%{assigns: %{source: source}, body_params: event} = conn, _log_params) do
    event
    |> List.wrap()
    |> Processor.ingest(Logs.GenericJson, source)
    |> handle(conn)
  end

  def vector(%{assigns: %{source: source}} = conn, %{"_json" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Vector, source)
    |> handle(conn)
  end

  def vector(%{assigns: %{source: source}, body_params: event} = conn, _log_params) do
    event
    |> List.wrap()
    |> Processor.ingest(Logs.Vector, source)
    |> handle(conn)
  end

  def browser_reports(%{assigns: %{source: source}} = conn, %{"_json" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.BrowserReport, source)
    |> handle(conn)
  end

  def browser_reports(%{assigns: %{source: source}, body_params: event} = conn, _log_params) do
    event
    |> List.wrap()
    |> Processor.ingest(Logs.BrowserReport, source)
    |> handle(conn)
  end

  def elixir_logger(%{assigns: %{source: source}} = conn, %{"batch" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Raw, source)
    |> handle(conn)
  end

  def create_with_typecasts(%{assigns: %{source: source}} = conn, %{"batch" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.IngestTypecasting, source)
    |> handle(conn)
  end

  def vercel_ingest(%{assigns: %{source: source}} = conn, %{"_json" => batch})
      when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Vercel, source)
    |> handle(conn)
  end

  def netlify(%{assigns: %{source: source}} = conn, %{"_json" => batch}) when is_list(batch) do
    batch
    |> Processor.ingest(Logs.Netlify, source)
    |> handle(conn)
  end

  def netlify(%{assigns: %{source: source}, body_params: params} = conn, _params)
      when is_map(params) do
    [params]
    |> Processor.ingest(Logs.Netlify, source)
    |> handle(conn)
  end

  def github(%{assigns: %{source: source}, body_params: params} = conn, _params) do
    [params]
    |> Processor.ingest(Logs.Github, source)
    |> handle(conn)
  end

  defp handle(:ok, conn), do: render(conn, "index.json", message: @message)

  defp handle({:error, errors}, conn) do
    conn
    |> put_status(406)
    |> put_view(LogflareWeb.LogView)
    |> render("index.json", message: errors)
  end
end
