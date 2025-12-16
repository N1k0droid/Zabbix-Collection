#!/bin/bash

################################################################################
# Script: check_smb_folder_size V2
# Author: Nicola Gurgone
# Date: 05-12-2025
################################################################################

# Parameters: <share> <username> <password> <domain> <metric>
# Items: total, used, free, pfree, pused

SHARE="$1"
USER="$2"
PASS="$3"
DOMAIN="$4"
METRIC="$5"

if [[ ! "$SHARE" =~ ^\\\\.*$ ]]; then
    if [[ "$SHARE" =~ ^\\ ]]; then
        SHARE="\\$SHARE"
    else
        SHARE="\\\\$SHARE"
    fi
fi

#echo "DEBUG: SHARE=$SHARE"

if [ -z "$SHARE" ] || [ -z "$USER" ] || [ -z "$PASS" ] || [ -z "$DOMAIN" ] || [ -z "$METRIC" ]; then
    echo "ERROR: Missing parameters"
    exit 1
fi

OUTPUT=$(smbclient "$SHARE" -U "${DOMAIN}\\${USER}%${PASS}" -W "$DOMAIN" -c "du" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$OUTPUT" ]; then
    echo "ERROR: Failed to connect to SMB share"
    exit 1
fi

BLOCKS_LINE=$(echo "$OUTPUT" | grep "blocks of size")

if [ -z "$BLOCKS_LINE" ]; then
    echo "ERROR: Cannot find blocks information"
    exit 1
fi

TOTAL_BLOCKS=$(echo "$BLOCKS_LINE" | awk '{print $1}')
BLOCK_SIZE=$(echo "$BLOCKS_LINE" | awk '{print $5}' | tr -d '.')
AVAILABLE_BLOCKS=$(echo "$BLOCKS_LINE" | awk '{print $6}')

if [ -z "$TOTAL_BLOCKS" ] || [ -z "$BLOCK_SIZE" ] || [ -z "$AVAILABLE_BLOCKS" ]; then
    echo "ERROR: Failed to parse data. T=$TOTAL_BLOCKS B=$BLOCK_SIZE A=$AVAILABLE_BLOCKS"
    exit 1
fi

if ! [[ "$TOTAL_BLOCKS" =~ ^[0-9]+$ ]] || ! [[ "$BLOCK_SIZE" =~ ^[0-9]+$ ]] || ! [[ "$AVAILABLE_BLOCKS" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid numeric values. T=$TOTAL_BLOCKS B=$BLOCK_SIZE A=$AVAILABLE_BLOCKS"
    exit 1
fi

TOTAL_SIZE=$((TOTAL_BLOCKS * BLOCK_SIZE))
FREE_SIZE=$((AVAILABLE_BLOCKS * BLOCK_SIZE))
USED_SIZE=$((TOTAL_SIZE - FREE_SIZE))

if [ $TOTAL_SIZE -gt 0 ]; then
    PFREE=$(echo "scale=2; $FREE_SIZE * 100 / $TOTAL_SIZE" | bc)
    PUSED=$(echo "scale=2; $USED_SIZE * 100 / $TOTAL_SIZE" | bc)
else
    PFREE=0
    PUSED=0
fi

case "$METRIC" in
    total)
        echo "$TOTAL_SIZE"
        ;;
    used)
        echo "$USED_SIZE"
        ;;
    free)
        echo "$FREE_SIZE"
        ;;
    pfree)
        echo "$PFREE"
        ;;
    pused)
        echo "$PUSED"
        ;;
    *)
        echo "ERROR: Invalid metric. Use: total, used, free, pfree, pused"
        exit 1
        ;;
esac

exit 0
