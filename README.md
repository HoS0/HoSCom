# HoSCom

Communication module for HoS services.

`npm install hos-com`

requirement:
- rabbitMQ

## Example

Each service in HoS environment need to have a contract suitable to its needs, please find the example of a contract in [test/serviceContract](https://github.com/HoS0/HoSCom/blob/master/test/serviceContract.coffee)

Creating an instance of the service:

``` coffee-script
serviceContract = require('./serviceContract')
HoSCom = require('hos-com')

HoSService = new HosCom serviceContract
HoSService.connect()
```

In order to give the library access to the target rabbitMQ you can set following environmental variables:

- AMQP_URL
- AMQP_USERNAME
- AMQP_PASSWORD

or when initializing the service pass as input argument: `HoSService = new HosCom serviceContract, amqpurl, username, password`

`connect()` return a promise for getting connected into HoS environment. after initialization you can send message to other services:

``` coffee-script
ok = HoSService.sendMessage {foo: "bar"} , "ServiceName", {task: 'TaskName', method: 'METHOD'}
```

by default by sending message HoSCom will assume you expect to get a response back in case you do not need a reply you can specify by passing `false` as the last argument of `sendMessage`, `sendMessage` returns a promise which contain the reply message if successful and error in `catch` if the request failed

``` coffee-script
ok.then (replyJSON)=>
    console.log replyJSON
ok.catch (error)=>
    console.log error
```

and according to your service contract `HoSCom` will emit the incoming message events:

``` coffee-script
HoSService.on 'TaskName.METHOD', (msg)=>
```

## Running Tests

Run test by:

`gulp test`

requires local rabbitMQ or setting up `AMQP_URL` , `AMQP_USERNAME` and `AMQP_PASSWORD`


This software is licensed under the MIT License.
