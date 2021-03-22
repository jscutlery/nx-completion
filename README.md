# Nx completion plugin for Zsh

![demo](https://user-images.githubusercontent.com/8522558/111908149-67e8d780-8a58-11eb-9343-691f6d664163.gif)

:warning: This plugin is at its early stages.

## Install

Install the dependency:

```sh
apt install jq
```

> Note: `jq` is a lightweight command-line JSON processor, more info [here](https://stedolan.github.io/jq/).

Clone the repository into the custom plugins directory:

```sh
git clone git@github.com:jscutlery/nx-completion.git ~/.oh-my-zsh/custom/plugins/nx-completion
```

Then load it as a plugin in your `.zshrc`:

```sh
plugins+=(nx-completion)
```

## License

This project is MIT licensed.