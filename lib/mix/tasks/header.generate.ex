defmodule Mix.Tasks.Header.Generate do
  @moduledoc """
  Generates a solid-color Twitter/X banner PNG.

      mix header.generate "#1DA1F2"
      mix header.generate "#1DA1F2" output/custom_header.png
  """

  use Mix.Task

  @shortdoc "Generates a solid-color Twitter/X banner PNG"

  @impl Mix.Task
  def run([hex_color]) do
    generate(hex_color, [])
  end

  def run([hex_color, output_path]) do
    generate(hex_color, output_path: output_path)
  end

  def run(_args) do
    Mix.raise("Usage: mix header.generate HEX_COLOR [OUTPUT_PATH]")
  end

  defp generate(hex_color, opts) do
    case Header.generate(hex_color, opts) do
      {:ok, path} ->
        Mix.shell().info("Generated #{path}")

      {:error, :invalid_hex_color} ->
        Mix.raise("Invalid hex color. Use a 6-digit value like #1DA1F2.")

      {:error, {:invalid_dimension, dimension}} ->
        Mix.raise("Invalid #{dimension}. Dimensions must be positive integers.")

      {:error, reason} ->
        Mix.raise("Could not generate header: #{inspect(reason)}")
    end
  end
end
