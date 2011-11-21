require 'puppet/cloudformation'
describe Puppet::CloudFormation do

  describe '#validate_config' do

    it 'should allow for an empty config file' do
      subject.validate_config(nil).should be_true
    end
    it 'should allow for an empty config file' do
      subject.validate_config('').should be_true
    end
    it 'should not allow invalid config elements' do
      expect {subject.validate_config('foo' => 'bar')}.should raise_error(Puppet::Error, /Invalid config keys found/)
    end
    describe 'when validating modules to install' do
      it 'should allow a single module to be specified as a string' do
        subject.validate_config('install_modules' => 'foo-module').should be_true
      end
      it 'should allow an array of modules' do
        subject.validate_config('install_modules' => ['foo-module', 'bar-module2']).should be_true
      end
      it 'should not allow a hash of modules' do
        expect {subject.validate_config('install_modules' => {})}.should raise_error(Puppet::Error, /install_modules is of invalid type/)
      end
    end
    describe 'when validating dashboard groups' do
      it 'should allow an empty group' do
        subject.validate_config(
          'dashboard_groups' => {'one_group' => nil}
        )
      end
      it 'should allow classes to be added to groups' do
        subject.validate_config(
          'dashboard_groups' => {'one_group' => {'classes' => ['one', 'two']}}
        ).should be_true
      end
      it 'should allow parameters to be added to groups' do
        subject.validate_config(
          'dashboard_groups' => {'one' => {'parameters' => {'foo' => 'bar'}}}
        ).should be_true
      end
      it 'should allow parent groups to be set' do
        subject.validate_config(
          'dashboard_groups' => {'one' => {'parent_groups' => ['foo', 'bar']}}
        ).should be_true
      end
      it 'should allow multiple groups to be added to dashboard' do
        subject.validate_config(
          'dashboard_groups' => {
            'one' => {'classes' => 'foo',
                     'parameters' => {'a' => 'b'}},
           'two' =>  {'classes' => ['f', 'b'],
                     'parent_groups' => 'foo'}
          }
        ).should be_true
      end
    end
    describe 'when validating puppet agents' do
      it 'should allow empty agents' do
        subject.validate_config(
          'puppet_agents' => {
            'agent1' => nil
          }
        ).should be_true
      end
      ['foo', ['foo', 'bar']].each do |x|
        it "should allow a group to be set for an agent as #{x.class}" do
          subject.validate_config(
            'puppet_agents' => {
              'agent1' => { 'groups' => x}
            }
          ).should be_true
        end
      end
      it 'should allow parameters to be set for an agent' do
        subject.validate_config(
          'puppet_agents' => {
            'agent1' => { 'parameters' => {'foo' => 'bar'}}
          }
        ).should be_true
      end
      ['foo', ['foo', 'bar'], {'foo' => nil}].each do |x|
        it "should allow classes to be set for an agent as #{x.class}" do
          subject.validate_config(
            'puppet_agents' => {
              'agent1' => { 'classes' => x}
            }
          ).should be_true
        end
      end
      it 'should not allow bad agent configs' do
        expect { subject.validate_config(
          'puppet_agents' => {
            'agent1' => { 'foo' => 'foo'}
          }
        )}.should raise_error
      end
    end
  end
end
