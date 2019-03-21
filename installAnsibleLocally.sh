#!/bin/bash

sudo apt-get update && sudo apt-get install -y libssl-dev libffi-dev python-dev python-pip 
sudo pip install ansible[azure]
