require 'nyny'
require 'yaml'

# Fake signaly.cz for testing. Start by `rackup`.
# To run against it, execute signaly-notify with options
# --url http://localhost:PORT --skip-login
class App < NYNY::App
  get '/' do
    locals = {}
    locals[:uri] = request.env['REQUEST_URI']
    locals.update(YAML.load(File.read('values.yml')))
    render 'index.erb', locals
  end
end

App.run!
