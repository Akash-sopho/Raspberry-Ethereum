**Setting up Ethereum Light Node on Raspberry Pi**

**Setting up Raspberry Pi**
* Download and install SD Card Formatter 5.0.1 (or the latest version available)
* Attach the memory card to the system using card reader and format it using SD Card Formatter (current download link is https://www.sdcard.org/downloads/formatter/ )
* Download NOOBS (not NOOBS Lite) to install Raspbian OS on the card (copy the extracted folder to the card, run it on Rpi and follow the installation instructions)
* Many videos and sites are available for reference - 
      Video : https://www.youtube.com/watch?v=iJbjAJpJA84
      Site : https://projects.raspberrypi.org/en/projects/noobs-install
* Set preferences for keyboard, time, location and internet
      Reference : https://www.instructables.com/id/Ultimate-Raspberry-Pi-Configuration-Guide/

**Setting up Ethereum Go client (GETH)**

Install latest version of go compatible with the arm processor (regular golang build will not work, so download required binaries, copy them to the correct location, assign permissions and update source)

```
cd /home/pi/
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install git wget curl
git clone https://github.com/Akash-sopho/Raspberry-Ethereum.git
cd Raspberry-Ethereum
sudo chmod +x install-go.sh
./install-go.sh
source ~/.bashrc
```
Check whether go is installed using `go version`

Now for installing geth, first install the required packages, then download arm compatible geth package and build it. Copy built binary to `/usr/local/bin/` to use geth from other directories.

```
sudo apt-get -y install dphys-swapfile build-essential libgmp3-dev curl
git clone https://github.com/ethereum/go-ethereum
cd go-ethereum
make geth
cp ./build/bin/geth /usr/local/bin/geth
```

Check whether geth is properly installed using `geth version`

**Setting up GETH on Docker Container**

Install docker and docker-compose

Build docker image using the following Docker file which installs go and other required packages for geth installation.

```
FROM ubuntu:16.04

LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y git wget
RUN cd /
RUN git clone https://github.com/Akash-sopho/Raspberry-Ethereum.git
RUN /bin/bash -c 'chmod +x /Raspberry-Ethereum/install-go.sh'
RUN /Raspberry-Ethereum/install-go.sh
RUN /bin/bash -c 'source ~/.bashrc'

RUN apt-get -y install dphys-swapfile build-essential libgmp3-dev curl
RUN git clone https://github.com/ethereum/go-ethereum

ENTRYPOINT bash
```

The dockerfile is present in the github repository cloned earlier.

Build and run a container using this dockerfile
```
cd /home/pi/Raspberry-Ethereum/
docker build -t node .
//docker build -t {name of image} {path to the dockerfile}

docker run --rm -it node
```
The docker run command opens the container on bash console due to the `-it` flag. Now enter the downloaded `go-ethereum` folder and build geth using `make geth`
```
cd /go-ethereum
make geth
cp ./build/bin/geth /usr/local/bin/geth
```
GETH installation would have to be done in each container separately as building geth in the dockerfile itself returns an error in `make geth` command saying `go not found`.

**Setting up a local Ethereum Network**

Building a local ethereum network containing multiple nodes on separate docker containers.
Create a docker network and build 2 docker containers using the image created earlier with the dockerfile. Run the containers using different ports but the same “net” parameter so that they are able to connect to each other.

```
docker network create ETH
docker run --rm -it -p 8545:8545 --net=ETH node
docker run --rm -it -p 8546:8546 --net=ETH node
```

As the entrypoint is set to bash, `docker run` commands need to be run from separate cmd line tabs as it opens the container in command line.
Run `make geth` and `cp ./build/bin/geth /usr/local/bin/geth` in both containers to install geth.

Now, run geth on first node 
Make new directory to be used as data directory for geth, copy `genesis.json` file cloned from the repository to it and run geth using this genesis file and data directory. Enter the port and netowrkid and attach console to the geth instance.
```
cd /
mkdir ethereum
cp /Raspberry-Ethereum/genesis.json /ethereum/genesis.json
cd ethereum
mkdir node_one
geth --datadir "/ethereum/node_one" --networkid "500" --rpc --rpcport=8545 --rpcaddr 0.0.0.0 init "/ethereum/genesis.json"
geth --datadir "/ethereum/node_one" console 2>console.log
```

Similarly for second node
```
cd /
mkdir ethereum
cp /Raspberry-Ethereum/genesis.json /ethereum/genesis.json
cd ethereum
mkdir node_two
geth --datadir "/ethereum/node_two" --networkid "500" --rpc --rpcport=8546 --rpcaddr 0.0.0.0 init "/ethereum/genesis.json"
geth --datadir "/ethereum/node_two" console 2>console.log
```

We are now running ethereum on both nodes but the nodes are not able to detect on another. We have add them as peers to create a network.

Run `admin.peers`. It shows there are currently no peers on the network. To add peers to a node, we need the enode url and ip address of the other node.

Lets first add peers to node 1. 

To get enode url of node 2 run on node 2's geth, command:
```
admin.nodeInfo.enode
```
It returns a url of the form `"enode://4f3c1f87914a68255f9b736aa**ac754d7558ba@[::]:30303"`, where ** represent a long string while [::] stands for the localhost. We need to to replace this with the ip address of container.

To get ip address of node 2 run on pi command line, command:
```
docker network inspect ETH
```
It returns something like
```
[
    {
        # .........
        "Containers": {
            "50e624e9481765443216eebaa4d0d7ae1dda3497f64eb55d6160632c7b7d0cce": {
                "Name": "tasty_raman",
                "EndpointID": "15a34c3bf61f85cd1e705bf72470e2ac46d370159db59d07715e428518533bba",
                "MacAddress": "02:42:ac:12:00:03",
                "IPv4Address": "172.1.0.2/16",
                "IPv6Address": ""
            },
            "54d6fecd407b586bd4d0e20422923dd7355a691ce4de8a2050d649d7c9318526": {
                "Name": "goldberg_nostal",
                "EndpointID": "64fdd19a2f50e5fd184afa839b271c122a22d8b965ea7c72240624804c73cf3b",
                "MacAddress": "02:42:ac:12:00:02",
                "IPv4Address": "172.1.0.3/16",
                "IPv6Address": ""
            }
        },
        # .........
    }
]
```

Get the ip address of node 2 from IPv4Address corresponding to container id and add peer using on node 1's shell the command:
```
admin.addPeer("enode://4f3c1f87914a68255f9b736aa**ac754d7558ba@172.1.0.3:30303")
```

Use `admin.peers` to check peer. Similarly add peer to node 2 using node 1's enode and ip address

The nodes are now connected and can be used to carry out transactions.

**Running Transactions on Testnet (Ropsten)**

Start syncing on ropsten testnet using `geth --testnet --syncmode "light"`. Enter geth console from another cmd line tab using `geth --testnet attach`. 
Some basic commands on geth console :

*  `eth.syncing` - returns current block number, highest block number etc and can be used to track sync progress (returns false when sync is complete)
*  `eth.blockNumber` - returns the current block number being synced
*  `eth.accounts` - returns array of accounts present in the geth directory
*  `eth.getBalance($account_key)` - returns balance of the entered account

To run transactions from geth console, we have to create account, request ether and write transaction. Create new account using `personal.newAccount()`. Now add ether
to this account from ropsten faucet at https://faucet.ropsten.be/.

![](./docs/images/create_account_final.png)
![](./docs/images/ether_final.png)

Now, check account balance using `eth.getBalance()` and unlock account with `personal.unlockAccount()`. Once ether is updated, write transaction as
`eth.sendTransaction($trans)` where `$trans` is transaction object given by `{from: "", to: "", value: web3.toWei(amount, "ether"), gas: value}`

![](./docs/images/transaction_final.png)

You can check the transaction hash using `web3.eth.getTransactionReceipt($transaction_id)`

![](./docs/images/transaction_hash_final.png)


**Problems**

* Problems during installation of go and geth

The readily available go and geth packages are not compatible with the arm processor. Therefore, the desired packages have to be seperately 
downloaded, build and granted permissions. For geth to work, the go version should also be compatible with the geth version.
The issue was resolved by writing the `install-go script` which download and install the latest version of go (1.9.3).

* go is installed still `go: not found` error occurs

update GOPATH variable in environment variables using `export GOPATH=$HOME/go` and then running `source ~/.bash_profile

*  `panic` error while syncing geth

Resolved by doing proxy settings i.e. exporting `HTTP_PROXY` and `HTTPS_PROXY` variables to proxy server given by IT department.

*  `no suitable peers available` while running functions on geth console such as `eth.getBalance` although the node is syncing

The geth client takes time to add peers. Wait and keep trying for upto 20 minutes.

*  Docker container crashes on running `personal.newAccount()` to create an account on the blockchain.

![](./docs/images/error_out_of_memory.png)

Resolved by running the command after the sync is over and running `sudo apt-get clean`. For creation of account, cryptographic functions need to be run which require lot of cache memory for working. 
Creating a new account while syncing can thus lead to out of memory error which crashes the container. If the container crashes even after syncing the node, then run `sudo apt-get clean` as the linux kernel 
stores the packages we had used (even those we have removed) earlier in the cache while can blow up to hundred megabytes if we rapidly add and remove packages.

The memory used by the container can be seen using `docker stats {docker_container_id}` where docker container's id can be seen using `docker container ls`.
The following graph shows memory usage by container over the entire sync. The datapoints are taken using `docker stats --no-stream {docker_container_id}`
 every 10 seconds using the `command.txt` file and running it using `bash command.txt`.

![](./docs/images/sync_cache_graph.PNG)

Free cache available for use can be seen using `free -h`. The following graph shows free cache memory over the sync.

![](./docs/images/sync_docker_graph.PNG)



As mentioned earlier the account creation function `personal.newAccount()` is computationally heavy as can be seen from the graph
 of memory usage by container during account creation after sync is finished. The datapoints are taken as earlier but at 1 sec interval.
 
![](./docs/images/account_cache_graph.PNG)

And free cache memory:

![](./docs/images/account_docker_graph.PNG)

As can be seen from the graph, after syncing the node, about 600 mb of cache memory is available while running the account creation function
 leaves only 40 mb of cache. Moreover even after account creation, memory is not freed and only about 80 mb is available unless the node is stopped and started again.


*  Unresolved errors

Installation of go on the container through dockerfile shows errors while building the dockerfile although building the same dockerfile without making geth shows it installed. Hence, geth has to be separately installed on each container after running the container.

![](./docs/images/error_dockerfile.png)

Error while mining on testnet as well as private node - Unresolved. The underlying miner functions might be incompatible with the arm processor.

