DummyJob = Struct.new(:text) do
  def perform
    puts "Running job: " + text
  end
end