defmodule Logflare.Auth.Cache do
  @moduledoc """
  Cache for Authorization context. The keys for this cache expire in the defined
  Cachex `expiration`.
  """

  require Cachex.Spec

  alias Logflare.Auth

  def child_spec(_) do
    stats = Application.get_env(:logflare, :cache_stats, false)

    %{
      id: __MODULE__,
      start:
        {Cachex, :start_link,
         [__MODULE__, [stats: stats, expiration: Cachex.Spec.expiration(default: 30_000)]]}
    }
  end

  @spec verify_access_token(OauthAccessToken.t() | String.t()) ::
          {:ok, User.t()} | {:error, term()}
  def verify_access_token(access_token_or_api_key),
    do: apply_repo_fun(__ENV__.function, [access_token_or_api_key])

  @spec verify_access_token(OauthAccessToken.t() | String.t(), String.t() | [String.t()]) ::
          {:ok, User.t()} | {:error, term()}
  def verify_access_token(access_token_or_api_key, scopes),
    do: apply_repo_fun(__ENV__.function, [access_token_or_api_key, scopes])

  defp apply_repo_fun(arg1, arg2) do
    Logflare.ContextCache.apply_fun(Auth, arg1, arg2)
  end
end
