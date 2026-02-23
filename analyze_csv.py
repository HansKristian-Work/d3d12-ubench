#!/usr/bin/env python3

"""
Compares two CSVs
"""

"""
Copyright (c) 2026 Hans-Kristian Arntzen for Valve Corporation
SPDX-License-Identifier: MIT
"""

import sys
import os
import argparse
import collections
import struct
import csv

ProfileCase = collections.namedtuple('ProfileCase', 'median avg stddev_pct')

def read_csv(path):
    runs = {}
    with open(path, 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            if row[0] == 'test':
                continue
            runs[row[0]] = ProfileCase(float(row[1]), float(row[2]), float(row[3]))

    return runs

def main():
    parser = argparse.ArgumentParser(description = 'Script for parsing profiling data.')
    parser.add_argument('--first', type = str, help = 'The first CSV.')
    parser.add_argument('--second', help = 'The second CSV.')

    args = parser.parse_args()
    if not args.first:
        raise AssertionError('Need --first.')
    if not args.second:
        raise AssertionError('Need --second.')

    first_csv = read_csv(args.first)
    second_csv = read_csv(args.second)

    results = []

    for test in first_csv.keys():
        if test not in second_csv:
            print(f'Cannot find test {test} in secondary CSV. Skipping.')
            continue

        first_data = first_csv[test]
        second_data = second_csv[test]
        results.append((test, first_data.median, second_data.median, second_data.median / first_data.median))

    results.sort(key = lambda a: a[3])

    print(f'Timings results going from {args.first} -> {args.second}:')
    for res in results:
        print(f'{res[0]}:')
        print(f'\tmedian time {res[1] * 1e6:.4} us/group -> {res[2] * 1e6:.4} us/group, delta {100.0 * (res[3] - 1.0):.3} %')

if __name__ == '__main__':
    main()

