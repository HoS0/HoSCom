generalContract = require('./serviceContract')
HosCom          = require('../index')
Promise         = require('bluebird')
crypto          = require('crypto')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "alikh"
password    = process.env.AMQP_PASSWORD ? "alikh12358"

describe "Create service", ()->
    it "and it should create 10 instances of hos and destroy them", (done)->
        services = []
        instances = []

        # create different services
        for i in [0 .. 10]
            serviceCon = JSON.parse(JSON.stringify(generalContract))
            serviceCon.name = "serviceTest#{i}"

            # create different instances for each service
            for i in [0 .. 5]
                ins = new HosCom(serviceCon, amqpurl, username, password)
                instances.push(ins)
                services.push(ins.connect())

        Promise.all(services).then ()->
            for s in instances
                s.destroy()
            done()

describe "Check basic operations", ()->
    beforeEach ()->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "serviceTest#{crypto.randomBytes(4).toString('hex')}"
        @serviceOne = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "serviceTest#{crypto.randomBytes(4).toString('hex')}"
        @serviceTwo = new HosCom @serviceCon2, amqpurl, username, password

    afterEach ()->
        @serviceOne.destroy()
        @serviceTwo.destroy()

    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                for i in [ 1 .. 100 ]
                    @serviceTwo.sendMessage {foo: "bar"} , @serviceCon.name, {task: 'users', method: 'GET'}

        count = 0
        @serviceOne.on 'users.GET', (msg)=>
            msg.reply()
            count = count + 1
            if count is 100
                done()


    it "and it sends a message and get the reply", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                @serviceTwo.sendMessage({foo: "bar"} , @serviceCon.name, {task: 'users', method: 'GET'}).then (replyPayload)=>
                    expect(replyPayload.foo).toEqual('notbar');
                    done()

        @serviceOne.on 'users.GET', (msg)=>
            msg.reply({foo: "notbar"})


    it "and it sends a message have the reply plus one", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                @serviceTwo.sendMessage({foo: 1} , @serviceCon.name, {task: 'users', method: 'GET'}).then (replyPayload)=>
                    expect(replyPayload.foo).toEqual(2);
                    done()

        @serviceOne.on 'users.GET', (msg)=>
            msg.content.foo = msg.content.foo + 1
            msg.reply(msg.content)

    it "and get the other service contract", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                @serviceTwo.sendMessage({} , @serviceCon.name, {task: 'contract', method: 'GET'}).then (replyPayload)=>
                    expect(JSON.stringify replyPayload).toEqual(JSON.stringify @serviceCon);
                    done()

    it "and get an error on reply for non-existence task", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                @serviceTwo.sendMessage({} , @serviceCon.name, {task: 'nonexistence', method: 'GET'})
                .then (replyPayload)=>
                    console.log replyPayload
                .catch (error)=>
                    expect(error.code).toEqual(404);
                    done()

    it "and it sends a message reject in for internal reason", (done)->
        @serviceOne.connect().then ()=>
            @serviceTwo.connect().then ()=>
                @serviceTwo.sendMessage({foo: 1} , @serviceCon.name, {task: 'users', method: 'GET'})
                .then (replyPayload)=>
                    console.log replyPayload
                .catch (error)=>
                    expect(error.code).toEqual(501);
                    expect(error.reason).toEqual('internal issue');
                    done()

        @serviceOne.on 'users.GET', (msg)=>
            msg.content.foo = msg.content.foo + 1
            msg.reject('internal issue', 501)
