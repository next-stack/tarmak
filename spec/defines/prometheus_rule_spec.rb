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
      :alert_name => "example-name",
    }
  end

  it do
    should contain_concat__fragment("kubectl-apply-prometheus-rules-test-rule")
      .with_content(/example-name/)
  end
end
