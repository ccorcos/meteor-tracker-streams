Package.describe({
  name: 'ccorcos:tracker-streams',
  summary: 'Observable streams baked into Tracker.',
  version: '0.0.1',
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
    'lib/streams.coffee',
  ], 'client');

});