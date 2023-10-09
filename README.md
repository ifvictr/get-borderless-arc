# Get Borderless Arc

A script that activates the borderless Arc experience.

## Demo

Video here: https://twitter.com/ifvictr/status/1711508526999498788

## How it works

This enables the `hide-scrim-border-enabled` feature flag in Arc’s preferences file.

## Setup

Open the Terminal and run the following commands:

```bash
# Download the script and make it executable
curl -O https://raw.githubusercontent.com/ifvictr/get-borderless-arc/master/get-borderless-arc.sh
chmod +x get-borderless-arc.sh

# Run it
./get-borderless-arc.sh
```

## Note

These changes will be reverted when Arc is closed, due to how it caches feature flags. When that happens, run this script again to reapply them.
