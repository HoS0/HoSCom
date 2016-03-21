generalContract = require('./serviceContract')
HosCom          = require('../index')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

@serviceCon = JSON.parse(JSON.stringify(generalContract))
@serviceCon.name = "service4Test"
@service1 = new HosCom @serviceCon, amqpurl, username, password

@serviceCon2 = JSON.parse(JSON.stringify(generalContract))
@serviceCon2.name = "service5Test"
@service2 = new HosCom @serviceCon2, amqpurl, username, password

@service1.connect().then ()=>
    @service2.connect().then ()=>
        @service2.sendMessage({} , @serviceCon.name, {task: 'jjcontract', method: 'GET'})
        .then (replyPayload)=>
            console.log replyPayload
            #if replyPayload.foo is 'notbar'
            @service2.destroy()
            @service1.destroy()
        .catch (reason)=>
            console.log reason
            @service2.destroy()
            @service1.destroy()

@service1.on 'message', (msg)=>
    console.log msg
    msg.reply(msg.content)
