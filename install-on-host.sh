#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory -l $1  15-phase1-waf-deploy.yaml
