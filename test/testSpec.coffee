generalContract = require('./serviceContract')
HosCom = require('../index')
Promise = require('bluebird')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "alikh"
password    = process.env.AMQP_PASSWORD ? "alikh12358"

describe "Create service", ()->
    it "and it should create 10 instances of hos and destroy them", (done)->
        services = []
        instances = []

        for i in [0 .. 10]
            serviceCon = JSON.parse(JSON.stringify(generalContract))
            serviceCon.name = "serviceTest#{i}"
            ins = new HosCom(serviceCon, amqpurl, username, password)
            instances.push(ins)
            services.push(ins.connect())

        Promise.all(services).then ()->
            for s in instances
                s.destroy()
            done()


    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "serviceTest"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service2Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                for i in [ 1 .. 100 ]
                    @service2.sendMessage {foo: "bar"} , @serviceCon.name, {task: 'users', method: 'GET'}

        count = 0
        @service1.on 'users.GET', (msg)=>
            msg.reply()
            count = count + 1
            if count is 100
                @service2.destroy()
                @service1.destroy()
                done()


    it "and it sends a message and get the reply", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "service4Test"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service5Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage({foo: "bar"} , @serviceCon.name, {task: 'users', method: 'GET'}).then (replyPayload)=>
                    expect(replyPayload.foo).toEqual('notbar');
                    @service2.destroy()
                    @service1.destroy()
                    done()

        @service1.on 'users.GET', (msg)=>
            msg.reply({foo: "notbar"})


    it "and it sends a message have the reply plus one", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "service6Test"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service7Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage({foo: 1} , @serviceCon.name, {task: 'users', method: 'GET'}).then (replyPayload)=>
                    expect(replyPayload.foo).toEqual(2);
                    @service2.destroy()
                    @service1.destroy()
                    done()

        @service1.on 'users.GET', (msg)=>
            msg.content.foo = msg.content.foo + 1
            msg.reply(msg.content)

    it "and get the other service contract", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "service9Test"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service10Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage({} , @serviceCon.name, {task: 'contract', method: 'GET'}).then (replyPayload)=>
                    expect(JSON.stringify replyPayload).toEqual(JSON.stringify @serviceCon);
                    @service2.destroy()
                    @service1.destroy()
                    done()

    it "and get an error on reply for non-existence task", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "service11Test"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service12Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage({} , @serviceCon.name, {task: 'nonexistence', method: 'GET'})
                .then (replyPayload)=>
                    console.log replyPayload
                .catch (error)=>
                    expect(error.code).toEqual(404);
                    @service2.destroy()
                    @service1.destroy()
                    done()

    it "and it sends a message reject in for internal reason", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "service6Test"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service7Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage({foo: 1} , @serviceCon.name, {task: 'users', method: 'GET'})
                .then (replyPayload)=>
                    console.log replyPayload
                .catch (error)=>
                    expect(error.code).toEqual(501);
                    expect(error.reason).toEqual('internal issue');
                    @service2.destroy()
                    @service1.destroy()
                    done()

        @service1.on 'users.GET', (msg)=>
            msg.content.foo = msg.content.foo + 1
            msg.reject('internal issue', 501)
