# Nx completion plugin for Zsh

> This plugin bring Nx autocompletion to Zsh.

![demo](https://user-images.githubusercontent.com/8522558/111908149-67e8d780-8a58-11eb-9343-691f6d664163.gif)

## Features

- **Dynamic command parsing**: Automatically discovers commands from `nx --help` output
- **Intelligent caching**: Uses Nx's built-in project graph cache when available
- **Auto-updating completions**: Commands and options stay current with your Nx version
- **Workspace executor integration**: Dynamically extracts completion options from project executors
- Commands and arguments autocompletion
- Projects, targets, and generators autocompletion
- Support different workspace versions
- **Performance optimized**: Caches parsed commands and reuses project graph data

## Performance Improvements

- **Project graph caching**: Checks for `.nx/workspace-data/project-graph.json` before calling `nx graph`
- **Dynamic command discovery**: Parses `nx --help` instead of maintaining static command lists
- **Workspace-aware options**: Extracts options from project executors for enhanced completion
- **Zsh completion caching**: Uses zsh's built-in caching system for better performance
- **All commands dynamic**: Every command now uses dynamic parsing for maximum flexibility

## Install

### Prerequisit

Install [`jq`](https://stedolan.github.io/jq/) dependency:

```shell
apt install jq
```

On MacOS you can install with:

```shell
brew install jq
```

> **Note**: [`jq`](https://stedolan.github.io/jq/) is a lightweight command-line JSON processor used to manipulate the workspace graph.

### As an [Oh My ZSH!](https://github.com/robbyrussell/oh-my-zsh) custom plugin

Clone the repository into the custom plugins directory:

```shell
git clone git@github.com:jscutlery/nx-completion.git ~/.oh-my-zsh/custom/plugins/nx-completion
```

Then load it as a plugin in your `.zshrc`:

```shell
plugins+=(nx-completion)
```

### Manually

Clone this repository somewhere (`~/.nx-completion` for example):

```shell
git clone git@github.com:jscutlery/nx-completion.git ~/.nx-completion
```

Then source it in your `.zshrc`:

```shell
source ~/.nx-completion/nx-completion.plugin.zsh
```

## Cache Management

When reinstalling or updating the nx-completion plugin, you may need to flush the zsh completion cache to ensure you're using the latest version.

### Quick Cache Clear

The simplest way to clear the zsh completion cache:

```shell
# Clear zsh completion cache and rebuild
rm -rf ~/.zcompdump* && autoload -U compinit && compinit -D
```

### Using the Clear Cache Script

Run the included script for automated cache clearing:

```shell
# Make executable and run
chmod +x clear-cache.zsh
./clear-cache.zsh
```

## License

This project is MIT licensed.
