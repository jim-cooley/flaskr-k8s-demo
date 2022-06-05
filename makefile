.PHONY:
	help
	all
	config
	clean
	build
	package
	deploy
	install
	remove
	redeploy
	run
	status
	FORCE


# -----------------------------------------------
#             D E F I N I T I O N S
# -----------------------------------------------
# directories.
# NOTE: $(CURDIR) didn't seem to be reliably set so use `shell`
ROOT_DIR:=$(shell pwd)

# defines
DOCKERFILE:=Dockerfile
PACKAGE:=flaskr-k8s
VERSION:=0.1.0
USER=1000
PORT=5000
EXTPORT=5001
REGISTRY:=mini.io:5000
FLASK_APP:=flaskr
FLASK_ENV:=development

NAMESPACE:=$(PACKAGE)
FLASK_OPTIONS:=-e FLASK_ENV=$(FLASK_ENV) -e FLASK_APP=$(FLASK_APP)
USER_ASSIGN=-u $(USER):$(USER)
PORT_ASSIGN=-p $(EXTPORT):$(PORT)

# colors
GREEN:="\\033[32m"
RED:="\\033[31m]"
ENDCOLOR:="\\033[97m"

# -----------------------------------------------
#                  T A R G E T S
# -----------------------------------------------
help: ## this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[1;32m%-30s\033[37m %s\033[0m\n", $$1, $$2}' $(MAKEFILE_LIST) | sort -u


#
all: config build package  ## build all and exit.  equivalent to: make config build package


#
build: requirements.txt  ## generate updated requirements.txt from poetry


#
clean: remove  ## remove deployment


#
deploy:  ## deploy $(PACKAGE)
	@printf "\npushing images to $(REGISTRY)...:\n"
	docker push $(REGISTRY)/$(PACKAGE):latest
	docker push $(REGISTRY)/$(PACKAGE):$(VERSION)
	@printf "\n$(GREEN)deploying...$(ENDCOLOR)\n"
	kubectl apply -f $(ROOT_DIR)/flaskr.yaml


#
install: install_namespace  ## installs the target namespace


#
inspect:  ## launch the container without starting the CMD, so it can be inspected
	@printf "$(GREEN)starting $(PACKAGE)...$(ENDCOLOR)\n"
	docker run --name $(PACKAGE) $(USER_ASSIGN) $(PORT_ASSIGN) $(FLASK_OPTIONS) $(PACKAGE):$(VERSION) --entrypoint /bin/sh


#
package: $(ROOT_DIR)/$(DOCKERFILE)  ## create docker images for deployment
	@printf "\n$(GREEN)building image:$(ENDCOLOR)\n"
	docker build -t $(PACKAGE) -t $(PACKAGE):$(VERSION) -t $(REGISTRY)/$(PACKAGE) -t $(REGISTRY)/$(PACKAGE):$(VERSION) .
	@printf "\nimages:\n"
	@docker image ls $(PACKAGE)
	@printf "\n"
	@docker image ls $(REGISTRY)/$(PACKAGE)


#
prune:  ## remove all stopped containers
	@printf "\n$(GREEN)removing stopped containers:$(ENDCOLOR)\n"
	docker container prune


#
purge:  remove remove_namespace  ## removes deployment and namespaces and all resources


#
redeploy: clean package deploy  ## removes deployment, then re-deploys.  equivalent to 'clean deploy'


#
remove:  ## remove deployment
	@printf "\n$(GREEN)removing deployment...$(ENDCOLOR)\n"
	kubectl delete --ignore-not-found=true -f $(ROOT_DIR)/flaskr.yaml


#
run:  ## run docker container locally
	@printf "$(GREEN)starting $(PACKAGE)...$(ENDCOLOR)\n"
	-@docker container rm $(PACKAGE)
	docker run --name $(PACKAGE) $(USER_ASSIGN) $(PORT_ASSIGN) $(FLASK_OPTIONS) $(PACKAGE):$(VERSION)
	@printf "$(GREEN)remove stopped container with `docker container rm $(PACKAGE)`.$(ENDCOLOR)\n"


#
status:
	@printf "$(GREEN)$(PACKAGE) status:$(ENDCOLOR)\n"
	kubectl get pods -n $(NAMESPACE)


# -----------------------------------------------
#         I N T E R N A L   T A R G E T S
# -----------------------------------------------

#
config:
	cd $(ROOT_DIR)


#
install_namespace:  ## installs the target namespace
	@printf "\n$(GREEN)deploying namespace $(PACKAGE)..$(ENDCOLOR)\n"
	kubectl apply -f $(ROOT_DIR)/namespace.yaml


# remove_namespace:
	@printf "\n$(GREEN)removing deployment...$(ENDCOLOR)\n"
	kubectl delete --ignore-not-found=true -f $(ROOT_DIR)/namespace.yaml


# phony target to force target to be out of date
FORCE:


# -----------------------------------------------
#        P R O D U C T I O N   R U L E S
# -----------------------------------------------
requirements.txt: poetry.lock
	@printf "\n$(GREEN)installing package requirements:$(ENDCOLOR)\n"
	poetry install
	@printf "\n$(GREEN)generating requirements.txt file:$(ENDCOLOR)\n"
	poetry export -f requirements.txt --output requirements.txt

