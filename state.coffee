class State
  constructor: (saved) ->
    @children = saved?.children ? {}
    @vars = saved?.vars ? {}

  toJSON: ->
    children: do =>
      x = {}
      for own name, child of @children
        c = {}
        for own route, state of child
          c[route] = state.toJSON?() ? state
        x[name] = c
      x
    vars: do =>
      x = {}
      x[k] = v for own k,v of @vars when k isnt 'value'
      x

class Binding
  constructor: (@var) ->
  toString: -> "#{@var.get()}"
  toJSON: -> @var.get()


Template::onStateRequested = (handler) ->
  @onStateRequestedHandler = handler

Blaze.TemplateInstance::requestState = ->
  h = @view.template.onStateRequestedHandler
  if h? then h.call(@) else null

Template::onStateUpdated = (handler) ->
  handlers = @onStateUpdatedHandlers ?= []
  handlers.push handler

Blaze.TemplateInstance::triggerOnStateUpdated = ->
  @stateParent.triggerOnStateUpdated() if @stateParent?
  # We must run setTimeout here to group update requests.
  unless @stateUpdatePending
    @stateUpdatePending = true
    setTimeout =>
      h.call(@) for h in @view.template.onStateUpdatedHandlers ? []
      @stateUpdatePending = false
    , 10

Template::initState = (initializers) ->
  makeState = (value, saved) ->
    state = new State saved
    if value instanceof Binding
      state.vars.value = value
      value = value.toJSON()
    else
      state.vars.value ?= value
    for key, init of initializers
      state.vars[key] ?= if typeof init is 'function' then init.call value else init
    state

  @helpers
    vars: -> Template.instance().vars
    bind: -> Template.instance().bindings

  @onCreated ->
    vars = @vars = {}
    bindings = @bindings = {}
    @state = new State
    template = @

    ## Creating reactive vars and subscription for reactive changes.
    ## State here is fake one, just to allow first autorun to run without errors.
    prop = (name) =>
      v = new ReactiveVar
      v.descriptor =
        get: -> v.get()
        set: (value) ->
          # TODO Move it in more proper way whey will check changes from database.
          template.triggerOnStateUpdated()
          v.set value
        enumerable: true
        configurable: true

      b = new Binding v
      b.descriptor =
        get: -> b
        enumerable: true
        configurable: true

      @autorun =>
        @state.vars[name] = v.get()

      # All properties of vars are reactive
      Object.defineProperty vars, name, v.descriptor
      Object.defineProperty bindings, name, b.descriptor


    prop name for name of initializers
    prop "value"
    @state = null

    @stateParent = template
    loop
      @stateParent = parentTemplate @stateParent
      break unless @stateParent?
      if @stateParent.state instanceof State
        break
    parent = @stateParent

    @autorun ->
      data = Blaze.getData(template.view) ? {}
      if data.constructor isnt Object
        console.error 'CURRENT DATA isnt Object', data, template
        throw new Error 'CURRENT DATA isnt Object'

      value = data.value
      name = data.name ? 'default'
      route = data.route ? '*'

      if parent?
        r = parent.state.children[route] ?= {}
        saved = r[name]
        template.state = if saved instanceof State
          saved
        else
          r[name] = makeState value, saved

      else
        ## POTENTIAL RESTORE FROM user defined source
        template.state = Tracker.nonreactive -> template.requestState()

      unless template.state instanceof State
        template.state = makeState value, template.state

      for key, init of template.state.vars
        if init instanceof Binding
          Object.defineProperty vars, key, init.var.descriptor
          Object.defineProperty bindings, key, init.descriptor
        else
          vars[key] = init


parentView = (view) -> view.originalParentView ? view.parentView
parentTemplate = (template) ->
  view = parentView(template.view)
  while view and (!view.template or view.name in ['(contentBlock)', '(elseBlock)'])
    view = parentView(view)
  view?.templateInstance?()



Template::methods = (methods) ->
  helpers = {}
  for name, method of methods
    do (method) ->
      helpers[name] = ->
        tpl = Template.instance()
        original = tpl.context  # Save context if somebody already used it.
        tpl.context = @

        result = if typeof method is 'function'
          method.call tpl
        else
          method

        tpl.context = original  # Restore original context
        return result
  @helpers helpers
