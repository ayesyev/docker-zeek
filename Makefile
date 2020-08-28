REPO=ayesyev/docker-zeek
ORG=ayesyev
NAME=zeek
BUILD ?=$(shell cat LATEST)
LATEST ?=$(shell cat LATEST)


all: clean-all zeek filebeat push

.PHONY: zeek
zeek: ## Build zeek docker image
	@echo "===> Building $(ORG)/zeek:$(BUILD)..."
	cd zeek; docker build -t $(ORG)/zeek:$(BUILD) .

.PHONY: filebeat
filebeat: ##Build filebeat docker images
	@echo "===> Building $(ORG)/filebeat:$(BUILD)..."
	cd filebeat; docker build -t $(ORG)/filebeat:$(BUILD) .

.PHONY: push-zeek
push-zeek: zeek ## Push zeek docker image to docker registry
	@echo "===> Pushing $(ORG)/zeek:$(BUILD) to docker hub..."
	@docker push $(ORG)/zeek:$(BUILD)

.PHONY: push-filebeat
push-filebeat: filebeat ## Push filebeat docker image to docker registry
	@echo "===> Pushing $(ORG)/filebeat:$(BUILD) to docker hub..."
	@docker push $(ORG)/filebeat:$(BUILD)

.PHONY: push
push: push-zeek push-filebeat ## Push all docker images to docker registry

.PHONY: run
run: stop ## Run all docker containers
	@docker-compose -f docker-compose.yml up -d

.PHONY: run-zeek
run-zeek: stop-zeek ## Run zeek docker container
	@docker run -d --cap-add=NET_RAW --net=host --name zeek -v `pwd`/pcap:/pcap:rw $(ORG)/zeek:$(BUILD) -i eth0

.PHONY: run-filebeat
run-filebeat: stop-filebeat ## Run filebbeat docker container
	@docker run -d --name filebeat -v `pwd`/pcap:/pcap:rw $(ORG)/filebeat:$(BUILD)

.PHONY: stop-zeek
stop-zeek: ## Kill running zeek docker containers
	@docker-compose -f docker-compose.yml stop zeek
	@docker-compose -f docker-compose.yml rm --force zeek

.PHONY: stop-filebeat
stop-filebeat: ## Kill running zeek docker containers
	@docker-compose -f docker-compose.yml stop filebeat
	@docker-compose -f docker-compose.yml rm --force filebeat

.PHONY: stop
stop: ## Kill running docker containers
	@docker-compose -f docker-compose.yml stop
	@docker-compose -f docker-compose.yml rm --force

.PHONY: stop-all
stop-all: ## Kill ALL running docker containers
	@docker stop $$(docker ps -aq)

clean: ## Clean docker image and stop all running containers
	@echo "===> Deleting $(ORG)/zeek:$(BUILD) and $(ORG)/filebeat:$(BUILD) images..."
	@docker rmi $(ORG)/zeek:$(BUILD) --force || true
	@docker rmi $(ORG)/filebeat:$(BUILD) --force || true

.PHONY: clean_pcap
clean-pcap: ## Clean zeek logs from pcap directory
	@rm pcap/*.log || true
	@rm -rf pcap/.state || true
	@rm -rf pcap/extract_files || true

.PHONY: clean-all
clean-all: clean clean-pcap ## Clean docker images and logs from pcap directory

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
