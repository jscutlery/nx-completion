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

# Describe the cache policy.
_nx_caching_policy() {
  oldp=( "$1"(Nmh+1) ) # 1 hour
  (( $#oldp ))
}

# Check if at least one of w_defs are present in working dir.
_check_workspace_def() {
  local w_defs=(
    "$PWD/angular.json"
    "$PWD/worspace.json"
  )
  local a_def=${w_defs[1]}
  local w_def=${w_defs[2]}

  if [[ -f $a_def || -f $w_def ]]; then 
    return 0
  else 
    return 1
  fi
}

# Get workspace defition path.
# Assumes _check_workspace_def get called before.
_workspace_def() {
  integer ret=1
  local w_defs=(
    "$PWD/angular.json"
    "$PWD/worspace.json"
  )
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

  # Autocomplete projects as an option$ (eg: nx run demo...).
  _describe -t nx-projects "Nx projects" projects && ret=0 
  return ret
}

_list_project_executors() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local -a def projects project_executors
  
  project_executors=()
  def=$(_workspace_def)
  projects=($(< $def | jq '.projects' | jq -r 'keys[]'))

  for p in $projects; do 
    local -a executors
    executors=($(< $def | jq ".projects[\"$p\"].architect" | jq -r 'keys[]'))
    for e in $executors; do
      project_executors+=("$p\:$e")
    done
  done

  _describe -t project-executors 'Project executors' project_executors && ret=0
  return ret
}

_list_generators() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local -a output generators
  
  output=(${(f)"$(nx g 2>&1)"})

  # @todo: handle no default project defined.
  # @todo: maybe there is better way to grab all workspace generators.

  # Split output to grab generators from default schematics.
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

  local cache_policy

  zstyle -s ":completion:${curcontext}:" cache-policy cache_policy
  if [[ -z "$cache_policy" ]]; then
    zstyle ":completion:${curcontext}:" cache-policy _nx_caching_policy
  fi

  if ( [[ ${+_nx_subcommands} -eq 0 ]] || _cache_invalid nx_subcommands ) \
    && ! _retrieve_cache nx_subcommands
  then
    local -a lines
    # Call CLI to get the command list.
    lines=(${(f)"$(_call_program commands nx 2>&1)"})
    
    # Format output: remove line breaks etc.
    _nx_subcommands=(${${${(M)${lines[$((${lines[(i)*Commands:]} + 1)),-1]}:# *}## #}/ ##/:})
    
    # Add Nx related commands.
    # @todo: Could be directly grabbed from parsing nx --help command.
    _nx_subcommands+=(
      'affected:Run task for affected projects'
      'run-many:Run task for multiple projects'
      'affected\:apps:Print applications affected by changes'
      'affected\:libs:Print libraries affected by changes'
      'affected\:build:Build applications and publishable libraries affected by changes'
      'affected\:test:Test projects affected by changes'
      'affected\:e2e:Run e2e tests for the applications affected by changes'
      'affected\:lint:Lint projects affected by changes'
      'print-affected:Graph execution plan'
      'dep-graph:Graph dependencies within workspace'
      'format\:check:Check for un-formatted files'
      'format\:write:Overwrite un-formatted files'
      'workspace-lint:[files...] Lint workspace or list of files'
      'workspace-schematic:[name] Runs a workspace schematic from the tools/schematics directory'
      'migrate:Creates a migrations file or runs migrations from the migrations file'
      'report:Reports useful version numbers to copy into the Nx issue template'
      'list:[plugin] Lists installed plugins, capabilities of installed plugins and other available plugins'
    )
    (( $#_nx_subcommands > 2 )) && _store_cache nx_subcommands _nx_subcommands
  fi

  # Run completion.
  _describe -t nx-commands "Nx commands" _nx_subcommands && ret=0
  return ret
}

_nx_command() {
  integer ret=1
  local -a _command_args opts_help opts_affected

  opts_help=("--help[Shows a help message for this command in the console]")
  
  case "$words[1]" in
    (add|affected|affected:apps|affected:build|affected:e2e|affected:libs|affected:lint|affected:test|format|format:write|format:check|print-affected)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--base[Base of the current branch (usually master).]:sha:" \
        "--head[Latest commit of the current branch (usually HEAD).]:sha:" \
        "--files[Change the way Nx is calculating the affected command by providing directly changed files, list of files delimited by commas.]:files:_files" \
        "--uncommitted[Uncommitted changes.]" \
        "--untracked[Untracked changes.]" \
        "--version[Show version number.]" \
        "--target[Task to run for affected projects.]:target:" \
        "--parallel[Parallelize the command.]" \
        "--maxParallel[Max number of parallel processes.]:count:" \
        "--all[All projects.]" \
        "--exclude[Exclude certain projects from being processed.]:projects:_list_projects" \
        "--runner[This is the name of the tasks runner configured in nx.json.]:runner:" \
        "--skip-nx-cache[Rerun the tasks even when the results are available in the cache.]" \
        "--configuration[This is the configuration to use when performing tasks on projects.]:configuration:" \
        "--only-failed[Isolate projects which previously failed.]" \
        "--verbose[Print additional error stack trace on failure.]" && ret=0
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
        "--deploy-url[URL where files will be deployed.]:deploy_url:" \
        "--experimental-rollup-pass[Concatenate modules with Rollup before bundling them with Webpack.]" \
        "--extract-css[Extract CSS from global styles into '.css' files instead of '.js'.]" \
        "--extract-licenses[Extract all licenses in a separate file.]" \
        "--fork-type-checker[Run the TypeScript type checker in a forked process.]" \
        "--i18n-file[Localization file to use for i18n.]:file:_files" \
        "--i18n-format[Format of the localization file specified with --i18n-file.]:format:" \
        "--i18n-locale[Locale to use for i18n.]:locale:" \
        "--i18n-missing-translation[How to handle missing translations for i18n.]:handler:" \
        "--index[Configures the generation of the application's HTML index.]:index:" \
        "--lazy-modules[List of additional NgModule files that will be lazy loaded. Lazy router modules will be discovered automatically.]:files:_files" \
        "--localize" \
        "--main[The full path for the main entry point to the app, relative to the current workspace.]:path:_files" \
        "--named-chunks[Use file name for lazy loaded chunks.]:filename:" \
        "--ngsw-config-path[Path to ngsw-config.json.]:filepath:" \
        "--optimization[Enables optimization of the build output.]" \
        "--output-hashing[Define the output filename cache-busting hashing mode.]:mode:" \
        "--output-path[The full path for the new output directory, relative to the current workspace.]:path:_path_files -/" \
        "--poll[Enable and define the file watching poll time period in milliseconds.]" \
        "--polyfills[The full path for the polyfills file, relative to the current workspace.]:file:_files" \
        "--preserve-symlinks[Do not use the real path when resolving modules.]" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console while building.]" \
        "--resources-output-path[The path where style resources will be placed, relative to outputPath.]:path:_path_files -/" \
        "--service-worker[Generates a service worker config for production builds.]" \
        "--show-circular-dependencies[Show circular dependency warnings on builds.]" \
        "--source-map[Output sourcemaps.]" \
        "--stats-json[Generates a 'stats.json' file which can be analyzed using tools such as 'webpack-bundle-analyzer'.]" \
        "--subresource-integrity[Enables the use of subresource integrity validation.]" \
        "--ts-config[The full path for the TypeScript configuration file, relative to the current workspace.]:file:_files" \
        "--vendor-chunk[Use a separate bundle containing only vendor libraries.]" \
        "--verbose[Adds more details to output logging.]" \
        "--watch[Run build when files change.]" \
        "--web-worker-ts-config[TypeScript configuration for Web Worker modules.]:file:_files" \
        ":project:_list_projects" && ret=0
    ;;
    (config)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-g --global)"{-g,--global}"[When true, accesses the global configuration in the caller's home directory.]" \
        ":json_path" \
        "::value" && ret=0
    ;;
    (dep-graph)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--version[Show version number.]" \
        "--file[Output file (e.g. --file=output.json or --file=dep-graph.html).]:file:_files" \
        "--focus[Use to show the dependency graph for a particular project and every node that is either an ancestor or a descendant.]:project:_list_projects" \
        "--exclude[List of projects delimited by commas to exclude from the dependency graph.]:projects:_list_projects:" \
        "--groupByFolder[Group projects by folder in dependency graph.]" \
        "--host[Bind the dep graph server to a specific ip address.]:host:_hosts" \
        "--port[Bind the dep graph server to a specific port.]:port" && ret=0
    ;;
    (deploy)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        ":project:_list_projects" && ret=0
    ;;
    (d|doc)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-s --search)"{-s,--search}"[When true, searches all of angular.io. Otherwise, searches only API reference documentation.]" \
        "--version[Contains the version of Angular to use for the documentation. If not provided, the command uses your current Angular core version.]:version:" \
        ":keyword" && ret=0
    ;;
    (e|e2e)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--base-url[Use this to pass directly the address of your distant server address with the port running your application.]:url:" \
        "--ci-build-id[A unique identifier for a run to enable grouping or parallelization.]:id:" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--cypress-config[The path of the Cypress configuration json file.]:file:_files" \
        "--dev-server-target[Dev server target to run tests against.]:target:" \
        "--exit[Whether or not the Cypress Test Runner will stay open after running tests in a spec file.]" \
        "--group[A named group for recorded runs in the Cypress dashboard.]:group:" \
        "--headless[Whether or not to open the Cypress application to run the tests. If set to 'true', will run in headless mode.]" \
        "--ignore-test-files[A String or Array of glob patterns used to ignore test files that would otherwise be shown in your list of tests. Cypress uses minimatch with the options: {dot: true, matchBase: true}.]:pattern:" \
        "--key[The key cypress should use to run tests in parallel/record the run (CI only).]:value:" \
        "--parallel[Whether or not Cypress should run its tests in parallel (CI only).]:value:" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--record[Whether or not Cypress should record the results of the tests.]" \
        "--reporter[The reporter used during cypress run.]:reporter:" \
        "--reporter-options[The reporter options used. Supported options depend on the reporter.]:options:" \
        "--spec[A comma delimited glob string that is provided to the Cypress runner to specify which spec files to run. i.e. '**examples/**,**actions.spec**.]:spec:" \
        "--ts-config[The path of the Cypress tsconfig configuration json file.]:file:_files" \
        "--watch[Recompile and run tests when files change.]" \
        ":project:_list_projects" && ret=0
    ;;
    (xi18n|i18n-extract|extract-i18n)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--browser-target[Target to extract from.]:target:" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--format[Output format for the generated file.]:format:" \
        "--i18n-format[Format of the localization file specified with --i18n-file.]:format:" \
        "--i18n-locale[Locale to use for i18n.]:locale:" \
        "--ivy[Use Ivy compiler to extract translations. The default for Ivy applications.]" \
        "--out-file[Name of the file to output.]:file:" \
        "--output-path[Path where output will be placed.]:path:_path_files -/" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console.]" \
        ":project:_list_projects" && ret=0
    ;;
    (g|generate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--version[Show version number.]" \
        "--defaults[When true, disables interactive input prompts for options with a default.]" \
        "--interactive[When false, disables interactive input prompts.]" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results.]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files.]" \
        ":generator:_list_generators" && ret=0
    ;;
    (l|lint)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[The linting configuration to use.]:configuration:" \
        "--exclude[Files to exclude from linting.]:files:_files" \
        "--files[Files to include from linting.]:files:_files" \
        "--fix[Fixes linting errors (may overwrite linted files).]" \
        "--force[Succeeds even if there was linting errors.]" \
        "--format[Output format.]:format:(prose json stylish verbose pmd msbuild checkstyle vso fileslist)" \
        "--silent[Show output text.]" \
        "--ts-config[The name of the TypeScript configuration file.]:file:_files" \
        "--tslint-config[The name of the TSLint configuration file.]:name:" \
        "--type-check[Controls the type check for linting.]" && ret=0
    ;;
    (migrate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--run-migrations[Run migrations.]:file:_files" \
        ":package:" && ret=0
    ;;
    (n|new)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--app-name[Run migrations.]:name:" \
        "(-c --collection)"{-c=,--collection=}"[A collection of schematics to use in generating the initial application.]:collection:" \
        "--commit[Initial repository commit information.]" \
        "--default-base[Default base branch for affected.]:branch:" \
        "--defaults[When true, disables interactive input prompts for options with a default.]" \
        "--directory[The directory name to create the workspace in.]:path:_path_files -/" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results.]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files.]" \
        "--interactive[When false, disables interactive input prompts.]" \
        "--linter[The tool to use for running lint checks.]:linter:" \
        "--npm-scope[Npm scope for importing libs.]:scope:" \
        "--nx-cloud[Connect the workspace to the free tier of the distributed cache provided by Nx Cloud.]" \
        "--package-manager[The package manager used to install dependencies.]:pm:" \
        "--preset[What to create in the new workspace.]:preset:" \
        "(-g --skip-git)"{-g,--skip-git}"[Skip initializing a git repository.]" \
        "--skip-install[Skip installing dependency packages.]" \
        "--style[The file extension to be used for style files.]:style:(css scss sass)" \
        "(-v --verbose)"{-v,--verbose}"[When true, adds more details to output logging.]" \
        ":package:" && ret=0
    ;;
    (run-many)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--version[Show version number.]" \
        "--target[Task to run for affected projects.]:target:" \
        "--parallel[Parallelize the command.]" \
        "--maxParallel[Max number of parallel processes.]:count:" \
        "--projects[Projects to run (comma delimited).]:projects:_list_projects" \
        "--all[Run the target on all projects in the workspace.]" \
        "--runner[Override the tasks runner in `nx.json`.]:runner:" \
        "--skip-nx-cache[Rerun the tasks even when the results are available in the.]" \
        "--configuration[This is the configuration to use when performing tasks on projects.]:configuration:" \
        "--with-deps[TInclude dependencies of specified projects when computing what to run.]" \
        "--only-failed[Isolate projects which previously failed.]" \
        "--verbose[Print additional error stack trace on failure.]" && ret=0
    ;;
    (run)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        ":project_and_executor:_list_project_executors" && ret=0
        # Because run command use the following pattern my-project:executor:configuration,
        # we are concatening these 3 arguments as a single one because no clue how to deal with this special separator,
        # maybe one day someone will contribute with the solution, who knows.
    ;;
    (s|serve)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--allowed-hosts[List of hosts that are allowed to access the dev server.]:hosts:_hosts" \
        "--aot[Build using Ahead of Time compilation.]" \
        "--base-href[Base url for the application being built.]:url:" \
        "--browser-target[Target to serve.]:brower_target:" \
        "--common-chunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--deploy-url[URL where files will be deployed.]:deploy_url:" \
        "--disable-host-check[Don't verify connected clients are part of allowed hosts.]" \
        "--hmr[Enable hot module replacement.]" \
        "--hmr-warning[Show a warning when the --hmr option is enabled.]" \
        "--host[Host to listen on.]:host:_hosts" \
        "--live-reload[Whether to reload the page on change, using live-reload.]" \
        "(-o --open)"{-o,--open}"[Opens the url in default browser.]" \
        "--optimization[Enables optimization of the build output.]" \
        "--poll[Enable and define the file watching poll time period in milliseconds.]" \
        "--port[Port to listen on.]:port:" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console while building.]" \
        "--proxy-config[Proxy configuration file.]:file:_files" \
        "--public-host[The URL that the browser client (or live-reload client, if enabled) should use to connect to the development server. Use for a complex dev server setup, such as one with reverse proxies.]:public_host:" \
        "--serve-path[The pathname where the app will be served.]:pathname:" \
        "--serve-path-default-warning[Show a warning when deploy-url/base-href use unsupported serve path values.]" \
        "--source-map[Output sourcemaps.]" \
        "--ssl[Serve using HTTPS.]" \
        "--ssl-cert[SSL certificate to use for serving HTTPS.]:certificate:_files" \
        "--ssl-key[SSL key to use for serving HTTPS.]:key:" \
        "--vendor-chunk[Use a separate bundle containing only vendor libraries.]" \
        "--verbose[Adds more details to output logging.]" \
        "--watch[Rebuild on change.]" \
        ":project:_list_projects" && ret=0
    ;;
    (t|test)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-b --bail)"{-o,--open}"[Exit the test suite immediately after `n` number of failing tests (https://jestjs.io/docs/en/cli#bail).]" \
        "--ci[Whether to run Jest in continuous integration (CI) mode. This option is on by default in most popular CI environments. It will prevent snapshots from being written unless explicitly requested (https://jestjs.io/docs/en/cli#ci).]" \
        "--clear-cache[Deletes the Jest cache directory and then exits without running tests. Will delete Jest's default cache directory. Note: clearing the cache will reduce performance.]" \
        "(-b --bail)"{-o,--open}"[Exit the test suite immediately after `n` number of failing tests (https://jestjs.io/docs/en/cli#bail).]" \
        "--common-chunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-coverage --code-coverage)"{-coverage,--code-coverage}"[Indicates that test coverage information should be collected and reported in the output (https://jestjs.io/docs/en/cli#coverage).]" \
        "(--color -colors)"{--color,-colors}"[Forces test results output color highlighting (even if stdout is not a TTY). Set to false if you would like to have no colors (https://jestjs.io/docs/en/cli#colors).]" \
        "--config[The path to a Jest config file specifying how to find and execute tests. If no rootDir is set in the config, the directory containing the config file is assumed to be the rootDir for the project. This can also be a JSON-encoded value which Jest will use as configuration.]:file:_files" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--coverage-directory[The directory where Jest should output its coverage files.]:path:_path_files -/" \
        "--coverage-reporters[A list of reporter names that Jest uses when writing coverage reports. Any istanbul reporter.]:reporter:" \
        "--detect-open-handles[Attempt to collect and print open handles preventing Jest from exiting cleanly (https://jestjs.io/docs/en/cli.html#--detectopenhandles).]" \
        "--find-related-tests[Find and run the tests that cover a comma separated list of source files that were passed in as arguments (https://jestjs.io/docs/en/cli#findrelatedtests-spaceseparatedlistofsourcefiles).]:files:_files" \
        "--jest-config[The path of the Jest configuration. (https://jestjs.io/docs/en/configuration).]:file:_files" \
        "--json[Prints the test results in JSON. This mode will send all other test output and user messages to stderr (https://jestjs.io/docs/en/cli#json).]" \
        "(-w --max-workers)"{-w=,--max-workers=}"[Specifies the maximum number of workers the worker-pool will spawn for running tests. This defaults to the number of the cores available on your machine. Useful for CI. (its usually best not to override this default) (https://jestjs.io/docs/en/cli#maxworkers-num).]:count:" \
        "(-o --only-changed)"{-o,--only-changed}"[Attempts to identify which tests to run based on which files have changed in the current repository. Only works if you're running tests in a git or hg repository at the moment (https://jestjs.io/docs/en/cli#onlychanged).]" \
        "--output-file[Write test results to a file when the --json option is also specified (https://jestjs.io/docs/en/cli#outputfile-filename).]:file:_files" \
        "--pass-with-no-tests[Will not fail if no tests are found (for example while using `--testPathPattern`.) (https://jestjs.io/docs/en/cli#passwithnotests).]" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--reporters[Run tests with specified reporters. Reporter options are not available via CLI. Example with multiple reporters: jest --reporters=\"default\" --reporters=\"jest-junit\" (https://jestjs.io/docs/en/cli#reporters).]:reporters:" \
        "(-i --run-in-band)"{-i,--run-in-band}"[Run all tests serially in the current process (rather than creating a worker pool of child processes that run tests). This is sometimes useful for debugging, but such use cases are pretty rare. Useful for CI. (https://jestjs.io/docs/en/cli#runinband).]" \
        "--show-config[Print your Jest config and then exits (https://jestjs.io/docs/en/cli#--showconfig).]" \
        "--silent[Prevent tests from printing messages through the console (https://jestjs.io/docs/en/cli#silent).]" \
        "--test-file[The name of the file to test.]:filename:" \
        "--test-location-in-results[Adds a location field to test results. Used to report location of a test in a reporter. { \"column\": 4, \"line\": 5 } (https://jestjs.io/docs/en/cli#testlocationinresults).]" \
        "(-t --test-name-pattern)"{-t=,--test-name-pattern=}"[Run only tests with a name that matches the regex pattern (https://jestjs.io/docs/en/cli#testnamepattern-regex).]:pattern:" \
        "--test-path-pattern[An array of regexp pattern strings that is matched against all tests paths before executing the test (https://jestjs.io/docs/en/cli#testpathpattern-regex).]:path_pattern:" \
        "--test-results-processor[Node module that implements a custom results processor (https://jestjs.io/docs/en/configuration#testresultsprocessor-string).]:processor:" \
        "(-u --update-snapshot)"{-u,--update-snapshot}"[Use this flag to re-record snapshots. Can be used together with a test suite pattern or with `--testNamePattern` to re-record snapshot for test matching the pattern (https://jestjs.io/docs/en/cli#updatesnapshot).]" \
        "--use-stderr[Divert all output to stderr.]" \
        "--verbose[Display individual test results with the test suite hierarchy. (https://jestjs.io/docs/en/cli#verbose).]" \
        "--watch[Watch files for changes and rerun tests related to changed files. If you want to re-run all tests when a file has changed, use the `--watchAll` option (https://jestjs.io/docs/en/cli#watch).]" \
        "--watch-all[Watch files for changes and rerun all tests when something changes. If you want to re-run only the tests that depend on the changed files, use the `--watch` option. (https://jestjs.io/docs/en/cli#watchall)]" \
        ":project:_list_projects" && ret=0
    ;;
    (update)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--all[Whether to update all packages in package.json.]" \
        "--allow-dirty[Whether to allow updating when the repository contains modified or untracked files.]" \
        "(-C --create-commits)"{-C,--create-commits}"[reate source control commits for updates and migrations.]" \
        "--force[If false, will error out if installed packages are incompatible with the update.]" \
        "--from[Version from which to migrate from. Only available with a single package being updated, and only on migration only.]:version:" \
        "--migrate-only[Only perform a migration, does not update the installed version.]" \
        "--next[Use the prerelease version, including beta and RCs.]" \
        "--packages[The names of package(s) to update.]:packages:" \
        "--to[Version up to which to apply migrations. Only available with a single package being updated, and only on migrations only. Requires from to be specified. Default to the installed version detected.]:version:" \
        "--verbose[Display additional details about internal operations during execution.]" && ret=0
    ;;
  esac

  return ret
}

_nx_completion() {
  # In case no workspace found in current workind dir,
  # suggest creating a new workspace.
  _check_workspace_def
  if [[ $? -eq 1 ]] ; then
    local bold=$(tput bold)
    local normal=$(tput sgr0)
    _message -r "The current directory isn't part of an Nx workspace."
    _message -r "Create a workspace using npm init: ${bold}npm init nx-workspace${normal}"
    _message -r "Create a workspace using yarn:     ${bold}yarn create nx-workspace${normal}"
    _message -r "Create a workspace using npx:      ${bold}npx create-nx-workspace${normal}" && return 0
  fi

  integer ret=1
  local curcontext="$curcontext" state _command_args opts_help
  
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
      curcontext=${curcontext%:*:*}:nx-$words[1]:
      _nx_command && ret=0
    ;;
  esac

  return ret
}
compdef _nx_completion nx
