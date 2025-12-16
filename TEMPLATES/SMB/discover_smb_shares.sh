#!/bin/bash
################################################################################
# Script: discover_smb_shares.sh
# Author: N1k0droid
# Date: 05-12-2025
################################################################################

# Parameters: <shares_list>
# Format: "\\server1\share1,\\server2\share2,\\server3\share3"

SHARES_LIST="$1"

if [ -z "$SHARES_LIST" ]; then
    echo '{"data":[]}'
    exit 0
fi

echo -n '{"data":['

FIRST=1
IFS=',' read -ra SHARES <<< "$SHARES_LIST"

for SHARE in "${SHARES[@]}"; do
    if [ -z "$SHARE" ]; then
        continue
    fi

    SHARE_NAME="${SHARE#\\\\}"
    SHARE_NAME=$(echo "$SHARE_NAME" | tr '\\' '/')

    if [ $FIRST -eq 0 ]; then
        echo -n ','
    fi
    FIRST=0

    SHARE_ESCAPED=$(echo "$SHARE" | sed 's/\\/\\\\/g')

    echo -n "{\"{#SMB_SHARE}\":\"$SHARE_ESCAPED\",\"{#SMB_SHARE_NAME}\":\"$SHARE_NAME\"}"
done

echo ']}'

exit 0
