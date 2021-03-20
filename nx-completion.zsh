w_defs=(
  "$PWD/angular.json"
  "$PWD/worspace.json"
)

_nx_command() {
  echo "${words[2]}"
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
  _describe -t projects "projects option" projects -qS ":" && ret=0 
  return ret
}

_list_executors() {
  return 0
  # @todo: grab project executors. 
}

_list_generators() {
  return 0
  # @todo: grab project genrators, doable with parsing nx generate result
}

_nx_arguments() {
  if zstyle -t ":completion:${curcontext}:" option-stacking; then
    print -- -s
  fi
}

_nx_commands() {
  local -a lines
  # Run nx to get subcommand list output.
  lines=(${(f)"$(_call_program commands nx 2>&1)"})
  
  # Format output for the completion.
  _nx_subcommands=(${${${(M)${lines[$((${lines[(i)*Commands:]} + 1)),-1]}:# *}## #}/ ##/:})

  # Run completion.
  _describe -t nx-commands "Nx commands" _nx_subcommands
}

_nx_command() {
  integer ret=1
  local -a _command_args opts_help

  opts_help=("--help[Shows a help message for this command in the console]")
  
  case "$words[1]" in
    (run)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration]: configuration:" \
        ": :_list_projects"
      ret=0

      # @todo: Find a way to list executors (eg: nx run my-project:executor),
      # Function _arguments let us easily handle multiple args with space between,
      # but no clue how to deal with the following pattern my-project:executor.
      # 
      # case $state in
      #   (*)
      #     _list_executors && ret=0
      #   ;;
      # esac
    ;;
    (g|generate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--defaults[When true, disables interactive input prompts for options with a default]" \
        "--interactive[When false, disables interactive input prompts]" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files]" \
        ": :->generator"
      case $state in
        (generator)
          _list_generators && ret=0
        ;;
      esac
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
  
  _arguments $(_nx_arguments) -C \
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
