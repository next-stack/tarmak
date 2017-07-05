require 'spec_helper'

describe 'prometheus::prometheus_rule', :type => :define do
  let(:pre_condition) {[
    'include kubernetes::apiserver',
  ]}
  let(:title) do
    'cpu-usage'
  end

  let :params do
    {
      :alert_if          => '(100 - (avg by (instance) (irate(node_cpu{name="node-exporter",mode="idle"}[5m])) * 100)) > 75',
      :alert_for         => "2m",
      :alert_summary     => '{{$labels.instance}}: High CPU usage detected',
      :alert_description => '{{$labels.instance}}: CPU usage is above 75% (current value is: {{ $value }})',
      :order             => '02',
    }
  end

  it do
    should contain_concat__fragment("kubectl-apply-prometheus-rules-cpu-usage")
      .with_content(/cpu-usage.rules/)
      .with_content(/ALERT cpu-usage/)
      .with_content(/severity="page"/)
      .with_content(/"{{\$labels.instance}}: High CPU usage detected"/)
  end
end
