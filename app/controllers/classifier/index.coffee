Spine = require 'spine'

Classification = require 'zooniverse/models/classification'
Subject = require 'zooniverse/models/subject'
User = require 'zooniverse/models/user'

Game = require '../../lib/game'

BaseController = require '../base-controller'

Actions = require './actions'
Announcer = require './announcer'
Details = require './details'
Stats = require './stats'
Video = require './video'

{ Tutorial } = require 'zootorial'
translate = require 't7e'

TutorialSteps = require '../../lib/tutorial/steps'
TutorialSubject = require '../../lib/tutorial/subject'

class Classifier extends BaseController
  className: 'classifier'
  template: require '../../views/classifier'

  elements:
    '.left': 'left'
    '.right': 'right'

  constructor: ->
    super
    @html @template()
    $(document).keydown @onKeyDown

    # Build pieces
    @details = new Details
    @details.el.appendTo @right

    @announcer = new Announcer
    @announcer.el.appendTo @right

    @stats = new Stats
    @stats.el.appendTo @right

    @video = new Video
    @video.el.appendTo @left

    @actions = new Actions
    @actions.el.appendTo @right

    @tutorial = new Tutorial
      firstStep: 'welcome'
      steps: TutorialSteps
      parent: $('body')

    @tutorial.video = @video

    @tutorial.el.on 'start-tutorial enter-tutorial-step', =>
      translate.refresh @tutorial.el.get 0

    User.on 'change', @onUserChange
    Subject.on 'select', @onSubjectSelect

    Spine.on 'make-favorite', @makeFavorite
    Spine.on 'finished-classification', @finish
    Game.on 'end', @onGameEnd

  onUserChange: (e, user) =>
    @stats.render()

    if user?.project.tutorial_done
      @tutorial.end()
      Subject.next()
    else
      tutorialSubject = TutorialSubject()
      tutorialSubject.select()

  onSubjectSelect: (e, subject) =>
    @video.render()

    @classification = new Classification { subject }
    new Game

  activate: =>
    super

    if Subject.current?.tutorial then @tutorial.start()

  deactivate: =>
    super
    @tutorial?.end()

  makeFavorite: =>
    @classification.favorite = true if @classification?

  finish: =>
    @classification.annotate Game.current.getGameStatus()
    @classification.send()

    Subject.next()

  onGameEnd: =>
    if Game.current.otherPlayer?
      yourEggs = "#{ Game.current.times.length } #{ if Game.current.times.length is 1 then 'egg' else 'eggs' }"
      theirEggs = "#{ Game.current.teamMateTimes.length } #{ if Game.current.teamMateTimes.length is 1 then 'egg' else 'eggs' }"
      message = "You marked #{ yourEggs } and #{ Game.current.otherPlayer } marked #{ theirEggs }."
    else
      if Game.current.times.length is 1
        message = "You marked 1 egg!"
      else
        message = "You marked #{ Game.current.times.length } eggs!"

    @announcer.announce message

  onKeyDown: (e) =>
    if not @isActive() or @dialogsActive() then return

    switch e.which
      when 27 # Esc
        @tutorial.end()
      when 88
        switch Game.current.status
          when'waiting' then Game.current.start()
          when 'finished'
            if Game.current.pastBuffer() then Spine.trigger 'finished-classification'
      when 90 # Z
        switch Game.current.status
          when 'playing' then Game.current.markTime()

  dialogsActive: =>
    loginDialogEl = require('zooniverse/controllers/login-dialog').el
    signUpDialogEl = require('zooniverse/controllers/signup-dialog').el

    if loginDialogEl.hasClass('showing') or signUpDialogEl.hasClass('showing')
      return true

    return false

module.exports = Classifier
