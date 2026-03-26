import csv
import datetime as dt
import random
import sys
import uuid

random.seed(19750523)

number_of_rows=100_000_000
number_of_rows=1_000_000

filename='initdb.d/etrefrigerator-sensor.csv'

entity_type = 'refrigerator-sensor'
entity_id = 'refrigerator-sensor:5e318760-Milesight'
fiware_servicepath = ''
instanceid = f'urn:ngsi-ld:{uuid.UUID(int=random.getrandbits(128))}'
appliance = 'Fryser'
department = 'Department'
floor = 'floor'
name = 'name'
room = 'room'

writer = csv.writer(sys.stdout)
time = dt.datetime(2025, 1, 1).astimezone()

for i in range(number_of_rows):
    time_index = 0
    __original_ngsi_entity__ = None # '{}'
    battery = random.randint(0, 100)
    humidity = round(random.uniform(0.00, 100.00), 2)
    temperature = round(random.uniform(-10, 20), 2)

    writer.writerow([
        entity_id,
        entity_type,
        time.isoformat(),
        fiware_servicepath,
        __original_ngsi_entity__,
        instanceid,
        appliance,
        battery,
        department,
        floor,
        humidity,
        name,
        room,
        temperature,
    ])

    time += dt.timedelta(minutes=10)

# print(f'{number_of_rows} rows written to file {filename}.')
