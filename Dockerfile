FROM ubuntu:16.04

LABEL version="1.0"
LABEL maintainer="goyalakash391@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y git wget dphys-swapfile build-essential libgmp3-dev curl
RUN git clone https://github.com/Akash-sopho/Raspberry-Ethereum.git && git clone https://github.com/ethereum/go-ethereum
RUN /bin/bash -c 'chmod +x /Raspberry-Ethereum/install-go.sh' && /Raspberry-Ethereum/install-go.sh && /bin/bash -c 'source ~/.bashrc'
WORKDIR /go-ethereum
RUN make geth

ENTRYPOINT bash

