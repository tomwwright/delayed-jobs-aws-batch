require "mongoid"

class AWSBatchJob
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :job_id,         type: String
  field :batch_job_id,   type: String

  field :_id, type: String, default: ->{ job_id }
end