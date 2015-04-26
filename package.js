Package.describe({
  name: 'nous:state',
  version: '0.6.0',
  summary: 'Heroic state for Metoer :P',
  git: 'https://github.com/nous-consulting/meteor-persistent-state',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.4');
  api.use('templating@1.0.0');
  api.use('blaze@2.0.0');
  api.use('coffeescript');
  api.use('reactive-var');
  api.addFiles(['state.coffee'], 'client');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('nous:state');
  api.addFiles('state-tests.js');
});
