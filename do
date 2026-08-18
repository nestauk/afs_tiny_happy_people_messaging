#!/usr/bin/env bash

# Exit on failure
set -e

if [ -e .env ]
  then
    source .env
fi

# Allow overriding the docker compose command. This can be useful when we need to use a docker compose configuration
# file other than the default.
if [ -z "$DOCKER_COMPOSE_COMMAND" ]
  then
    DOCKER_COMPOSE_COMMAND="docker compose"
fi

# This docker compose service is used when running commands
if [ -z "$RUN_DOCKER_SERVICE" ]
  then
    RUN_DOCKER_SERVICE="rails"
fi

if [ $# -eq 0 ] || [ $1 = "help" ]
  then
    echo "do - a helper script for performing common tasks"
    echo
    echo "Usage"
    echo "  ./do <build|b>              build docker images"
    echo "  ./do <up|u>                 start all or a specified docker compose services"
    echo "  ./do <stop|s>               stop all or a specified docker compose service"
    echo "  ./do <restart|rs>           restart all or a specified docker compose service"
    echo "  ./do <down|d>               stop and discard all docker compose services and networks"
    echo "  ./do <logs|l>               display the logs for all or a specified docker compose service"
    echo "  ./do <run|r>                run the specified console command in the primary docker service"
    echo "  ./do <console|c>            start a bash console in the primary docker service"
    echo "  ./do claude                 run Claude Code in the docker container"
    echo "  ./do attach                 attach to the running web server (for binding.b debugging)"
    echo "  ./do <rails|rr>             run the bin/rails binary with the given arguments"
    echo "  ./do <rake|rk>              run the bin/rake binary with the given arguments"
    echo "  ./do ci                     run the CI pipeline"
    echo "  ./do cs                     run the rubocop coding standards checker"
    echo "  ./do cs:fix                 run the rubocop coding standards fixer"
    echo "  ./do js                     run the biome coding standards checker"
    echo "  ./do js:fix                 run the biome coding standards fixer"
    echo "  ./do <brakeman|bm>          run the brakeman static analysis"
    echo "  ./do <test|t>               run the unit and integration test suite"
    echo "  ./do <test:system|ts>       run the system test suite"
    echo "  ./do <test:system:vr|tsv>   run the system test suite then a visual regression diff"
    echo "  ./do pgadmin                start pgadmin"
    echo "  ./do vr:baseline            set the visual regression baseline using the current set of snapshots"
    echo "  ./do vr:diff                compare the current set of snapshots to the baseline"
    echo "  ./do vr:heatmap             perform simulated eye tracking analysis on the current set of snapshots"
    echo "  ./do stopall                kill all docker containers running on the system"
    exit 1
fi


if [ $1 = "build" ] || [ $1 = "b" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND build ${@:2}"
    $DOCKER_COMPOSE_COMMAND build ${@:2}
    exit 0
fi

if [ $1 = "up" ] || [ $1 = "u" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND up -d --remove-orphans ${@:2}"
    $DOCKER_COMPOSE_COMMAND up -d --remove-orphans ${@:2}
    exit 0
fi

if [ $1 = "stop" ] || [ $1 = "s" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND --profile '*' stop ${@:2}"
    $DOCKER_COMPOSE_COMMAND --profile '*' stop ${@:2}
    exit 0
fi

if [ $1 = "restart" ] || [ $1 = "rs" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND restart ${@:2}"
    $DOCKER_COMPOSE_COMMAND restart ${@:2}
    exit 0
fi

if [ $1 = "down" ] || [ $1 = "d" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND --profile '*' down ${@:2}"
    $DOCKER_COMPOSE_COMMAND --profile '*' down ${@:2}
    exit 0
fi

if [ $1 = "run" ] || [ $1 = "r" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE ${@:2}
    exit 0
fi

if [ $1 = "console" ] || [ $1 = "c" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm -it $RUN_DOCKER_SERVICE bash ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm -it $RUN_DOCKER_SERVICE bash ${@:2}
    exit 0
fi

if [ $1 = "claude" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm -it $RUN_DOCKER_SERVICE claude --dangerously-skip-permissions ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm -it $RUN_DOCKER_SERVICE claude --dangerously-skip-permissions ${@:2}
    exit 0
fi

if [ $1 = "attach" ]
  then
    echo "Attaching to web container"
    echo "useful debug commands:"
    echo "whereami - show the current location in the code"
    echo "info locals - show local variables and their values"
    echo "continue - resume execution until the next breakpoint"
    $DOCKER_COMPOSE_COMMAND attach web
    exit 0
fi

if [ $1 = "runon" ] || [ $1 = "ro" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND exec $2 ${@:3}"
    $DOCKER_COMPOSE_COMMAND exec $2 ${@:3}
    exit 0
fi

if [ $1 = "rails" ] || [ $1 = "rr" ]
  then
    if [ $# -lt 2 ]
      then
        echo "Usage: ./do rails <command>"
        echo "Run './do rails help' for a list of rails commands"
        exit 1
    fi
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails ${@:2}
    exit 0
fi

if [ $1 = "rake" ] || [ $1 = "rk" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rake ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rake ${@:2}
    exit 0
fi

if [ $1 = "ci" ]
  then
    ./do cs
    echo
    ./do js
    echo
    ./do bm
    echo
    ./do test
    echo
    ./do tsv
    exit 0
fi

if [ $1 = "lint:rb" ] || [ $1 = "cs" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec rubocop ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec rubocop ${@:2}
    exit 0
fi

if [ $1 = "lint:rb:fix" ] || [ $1 = "cs:fix" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec rubocop -A ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec rubocop -A ${@:2}
    exit 0
fi

if [ $1 = "lint:js" ] || [ $1 = "js" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE npx @biomejs/biome check ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE npx @biomejs/biome check ${@:2}
    exit 0
fi

if [ $1 = "lint:js:fix" ] || [ $1 = "js:fix" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE npx @biomejs/biome check --write ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE npx @biomejs/biome check --write ${@:2}
    exit 0
fi

if [ $1 = "brakeman" ] || [ $1 = "bm" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec brakeman -q --no-pager ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bundle exec brakeman -q --no-pager ${@:2}
    exit 0
fi

if [ $1 = "test" ] || [ $1 = "t" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails test ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails test ${@:2}
    exit 0
fi

if [ $1 = "test:system" ] || [ $1 = "ts" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails test:system ${@:2}"
    $DOCKER_COMPOSE_COMMAND run --rm $RUN_DOCKER_SERVICE bin/rails test:system ${@:2}
    exit 0
fi

if [ $1 = "test:system:vr" ] || [ $1 = "tsv" ]
  then
    echo "Removing existing system test snapshots..."
    rm tmp/snapshots/*.png || true
    echo ""
    ./do test:system ${@:2}
    echo ""
    ./do vr:diff
    exit 0
fi

if [ $1 = "log" ] || [ $1 = "logs" ] || [ $1 = "l" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND logs ${@:2} | less"
    $DOCKER_COMPOSE_COMMAND logs ${@:2} | less
    exit 0
fi

if [ $1 = "stopall" ] || [ $1 = "s!" ]
  then
    echo "Retrieving list of non-project containers: \$(grep -v -f <($DOCKER_COMPOSE_COMMAND ps -q) <(docker ps -q --no-trunc))"
    CONTAINERS="$(grep -v -f <($DOCKER_COMPOSE_COMMAND ps -q) <(docker ps -q --no-trunc))" || true

    if [ -n "${CONTAINERS}" ]
      then
        echo "$(echo $CONTAINERS | wc -w) containers found"
        echo "Stopping all non-project containers: docker stop \$CONTAINERS"
        docker stop $CONTAINERS
    else
      echo "No running containers to stop"
    fi
    exit 0
fi

if [ $1 = "stopallandup" ] || [ $1 = "u!" ] || [ $1 = "su!" ]
  then
    ./do s!
    ./do u
    exit 0
fi

if [ $1 = "vr:baseline" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm image_processing python baseline.py"
    $DOCKER_COMPOSE_COMMAND run --rm image_processing python baseline.py
    exit 0
fi

if [ $1 = "vr:diff" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm image_processing python diff.py"
    $DOCKER_COMPOSE_COMMAND run --rm image_processing python diff.py
    exit 0
fi

if [ $1 = "vr:heatmap" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND run --rm image_processing python simulated_eye_tracking.py"
    $DOCKER_COMPOSE_COMMAND run --rm image_processing python simulated_eye_tracking.py
    exit 0
fi

if [ $1 = "pgadmin" ]
  then
    echo "Running command: $DOCKER_COMPOSE_COMMAND up -d --remove-orphans pgadmin"
    $DOCKER_COMPOSE_COMMAND up -d --remove-orphans pgadmin

    echo ""
    echo "pgadmin is now available at http://127.0.0.1:5000"
    exit 0
fi

echo "Running command: $DOCKER_COMPOSE_COMMAND ${@:1}"
$DOCKER_COMPOSE_COMMAND ${@:1}
