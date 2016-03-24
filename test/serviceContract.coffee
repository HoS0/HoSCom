tasks =
  users:
    description: 'Users resource'
    methods:
      GET:
        parameters:
          deleted: false

        description:
          request: ''
          response: JSON.stringify([{firstname: "foo", lastname: "bar", email: "foo@bar.com"}])
          summary: 'Get array of all users in the system'

      POST:
        parameters: {}

        description:
          request: JSON.stringify({firstname: "foo", lastname: "bar", email: "foo@bar.com"})
          response: '{"err": null}'
          summary: 'Create a new user'

  user:
    methods:
      GET:
        parameters:
          id: true

        description:
          request: ''
          response: JSON.stringify({firstname: "foo", lastname: "bar", email: "foo@bar.com"})
          summary: 'Get a particular user from the system'

      PUT:
        parameters:
          id: true

        description:
          request: JSON.stringify({firstname: "foo", lastname: "bar", email: "foo@bar.com"})
          response: '{"err": null}'
          summary: 'Update a single user'

      DELETE:
        parameters:
          id: true

        description:
          request: ''
          response: '{"err": null}'
          summary: 'Delete a particular user from the system'

  friends:
    description: 'Friends resource'
    methods:
      GET:
        parameters:
          id: true

        description:
          request: ''
          response: JSON.stringify([{id: 'abcd1234'}])
          summary: 'Get array of all friends of a particular user'

      POST:
        parameters:
          id: true

        description:
          request: JSON.stringify({id: 'bcde1234'})
          response: '{"err": null}'
          summary: 'Add friend to a particular user - supply user id of the friend in the request'

      DELETE:
        parameters:
          id: true

        description:
          request: JSON.stringify({id: 'bcde1234'})
          response: '{"err": null}'
          summary: 'Remove friend to a particular user - supply user id of the friend in the request'

serviceInfo =
  name: 'User'
  version: '0.1.0'
  description: 'Allmighty service for user management and interaction'
  tasks: tasks
  prefetch: 1
  consumerNumber: 1
  messageTimeout: 300

module.exports = serviceInfo
