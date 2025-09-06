defmodule HotdogLounge.Dingers do
  def random_dingers do
    Enum.take_random(dingers(), 3) |> Enum.join(" ")
  end

  defp dingers() do
    [
      ":O",
      ":3",
      ">:O",
      "B-)",
      "XD",
      ":)",
      "⎝｡⌓°⎞",
      "ᐡ𖦹‎ ̫ 𖦹‎ᐡ",
      "o_O",
      "O_o",
      "/o/",
      "\\o/",
      "\\o\\",
    ]
  end
end
