#!/usr/bin/env python3

# Note: This script is run inside the `test-data-timescale` service (unsing the
# timescale/timescaledb-ha image), i.e. we can only import the packages listed
# by
#
#   task compose -- exec test-data-timescale pip list
#
# Test the script with an incantation like
#
#   task compose -- exec test-data-timescale /test-data/generate-data.py

import csv
import datetime as dt
import random
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('values', metavar='value', nargs='+', help='Examples: {time.isoformat()}, {random.randint(0, 100)}, round(random.uniform(0.00, 100.00), 2)')
parser.add_argument('--start-time', help='A time in ISO 8601 format, e.g "2021-01-01"')
parser.add_argument('--end-time', help='A time in ISO 8601 format, e.g "2021-01-01"')
parser.add_argument('--number-of-rows', type=int)
parser.add_argument('--interval', type=int, default=60*60, help='Interval in seconds')
parser.add_argument('--interval-wobble', type=int, default=0, help='If set, a random number between -interval-wobble and interval-wobble will be added to the time')
parser.add_argument('--random-seed', type=int, default=0, help='Seed for the random number generator')
parser.add_argument('--debug', action='store_true')
args = parser.parse_args()

if args.random_seed != 0:
    random.seed(args.random_seed)

number_of_rows = args.number_of_rows
values = args.values
start_time = dt.datetime.fromisoformat(args.start_time).astimezone() if args.start_time is not None else None
end_time = dt.datetime.fromisoformat(args.end_time).astimezone() if args.end_time is not None else None
interval = args.interval
interval_wobble = args.interval_wobble

if interval < 1:
    raise ValueError("Interval must be greater than 0")

if interval_wobble is not None and interval_wobble < 0:
    raise ValueError("Interval wobble must be greater than 0")

if number_of_rows is not None and number_of_rows < 0:
    raise ValueError("Number of rows must be greater than 0")

delta = dt.timedelta(seconds=interval)

if start_time is None and end_time is None:
    raise ValueError("A start time or end time must be specified")
elif start_time is None and number_of_rows is None:
    raise ValueError("Number of rows must be specified along with start time")
elif end_time is None and number_of_rows is None:
    raise ValueError("Number of rows must be specified along with end time")

if start_time is not None and end_time is None and number_of_rows > 0:
    end_time = start_time + number_of_rows * delta

if start_time is None and end_time is not None and number_of_rows > 0:
    start_time = end_time - number_of_rows * delta

# https://stackoverflow.com/a/57597617
def generate_values(values):
    return map(lambda template: eval(f"f'{template}'"), values)

writer = csv.writer(sys.stdout)
debug_writer = csv.writer(sys.stderr)

time = start_time
index = 0
while time < end_time:
    time += delta
    if interval_wobble is not None and interval_wobble > 0:
        time += dt.timedelta(seconds=random.randint(-interval_wobble, interval_wobble))

    writer.writerow(generate_values(values))
    if args.debug:
        debug_writer.writerow(generate_values(values))

    index += 1
