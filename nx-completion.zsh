w_defs=(
  "$PWD/angular.json"
  "$PWD/worspace.json"
)

# @todo: Document.
_nx_command() {
  echo "${words[2]}"
}

# @todo: Document.
_nx_arguments() {
  if zstyle -t ":completion:${curcontext}:" option-stacking; then
    print -- -s
  fi
}

# Check if at least one of w_defs are present in working dir.
_check_workspace_def() {
  integer ret=1
  local a_def=${w_defs[1]}
  local w_def=${w_defs[2]}

  if [[ ! -f $a_def && ! -f $w_def ]]; then 
    echo 1
  else 
    echo 0 && ret=0
  fi
  return ret
}

# Get workspace defition path.
# Assumes _check_workspace_def get called before.
_workspace_def() {
  integer ret=1
  local a_def=${w_defs[1]}
  local w_def=${w_defs[2]}

  if [[ -f $a_def ]]; then
    echo $a_def && ret=0
  else
    echo $w_def && ret=0
  fi
  return ret
}

# List projects within workspace definition file,
# uses jq dependency to parse and manipulate JSON file
# instead of using a dirty grep or sed.
_list_projects() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local def=$(_workspace_def)
  local -a projects
  
  # Parse workspace def,
  # create JSON array from projects name,
  # and transform to zsh array.
  projects=($(< $def | jq '.projects' | jq -r 'keys[]'))

  # Autocomplete projects as an option$ (eg: nx run demo...) and append ':'.
  _describe -t nx-projects "projects option" projects -qS ":" && ret=0 
  return ret
}

_list_executors() {
  [[ $PREFIX = -* ]] && return 1
  return 0
  # @todo: grab project executors. 
}

_list_generators() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local -a output generators
  
  output=(${(f)"$(nx g 2>&1)"})
  # Split output to grab generators from default schematics.
  # @todo: handle no default set.
  generators=(${(s/(default):/)output})
  generators=(${generators[2]})
  generators=(${(s/ /)generators})
 
  # Run completion.
  _describe -t nx-generators "Nx generators" generators && ret=0
  return ret
}

_nx_commands() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local -a lines commands
  
  # Call nx to get the command list.
  lines=(${(f)"$(_call_program commands nx 2>&1)"})
  
  # Format output: remove line breaks etc.
  commands=(${${${(M)${lines[$((${lines[(i)*Commands:]} + 1)),-1]}:# *}## #}/ ##/:})

  # Run completion.
  _describe -t nx-commands "Nx commands" commands && ret=0
  return ret
}

_nx_command() {
  integer ret=1
  local -a _command_args opts_help

  opts_help=("--help[Shows a help message for this command in the console]")
  
  case "$words[1]" in
    (add)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--defaults[When true, disables interactive input prompts for options with a default.]" \
        "--interactive[When false, disables interactive input prompts.]" \
        "--regristry[The NPM registry to use.]:registry:" \
        "--verbose[Display additional details about internal operations during execution.]" \
        ":package" && ret=0
    ;;
    (analytics)
      _arguments $(_nx_arguments) \
        $opts_help \
        "1:setting_or_project" \
        "2:project_setting" && ret=0
    ;;
    (b|build)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--allowed-common-js-dependencies[A list of CommonJS packages that are allowed to be used without a build time warning.]:packages:" \
        "--aot[Build using Ahead of Time compilation.]" \
        "--base-href[Base url for the application being built.]" \
        "--verbose[Display additional details about internal operations during execution.]" \
        "--build-optimizer[Enables '@angular-devkit/build-optimizer' optimizations when using the 'aot' option.]" \
        "--common-chunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration, setting this explicitly overrides the \"--prod\" flag.]:configuration:" \
        "--cross-origin[Define the crossorigin attribute setting of elements that provide CORS support.]" \
        "--delete-output-path[Delete the output path before building.]" \
        "--deploy-url[URL where files will be deployed.]" \
        "--deploy-url[URL where files will be deployed.]:deploy_url:" \
        "--experimental-rollup-pass[Concatenate modules with Rollup before bundling them with Webpack.]" \
        "--extract-css[Extract CSS from global styles into '.css' files instead of '.js'.]" \
        "--extract-licenses[Extract all licenses in a separate file.]" \
        "--fork-type-checker[Run the TypeScript type checker in a forked process.]" \
        "--i18n-file[Localization file to use for i18n.]:file:" \
        "--i18n-format[Format of the localization file specified with --i18n-file.]:format:" \
        "--i18n-locale[Locale to use for i18n.]:locale:" \
        "--i18n-missing-translation[How to handle missing translations for i18n.]:handler:" \
        "--index[Configures the generation of the application's HTML index.]:index:" \
        "--lazy-modules[List of additional NgModule files that will be lazy loaded. Lazy router modules will be discovered automatically.]:modules:" \
        "--localize" \
        "--main[The full path for the main entry point to the app, relative to the current workspace.]:path:" \
        "--named-chunks[Use file name for lazy loaded chunks.]:filename:" \
        "--ngsw-config-path[Path to ngsw-config.json.]:filepath:" \
        "--optimization[Enables optimization of the build output.]" \
        "--output-hashing[Define the output filename cache-busting hashing mode.]:mode:" \
        "--output-path[The full path for the new output directory, relative to the current workspace.]:path:" \
        "--poll[Enable and define the file watching poll time period in milliseconds.]" \
        "--polyfills[The full path for the polyfills file, relative to the current workspace.]:filepath:" \
        "--preserve-symlinks[Do not use the real path when resolving modules.]" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console while building.]" \
        "--resources-output-path[The path where style resources will be placed, relative to outputPath.]:path:" \
        "--service-worker[Generates a service worker config for production builds.]" \
        "--show-circular-dependencies[Show circular dependency warnings on builds.]" \
        "--source-map[Output sourcemaps.]" \
        "--stats-json[Generates a 'stats.json' file which can be analyzed using tools such as 'webpack-bundle-analyzer'.]" \
        "--subresource-integrity[Enables the use of subresource integrity validation.]" \
        "--ts-config[The full path for the TypeScript configuration file, relative to the current workspace.]:path:" \
        "--vendor-chunk[Use a separate bundle containing only vendor libraries.]" \
        "--verbose[Adds more details to output logging.]" \
        "--watch[Run build when files change.]" \
        "--web-worker-ts-config[TypeScript configuration for Web Worker modules.]:config:" \
        ":project" && ret=0
    ;;
    (run)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        ": :_list_projects" && ret=0

      # @todo: Find a way to list executors (eg: nx run my-project:executor),
      # _arguments fn let us easily handle multiple args with space between,
      # but no clue how to deal with the following pattern my-project:executor.
    ;;
    (g|generate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--defaults[When true, disables interactive input prompts for options with a default.]" \
        "--interactive[When false, disables interactive input prompts.]" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results.]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files.]" \
        ": :_list_generators" && ret=0
    ;;
  esac

  return ret
}

_nx_completion() {
  # Display an error if no workspace definition found.
  [[ $(_check_workspace_def) -eq 1 ]] && echo "error: workspace definition not found" && return 1

  integer ret=1
  typeset -A opt_args
  local -a _command_args opts_help
  
  opts_help=("--help[Shows a help message for this command in the console]")
  
  _arguments $(_nx_arguments) \
    $opts_help \
    "--version[Show version number]" \
    ": :->root_command" \
    "*:: :->command" && ret=0

  case $state in
      (root_command)
        _nx_commands && ret=0
      ;;
      (command)
        _nx_command && ret=0
      ;;
  esac

  return ret
}
compdef _nx_completion nx
