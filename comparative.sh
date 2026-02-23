#!/bin/bash

./d3d12-ubench.exe --filter $1 --max-test-seconds 2 --output native.csv
./d3d12-ubench.exe --filter $1 --max-test-seconds 2 --vkd3d-proton --d3d12 d3d12core_heap.dll --output heap.csv
./d3d12-ubench.exe --filter $1 --max-test-seconds 2 --vkd3d-proton --d3d12 d3d12core_db.dll --output db.csv

echo "DB -> Native"
python analyze_csv.py --first db.csv --second native.csv

echo "DB -> Heap"
python analyze_csv.py --first db.csv --second heap.csv

echo "Heap -> Native"
python analyze_csv.py --first heap.csv --second native.csv

