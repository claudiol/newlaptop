#!/bin/sh

ANSIBLE_COW_SELECTION=tux ansible-playbook ~/bin/ansible/upgrade-silverblue.yaml --ask-become-pass
