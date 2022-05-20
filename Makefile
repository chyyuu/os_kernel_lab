DOCKER_NAME ?= dinghao188/rcore-tutorial
.PHONY: docker build_docker

docker:
	docker run --rm -it --mount type=bind,source=$(shell pwd),destination=/mnt ${DOCKER_NAME}

build_docker: 
	docker build -t ${DOCKER_NAME} .
fmt:
	cd os ; cargo fmt;  cd ..