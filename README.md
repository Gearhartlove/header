# Header

Generate a solid-color Twitter/X banner PNG from a hex color.

The generated banner is `1500x500`, which matches the recommended Twitter/X
header image size.

## Usage

Generate a banner at the default output path:

```bash
mix header.generate "#1DA1F2"
```

This writes:

```text
output/twitter_header_1DA1F2.png
```

You can also provide a custom output path:

```bash
mix header.generate ff8800 output/orange_header.png
```

Hex colors must be 6 digits. The leading `#` is optional. Default filenames use
the normalized uppercase hex value.

## Library API

```elixir
Header.generate("#1DA1F2")
Header.generate("ff8800", output_path: "output/orange_header.png")
```
