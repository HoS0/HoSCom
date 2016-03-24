amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./test/serviceContract')
uuid            = require('node-uuid')
Promise         = require('bluebird')

HosCom = require('./src/HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

module.exports = HosCom
