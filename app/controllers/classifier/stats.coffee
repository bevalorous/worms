Spine = require 'spine'

Subject = require 'zooniverse/models/subject'
User = require 'zooniverse/models/user'

Game = require '../../lib/game'

class Stats extends Spine.Controller
  className: 'section players'
  template: require '../../views/classifier/stats'

  elements:
    '.score': 'scoreBox'
    '.player1 .times': 'p1Times'
    '.player2 .times': 'p2Times'

  events:
    'click .sign-in': 'onClickSignIn'
    'click .player1 .times button': 'removeTime'

  constructor: ->
    super
    
    @html @template()

    Game.on 'new', @render
    Game.on 'status mark remove-mark', @render

  render: =>
    @html @template
      game: Game.current
      user: User.current

  removeTime: (e) =>
    Game.current.removeTime $(e.currentTarget).parent().index()

  onClickSignIn: =>
    require('zooniverse/controllers/login-dialog').show()

module.exports = Stats