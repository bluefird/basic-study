#!/bin/bash
ip add|grep "eth" | grep inet|awk '{print $NF,$2}'|sed 's/\(.*\)\/[1-9]*/\1/g'