#!/bin/bash
free -m|awk '{print $1,$2,$3}'|column -t