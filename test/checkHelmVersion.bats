#!./libs/bats/bin/bats

script=${COMMAND:-"scripts/checkHelmVersion.sh"}

setup() {
    source ${script}
    cp ./Dockerfile test/Dockerfile
    sed -i "/ARG HELM_VERSION=/c\ARG HELM_VERSION=v3.3.4" ./Dockerfile
}

teardown() {
    cp test/Dockerfile ./Dockerfile
    rm test/Dockerfile    
}

@test "helm version did not change" {
    eval $(run_main 3.3.4 3.3.4)
    [[ ${triggerNewRelease} =~ "false" ]]
    [[ ${helmRelease} =~ "3.3.4" ]]
    [[ $(checkDockerfileVersion 3.3.4) =~ "0" ]]
}

@test "latest helm version is one major behind" {
    eval $(run_main 2.3.4 3.3.4)
    [[ ${triggerNewRelease} =~ "false" ]]
    [[ ${helmRelease} =~ "2.3.4" ]]
    [[ $(checkDockerfileVersion 3.3.4) =~ "0" ]]
}

@test "new major helm version available" {
    eval $(run_main 4.0.0 3.3.4)
    [[ ${triggerNewRelease} =~ "true" ]]
    [[ ${helmRelease} =~ "4.0.0" ]]
    [[ $(checkDockerfileVersion 4.0.0) =~ "0" ]]
}

@test "new minor helm version available" {
    eval $(run_main 3.4.0 3.3.4)
    [[ ${triggerNewRelease} =~ "true" ]]
    [[ ${helmRelease} =~ "3.4.0" ]]
    [[ $(checkDockerfileVersion 3.4.0) =~ "0" ]]
}

function checkDockerfileVersion() {
    case `grep -Fx "ARG HELM_VERSION=v$1" ./Dockerfile >/dev/null; echo $?` in
  0)
    echo "0"
    ;;
  1)
    echo "1"
    ;;
  *)
    # code if an error occurred
    ;;
esac
}