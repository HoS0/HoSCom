module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options= {durable: true, autoDelete: true}
            @isClosed= false
            super()

        connect: ()->
            @_serviceContract = @_HoSCom._serviceContract
            @_serviceId = @_HoSCom._serviceId

            connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            connectionOk.catch (err)=>
                @isClosed = true
                @emit('error', err)

            connectionOk.then (conn)=>
                @_amqpConnection = conn
                return conn.createChannel()

            .then (ch)=>
                ch.prefetch(@_HoSCom._serviceContract.prefetch)
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true

                @consumeChannel = ch
                @_CreatServiceExchange()

        _CreatServiceExchange: ()->
            if @consumeChannel
                HoSExOk = @consumeChannel.assertExchange(@_HoSCom.HoSPull, 'topic', {durable: true})
                HoSExOk.then ()=>
                    ok = @consumeChannel.assertExchange(@_serviceContract.serviceDoc.basePath, 'topic', @_options)
                    ok.then ()=>
                        res = []
                        res.push @consumeChannel.bindExchange(@_serviceContract.serviceDoc.basePath,@_HoSCom.HoSPull,"#{@_serviceContract.serviceDoc.basePath}.#")
                        res.push @_CreateQueue "#{@_serviceContract.serviceDoc.basePath}.#{@_serviceId}", "#{@_serviceContract.serviceDoc.basePath}", @_serviceId
                        res.push @_CreateQueue "#{@_serviceContract.serviceDoc.basePath}", "#{@_serviceContract.serviceDoc.basePath}"

                        Promise.all(res)
            else
                @emit('error', 'no consume channel')
                reject()

        _CreateQueue: (queueName, bindingKey, id)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                if id
                    bindingKey += ".#{id}"

                @consumeChannel.bindQueue(queueName, @_serviceContract.serviceDoc.basePath, bindingKey).then ()=>
                    @consumeChannel.bindQueue(queueName, @_serviceContract.serviceDoc.basePath, "#{bindingKey}.broadcast").then ()=>
                        pm = (msg)=>
                            @_processMessage(msg)
                        @consumeChannel.consume(queueName, pm)

        _processMessage: (msg)->
            if @_processRepliedMessage msg
                return

            if msg.properties.contentType is 'application/json' and msg.content
                msg.content = JSON.parse msg.content

            msg.reply = (payload)=>
                if !payload
                    payload = {}
                @consumeChannel.ack(msg)
                if payload and msg.properties.replyTo
                    @_HoSCom.Publisher.sendReply(msg, payload)

            msg.reject = (reason = "failed", code = 500)=>
                @consumeChannel.ack(msg)
                msg.properties.headers.error = code
                msg.properties.headers.errorMessage = reason
                if reason and msg.properties.replyTo
                    @_HoSCom.Publisher.sendReply(msg, {error: reason})

            @emit('message', msg)

        _processRepliedMessage: (msg)->
            if @_HoSCom._messagesToReply[msg.properties.correlationId]
                if @_HoSCom._messagesToReply[msg.properties.correlationId].timeout
                    clearTimeout @_HoSCom._messagesToReply[msg.properties.correlationId].timeout
                @consumeChannel.ack(msg)
                rep = @_HoSCom._messagesToReply[msg.properties.correlationId]
                if typeof rep.fullfil is 'function'
                    if msg.properties.headers.error
                        rep.reject({code: msg.properties.headers.error,reason: msg.properties.headers.errorMessage})
                    else
                        if msg.properties and msg.properties.headers and msg.properties.headers.replyWholeMessage
                            msg.content = JSON.parse msg.content
                            rep.fullfil(msg)
                        else
                            rep.fullfil(JSON.parse msg.content)

                    delete @_HoSCom._messagesToReply[msg.properties.correlationId]
                    return true
            return false
