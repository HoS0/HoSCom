amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./serviceContract')
uuid            = require('node-uuid');

HosCom = require('./HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid)

service1 = JSON.parse(JSON.stringify(generalContract))
service1.name = "service1"

a = new HosCom service1, 'al-kh.me', 'alikh', 'alikh12358'
a.on 'error', (err)->
    console.log "this cool error  " +  err.toString()
a.Connect ()->

a.on 'message', (msg)=>
    a.ack(msg)

module.exports = HosCom