# celld-nix

A Nix flake for [celld](https://github.com/denoland/celld), Deno's self-hosted,
distributed Durable Objects server.

celld embeds V8, so building it from source is not practical. This flake
packages the prebuilt binaries from the upstream GitHub releases instead.

| System           | Release asset                          |
| ---------------- | -------------------------------------- |
| `aarch64-darwin` | `celld-aarch64-apple-darwin.gz`        |
| `aarch64-linux`  | `celld-aarch64-unknown-linux-gnu.gz`   |
| `x86_64-linux`   | `celld-x86_64-unknown-linux-gnu.gz`    |

## Usage

Run it once:

```sh
nix run github:akshatagarwl/celld-nix -- --help
```

### As a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    celld-nix = {
      url = "github:akshatagarwl/celld-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, celld-nix, ... }: {
    # for example, in a home-manager or NixOS module:
    # home.packages = [ celld-nix.packages.${pkgs.stdenv.hostPlatform.system}.celld ];
  };
}
```

### As an overlay

```nix
nixpkgs.overlays = [ celld-nix.overlays.default ];
# then use pkgs.celld
```

## Notes

- On startup celld may print a jemalloc `background_thread` warning on macOS.
  It is harmless.
- There is no binary cache yet; Nix downloads the release asset directly.
  A public cache is tracked in
  [akshatagarwl/nix#20](https://github.com/akshatagarwl/nix/issues/20).

## Updating

```sh
nix run .#update            # latest release
nix run .#update -- 0.6.3   # a specific version
```

The script rewrites `pkgs/sources.json` with the new version and hashes.

## License

The Nix packaging in this repository is MIT licensed. celld itself is
Apache-2.0; its `LICENSE` and `NOTICE` are installed to
`share/licenses/celld/`.
