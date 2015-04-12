class State
  constructor: (@children={}, @vars={}) ->

Template::initState = (initializers) ->
  @helpers
    vars: -> Template.instance().vars

  @onCreated ->
    console.log 'initState', initializers
    vars = @vars = {}
    @state = new State
    prop = (name) =>
      v = new ReactiveVar
      @autorun =>
        @state.vars[name] = v.get()
      Object.defineProperty vars, name,
        get: -> v.get()
        set: (value) -> v.set value
        enumerable: true
    prop name for name of initializers
    prop "value"

    template = @
    @autorun ->
      currentData = Blaze.getData template.view
      console.warn 'currentData', currentData, template.view.name
      {name, value} = currentData ? {}
      name ?= 'default'

      # Links current state into parent's state
      parent = template
      i = 0
      loop
        ++i
        console.log 'parent', i, parent
        parent = parentTemplate parent
        break unless parent?
        if parent.state instanceof State
          template.state = parent.state.children[name] ?= new State
          break

      ## POTENTIAL RESTORE
      template.state ?= new State

      for key, init of initializers
        init = init.call value if typeof init is 'function'
        console.log 'key', key, 'init', init
        vars[key] = init
      vars.value = value


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
