# iOS Example — SiloKit CLI

A minimal command-line tool demonstrating the [SiloKit SDK](../../sdk/swift/).

## Usage

```bash
cd examples/ios
swift build

# Read a .silo file
swift run silo-example read ../trip-planning/trip-planning.silo

# Create a new .silo file
swift run silo-example create "My Project" /tmp

# Validate a .silo file
swift run silo-example validate ../trip-planning/trip-planning.silo
```

## What It Demonstrates

- Opening and inspecting a `.silo` package with `SiloPackage.open(at:)`
- Creating a silo programmatically with the `SiloWriter` builder
- Validating packages against the spec with `SiloValidator`
