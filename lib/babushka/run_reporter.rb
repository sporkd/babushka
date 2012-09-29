module Babushka
  class RunReporter
  class << self
    include LogHelpers

    def queue dep, result, reportable
      if dep.dep_source.type != :public
        debug "Not reporting #{dep.contextual_name}, since it's not in a public source."
      else
        queue_report dep, (reportable ? 'error' : (result ? 'ok' : 'fail'))
      end
    end

    def post_reports
      require 'net/http'

      while Base.task.running? && (report = most_recent_report)
        post_report report
      end
    end


    private

    def post_report report
      submit_report_to_webservice(report.p.read).tap {|result|
        if result.is_a?(Net::HTTPSuccess) || result.is_a?(Net::HTTPNotAcceptable)
          # Remove the run on success, and on validation error: retrying
          # won't help that anyway.
          report.p.rm
        else
          # Wait for a moment before trying again, so persistent problems don't
          # slam babushka.me (if it's rejecting the data) or peg our CPU (if
          # the network is down).
          sleep 1
        end
      }
    end

    require 'net/http'
    def submit_report_to_webservice data
      Net::HTTP.start('babushka.me') {|http|
        http.open_timeout = http.read_timeout = 5
        http.post '/runs.json', data
      }
    rescue Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, SocketError
      log_error "Couldn't connect to the babushka webservice." unless Base.task.running?
    rescue Timeout::Error, Errno::ETIMEDOUT
      debug "Timeout while submitting run report."
    end

    def most_recent_report
      ReportPrefix.p.glob('*').sort.last
    end

    def queue_report dep, result
      ReportPrefix.p.mkdir
      (ReportPrefix / Time.now.to_f).open('w') {|f|
        f << run_report_for(dep, result).to_http_params
      }
    end

    def run_report_for dep, result
      Base.task.task_info(dep, result)
    end

  end
  end
end
