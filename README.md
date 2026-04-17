# IOTLab QuantumLeap

Based on <https://quantumleap.readthedocs.io/>.

Start the show:

``` shell name=start
task compose -- pull
task compose -- up --detach --wait

open https://orion.quantumleap.local.itkdev.dk
open https://grafana.quantumleap.local.itkdev.dk
```

``` shell name=orion-subscription-create
# https://quantumleap.readthedocs.io/en/latest/user/using/#orion-subscription
task compose -- exec --no-TTY orion curl --silent --show-error localhost:1026/v2/subscriptions --header 'content-type: application/json' --data @- <<EOF
{
    "description": "Test subscription",
    "subject": {
        "entities": [
            {
                "idPattern": ".*",
                "type": "Room"
            }
        ]
    },
    "notification": {
        "http": {
            "url": "http://quantumleap:8668/v2/notify"
        },
        "metadata": ["dateCreated", "dateModified"]
    },
    "throttling": 5
}
EOF
```

``` shell name=orion-subscriptions-get
task compose -- exec --no-TTY orion curl --silent --show-error localhost:1026/v2/subscriptions | jq
```

``` shell name=orion-entity-create
# https://fiware-orion.readthedocs.io/en/master/user/walkthrough_apiv2.html#entity-creation
task compose -- exec --no-TTY orion curl --silent --show-error localhost:1026/v2/entities --header 'content-type: application/json' --data @- <<EOF
{
  "id": "Room1",
  "type": "Room",
  "temperature": {
    "value": 23,
    "type": "Float"
  },
  "pressure": {
    "value": 720,
    "type": "Integer"
  }
}
EOF
```


``` shell name=orion-entity-update substitutions="{«temperature.value»: 87, «pressure.value»: 42}"
# https://fiware-orion.readthedocs.io/en/master/user/walkthrough_apiv2.html#update-entity
task compose -- exec --no-TTY orion curl --silent --show-error localhost:1026/v2/entities/Room1/attrs --header 'content-type: application/json' --data @- <<EOF
{
  "temperature": {
    "value": «temperature.value»,
    "type": "Float"
  },
  "pressure": {
    "value": «pressure.value»,
    "type": "Float"
  }
}
EOF
```

Talk to the timescale database:

``` shell name=timescale-query
task compose -- exec timescale psql quantumleap quantumleap --command '\dt'
task compose -- exec timescale psql quantumleap quantumleap --command 'SELECT * FROM etroom'
```

Generate some random data:

``` shell name=generate-random-data
while true; do
    temperature=$((-20 + $RANDOM % 50))
    pressure=$(($RANDOM % 1024))
    echo "temperature: $temperature; pressure: $pressure"
    markdown-code-runner run orion-entity-update --substitutions "{«temperature.value»: $temperature, «pressure.value»: $pressure}"
    sleep 1
done
```


``` shell
markdown-code-runner run orion-subscription-create orion-subscriptions-get
markdown-code-runner run orion-entity-create generate-random-data
```

## Production

Create/edit `.env.docker.local`:

``` dotenv
COMPOSE_PROJECT_NAME=quantumleap
COMPOSE_DOMAIN=quantumleap.srvitkiotlab.itkdev.dk
COMPOSE_FILES=docker-compose.yml,docker-compose.prod.yml
```

## Test data

``` shell
task test-data:load
```

## Data types

QuantumLeap tries to guess data types, but sometimes guesses wrong and may need a little help, e.g.

``` sql
# The first "temperature" data may have been integral.
ALTER TABLE "etrefrigerator-sensor" ALTER COLUMN temperature TYPE DOUBLE PRECISION;
ALTER TABLE "etrefrigerator-sensor" ALTER COLUMN battery TYPE DOUBLE PRECISION;
```

<https://github.com/orchestracities/ngsi-timeseries-api/issues/778#:~:text=the%20moment%2C%20but-,the%20situation%20might%20change%20in%20Q2%202026%20if%20we%20get%20funded,-.>




* <https://quantumleap.iotlab-quantumleap.srvitkiotlab.itkdev.dk/v2/entities?type=refrigerator-sensor>
* <https://quantumleap.iotlab-quantumleap.srvitkiotlab.itkdev.dk/v2/entities?typePattern=*>
* <https://quantumleap.iotlab-quantumleap.srvitkiotlab.itkdev.dk/v2/entities/refrigerator-sensor:2515-Milesight>



``` sql
quantumleap=> CREATE INDEX ON public."etrefrigerator-sensor" (department);
CREATE INDEX

quantumleap=> EXPLAIN ANALYSE SELECT * FROM "etrefrigerator-sensor" WHERE department = 'test';
                                                                            QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using "etrefrigerator-sensor_department_idx" on "etrefrigerator-sensor"  (cost=0.42..8.44 rows=1 width=322) (actual time=0.072..0.073 rows=0 loops=1)
   Index Cond: (department = 'test'::text)
 Planning Time: 0.623 ms
 Execution Time: 0.142 ms
(4 rows)

quantumleap=> DROP INDEX "etrefrigerator-sensor_department_idx";
DROP INDEX

quantumleap=> EXPLAIN ANALYSE SELECT * FROM "etrefrigerator-sensor" WHERE department = 'test';
                                                             QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8122.64 rows=1 width=322) (actual time=32.369..36.594 rows=0 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on "etrefrigerator-sensor"  (cost=0.00..7122.54 rows=1 width=322) (actual time=8.708..8.709 rows=0 loops=3)
         Filter: (department = 'test'::text)
         Rows Removed by Filter: 105123
 Planning Time: 0.263 ms
 Execution Time: 36.625 ms
(8 rows)

quantumleap=> SELECT * FROM pg_indexes WHERE tablename = 'etrefrigerator-sensor';
 schemaname |       tablename       |              indexname               | tablespace |                                                           indexdef
------------+-----------------------+--------------------------------------+------------+-------------------------------------------------------------------------------------------------------------------------------
 public     | etrefrigerator-sensor | etrefrigerator-sensor_time_index_idx |            | CREATE INDEX "etrefrigerator-sensor_time_index_idx" ON public."etrefrigerator-sensor" USING btree (time_index DESC)
 public     | etrefrigerator-sensor | ix_etrefrigerator-sensor_eid_and_tx  |            | CREATE INDEX "ix_etrefrigerator-sensor_eid_and_tx" ON public."etrefrigerator-sensor" USING btree (entity_id, time_index DESC)
(2 rows)
```
