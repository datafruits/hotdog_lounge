defmodule Chat.Token do
  use Joken.Config

  def token_config do
    default_claims(skip: [:aud])
  end
end

