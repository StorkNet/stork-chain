#!/usr/bin/env bash

# Read the contract name
echo Which contract do you want to deploy \(eg Greeter\)?
read contract

# Read the constructor arguments
echo Enter constructor arguments separated by spaces \(eg 1 2 3\):
read -r args

if [ ${#args} -eq 0 ]; then
    forge create ./src/${contract}.sol:${contract} -i --rpc-url "http://127.0.0.1:8545/"
else
    forge create ./src/${contract}.sol:${contract} -i --rpc-url "http://127.0.0.1:8545/" --constructor-args ${args}
fi