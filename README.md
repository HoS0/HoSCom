![build status](https://travis-ci.org/HoS0/HoSCom.svg?branch=master)

# HoSCom

Communication module for HoS services.

`npm install hos-com`

requirement:
- rabbitMQ

## Example

Each service in HoS environment need to have a contract suitable to its needs, please find the example of a contract in [test/serviceContract](https://github.com/HoS0/HoSCom/blob/master/test/serviceContract.coffee)

In HoS we love [swagger](http://swagger.io/). before developing your service you need to write your documentation ether in swagger or other tools like [API bluepring](https://apiary.io/) and convert it to swagger JSON and includes it in your service contract, note that other service will send messages to each other base on `basePath` they should start with `/`, which in each service should be unique, tasks are in `paths` and also should start with `/`.

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
ok = HoSService.sendMessage {foo: "1"} , "/ServiceName", {task: '/TaskName', method: 'method'}
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
HoSService.on '/TaskName.method', (msg)=>
```

A message should be replied or rejected, ether with content or without content(in which case the reply won't be send to requester but just allows the HoSCom to acknowledge the message and free service queue in rabbitMQ)

``` coffee-script
msg.content.foo = msg.content.foo + 1
msg.reply(msg.content)
```

message can be rejected `msg.reject('internal issue', 501)` default value for error code is `500`.

Note: for using the current package you have to have a running HoSAuth service to authenticate validation of the packages, for more info please refer to [HoSAuth](https://github.com/HoS0/HoSAuth)

## Running Tests

Run test by:

`gulp test`

requires local rabbitMQ or setting up `AMQP_URL` , `AMQP_USERNAME` and `AMQP_PASSWORD`


This software is licensed under the MIT License.
