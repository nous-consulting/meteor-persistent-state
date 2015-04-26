class State
  constructor: (value) ->
    @children = {}
    @vars = {value: value}

Template::initState = (initializers) ->
  @helpers
    vars: -> Template.instance().vars

  @onCreated ->
    vars = @vars = {}
    @state = new State

    ## Creating reactive vars and subscription for reactive changes.
    ## State here is fake one, just to allow first autorun to run without errors.
    prop = (name) =>
      v = new ReactiveVar
      @autorun =>
        @state.vars[name] = v.get()

      # All properties of vars are reactive
      Object.defineProperty vars, name,
        get: -> v.get()
        set: (value) ->
          v.set value
        enumerable: true
    prop name for name of initializers
    prop "value"
    @state = null

    template = @
    @autorun ->
      data = Blaze.getData(template.view) ? {}

      console.error 'CURRENT DATA isnt Object', data, template if data.constructor isnt Object
      initialValue = data.value
      name = data.name ? 'default'
      route = data.route ? '*'

      # Links current state into parent's state
      parent = template
      i = 0
      loop
        ++i
        parent = parentTemplate parent
        break unless parent?
        if parent.state instanceof State
          template.state = (parent.state.children[route] ?= {})[name] ?= new State initialValue
          break

      ## POTENTIAL RESTORE
      if template.state?
        vars[key] = init for key, init of template.state.vars
      else
        template.state = new State initialValue
        for key, init of initializers
          init = init.call initialValue if typeof init is 'function'
          vars[key] = init
        vars.value = initialValue


parentView = (view) -> view.originalParentView ? view.parentView
parentTemplate = (template) ->
  view = parentView(template.view)
  while view and (!view.template or view.name in ['(contentBlock)', '(elseBlock)'])
    view = parentView(view)

  # Tracker.nonreactive prevents reactivity in parent template to avoid running multiple times.
  Tracker.nonreactive -> view?.templateInstance?()



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
