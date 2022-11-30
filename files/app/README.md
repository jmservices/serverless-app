# Prerequisites

## Application block diagram:
![alt Infrastructure Diagram](https://github.com/jmservices/serverless-app/blob/master/files/app/docs/diagram.png)


## Test application in local environment:

### Install python `python-lambda-local` to execute lambda function handler locally.

```
pip3 install python-lambda-local
```

### Deploy local dynamo DB
```
docker-compose -f tests/docker-dynamodb.yml up -d
```

### Positive Test #1 : Output
```
python-lambda-local -f lambda_handler -t 5 -e env.json api.py tests/getPositive.json
```
### Negative Test #1 : Output
```
python-lambda-local -f lambda_handler -t 5 -e env.json api.py tests/getNegative.json
```
### Negative Test #2 : Input
```
python-lambda-local -f lambda_handler -t 5 -e env.json api.py tests/putNegative.json
```
### Negative Test #2 : Input
```
python-lambda-local -f lambda_handler -t 5 -e env.json api.py tests/putNegative.json
```
### Negative Test #3 : Input
```
python-lambda-local -f lambda_handler -t 5 -e env.json api.py tests/putNegative2.json
```