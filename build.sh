#!/bin/sh
forge build --root imports_naked --out imports_naked/output --sizes --force
sleep 1
forge build --root imports_named --out imports_named/output --sizes --force
