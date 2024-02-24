# Speakerlist

A speakerlist for the division meetings at the [computer science division](https://www.dtek.se) at Chalmers. Made using the [Phoenix framework](https://www.phoenixframework.org/).

## Prerequisites

Make sure you have Elixir and Phoenix installed. For the installation guide, check out the [phoenix documentation](https://hexdocs.pm/phoenix/installation.html)

## Start speakerlist server

To start your the speakerlist:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Hotkeys

This application features hotkeys as opposed to UI elements for most actions. The hotkeys are as follows.

* **\+** : Add a new topic to the stack.

* **-** : Pop topic from the stack

* **.** : Start/stop the timer for the current speaker.

* **§** : Dequeue the current speaker.

* **<** : Save the current stats to file. They can be found in `save.json`

* **AltGr** : Set focus to the name input

* **Insert** : Adjourn

## Learn more

  * Phoenix official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
