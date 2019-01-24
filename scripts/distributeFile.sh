##!/usr/bin/env bash
#$1 - the file to distribute
#$2 - the connection path "user@IP:/some/remote/path"
#example usage:
## . $(pwd)/distributeBinary.sh \
##   $(pwd)/some/file/at/current/path \
##   $SOME_USER@$SOME_IP:/some/remote/path
scp -i ~/.ssh/id_rsa $1 $2
