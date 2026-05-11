defmodule Header do
  @moduledoc """
  Generates solid-color Twitter/X banner images.
  """

  @twitter_width 1500
  @twitter_height 500
  @output_dir "output"
  @output_filename_prefix "twitter_header"

  @type rgb :: {0..255, 0..255, 0..255}

  @doc """
  Returns the default banner width in pixels.
  """
  def twitter_width, do: @twitter_width

  @doc """
  Returns the default banner height in pixels.
  """
  def twitter_height, do: @twitter_height

  @doc """
  Returns the default output path for a hex color.
  """
  @spec output_path_for_color(binary()) :: {:ok, Path.t()} | {:error, :invalid_hex_color}
  def output_path_for_color(hex_color) do
    with {:ok, normalized_hex} <- normalize_hex_color(hex_color) do
      {:ok, default_output_path(normalized_hex)}
    end
  end

  @doc """
  Generates a solid-color PNG banner.

  The color must be a 6-digit hex color, with or without a leading `#`.

  ## Examples

      iex> Header.generate("#1DA1F2")
      {:ok, "output/twitter_header_1DA1F2.png"}

      iex> Header.generate("#1DA1F2", output_path: "output/example.png")
      {:ok, "output/example.png"}

  """
  @spec generate(binary(), keyword()) :: {:ok, Path.t()} | {:error, term()}
  def generate(hex_color, opts \\ [])

  def generate(hex_color, opts) when is_binary(hex_color) and is_list(opts) do
    width = Keyword.get(opts, :width, @twitter_width)
    height = Keyword.get(opts, :height, @twitter_height)

    with {:ok, normalized_hex} <- normalize_hex_color(hex_color),
         :ok <- validate_dimension(width, :width),
         :ok <- validate_dimension(height, :height),
         rgb = rgb_from_hex(normalized_hex),
         output_path =
           Keyword.get_lazy(opts, :output_path, fn -> default_output_path(normalized_hex) end),
         png = build_png(rgb, width, height),
         :ok <- ensure_parent_dir(output_path),
         :ok <- File.write(output_path, png) do
      {:ok, output_path}
    end
  end

  def generate(_hex_color, _opts), do: {:error, :invalid_hex_color}

  @doc """
  Parses a 6-digit hex color into an RGB tuple.
  """
  @spec parse_hex_color(binary()) :: {:ok, rgb()} | {:error, :invalid_hex_color}
  def parse_hex_color(hex_color) when is_binary(hex_color) do
    with {:ok, normalized_hex} <- normalize_hex_color(hex_color) do
      {:ok, rgb_from_hex(normalized_hex)}
    end
  end

  def parse_hex_color(_hex_color), do: {:error, :invalid_hex_color}

  defp normalize_hex_color(hex_color) when is_binary(hex_color) do
    normalized =
      case String.trim(hex_color) do
        "#" <> value -> value
        value -> value
      end

    if Regex.match?(~r/\A[0-9a-fA-F]{6}\z/, normalized) do
      {:ok, String.upcase(normalized)}
    else
      {:error, :invalid_hex_color}
    end
  end

  defp normalize_hex_color(_hex_color), do: {:error, :invalid_hex_color}

  defp default_output_path(normalized_hex) do
    Path.join(@output_dir, "#{@output_filename_prefix}_#{normalized_hex}.png")
  end

  defp rgb_from_hex(normalized_hex) do
    <<red::binary-size(2), green::binary-size(2), blue::binary-size(2)>> = normalized_hex
    {parse_component(red), parse_component(green), parse_component(blue)}
  end

  defp parse_component(component) do
    {value, ""} = Integer.parse(component, 16)
    value
  end

  defp validate_dimension(value, _name) when is_integer(value) and value > 0, do: :ok
  defp validate_dimension(_value, name), do: {:error, {:invalid_dimension, name}}

  defp ensure_parent_dir(path) do
    case Path.dirname(path) do
      "." -> :ok
      dir -> File.mkdir_p(dir)
    end
  end

  defp build_png({red, green, blue}, width, height) do
    image_data = build_image_data({red, green, blue}, width, height)

    [
      png_signature(),
      chunk("IHDR", ihdr(width, height)),
      chunk("IDAT", :zlib.compress(image_data)),
      chunk("IEND", "")
    ]
    |> IO.iodata_to_binary()
  end

  defp build_image_data({red, green, blue}, width, height) do
    row = [<<0>>, :binary.copy(<<red, green, blue>>, width)]
    :binary.copy(IO.iodata_to_binary(row), height)
  end

  defp png_signature, do: <<137, 80, 78, 71, 13, 10, 26, 10>>

  defp ihdr(width, height) do
    <<width::unsigned-big-32, height::unsigned-big-32, 8, 2, 0, 0, 0>>
  end

  defp chunk(type, data) when byte_size(type) == 4 do
    crc = :erlang.crc32(type <> data)
    <<byte_size(data)::unsigned-big-32, type::binary, data::binary, crc::unsigned-big-32>>
  end
end
