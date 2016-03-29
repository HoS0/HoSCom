module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    HoSConsumer     = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)
    HoSPublisher    = require("./HoSPublisher")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

    class HoSCom extends EventEmitter
        _serviceContract: null
        _serviceId: null
        Publisher: null

        constructor: (@_serviceContract, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD, @HoSPush = 'HoSPush', @HoSPull = 'HoSPull') ->
            @HoSConsumers = []
            @_messagesToReply = {}
            super()

            ServiceInfo =
                ID: crypto.randomBytes(10).toString('hex')
                CreateOn: Date.now()
                HostName: os.hostname()

            @_serviceId = URLSafeBase64.encode(new Buffer(JSON.stringify ServiceInfo))

            @_paths = []
            if @_serviceContract.serviceDoc.paths
                for path in Object.keys(@_serviceContract.serviceDoc.paths)
                    pathToPush = path.replace(/(\{.*?\}) */g, '')
                    pathToPush = pathToPush.replace(/\//g, '');
                    @_paths.push pathToPush

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
            task    = msg.properties.headers.task.replace('/','')
            method  = msg.properties.headers.method

            if task is 'contract' and method is 'get'
                msg.reply(@_serviceContract)
                return

            if task and method and @_paths.indexOf(task) isnt -1
                @emit("#{msg.properties.headers.task}.#{method}", msg)
                return

            msg.reject("this service is not offering the following task.", 404)
