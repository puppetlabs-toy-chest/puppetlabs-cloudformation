require 'puppet/face'
require 'spec_helper'
require 'puppet/cloudformation'
describe Puppet::Face[:cloudformation, :current] do
  describe 'action deploy' do
    let :default_config do
      {'install_modules' => [],
       'puppet_agents' => {}
      }
    end
    let(:tempfile) { Tempfile.new('test') }
    let(:config) { Tempfile.new('config') }
    let :default_options do
      {:stack_name => 'DansStack',
       :keyname => 'dans_key',
       :config => config.path}
    end
    describe 'required options' do
      [:stack_name, :keyname, :config].each do |opt|
        it "should require #{opt}" do
          default_options.delete(opt)
          expect { subject.deploy(default_options) }.should raise_error(ArgumentError, "The following options are required: #{opt.to_s}")
        end
      end
    end
    it 'should not set disable rollback by default' do
      config.write(default_config.to_yaml)
      Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{default_options[:stack_name]} --template-file #{tempfile.path} --parameters='KeyName=#{default_options[:keyname]}' --region us-east-1 --capabilities CAPABILITY_IAM")
      subject.deploy(default_options)
    end
    it 'should set disable rollback when specified' do
      Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{default_options[:stack_name]} --template-file #{tempfile.path} --parameters='KeyName=#{default_options[:keyname]}' --region us-east-1 --capabilities CAPABILITY_IAM --disable-rollback")
      subject.deploy(default_options.merge(:disable_rollback => true))
    end
    it 'should be able to set region from options' do
      Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{default_options[:stack_name]} --template-file #{tempfile.path} --parameters='KeyName=#{default_options[:keyname]}' --region us-west-1 --capabilities CAPABILITY_IAM")
      subject.deploy(default_options.merge(:region => 'us-west-1'))
    end
    it 'should default region to the EC2_REGION environment variable' do
      ENV['EC2_REGION']='us-west-2'
      Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{default_options[:stack_name]} --template-file #{tempfile.path} --parameters='KeyName=#{default_options[:keyname]}' --region us-west-2 --capabilities CAPABILITY_IAM")
      subject.deploy(default_options)
    end
    describe 'testing template variable evalution' do
      before :each do
        write_template = Tempfile.new('cfn_template')
        write_template.open()
        write_template.write(
"<%= install_modules.join(',') -%>
<% puppet_agents.each do |k,v| -%>

<%= k %>=<%= v %>
<% end -%>")
        write_template.close
        Puppet::CloudFormation.expects(:get_pe_cfn_template).returns(write_template.path)
        Puppet::CloudFormation.stubs(:execute)
      end
      it 'should work with an empty config file' do
        config.write(default_config.to_yaml)
        Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
        config.close
        File.read(config.path)
        subject.deploy(default_options)
        File.read(tempfile.path).should == ''
      end
      it 'should build a template correctly with contents in the config file' do
        config.write({'install_modules' => ['a', 'b'],'puppet_agents' => {'a'=>{}}}.to_yaml)
        Puppet::CloudFormation.expects(:get_pe_cfn_tempfile).returns(tempfile)
        config.close
        subject.deploy(default_options)
        File.read(tempfile.path).should == "a,b\na=\n"
      end
    end
  end
  after :each do
    config.close!
    tempfile.close!
  end
end
