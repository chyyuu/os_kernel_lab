#!/bin/bash
./clean.sh
./build.sh
riscvemu32 -ctrlc lab00.cfg
