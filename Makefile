DOCKER_NAME ?= blackanger/tutorial
.PHONY: docker build_docker
all:
	make -C usr user_img
	make -C os build
run:
	make -C usr user_img
	make -C os run
clean:
	make -C usr clean
	make -C os clean
env:
	make -C os env

docker:
	docker run --rm -it --mount type=bind,source=$(shell pwd),destination=/mnt ${DOCKER_NAME}

build_docker: 
	docker build -t ${DOCKER_NAME} .