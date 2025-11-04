# Cursor NixOS Flake

A clean, simple NixOS flake for packaging the [Cursor](https://cursor.sh/) AI-powered code editor.

## Auto checks for updates every day

## 📦 What This Flake Provides

This flake packages Cursor as a Nix package that can be easily integrated into any NixOS system or used standalone.

**Packages:**
- `packages.x86_64-linux.cursor` - The Cursor editor with full desktop integration
- `packages.x86_64-linux.default` - Same as cursor (default package)

**Features:**
- ✅ **Complete Desktop Integration** - Includes icon extraction and desktop entry
- ✅ **Icon Support** - Automatically extracts and installs Cursor icon from AppImage
- ✅ **MIME Type Associations** - Supports opening various file types with Cursor
- ✅ **Version Management** - Built-in version checking (`cursor --version`)
- ✅ **Update Disabled** - Prevents Cursor's built-in updater (managed by Nix instead)

## 🚀 Quick Start

### Using in Your NixOS Configuration

Add this flake as an input to your main system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cursor-flake = {
      url = "path:/path/to/cursor-flake"; # Update this path
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ... other inputs
  };

  outputs = { nixpkgs, cursor-flake, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        ./configuration.nix
        {
          # Add Cursor to your system packages
          environment.systemPackages = with pkgs; [
            cursor-flake.packages.x86_64-linux.cursor
            # ... other packages
          ];
        }
        # Or in home-manager:
        {
          home-manager.users.your-username = { pkgs, ... }: {
            home.packages = [
              cursor-flake.packages.x86_64-linux.cursor
              # ... other packages
            ];
          };
        }
      ];
    };
  };
}
```

### Standalone Usage

You can also build and run Cursor directly from this flake:

```bash
# Build the package
nix build .#cursor

# Run Cursor
./result/bin/cursor

# Or run directly without building
nix run .#cursor
```

## 🔄 Updating Cursor

When a new version of Cursor is released, use the included update script:

### Method 1: Automatic with URL
```bash
./update-cursor.sh "https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-1.6.0-x86_64.AppImage"
```

### Method 2: Interactive
```bash
./update-cursor.sh
# Follow the prompts to enter version or URL
```

### Method 3: Version number
```bash
./update-cursor.sh "1.6.0"
# Script will prompt for the full download URL
```

The script will automatically:
- ✅ Update the version in `flake.nix`
- ✅ Update the download URL
- ✅ Fetch and update the SHA256 hash
- ✅ Test that the package builds correctly
- ✅ Verify the version is correct
- ✅ Confirm icon extraction and desktop entry creation

## 📁 Repository Structure

```
cursor-flake/
├── flake.nix              # Main flake configuration (package-only)
├── flake.lock             # Flake lock file
├── update-cursor.sh       # Update script for new versions
├── README.md              # This file
├── LICENSE                # MIT License
└── archive-old-system-configs/  # Archived old system configs
    ├── configuration.nix  # (archived - was for full system setup)
    ├── home.nix          # (archived - was for home-manager)
    └── ...               # (other archived files)
```

## 🔧 Development

### Testing Changes

```bash
# Test that the package builds
nix build .#cursor

# Test that it runs
./result/bin/cursor --version

# Clean build (removes cached results)
nix build .#cursor --rebuild
```

### Manual Updates

If you prefer to update manually:

1. Get the new AppImage URL from [cursor.sh](https://cursor.sh)
2. Update version and URL in `flake.nix`
3. Get the new hash:
   ```bash
   nix-prefetch-url "https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-X.Y.Z-x86_64.AppImage"
   ```
4. Update the hash in `flake.nix`
5. Test: `nix build .#cursor`

## 🏗️ Architecture

This flake uses `appimageTools.extract` and `appimageTools.wrapType2` to properly package the Cursor AppImage with all necessary dependencies and desktop integration. The packaging process:

- **Extracts AppImage contents** to access embedded icons and metadata
- **Bundles required system libraries** using appimageTools
- **Installs icons** to standard XDG locations (`/share/pixmaps`, `/share/icons/hicolor/`)
- **Creates desktop entry** with proper MIME type associations
- **Sets up environment variables** for optimal compatibility
- **Disables built-in updater** (managed by Nix instead)
- **Creates temporary directories** to avoid permission issues
- **Provides clean `cursor` command** with version support

## 🆚 Migration from Complex Structure

This flake was simplified from a previous version that included full NixOS system configurations. The old structure has been archived in `archive-old-system-configs/` for reference.

**Benefits of the new structure:**
- ✅ **Focused**: Just packages Cursor, nothing else
- ✅ **Reusable**: Easy to integrate into any NixOS system
- ✅ **Maintainable**: No complex system configurations to maintain
- ✅ **Safe**: No risk of breaking your system during updates
- ✅ **Consistent**: Matches the pattern of other package flakes

## 📜 License

MIT License - see [LICENSE](LICENSE) file.

## 🤝 Contributing

Issues and pull requests are welcome! Please test any changes by running:

```bash
nix build .#cursor
./result/bin/cursor --version
```

## 🔗 Related

- [Cursor Official Website](https://cursor.sh/)
- [NixOS Documentation](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)