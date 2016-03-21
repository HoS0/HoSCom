module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    HoSConsumer     = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)
    HoSPublisher    = require("./HoSPublisher")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

    class HoSCom extends EventEmitter
        _serviceContract: null
        _serviceId: null
        Publisher: null

        constructor: (@_serviceContract, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @HoSConsumers = []
            @_messagesToReply = {}
            super()

            ServiceInfo =
                ID: crypto.randomBytes(10).toString('hex')
                CreateOn: Date.now()
                HostName: os.hostname()

            @_serviceId = URLSafeBase64.encode(new Buffer(JSON.stringify ServiceInfo))

        connect: ()->
            promises = []
            for i in [0 .. @_serviceContract.consumerNumber - 1]
                con = new HoSConsumer(@, @amqpurl, @username, @password)
                promises.push con.connect()
                con.on 'error', (msg)=>
                    # console.log msg
                con.on 'message', (msg)=>
                    @_processMessage(msg)
                @HoSConsumers.push con

            @Publisher = new HoSPublisher(@, @amqpurl, @username, @password)

            promises.push @Publisher.connect()

            Promise.all(promises)

        sendMessage: (payload, destination, headers, isReplyNeeded = true)->
            return @Publisher.send(payload, destination, headers, isReplyNeeded)

        destroy: ()->
            @Publisher._amqpConnection.close()

            for con in @HoSConsumers
                con._amqpConnection.close()

        _processMessage: (msg)->
            task    = msg.properties.headers.task
            method  = msg.properties.headers.method

            if task is 'contract' and method is 'GET'
                msg.reply(@_serviceContract)
                return

            if task and method and @_serviceContract.tasks[task]
                @emit("#{task}.#{method}", msg)
                return

            msg.reject("this service is not offering the following task.", 404)
