#! /bin/bash

docker build -t wasicse/esmdispred - < Dockerfile

docker build -t wasicse/esmdispredroot - < DockerfileRoot

# docker commit CONTAINERNAME  wasicse/esmdispred:latest

# docker push  wasicse/esmdispred:latest