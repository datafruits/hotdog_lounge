defmodule Chat.Token do
  @moduledoc """
  Token configuration for Chat application using Joken 2.x
  """
  
  def generate_and_sign(claims \\ %{}) do
    signer = Joken.Signer.create("HS256", secret_key())
    
    Joken.generate_and_sign(claims, signer)
  end
  
  def verify_and_validate(token) do
    signer = Joken.Signer.create("HS256", secret_key())
    
    Joken.verify_and_validate(token, signer)
  end
  
  defp secret_key do
    Application.get_env(:chat, :secret_key_base) || "default_secret_key"
  end
end

