#! /usr/bin/env bash

# -----------------------------------------------------------------------
# Script configuration
# -----------------------------------------------------------------------
# Owner is the owner passed to ownables contracts
OWNER='0x5f2cbede27de610a215a63a9cbbf1d99787a12a9'
# Admin is the account used to deploy and manage upgrades.
# After deployment the multisig wallet is set to Admin
ADMIN='0x1df62f291b2e969fb0849d99d9ce41e2f137006e'
# Config variables for initializers
stake='10'
maxSlots='1'
# load NETWORK from environment
NETWORK=${NETWORK:-development}

# -----------------------------------------------------------------------
# Script setup
# -----------------------------------------------------------------------
# Set zos session (network, admin, timeout)
npx zos session --network $NETWORK --from $ADMIN --expires 36000
# Setup multisig wallet
npx truffle exec scripts/setupWallet.js
# Get wallet address
MULTISIG=$(jq -r '.wallet' wallet.json)
# Clean up
rm -f zos.*

# -----------------------------------------------------------------------
# Project setup using zOS
# -----------------------------------------------------------------------
# List of contracts
declare -a contracts=("DIDRegistry" "OceanToken" "Dispenser" "ServiceExecutionAgreement" "AccessConditions" "PaymentConditions" "FitchainConditions" "ComputeConditions")
# Initialize project zOS project
# NOTE: Creates a zos.json file that keeps track of the project's details
npx zos init oceanprotocol 0.1.poc -v
# Register contracts in the project as an upgradeable contract.
for contract in "${contracts[@]}"
do
    npx zos add $contract -v --skip-compile
done

# Deploy all implementations in the specified network.
# NOTE: Creates another zos.<network_name>.json file, specific to the network used, which keeps track of deployed addresses, etc.
npx zos push --skip-compile  -v
# Request a proxy for the upgradeably contracts.
# Here we run initialize which replace contract constructors
# Since each contract initialize function could be different we can not use a loop
# NOTE: A dapp could now use the address of the proxy specified in zos.<network_name>.json
# instance=MyContract.at(proxyAddress)
npx zos create DIDRegistry --init initialize --args $OWNER -v
token=$(npx zos create OceanToken --init -v)
dispenser=$(npx zos create Dispenser --init initialize --args $token,$OWNER -v)
service=$(npx zos create ServiceExecutionAgreement -v)
npx zos create AccessConditions --init initialize --args $service -v
npx zos create PaymentConditions --init initialize --args $service,$token -v
npx zos create FitchainConditions --init initialize --args $service,$stake,$maxSlots -v
npx zos create ComputeConditions --init initialize --args $service -v

# -----------------------------------------------------------------------
# Change admin priviliges to multisig
# -----------------------------------------------------------------------
for contract in "${contracts[@]}"
do
    npx zos set-admin $contract $MULTISIG --yes
done