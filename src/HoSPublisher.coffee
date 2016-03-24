module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSPublisher extends EventEmitter
        _amqpConnection: null

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options = {durable: true, autoDelete: true}
            isClosed = false
            super()

        connect: ()->
            @_serviceContract = @_HoSCom._serviceContract
            @_serviceId = @_HoSCom._serviceId

            connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            connectionOk.then (conn)=>
                @_amqpConnection = conn
                return conn.createChannel()

            .catch (err)=>
                @isClosed = true
                @emit('error', err)

            .then (ch)=>
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true
                @publishChannel = ch
                @publishChannel.assertExchange(@_HoSCom.HoSPush, 'topic', {durable: true})

        send: (paylaod, destination, headers, isReplyNeeded)->
            return new Promise (fullfil, reject)=>
                sendOption = {messageId: uuid.v1(), timestamp: Date.now(), headers: headers, contentType: 'application/json', expiration: 3600000}
                destinationParts = destination.split '.'
                destService = destinationParts[0]
                sendOption.correlationId = sendOption.messageId
                sendOption.appId = "#{@_serviceContract.name}.#{@_serviceId}"

                key = "#{destService}"
                key += ".#{destinationParts[1]}" if destinationParts[1]

                if isReplyNeeded
                    sendOption.replyTo = "#{@_serviceContract.name}.#{@_serviceId}"
                    @_HoSCom._messagesToReply[sendOption.correlationId] = {fullfil: fullfil, reject: reject}
                    if @_serviceContract.messageTimeout
                        tick= ()=>
                            @_HoSCom._messagesToReply[sendOption.correlationId].reject({code: 404,reason: 'service not found or unavailable'})
                            delete @_HoSCom._messagesToReply[sendOption.correlationId]
                        timer = setTimeout tick, @_serviceContract.messageTimeout
                        @_HoSCom._messagesToReply[sendOption.correlationId].timeout= timer

                @publishChannel.publish(@_HoSCom.HoSPush, key, new Buffer(JSON.stringify paylaod),sendOption)

                if !isReplyNeeded
                    fullfil()

        sendReply: (message, payload)->
            sendOption = {messageId: uuid.v1(), timestamp: message.properties.timestamp, headers: message.properties.headers, contentType: 'application/json', expiration: 3600000}
            sendOption.correlationId = message.properties.correlationId

            @publishChannel.publish(@_HoSCom.HoSPush, message.properties.replyTo, new Buffer(JSON.stringify payload),sendOption)
