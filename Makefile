# Dockerfile Builder
# ==================
#
# All the content is in `docker-bits`; this Makefile
# just builds target dockerfiles by combining the dockerbits.
#
# Management of build, pull/push, and testing is modified from
# https://github.com/jupyter/docker-stacks
#
# Tests/some elements of makefile strongly inspired by
# https://github.com/jupyter/docker-stacks/blob/master/Makefile

# The docker-stacks tag
DOCKER-STACKS-UPSTREAM-TAG := ed2908bbb62e

tensorflow-CUDA := 11.1
pytorch-CUDA    := 11.1
newpytorch-CUDA    := 11.6
ml-CUDA        := 11.1
mlnocopy-CUDA        := 11.1
monai-CUDA        := 11.1
computer-CUDA        := 11.1
remote-desktop-CUDA := 11.1
remote-desktop-ros-CUDA := 11.1
remote-desktop-ros-eng-CUDA := 11.1
newmonai-CUDA        := 11.1

# https://stackoverflow.com/questions/5917413/concatenate-multiple-files-but-include-filename-as-section-headers
CAT := awk '(FNR==1){print "\n\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\n\#\#\#  " FILENAME "\n\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\n"}1'

# Misc Directories
SRC := docker-bits
RESOURCES := resources
OUT := output
TMP := .tmp
TESTS_DIR := ./tests
MAKE_HELPERS := ./make_helpers/
PYTHON_VENV := .venv

# Executables
PYTHON := $(PYTHON_VENV)/bin/python
POST_BUILD_HOOK := post-build-hook.sh

# Default labels
DEFAULT_REPO := k8scc01covidacr.azurecr.io
GIT_SHA := $(shell git rev-parse HEAD)
# This works during local development, but if on a GitHub PR it will resolve to "HEAD"
# so don't rely on it when on the GH runners!
DEFAULT_TAG := $(shell ./make_helpers/get_branch_name.sh)
BRANCH_NAME := $(shell ./make_helpers/get_branch_name.sh)

# Other
DEFAULT_PORT := 8888
DEFAULT_NB_PREFIX := /notebook/username/notebookname

# ENG
DEFAULT_ENG := FALSE



.PHONY: clean .output generate-dockerfiles

clean:
	rm -rf $(OUT) $(TMP)

.output:
	mkdir -p $(OUT)/ $(TMP)/

#############################
###    Generated Files    ###
#############################
get-docker-stacks-upstream-tag:
	@echo $(DOCKER-STACKS-UPSTREAM-TAG)

generate-CUDA:
	bash scripts/get-nvidia-stuff.sh $(TensorFlow-CUDA) > $(SRC)/1_CUDA-$(TensorFlow-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(ml-CUDA) > $(SRC)/1_CUDA-$(ml-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(mlnocopy-CUDA) > $(SRC)/1_CUDA-$(mlnocopy-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(monai-CUDA) > $(SRC)/1_CUDA-$(monai-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(newmonaimonai-CUDA) > $(SRC)/1_CUDA-$(newmonai-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(computer-CUDA) > $(SRC)/1_CUDA-$(computer-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(all-CUDA) > $(SRC)/1_CUDA-$(all-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(Remote-Desktop-CUDA) > $(SRC)/1_CUDA-$(Remote-Desktop-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(PyTorch-CUDA) > $(SRC)/1_CUDA-$(PyTorch-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(Remote-Desktop-ROS-CUDA) > $(SRC)/1_CUDA-$(Remote-Desktop-ROS-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(Remote-Desktop-ROS-ENG-CUDA) > $(SRC)/1_CUDA-$(Remote-Desktop-ROS-ENG-CUDA).Dockerfile
	bash scripts/get-nvidia-stuff.sh    $(newPyTorch-CUDA) > $(SRC)/1_CUDA-$(newPyTorch-CUDA).Dockerfile


generate-Spark:
	bash scripts/get-spark-stuff.sh --commit $(COMMIT)  > $(SRC)/2_Spark.Dockerfile

###################################
###### Dockerfile Management ######
###################################

all:
	@echo 'Did you mean to generate all Dockerfiles?  That has been renamed to `make generate-dockerfiles`'

generate-dockerfiles: clean jupyterlab rstudio remote-desktop sas docker-stacks-datascience-notebook remote-desktop-ros
	@echo "All dockerfiles created."

##############################
###   Bases GPU & Custom   ###
##############################

# Configure the "Bases".
#
# Revert Stan's change made in PR#306 that includes $(SRC)/2_cpu.Dockerfile It really balloons the size of the image
pytorch tensorflow ml mlnocopy monai computer newmonai : .output
	$(CAT) \
		$(SRC)/0_cpu.Dockerfile \
		$(SRC)/1_CUDA-$($(@)-CUDA).Dockerfile \
		$(SRC)/2_$@.Dockerfile \
	> $(TMP)/$@.Dockerfile

newpytorch : .output
	$(CAT) \
		$(SRC)/0_cpu.Dockerfile \
		$(SRC)/1_CUDA-$($(@)-CUDA).Dockerfile \
		$(SRC)/2_$@.Dockerfile \
	> $(TMP)/$@.Dockerfile

cpu: .output
	$(CAT) $(SRC)/0_$@.Dockerfile > $(TMP)/$@.Dockerfile

################################
###    R-Studio & Jupyter    ###
################################

# Only one output version
rstudio: cpu
	mkdir -p $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@

	$(CAT) \
		$(TMP)/$<.Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/5_DB-Drivers.Dockerfile \
		$(SRC)/6_$(@).Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD.Dockerfile \
	>   $(OUT)/$@/Dockerfile

# Only one output version
sas:
	mkdir -p $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/sas/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_cpu_sas.Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/5_DB-Drivers.Dockerfile \
		$(SRC)/6_jupyterlab.Dockerfile \
		$(SRC)/6_rstudio.Dockerfile\
		$(SRC)/6_$(@).Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD.Dockerfile \
	>   $(OUT)/$@/Dockerfile

# create directories for current images
jupyterlab: pytorch tensorflow ml mlnocopy cpu

	for type in $^; do \
		mkdir -p $(OUT)/$@-$${type}; \
		cp -r resources/common/. $(OUT)/$@-$${type}/; \
		$(CAT) \
			$(TMP)/$${type}.Dockerfile \
			$(SRC)/3_Kubeflow.Dockerfile \
			$(SRC)/4_CLI.Dockerfile \
			$(SRC)/5_DB-Drivers.Dockerfile \
			$(SRC)/6_$(@).Dockerfile \
			$(SRC)/7_remove_vulnerabilities.Dockerfile \
			$(SRC)/∞_CMD.Dockerfile \
		>   $(OUT)/$@-$${type}/Dockerfile; \
	done

# new
newlab: newpytorch
	for type in $^; do \
		mkdir -p $(OUT)/$@-$${type}; \
		cp -r resources/common/. $(OUT)/$@-$${type}/; \
		$(CAT) \
			$(TMP)/$${type}.Dockerfile \
			$(SRC)/3_Kubeflow.Dockerfile \
			$(SRC)/4_CLI.Dockerfile \
			$(SRC)/5_DB-Drivers.Dockerfile \
			$(SRC)/6_$(@).Dockerfile \
			$(SRC)/7_remove_vulnerabilities.Dockerfile \
			$(SRC)/∞_CMD.Dockerfile \
		>   $(OUT)/$@-$${type}/Dockerfile; \
	done

# create monai
medical: monai

	for type in $^; do \
		mkdir -p $(OUT)/$@-$${type}; \
		cp -r resources/common/. $(OUT)/$@-$${type}/; \
		$(CAT) \
			$(TMP)/$${type}.Dockerfile \
			$(SRC)/3_Kubeflow.Dockerfile \
			$(SRC)/4_CLI.Dockerfile \
			$(SRC)/5_DB-Drivers.Dockerfile \
			$(SRC)/6_$(@).Dockerfile \
			$(SRC)/7_remove_vulnerabilities.Dockerfile \
			$(SRC)/∞_CMD.Dockerfile \
		>   $(OUT)/$@-$${type}/Dockerfile; \
	done

# create monai
newmedical: newmonai

	for type in $^; do \
		mkdir -p $(OUT)/$@-$${type}; \
		cp -r resources/common/. $(OUT)/$@-$${type}/; \
		$(CAT) \
			$(TMP)/$${type}.Dockerfile \
			$(SRC)/3_Kubeflow.Dockerfile \
			$(SRC)/4_CLI.Dockerfile \
			$(SRC)/5_DB-Drivers.Dockerfile \
			$(SRC)/6_$(@).Dockerfile \
			$(SRC)/7_remove_vulnerabilities.Dockerfile \
			$(SRC)/∞_CMD.Dockerfile \
		>   $(OUT)/$@-$${type}/Dockerfile; \
	done

# create cv
cvma: computer

	for type in $^; do \
		mkdir -p $(OUT)/$@-$${type}; \
		cp -r resources/common/. $(OUT)/$@-$${type}/; \
		$(CAT) \
			$(TMP)/$${type}.Dockerfile \
			$(SRC)/3_Kubeflow.Dockerfile \
			$(SRC)/4_CLI.Dockerfile \
			$(SRC)/5_DB-Drivers.Dockerfile \
			$(SRC)/6_$(@).Dockerfile \
			$(SRC)/7_remove_vulnerabilities.Dockerfile \
			$(SRC)/∞_CMD.Dockerfile \
		>   $(OUT)/$@-$${type}/Dockerfile; \
	done

# Remote Desktop
remote-desktop:
	mkdir -p $(OUT)/$@
	echo "REMOTE DESKTOP"
	cp -r scripts/remote-desktop $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/remote-desktop/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_Rocker.Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/6_new-remote-desktop_normal.Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD_remote-desktop.Dockerfile \
	>   $(OUT)/$@/Dockerfile

remote-desktop-eng:
	mkdir -p $(OUT)/$@
	echo "REMOTE DESKTOP ENG"
	cp -r scripts/remote-desktop $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/remote-desktop/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_Rocker.Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/6_new-remote-desktop_normal.Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD_remote-desktop.Dockerfile \
	>   $(OUT)/$@/Dockerfile

# Remote Desktop for ROS
remote-desktop-ros:
	mkdir -p $(OUT)/$@
	echo "REMOTE DESKTOP ROS"
	cp -r scripts/remote-desktop $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/remote-desktop/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_Rocker.Dockerfile \
		$(SRC)/1_CUDA-$($(@)-CUDA).Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/6_new-remote-desktop_ros.Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD_remote-desktop.Dockerfile \
	>   $(OUT)/$@/Dockerfile

remote-desktop-ros-eng:
	mkdir -p $(OUT)/$@
	echo "REMOTE DESKTOP ROS ENG"
	cp -r scripts/remote-desktop $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/remote-desktop/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_Rocker.Dockerfile \
		$(SRC)/1_CUDA-$($(@)-CUDA).Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/6_new-remote-desktop_ros.Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD_remote-desktop.Dockerfile \
	>   $(OUT)/$@/Dockerfile

# Remote Desktop for database-design
remote-desktop-database-design:
	mkdir -p $(OUT)/$@
	echo "REMOTE DESKTOP DATABASE DESIGN"
	cp -r scripts/remote-desktop $(OUT)/$@
	cp -r resources/common/. $(OUT)/$@
	cp -r resources/remote-desktop/. $(OUT)/$@

	$(CAT) \
		$(SRC)/0_Rocker.Dockerfile \
		$(SRC)/3_Kubeflow.Dockerfile \
		$(SRC)/4_CLI.Dockerfile \
		$(SRC)/6_remote-desktop-database-design.Dockerfile \
		$(SRC)/7_remove_vulnerabilities.Dockerfile \
		$(SRC)/∞_CMD_remote-desktop.Dockerfile \
	>   $(OUT)/$@/Dockerfile
	
# Debugging Dockerfile generator that essentially uses docker-stacks images
# Used for when you need something to build quickly during debugging
docker-stacks-datascience-notebook:
	mkdir -p $(OUT)/$@
	cp -r resources/common/* $(OUT)/$@
	DS_TAG=$$(make -s get-docker-stacks-upstream-tag); \
	echo "FROM jupyter/datascience-notebook:$$DS_TAG" > $(OUT)/$@/Dockerfile; \
	$(CAT) $(SRC)/∞_CMD.Dockerfile >> $(OUT)/$@/Dockerfile

###################################
######    Docker helpers     ######
###################################

pull/%: DARGS?=
pull/%: REPO?=$(DEFAULT_REPO)
pull/%: TAG?=$(DEFAULT_TAG)
pull/%:
	# End repo with a single slash and start tag with a single colon, if they exist
	REPO=$$(echo "$(REPO)" | sed 's:/*$$:/:' | sed 's:^\s*/*\s*$$::') &&\
	TAG=$$(echo "$(TAG)" | sed 's~^:*~:~' | sed 's~^\s*:*\s*$$~~') &&\
	echo "Pulling $${REPO}$(notdir $@)$${TAG}" &&\
	docker pull $(DARGS) "$${REPO}$(notdir $@)$${TAG}"

build/%: DARGS?=
build/%: REPO?=$(DEFAULT_REPO)
build/%: TAG?=$(DEFAULT_TAG)
build/%: ## build the latest image
	# End repo with exactly one trailing slash, unless it is empty
	REPO=$$(echo "$(REPO)" | sed 's:/*$$:/:' | sed 's:^\s*/*\s*$$::') &&\
	IMAGE_NAME="$${REPO}$(notdir $@):$(TAG)" ; \
	if [ $$IMAGE_NAME = "$${REPO}remote-desktop:$(TAG)" ] || [ $$IMAGE_NAME = "$${REPO}remote-desktop-ros:$(TAG)" ]; then \
		ENG="FALSE" && \
		LANGUAGE="zh_TW.UTF-8" ; \
	else \
		ENG="TRUE" && \
		LANGUAGE="en_US.UTF-8" ; \
	fi ; \
	docker build $(DARGS) --progress=auto --rm --force-rm -t $$IMAGE_NAME ./output/$(notdir $@) --build-arg ENG=$$ENG --build-arg LANGUAGE=$$LANGUAGE && \
	echo -n "Built image $$IMAGE_NAME of size: " && \
	docker images $$IMAGE_NAME --format "{{.Size}}" && \
	echo "::set-output name=full_image_name::$$IMAGE_NAME" && \
	echo "::set-output name=image_tag::$(TAG)" && \
	echo "::set-output name=image_repo::$${REPO}"

post-build/%: export REPO?=$(DEFAULT_REPO)
post-build/%: export TAG?=$(DEFAULT_TAG)
post-build/%: export SOURCE_FULL_IMAGE_NAME?=
post-build/%: export IMAGE_VERSION?=
post-build/%: export IS_LATEST?=
post-build/%:
	# TODO: could check for custom hook in the build's directory
	IMAGE_NAME="$(notdir $@)" \
	GIT_SHA=$(GIT_SHA) \
	BRANCH_NAME=$(BRANCH_NAME) \
	bash "$(MAKE_HELPERS)/$(POST_BUILD_HOOK)"

push/%: DARGS?=
push/%: REPO?=$(DEFAULT_REPO)
push/%:
	REPO=$$(echo "$(REPO)" | sed 's:/*$$:/:' | sed 's:^\s*/*\s*$$::') &&\
	echo "Pushing the following tags for $${REPO}$(notdir $@) (all tags)" &&\
	docker images $${REPO}$(notdir $@) --format="{{ .Tag }}" &&\
	docker push --all-tags $(DARGS) "$${REPO}"$(notdir $@)

###################################
######     Image Testing     ######
###################################
check-python-venv:
	@if $(PYTHON) --version> /dev/null 2>&1; then \
		echo "Found dev python venv via $(PYTHON)"; \
	else \
		echo -n 'No dev python venv found at $(PYTHON)\n' \
				'Please run `make install-python-dev-venv` to build a dev python venv'; \
		exit 1; \
	fi

check-port-available:
	@if curl http://localhost:$(DEFAULT_PORT) > /dev/null 2>&1; then \
		echo "Port $(DEFAULT_PORT) busy - clear port or change default before continuing"; \
		exit 1; \
	fi

check-test-prereqs: check-python-venv check-port-available

install-python-dev-venv:
	python3 -m venv $(PYTHON_VENV)
	$(PYTHON) -m pip install -Ur requirements-dev.txt

test/%: REPO?=$(DEFAULT_REPO)
test/%: TAG?=$(DEFAULT_TAG)
test/%: NB_PREFIX?=$(DEFAULT_NB_PREFIX)
test/%: check-test-prereqs # Run all generic and image-specific tests against an image
	# End repo with exactly one trailing slash, unless it is empty
	REPO=$$(echo "$(REPO)" | sed 's:/*$$:/:' | sed 's:^\s*/*\s*$$::') ;\
	TESTS="$(TESTS_DIR)/general";\
	SPECIFIC_TEST_DIR="$(TESTS_DIR)/$(notdir $@)";\
	if [ ! -d "$${SPECIFIC_TEST_DIR}" ]; then\
		echo "No specific tests found for $${SPECIFIC_TEST_DIR}.  Running only general tests";\
	else\
		TESTS="$${TESTS} $${SPECIFIC_TEST_DIR}";\
		echo "Found specific tests folder";\
	fi;\
	echo "Running tests on folders '$${TESTS}'";\
	IMAGE_NAME="$${REPO}$(notdir $@):$(TAG)" NB_PREFIX=$(DEFAULT_NB_PREFIX) $(PYTHON) -m pytest -m "not info" $${TESTS}

dev/%: ARGS?=
dev/%: DARGS?=
dev/%: NB_PREFIX?=$(DEFAULT_NB_PREFIX)
dev/%: PORT?=8888
dev/%: REPO?=$(DEFAULT_REPO)
dev/%: TAG?=$(DEFAULT_TAG)
dev/%: ## run a foreground container for a stack (useful for local testing)
	# End repo with exactly one trailing slash, unless it is empty
	REPO=$$(echo "$(REPO)" | sed 's:/*$$:/:' | sed 's:^\s*/*\s*$$::') ;\
	IMAGE_NAME="$${REPO}$(notdir $@):$(TAG)" ;\
	echo "\n###############\nLaunching docker container.  Connect to it via http://localhost:$(PORT)$(NB_PREFIX)\n###############\n" ;\
	if xdg-open --version > /dev/null; then\
		( sleep 5 && xdg-open "http://localhost:8888$(NB_PREFIX)" ) & \
	else\
		( sleep 5 && open "http://localhost:8888$(NB_PREFIX)" ) &  \
	fi; \
	docker run -it --rm -p $(PORT):8888 -e NB_PREFIX=$(NB_PREFIX) $(DARGS) $${IMAGE_NAME} $(ARGS)

