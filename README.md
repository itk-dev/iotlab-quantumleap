# IOTLab QuantumLeap

Based on <https://quantumleap.readthedocs.io/>.

Start the show:

``` shell name=start
docker compose pull
docker compose up --detach --wait

open https://orion.quantumleap.local.itkdev.dk
open https://grafana.quantumleap.local.itkdev.dk
```

``` shell name=orion-subscription-create
# https://quantumleap.readthedocs.io/en/latest/user/using/#orion-subscription
docker compose exec --no-TTY orion curl --silent --show-error localhost:1026/v2/subscriptions --header 'content-type: application/json' --data @- <<EOF
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
docker compose exec --no-TTY orion curl --silent --show-error localhost:1026/v2/subscriptions | jq
```

``` shell name=orion-entity-create
# https://fiware-orion.readthedocs.io/en/master/user/walkthrough_apiv2.html#entity-creation
docker compose exec --no-TTY orion curl --silent --show-error localhost:1026/v2/entities --header 'content-type: application/json' --data @- <<EOF
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
docker compose exec --no-TTY orion curl --silent --show-error localhost:1026/v2/entities/Room1/attrs --header 'content-type: application/json' --data @- <<EOF
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
docker compose exec timescale psql quantumleap quantumleap --command '\dt'
docker compose exec timescale psql quantumleap quantumleap --command 'SELECT * FROM etroom'
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
