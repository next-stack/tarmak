require 'spec_helper'

describe 'prometheus::prometheus_rule', :type => :define do
  let(:pre_condition) {[
    'include kubernetes::apiserver',
  ]}
  let(:title) do
    'test-rule'
  end

  let :params do
    {
      :alert_name => "asdf",
    }
  end

  it do
    should contain_concat__fragment("kubectl-apply-prometheus-rule-test-rule-content")
  end
end
