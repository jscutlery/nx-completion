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
  integer ret=1
  local files=(
    "$PWD/angular.json"
    "$PWD/workspace.json"
    "$PWD/nx.json"
  )

  # return 1 if none of the files are present.
  for f in $files; do
    if [[ -f $f ]]; then
      ret=0
      break
    fi
  done

  # To get all workspace projects and targets nx graph needs to be called to store the
  # data in a file.
  if [[ $ret -eq 0 ]]; then
    local cwd_id=$(echo $PWD | (command -v md5sum &> /dev/null && md5sum || md5 -r) | awk '{print $1}')
    tmp_cached_def="/tmp/nx-completion-$cwd_id.json"

    # Check if Nx cached project graph exists first
    local nx_cached_graph="$PWD/.nx/workspace-data/project-graph.json"
    if [[ -f "$nx_cached_graph" ]]; then
      tmp_cached_def="$nx_cached_graph"
    else
      # Generate new graph file if cached one doesn't exist
      nx graph --file="$tmp_cached_def" > /dev/null
    fi
  fi

  return ret
}

# Read workspace definition from generated tmp file.
# Assumes _check_workspace_def get called before.
_workspace_def() {
  integer ret=1
  if [[ -f $tmp_cached_def ]]; then
    echo $tmp_cached_def && ret=0
  fi
  return ret
}

# Collect workspace projects
_workspace_projects() {
  integer ret=1
  local def=$(_workspace_def)
  local -a projects=($(<$def | jq -r '.graph.nodes[] | .name'))
  echo $projects && ret=0
  return ret
}

# Collect workspace targets
_nx_workspace_targets() {
  integer ret=1
  local def=$(_workspace_def)
  jq -r '[.graph.nodes[] | .data.targets | keys[]] | unique[] | if test(":") then . | gsub(":"; "\\:") else . end' $def && ret=0
  return ret
}


# List projects within workspace definition file,
# uses jq dependency to parse and manipulate JSON file
# instead of using a dirty grep or sed.
_list_projects() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local def=$(_workspace_def)
  local -a projects=($(_workspace_projects))
  # Autocomplete projects as an option$ (eg: nx run demo...).
  _describe -t nx-projects "Nx projects" projects && ret=0
  return ret
}

_list_targets() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local def=$(_workspace_def)
  local -a targets=($(<$def | jq -r '.graph.nodes[] | { name: .name, target: (.data.targets | keys[] | if test(":") then . | tojson | gsub(":"; "\\:") else . end ) } | .name + "\\:" + .target'))

  _describe -t project-targets 'Project targets' targets && ret=0
  return ret
}

_list_generators() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1

  local -a generators
  local -a plugins

  plugins=(${(f)"$(nx list | awk '/Installed/,/Also available:/' | grep generators | awk -F ' ' '{print $1}')"})

  for p in $plugins; do
    local -a pluginGenerators
    pluginGenerators=(${(f)"$(nx list $p | awk '/GENERATORS/,/EXECUTORS/' | grep ' : ' | awk -F " : " '{ print $1}' | awk '{$1=$1};1')"})
    for g in $pluginGenerators; do
      generators+=("$p\:$g")
    done
  done

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
    # Add Nx related commands.
    _nx_subcommands=(
      'generate:Generate or update source code. (e.g., nx generate @nrwl/js\:lib mylib) [aliases\: g]'
      'run:[project][\:target][\:configuration] Run a target for a project. (e.g., nx run myapp\:serve\:production)'
      'run-many:Run task for multiple listed projects.'
      'affected:Run task for affected projects.'
      'affected\:apps:Print applications affected by changes.'
      'affected\:libs:Print libraries affected by changes.'
      'affected\:graph:Graph dependencies affected by changes. [aliases: affected\:dep-graph]'
      'affected\:build:Build applications and publishable libraries affected by changes.'
      'affected\:test:Test projects affected by changes.'
      'affected\:e2e:Run e2e tests for the applications affected by changes.'
      'affected\:lint:Lint projects affected by changes.'
      'print-affected:Graph execution plan.'
      'graph:Graph dependencies within workspace. [aliases\: dep-graph]'
      'repair:Repair any configuration that is no longer supported by Nx.'
      'init:Adds nx.json file and installs nx if not installed already.'
      'exec:Executes any command as if it was a target on the project.'
      'format\:check:Check for un-formatted files.'
      'format\:write:Overwrite un-formatted files. [aliases\: format]'
      'workspace-lint:[files...] Lint workspace or list of files.'
      'workspace-generator:[name] Runs a workspace generator from the tools/generators directory. [aliases\: workspace-schematic]'
      'migrate:Creates a migrations file or runs migrations from the migrations file.'
      'report:Reports useful version numbers to copy into the Nx issue template.'
      'list:[plugin]Lists installed plugins, capabilities of installed plugins and other available plugins.'
      'reset:Clears all the cached Nx artifacts and metadata about the workspace and shuts down the Nx Daemon.'
      'show:Show information about the workspace'
      'connect-to-nx-cloud:Makes sure the workspace is connected to Nx Cloud.'
    )
    (( $#_nx_subcommands > 2 )) && _store_cache nx_subcommands _nx_subcommands
  fi

  local _nx_subcommands_and_targets=($(_nx_workspace_targets) $_nx_subcommands)

  # Run completion.
  _describe -t nx-commands "Nx commands" _nx_subcommands_and_targets && ret=0
  return ret
}

_nx_command() {
  integer ret=1
  local -a _command_args opts_help opts_affected

  opts_help=("--help[Shows a help message for this command in the console]")
  opts_affected=(
    "--base[Base of the current branch (usually master).]:sha:"
    "--head[Latest commit of the current branch (usually HEAD).]:sha:"
    "--files[Change the way Nx is calculating the affected command by providing directly changed files, list of files delimited by commas.]:files:_files"
    "--uncommitted[Uncommitted changes.]"
    "--untracked[Untracked changes.]"
    "--version[Show version number.]"
    "--target[Task to run for affected projects.]:target:"
    "--output-style[Defines how Nx emits outputs tasks logs.]:output:"
    "--nx-bail[Stop command execution after the first failed task.]"
    "--nx-ignore-cycles[Ignore cycles in the task graph.]"
    "--parallel[Parallelize the command.]"
    "--all[All projects.]"
    "--exclude[Exclude certain projects from being processed.]:projects:_list_projects"
    "--runner[This is the name of the tasks runner configured in nx.json.]:runner:"
    "--configuration[This is the configuration to use when performing tasks on projects.]:configuration:"
    "--verbose[Print additional error stack trace on failure.]"
    "--skip-nx-cache[Rerun the tasks even when the results are available in the cache.]"
  )

  case "$words[1]" in
    (affected|affected:apps|affected:build|affected:libs|affected:e2e|affected:lint|affected:test|affected:graph|format|format:write|format:check|print-affected)
      _arguments $(_nx_arguments) \
        $opts_help \
        $opts_affected && ret=0
    ;;
    (b|build)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--allowedCommonJsDependencies[A list of CommonJS packages that are allowed to be used without a build time warning.]:packages:" \
        "--aot[Build using Ahead of Time compilation.]" \
        "--baseHref[Base url for the application being built.]" \
        "--verbose[Display additional details about internal operations during execution.]" \
        "--buildOptimizer[Enables '@angular-devkit/build-optimizer' optimizations when using the 'aot' option.]" \
        "--commonChunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration, setting this explicitly overrides the \"--prod\" flag.]:configuration:" \
        "--crossOrigin[Define the crossorigin attribute setting of elements that provide CORS support.]" \
        "--deleteOutputPath[Delete the output path before building.]" \
        "--deployUrl[URL where files will be deployed.]:deploy_url:" \
        "--experimentalRollupPass[Concatenate modules with Rollup before bundling them with Webpack.]" \
        "--extractCss[Extract CSS from global styles into '.css' files instead of '.js'.]" \
        "--extractLicenses[Extract all licenses in a separate file.]" \
        "--forkTypeChecker[Run the TypeScript type checker in a forked process.]" \
        "--i18nFile[Localization file to use for i18n.]:file:_files" \
        "--i18nFormat[Format of the localization file specified with --i18n-file.]:format:" \
        "--i18nLocale[Locale to use for i18n.]:locale:" \
        "--i18nMissingTranslation[How to handle missing translations for i18n.]:handler:" \
        "--index[Configures the generation of the application's HTML index.]:index:" \
        "--lazyModules[List of additional NgModule files that will be lazy loaded. Lazy router modules will be discovered automatically.]:files:_files" \
        "--localize" \
        "--main[The full path for the main entry point to the app, relative to the current workspace.]:path:_files" \
        "--namedChunks[Use file name for lazy loaded chunks.]:filename:" \
        "--ngswConfigPath[Path to ngsw-config.json.]:filepath:" \
        "--optimization[Enables optimization of the build output.]" \
        "--outputHashing[Define the output filename cache-busting hashing mode.]:mode:" \
        "--outputPath[The full path for the new output directory, relative to the current workspace.]:path:_path_files -/" \
        "--poll[Enable and define the file watching poll time period in milliseconds.]" \
        "--polyfills[The full path for the polyfills file, relative to the current workspace.]:file:_files" \
        "--preserveSymlinks[Do not use the real path when resolving modules.]" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console while building.]" \
        "--resourcesOutputPath[The path where style resources will be placed, relative to outputPath.]:path:_path_files -/" \
        "--serviceWorker[Generates a service worker config for production builds.]" \
        "--showCircularDependencies[Show circular dependency warnings on builds.]" \
        "--sourceMap[Output sourcemaps.]" \
        "--statsJson[Generates a 'stats.json' file which can be analyzed using tools such as 'webpack-bundle-analyzer'.]" \
        "--subresourceIntegrity[Enables the use of subresource integrity validation.]" \
        "--tsConfig[The full path for the TypeScript configuration file, relative to the current workspace.]:file:_files" \
        "--vendorChunk[Use a separate bundle containing only vendor libraries.]" \
        "--verbose[Adds more details to output logging.]" \
        "--watch[Run build when files change.]" \
        "--webWorkerTsConfig[TypeScript configuration for Web Worker modules.]:file:_files" \
        "--skipNxCache[Rerun the tasks even when the results are available in the cache.]" \
        ":project:_list_projects" && ret=0
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
    (e|e2e)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--baseUrl[Use this to pass directly the address of your distant server address with the port running your application.]:url:" \
        "--ciBuildId[A unique identifier for a run to enable grouping or parallelization.]:id:" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--cypressConfig[The path of the Cypress configuration json file.]:file:_files" \
        "--devServerTarget[Dev server target to run tests against.]:target:" \
        "--exit[Whether or not the Cypress Test Runner will stay open after running tests in a spec file.]" \
        "--group[A named group for recorded runs in the Cypress dashboard.]:group:" \
        "--headless[Whether or not to open the Cypress application to run the tests. If set to 'true', will run in headless mode.]" \
        "--ignoreTestFiles[A String or Array of glob patterns used to ignore test files that would otherwise be shown in your list of tests. Cypress uses minimatch with the options: {dot: true, matchBase: true}.]:pattern:" \
        "--key[The key cypress should use to run tests in parallel/record the run (CI only).]:value:" \
        "--parallel[Whether or not Cypress should run its tests in parallel (CI only).]:value:" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--record[Whether or not Cypress should record the results of the tests.]" \
        "--reporter[The reporter used during cypress run.]:reporter:" \
        "--reporterOptions[The reporter options used. Supported options depend on the reporter.]:options:" \
        "--spec[A comma delimited glob string that is provided to the Cypress runner to specify which spec files to run. i.e. '**examples/**,**actions.spec**.]:spec:" \
        "--tsConfig[The path of the Cypress tsconfig configuration json file.]:file:_files" \
        "--watch[Recompile and run tests when files change.]" \
        "--skipNxCache[Rerun the tasks even when the results are available in the cache.]" \
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
        "--tsConfig[The name of the TypeScript configuration file.]:file:_files" \
        "--tslintConfig[The name of the TSLint configuration file.]:name:" \
        "--skipNxCache[Rerun the tasks even when the results are available in the cache.]" \
        "--typeCheck[Controls the type check for linting.]" && ret=0
    ;;
    (migrate)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--runMigrations[Run migrations.]:file:_files" \
        ":package:" && ret=0
    ;;
    (n|new)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--appName[Run migrations.]:name:" \
        "(-c --collection)"{-c=,--collection=}"[A collection of schematics to use in generating the initial application.]:collection:" \
        "--commit[Initial repository commit information.]" \
        "--defaultBase[Default base branch for affected.]:branch:" \
        "--defaults[When true, disables interactive input prompts for options with a default.]" \
        "--directory[The directory name to create the workspace in.]:path:_path_files -/" \
        "(-d --dry-run)"{-d,--dry-run}"[When true, runs through and reports activity without writing out results.]" \
        "(-f --force)"{-f,--force}"[When true, forces overwriting of existing files.]" \
        "--interactive[When false, disables interactive input prompts.]" \
        "--linter[The tool to use for running lint checks.]:linter:" \
        "--npmScope[Npm scope for importing libs.]:scope:" \
        "--nxCloud[Connect the workspace to the free tier of the distributed cache provided by Nx Cloud.]" \
        "--packageManager[The package manager used to install dependencies.]:pm:" \
        "--preset[What to create in the new workspace.]:preset:" \
        "(-g --skip-git)"{-g,--skip-git}"[Skip initializing a git repository.]" \
        "--skipInstall[Skip installing dependency packages.]" \
        "--style[The file extension to be used for style files.]:style:(css scss sass)" \
        "(-v --verbose)"{-v,--verbose}"[When true, adds more details to output logging.]" \
        ":package:" && ret=0
    ;;
    (run-many)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--all[(deprecated) Run the target on all projects in the workspace]" \
        "--configuration[This is the configuration to use when performing tasks on projects]:configuration:" \
        "--exclude[Exclude certain projects from being processed]:projects:_list_projects:" \
        "--nx-bail[Stop command execution after the first failed task]" \
        "--nx-ignore-cycles[Ignore cycles in the task graph]" \
        "--output-style[Defines how Nx emits outputs tasks logs]:style:(dynamic static stream stream-without-prefixes)" \
        "(--parallel --maxParallel)"{--parallel,--maxParallel}"[Max number of parallel processes. (default is 3)]:count:" \
        "--projects[Projects to run (comma delimited).]:projects:_list_projects" \
        "--runner[Override the tasks runner in nx.json.]:runner:" \
        "(--skip-nx-cache --skipNxCache)"{--skip-nx-cache,--skipNxCache}"[Rerun the tasks even when the results are available in the cache.]" \
        "(-t --target --targets)"{-t=,--target=,--targets=}"[Task(s) to run for affected projects.]:target:" \
        "--version[Show version number.]" \
        "--verbose[Print additional error stack trace on failure.]" \
        && ret=0
    ;;
    (run|run-one)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        ":target:_list_targets" && ret=0
        # Because run command use the following pattern my-project:executor:configuration,
        # we are concatening these 3 arguments as a single one because no clue how to deal with this special separator,
        # maybe one day someone will contribute with the solution, who knows.
    ;;
    (s|serve)
      _arguments $(_nx_arguments) \
        $opts_help \
        "--allowedHosts[List of hosts that are allowed to access the dev server.]:hosts:_hosts" \
        "--aot[Build using Ahead of Time compilation.]" \
        "--baseHref[Base url for the application being built.]:url:" \
        "--browserTarget[Target to serve.]:brower_target:" \
        "--commonChunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--deployUrl[URL where files will be deployed.]:deploy_url:" \
        "--disableHostCheck[Don't verify connected clients are part of allowed hosts.]" \
        "--hmr[Enable hot module replacement.]" \
        "--hmrWarning[Show a warning when the --hmr option is enabled.]" \
        "--host[Host to listen on.]:host:_hosts" \
        "--liveReload[Whether to reload the page on change, using live-reload.]" \
        "(-o --open)"{-o,--open}"[Opens the url in default browser.]" \
        "--optimization[Enables optimization of the build output.]" \
        "--poll[Enable and define the file watching poll time period in milliseconds.]" \
        "--port[Port to listen on.]:port:" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--progress[Log progress to the console while building.]" \
        "--proxyConfig[Proxy configuration file.]:file:_files" \
        "--publicHost[The URL that the browser client (or live-reload client, if enabled) should use to connect to the development server. Use for a complex dev server setup, such as one with reverse proxies.]:public_host:" \
        "--servePath[The pathname where the app will be served.]:pathname:" \
        "--servePathDefaultWarning[Show a warning when deploy-url/base-href use unsupported serve path values.]" \
        "--sourceMap[Output sourcemaps.]" \
        "--ssl[Serve using HTTPS.]" \
        "--sslCert[SSL certificate to use for serving HTTPS.]:certificate:_files" \
        "--sslKey[SSL key to use for serving HTTPS.]:key:" \
        "--vendorChunk[Use a separate bundle containing only vendor libraries.]" \
        "--verbose[Adds more details to output logging.]" \
        "--watch[Rebuild on change.]" \
        ":project:_list_projects" && ret=0
    ;;
    (show)
      _arguments $(_nx_arguments) \
        $opts_help \
        ":object:(projects)" && ret=0
    ;;
    (t|test)
      _arguments $(_nx_arguments) \
        $opts_help \
        "(-b --bail)"{-o,--open}"[Exit the test suite immediately after n number of failing tests (https://jestjs.io/docs/en/cli#bail).]" \
        "--ci[Whether to run Jest in continuous integration (CI) mode. This option is on by default in most popular CI environments. It will prevent snapshots from being written unless explicitly requested (https://jestjs.io/docs/en/cli#ci).]" \
        "--clearCache[Deletes the Jest cache directory and then exits without running tests. Will delete Jest's default cache directory. Note: clearing the cache will reduce performance.]" \
        "(-b --bail)"{-o,--open}"[Exit the test suite immediately after n number of failing tests (https://jestjs.io/docs/en/cli#bail).]" \
        "--commonChunk[Use a separate bundle containing code used across multiple bundles.]" \
        "(-coverage --code-coverage)"{-coverage,--code-coverage}"[Indicates that test coverage information should be collected and reported in the output (https://jestjs.io/docs/en/cli#coverage).]" \
        "(--color -colors)"{--color,-colors}"[Forces test results output color highlighting (even if stdout is not a TTY). Set to false if you would like to have no colors (https://jestjs.io/docs/en/cli#colors).]" \
        "--config[The path to a Jest config file specifying how to find and execute tests. If no rootDir is set in the config, the directory containing the config file is assumed to be the rootDir for the project. This can also be a JSON-encoded value which Jest will use as configuration.]:file:_files" \
        "(-c --configuration)"{-c=,--configuration=}"[A named builder configuration.]:configuration:" \
        "--coverageDirectory[The directory where Jest should output its coverage files.]:path:_path_files -/" \
        "--coverageReporters[A list of reporter names that Jest uses when writing coverage reports. Any istanbul reporter.]:reporter:" \
        "--detectOpenHandles[Attempt to collect and print open handles preventing Jest from exiting cleanly (https://jestjs.io/docs/en/cli.html#--detectopenhandles).]" \
        "--findRelatedTests[Find and run the tests that cover a comma separated list of source files that were passed in as arguments (https://jestjs.io/docs/en/cli#findrelatedtests-spaceseparatedlistofsourcefiles).]:files:_files" \
        "--jestConfig[The path of the Jest configuration. (https://jestjs.io/docs/en/configuration).]:file:_files" \
        "--json[Prints the test results in JSON. This mode will send all other test output and user messages to stderr (https://jestjs.io/docs/en/cli#json).]" \
        "(-w --max-workers)"{-w=,--max-workers=}"[Specifies the maximum number of workers the worker-pool will spawn for running tests. This defaults to the number of the cores available on your machine. Useful for CI. (its usually best not to override this default) (https://jestjs.io/docs/en/cli#maxworkers-num).]:count:" \
        "(-o --only-changed)"{-o,--only-changed}"[Attempts to identify which tests to run based on which files have changed in the current repository. Only works if you're running tests in a git or hg repository at the moment (https://jestjs.io/docs/en/cli#onlychanged).]" \
        "--outputFile[Write test results to a file when the --json option is also specified (https://jestjs.io/docs/en/cli#outputfile-filename).]:file:_files" \
        "--passWithNoTests[Will not fail if no tests are found (for example while using --testPathPattern.) (https://jestjs.io/docs/en/cli#passwithnotests).]" \
        "--prod[When true, sets the build configuration to the production target, shorthand for \"--configuration=production\".]" \
        "--reporters[Run tests with specified reporters. Reporter options are not available via CLI. Example with multiple reporters: jest --reporters=\"default\" --reporters=\"jest-junit\" (https://jestjs.io/docs/en/cli#reporters).]:reporters:" \
        "(-i --run-in-band)"{-i,--run-in-band}"[Run all tests serially in the current process (rather than creating a worker pool of child processes that run tests). This is sometimes useful for debugging, but such use cases are pretty rare. Useful for CI. (https://jestjs.io/docs/en/cli#runinband).]" \
        "--showConfig[Print your Jest config and then exits (https://jestjs.io/docs/en/cli#--showconfig).]" \
        "--silent[Prevent tests from printing messages through the console (https://jestjs.io/docs/en/cli#silent).]" \
        "--testFile[The name of the file to test.]:filename:" \
        "--testLocationInResults[Adds a location field to test results. Used to report location of a test in a reporter. { \"column\": 4, \"line\": 5 } (https://jestjs.io/docs/en/cli#testlocationinresults).]" \
        "(-t --testNamePattern)"{-t=,--test-name-pattern=}"[Run only tests with a name that matches the regex pattern (https://jestjs.io/docs/en/cli#testnamepattern-regex).]:pattern:" \
        "--testPathPattern[An array of regexp pattern strings that is matched against all tests paths before executing the test (https://jestjs.io/docs/en/cli#testpathpattern-regex).]:path_pattern:" \
        "--testResultsProcessor[Node module that implements a custom results processor (https://jestjs.io/docs/en/configuration#testresultsprocessor-string).]:processor:" \
        "(-u --update-snapshot)"{-u,--update-snapshot}"[Use this flag to re-record snapshots. Can be used together with a test suite pattern or with --testNamePattern to re-record snapshot for test matching the pattern (https://jestjs.io/docs/en/cli#updatesnapshot).]" \
        "--useStderr[Divert all output to stderr.]" \
        "--verbose[Display individual test results with the test suite hierarchy. (https://jestjs.io/docs/en/cli#verbose).]" \
        "--watch[Watch files for changes and rerun tests related to changed files. If you want to re-run all tests when a file has changed, use the --watchAll option (https://jestjs.io/docs/en/cli#watch).]" \
        "--watchAll[Watch files for changes and rerun all tests when something changes. If you want to re-run only the tests that depend on the changed files, use the --watch option. (https://jestjs.io/docs/en/cli#watchall)]" \
        "--skipNxCache[Rerun the tasks even when the results are available in the cache.]" \
        ":project:_list_projects" && ret=0
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
    _message -r ""
    _message -r "Create a workspace using npm init:"
    _message -r "${bold}npm init nx-workspace${normal}"
    _message -r "Create a workspace using yarn:"
    _message -r "${bold}yarn create nx-workspace${normal}"
    _message -r "Create a workspace using npx:"
    _message -r "${bold}npx create-nx-workspace${normal}" && return 0
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
