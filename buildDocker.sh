#! /bin/bash

docker build -t wasicse/esmdispred - < Dockerfile

docker commit CONTAINERNAME  wasicse/esmdispred:latest

docker push  wasicse/esmdispred:latest