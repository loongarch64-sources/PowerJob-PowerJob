#!/bin/bash

set -u
set -e



mvn_build(){
    mvn package -Pdev -DskipTests -U -e && /bin/cp -rf powerjob-server/powerjob-server-starter/target/*.jar powerjob-server/docker/powerjob-server.jar && /bin/cp -rf powerjob-worker-agent/target/*.jar powerjob-worker-agent/powerjob-agent.jar && /bin/cp -rf powerjob-worker-samples/target/*.jar powerjob-worker-samples/powerjob-worker-samples.jar
}

build_server(){
    pushd powerjob-server/docker > /dev/null 2>&1
        docker build \
                   -t powerjob/powerjob-server:latest \
                   -t powerjob/powerjob-server:5.1.0 \
                   -t cr.loongnix.cn/powerjob/powerjob-server:latest \
                   -t 'cr.loongnix.cn/powerjob/powerjob-server:5.1.0' .

    popd
}

# ./powerjob-worker-agent/Dockerfile
build_woker_agent(){
    pushd powerjob-worker-agent > /dev/null 2>&1
        docker build \
                -t powerjob/powerjob-agent:latest \
                -t powerjob/powerjob-agent:5.1.0 \
                -t cr.loongnix.cn/powerjob/powerjob-agent:latest \
                -t cr.loongnix.cn/powerjob/powerjob-agent:5.1.0 \
                .
    popd
}

# ./powerjob-worker-samples/Dockerfile
build_worker_samples(){
    pushd powerjob-worker-samples > /dev/null 2>&1
        docker build \
            -t powerjob/powerjob-worker-samples:latest \
            -t powerjob/powerjob-worker-samples:5.1.0 \
            -t cr.loongnix.cn/powerjob/powerjob-worker-samples:latest \
            -t cr.loongnix.cn/powerjob/powerjob-worker-samples:5.1.0 \
            .
    popd 
}

# ./others/Dockerfile

build_mysql() {
    pushd others > /dev/null 2>&1
        docker build \
            -t powerjob/powerjob-mysql:latest \
            -t powerjob/powerjob-mysql:5.1.0 \
            -t cr.loongnix.cn/powerjob/powerjob-mysql:latest \
            -t cr.loongnix.cn/powerjob/powerjob-mysql:5.1.0 \
            .

    popd

}

check_ports(){
    local ports=('10086'
         '10010' 
         '3307' 
         '8081' 
         '27777')
    for port in "${ports[@]}"
    do
        if lsof -i :${port}; then
            echo "${port} has been used"
        fi
    done
}

docker_clean(){
    docker images | grep "powerjob" | awk '{print $1":"$2}' | xargs docker rmi
}

check_arch_jar(){
    jar_abs_path=$(realpath "$1")
    tmp_dir=$(mktemp -d)
    
    pushd "${tmp_dir}" > /dev/null 2>&1
        jar xf "${jar_abs_path}"
    popd
    
    
}

start(){
    echo "start powerjob-mysql"
    docker-compose up powerjob-mysql -d
    while ! nc -z 127.0.0.1 3307;do
        sleep 1 
    done 
    echo "start powerjob-server"
    docker-compose up powerjob-server -d
    while ! nc -z 127.0.0.1; do
        sleep 1
    done
    
}


docker_push(){
    local images=$(docker images | grep "powerjob" | grep "cr" | awk '{print $1":"$2}');
    for image_name in ${images};
    do
        docker push ${image_name}
    done
}

set -x

docker_push
