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
        "--defaults[When true, disables interactive input prompts for options with a default]" \
        "--interactive[When false, disables interactive input prompts]" \
        "--regristry[The NPM registry to use]:registry:" \
        "--verbose[Display additional details about internal operations during execution]" \
        ":package" && ret=0
    ;;
    (analytics)
      _arguments $(_nx_arguments) \
        $opts_help \
        "1:setting_or_project" \
        "2:project_setting" && ret=0
    ;;
    (run)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration]: configuration:" \
        ": :_list_projects" && ret=0

      # @todo: Find a way to list executors (eg: nx run my-project:executor),
      # _arguments fn let us easily handle multiple args with space between,
      # but no clue how to deal with the following pattern my-project:executor.
    ;;
    (g|generate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--defaults[When true, disables interactive input prompts for options with a default]" \
        "--interactive[When false, disables interactive input prompts]" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files]" \
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
