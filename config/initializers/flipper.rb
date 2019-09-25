Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new

    Flipper.new(adapter)
  end
end

Flipper.register(:admins) do |actor|
  actor.admin?
end
