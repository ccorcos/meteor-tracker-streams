Package.describe({
  name: 'ccorcos:tracker-streams',
  summary: 'Observable streams using Tracker.',
  version: '1.0.0',
  git: 'https://github.com/ccorcos/meteor-tracker-streams'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1');

  api.use([
    'tracker',
    'reactive-var',
    'coffeescript',
    'templating',
    'underscore',
    'aldeed:template-extension@3.3.0'
  ], 'client');

  api.addFiles([
    'lib/stream.coffee',
  ], 'client');

});