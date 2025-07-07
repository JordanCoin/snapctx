#!/usr/bin/env bash

json_kv() { jq -n --arg k "$1" --arg v "$2" '{($k):$v}'; }
merge_json() { jq -s 'reduce .[] as $item ({}; . += $item)'; }
