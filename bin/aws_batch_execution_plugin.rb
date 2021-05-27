require "aws-sdk-batch"
require_relative "aws_batch_job"

class AwsBatchExecutionPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, job, &block|
      
      Delayed::Worker.logger.info("Beginning AWS Batch Execution...")
      Delayed::Worker.logger.info(job)

      batch = Aws::Batch::Client.new(region: "us-west-2")

      batch_job_record = AWSBatchJob.find(job.id)
      if batch_job_record.nil?
        Delayed::Worker.logger.info("AWS Batch Job marker not found in database, launching job")

        batch_job = batch.submit_job({
          job_definition: "delayed-job",
          job_name: "delayed-job-" + job.id + "-" + (job.attempts + 1).to_s,
          job_queue: "delayed-job-testing",
          parameters: {
            "jobid": job.id.to_s
          }
        })

        Delayed::Worker.logger.info(batch_job)
        
        batch_job_record = AWSBatchJob.new(job_id: job.id, batch_job_id: batch_job.job_id)
        batch_job_record.save()
      end

      Delayed::Worker.logger.info("Polling status of AWS Batch Job...")
      loop do
      
        batch_job = batch.describe_jobs({
          jobs: [batch_job_record.batch_job_id]
        }).jobs[0]

        Delayed::Worker.logger.info("AWS Batch Job status: " + batch_job.job_id + " " + batch_job.status)

        if ["SUCCEEDED", "FAILED"].include? batch_job.status

          Delayed::Worker.logger.info(batch_job)

          break
        end
        
        sleep(5)
      end

      # remove job marker
      batch_job_record.destroy()
      
      #block.call(worker, job) # not calling the enclosed block omits the actual job processing by this worker 
    end
  end
end