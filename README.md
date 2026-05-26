# Hotdog Lounge

[![Build Status](https://img.shields.io/travis/datafruits/hotdog_lounge.svg?style=flat)](http://travis-ci.org/datafruits/hotdog_lounge)

datafruits.fm chat server, simply some modifications to
https://github.com/chrismccord/phoenix_chat_example

## Installing Elixir & Erlang

This project uses [asdf](https://asdf-vm.com) to manage language versions. The required versions are pinned in `.tool-versions`:

- **Erlang 26.2**
- **Elixir 1.15.8-otp-26**
- **Node.js 22.18.0**

To install them:

```bash
# Install asdf (if not already installed)
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
# Add to your shell profile: . "$HOME/.asdf/asdf.sh"

# Add plugins
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add nodejs

# Install the versions specified in .tool-versions
asdf install
```

> **Note:** Building Erlang requires some system dependencies. See the [erlang-otp build guide](https://github.com/asdf-vm/asdf-erlang#before-asdf-install) for your OS.

You should also have a redis server running for the app to connect to.

1. Clone this repo, then cd to the new directory
2. Install dependencies with `mix deps.get`
3. Source the environment variables in the .env file with `source .env`
4. Start server with `mix phx.server`

To connect to the local server from the datafruits app, set the environment variable `CHAT_SOCKET_URL` to `ws://localhost:4000/socket`, in the .env file in the datafruits app.

```
$ cd ~/src/datafruits
$ echo "CHAT_SOCKET_URL=ws://localhost:4000/socket" >> .env
```
