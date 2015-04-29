Installation: 

    `meteor add nous:state`


## Usage

```JavaScript
Template.mytemplate.initState({
  someVar: 'default value',
  selectedColor: undefined
});
  
Template.mytemplate.helpers({
  getCar: function () {
    color = Template.instance().vars.selectedColor;
    return Cars.findOne({country: @country, color: color});
  }
});

Template.mytemlpate.events({
  'click .selectColor': function (e, tpl) {
    tpl.vars.selectedColor = e.target.value;
  }
});
```

or you can use our methods and CoffeScript for more beatifull code:
```CoffeeScript
Template.mytemplate.initState
  someVar: 'default value'
  selectedColor: undefined
  
Template.mytemplate.methods
  getCar: ->
    Cars.findOne
      country: @context.country
      color: @vars.selectedColor})

Template.mytemlpate.events
  'click .selectColor': (e, tpl) ->
    tpl.vars.selectedColor = e.target.value
```

## Persistence and Hooks
If you want to store/restore to/from database, you can use `onStateUpdated` and `onStateRequested` template hooks.
Also you can use `nous:tabmanager` if you want to persist your state (all tree) into database each time 
URL is changed, to have possibility to restore it when you back.
