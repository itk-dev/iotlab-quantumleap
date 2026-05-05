# IOTLab QuantumLeap

Based on <https://quantumleap.readthedocs.io/>.

Start the show:

``` shell name=start
task install
task start

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

``` shell name=scorpio-entity-create
# https://fiware-scorpio.readthedocs.io/en/master/user/walkthrough_apiv2.html#entity-creation
task compose -- exec --no-TTY scorpio curl --silent --show-error localhost:9090/ngsi-ld/v1/entities --header 'content-type: application/json' --data @- <<EOF
{
  "id": "urn:room1",
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

``` shell name=scorpio-entity-get
task compose -- exec --no-TTY scorpio curl --silent --show-error 'localhost:9090/ngsi-ld/v1/entities?type=*'
```

``` shell name=scorpio-entity-update
# https://fiware-scorpio.readthedocs.io/en/master/user/walkthrough_apiv2.html#entity-creation
task compose -- exec --no-TTY scorpio curl --silent --show-error localhost:9090/ngsi-ld/v1/entities/urn%3Aroom1/attrs --header 'content-type: application/json' --data @- <<EOF
{
  "temperature": {
    "value": $((1 + RANDOM % 10)),
    "observedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF

# https://stackoverflow.com/a/49189559
task compose -- exec --no-TTY scorpio curl --silent --show-error localhost:9090/ngsi-ld/v1/entities/urn%3Aroom1/attrs/temperature --header 'content-type: application/json' --request PATCH --data @- <<EOF
{
  "value": $((1 + RANDOM % 10)),
  "observedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
```

``` shell name=scorpio-temporal
#task compose -- exec scorpio curl --silent --show-error 'localhost:9090/ngsi-ld/v1/entities?type=Room'
# task compose -- exec scorpio curl --silent --show-error 'localhost:9090/ngsi-ld/v1/temporal/entities?type=Room&attr=pressure'
# task compose -- exec scorpio curl --silent --show-error 'localhost:9090/ngsi-ld/v1/temporal/entities?type=Room&attr=pressure&options=temporalValues'
task compose -- exec scorpio curl --silent --show-error 'localhost:9090/ngsi-ld/v1/temporal/entities?type=Room&attr=pressure&timerel=between&timeAt=2025-05-05T12:03:58.903Z&endTimeAt=2027-05-05T13:03:58.903Z&options=temporalValues'

# temporal/temporal/entities?type=Room&attrs=pressure&timerel=between&timeAt=2026-05-05T12:03:58.903Z&endTimeAt=2026-05-05T13:03:58.903Z&format=temporalValues
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

## Grafana plugins

### NGSI-LD Grafana datasource plugin

[NGSI-LD Grafana datasource plugin](https://github.com/bfi-de/ngsild-grafana-datasource); datasource setup:

| Name                | Value                            |
|---------------------|----------------------------------|
| Context broker URL  | `http://scorpio:9090`            |
| Temporal broker URL | `http://scorpio:9090/ngsi-ld/v1` |
| Format parameter    | options                          |
| Access              | proxy                            |
| Flavour             | generic                          |

> [!IMPORTANT]
> The value of "Temporal broker URL" _must_ be the value of "Context broker URL" followed by `/ngsi-ld/v1`.
