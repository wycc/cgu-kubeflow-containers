# Docker-stacks version tags (eg: `r-4.0.3`) are LIVE images that are frequently updated.  To avoid unexpected
# image updates, pin to the docker-stacks git commit SHA tag.
# It can be obtained by running `docker inspect repo/imagename:tag@digest` or from
# https://github.com/jupyter/docker-stacks/wiki

ARG BASE_VERSION=ed2908bbb62e
# The digest makes the base image immutable; update it together with BASE_VERSION
FROM jupyter/datascience-notebook:$BASE_VERSION@sha256:58a9bc9b48ea3af154134ae5866ce1dca820b478cee243fbe742d48a46622462

USER root

ENV PATH="/home/jovyan/.local/bin/:${PATH}"

RUN apt-get update --yes \
    && apt-get install --yes language-pack-fr \
    && rm -rf /var/lib/apt/lists/*
