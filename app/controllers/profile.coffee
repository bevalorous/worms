User = require 'zooniverse/models/user'

BaseController = require './base-controller'
Spinner = require '../lib/spin'

class Profile extends BaseController
  className: 'sub-page profile'
  template: require '../views/profile'

  constructor: ->
    super

    @render()

    User.on 'change', @render

  render: =>
    @html @template
      user: User.current
      format: @formatNumber

  active: =>
    super
    @el.css 'opacity', '0.5'

    @loading = new Spinner().spin @el.get(0)

    User.fetch().done =>
      @el.css 'opacity', '1'
      @loading.stop()
      @render()

  formatNumber: (n) ->
    return n unless n
    n.toString().replace /(\d)(?=(\d{3})+(?!\d))/g, '$1,'

module.exports = Profile