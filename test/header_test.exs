defmodule HeaderTest do
  use ExUnit.Case

  test "parses hex colors with and without leading hash" do
    assert Header.parse_hex_color("#1DA1F2") == {:ok, {0x1D, 0xA1, 0xF2}}
    assert Header.parse_hex_color("ff8800") == {:ok, {0xFF, 0x88, 0x00}}
  end

  test "builds color-specific output paths" do
    assert Header.output_path_for_color("#1da1f2") == {:ok, "output/twitter_header_1DA1F2.png"}
    assert Header.output_path_for_color("ff8800") == {:ok, "output/twitter_header_FF8800.png"}
  end

  test "rejects invalid hex colors" do
    assert Header.parse_hex_color("#12345") == {:error, :invalid_hex_color}
    assert Header.parse_hex_color("#1234567") == {:error, :invalid_hex_color}
    assert Header.parse_hex_color("##123456") == {:error, :invalid_hex_color}
    assert Header.parse_hex_color("#12GG56") == {:error, :invalid_hex_color}
  end

  test "generates a solid color PNG at the requested path" do
    output_path = tmp_path("nested/twitter_header.png")

    assert Header.generate("#1DA1F2", output_path: output_path) == {:ok, output_path}
    assert File.exists?(output_path)

    png = File.read!(output_path)

    assert <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> = png
    assert {Header.twitter_width(), Header.twitter_height()} == png_dimensions(png)
    assert {0x1D, 0xA1, 0xF2} == first_pixel(png)
  end

  test "generates a color-specific filename by default" do
    tmp_dir = tmp_path("default-output")
    File.mkdir_p!(tmp_dir)

    File.cd!(tmp_dir, fn ->
      output_path = "output/twitter_header_FF8800.png"

      assert Header.generate("ff8800") == {:ok, output_path}
      assert File.exists?(output_path)
    end)
  end

  test "returns an error and does not write a file for invalid colors" do
    output_path = tmp_path("invalid.png")

    assert Header.generate("not-a-color", output_path: output_path) ==
             {:error, :invalid_hex_color}

    refute File.exists?(output_path)
  end

  defp tmp_path(name) do
    Path.join([System.tmp_dir!(), "header-test-#{System.unique_integer([:positive])}", name])
  end

  defp png_dimensions(png) do
    <<_signature::binary-size(8), 13::unsigned-big-32, "IHDR", ihdr::binary-size(13),
      _crc::unsigned-big-32, _rest::binary>> = png

    <<width::unsigned-big-32, height::unsigned-big-32, 8, 2, 0, 0, 0>> = ihdr
    {width, height}
  end

  defp first_pixel(png) do
    <<_signature::binary-size(8), 13::unsigned-big-32, "IHDR", _ihdr::binary-size(13),
      _ihdr_crc::unsigned-big-32, idat_size::unsigned-big-32, "IDAT",
      compressed::binary-size(idat_size), _idat_crc::unsigned-big-32, _rest::binary>> = png

    <<0, red, green, blue, _rest::binary>> = :zlib.uncompress(compressed)
    {red, green, blue}
  end
end
