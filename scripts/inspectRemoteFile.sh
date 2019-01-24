##!/usr/bin/env bash
#$1 - the remote ip
#$2 - the remote file path
ssh -i ~/.ssh/id_rsa -tq $REMOTE_SUDO_USER@$1 "cat $2"
