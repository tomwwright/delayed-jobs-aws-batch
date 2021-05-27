DummyErrorJob = Struct.new(:text) do
  def perform
    puts "Finna blow up: " + text
    raise
  end

  def max_attempts
    return 2
  end
end