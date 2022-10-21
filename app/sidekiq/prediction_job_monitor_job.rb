# frozen_string_literal: true

class PredictionJobMonitorJob
  include Sidekiq::Job

  MONITOR_JOB_RESCHEDULE_DELAY = ENV.fetch('MONITOR_JOB_RESCHEDULE_DELAY', 1).to_i

  def perform(prediction_job_id)
    prediction_job = PredictionJob.find(prediction_job_id)

    # short circuit if we run this on a job that's already done
    return if prediction_job.completed?

    # TBC what this interface returns, perahps a result object?
    # or it composes another service to do the work of aggregating the prediction job results
    # and it can't mark this job as successful until that is done?
    prediction_job = Batch::Prediction::MonitorJob.new(prediction_job).run

    return if prediction_job.completed?

    # reschedule this job to run again in 1 minute
    PredictionJobMonitorJob.perform_in(MONITOR_JOB_RESCHEDULE_DELAY.minute, prediction_job.id)
  end
end