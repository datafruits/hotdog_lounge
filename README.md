# Hotdog Lounge

[![Build Status](https://img.shields.io/travis/datafruits/hotdog_lounge.svg?style=flat)](http://travis-ci.org/datafruits/hotdog_lounge)

datafruits.fm chat server, simply some modifications to
https://github.com/chrismccord/phoenix_chat_example

[Install elixir](https://elixir-lang.org/install.html) if you haven't already.

1. Clone this repo, then cd to the new directory
2. Install dependencies with `mix deps.get`
3. Start server with `mix phoenix.server`

To connect to the local server from the datafruits app, set the environment variable `CHAT_SOCKET_URL` to `ws://localhost:4000/socket`, in the .env file in the datafruits app.

```
$ cd ~/src/datafruits
$ echo "CHAT_SOCKET_URL=ws://localhost:4000/socket" >> .env
```
