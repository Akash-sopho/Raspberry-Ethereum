FROM ubuntu:16.04

LABEL version="1.0"
LABEL maintainer="goyalakash391@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y git wget
RUN git clone https://github.com/Akash-sopho/Raspberry-Ethereum.git
RUN /bin/bash -c 'chmod +x /Raspberry-Ethereum/install-go.sh'
RUN /Raspberry-Ethereum/install-go.sh
RUN /bin/bash -c 'source ~/.bashrc'
RUN go version
RUN apt-get -y install dphys-swapfile build-essential libgmp3-dev curl
RUN git clone https://github.com/ethereum/go-ethereum
WORKDIR /go-ethereum
RUN make geth

ENTRYPOINT bash

