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
    before :each do
      @tempfile = Tempfile.new('test')
      @config = Tempfile.new('config')
      @write_template = Tempfile.new('cfn-template')
      @default_options = {
        :stack_name => 'DansStack',
        :keyname => 'dans_key',
        :config => @config.path
      }
    end
    describe 'required options' do
      [:stack_name, :keyname, :config].each do |opt|
        it "should require #{opt}]" do
          @default_options.delete(opt)
          expect { subject.deploy(@default_options) }.should raise_error(ArgumentError, "The following options are required: #{opt.to_s}")
        end
      end
    end
    it 'should not set disable rollback by default' do
      @config.write(default_config.to_yaml)
      Tempfile.expects(:new).with(['cfn-template', '.erb']).returns(@tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{@default_options[:stack_name]} --template-file #{@tempfile.path} --parameters='KeyName=#{@default_options[:keyname]}' --capabilities CAPABILITY_IAM")
      subject.deploy(@default_options)
    end
    it 'should set disable rollback when specified' do
      Tempfile.expects(:new).with(['cfn-template', '.erb']).returns(@tempfile)
      Puppet::CloudFormation.expects(:execute).with("cfn-create-stack #{@default_options[:stack_name]} --template-file #{@tempfile.path} --parameters='KeyName=#{@default_options[:keyname]}' --capabilities CAPABILITY_IAM --disable-rollback")
      subject.deploy(@default_options.merge(:disable_rollback => true))
    end
    describe 'testing template variable evalution' do
      before :each do
        @write_template.write(
"<%= install_modules.join(',') -%>
<% puppet_agents.each do |k,v| -%>

<%= k %>=<%= v %>
<% end -%>")
        @write_template.close
        Puppet::CloudFormation.expects(:get_pe_cfn_template).returns(@write_template.path)
        Tempfile.expects(:new).with(['cfn-template', '.erb']).returns(@tempfile)
      end
      it 'should work with an empty config file' do
        @config.write(default_config.to_yaml)
        File.read(@config.path)
        @config.close
        subject.deploy(@default_options)
        File.read(@tempfile.path).should == ''
      end
      it 'should build a template correctly with contents in the config file' do
        @config.write({'install_modules' => ['a', 'b'],'puppet_agents' => {'a'=>{}}}.to_yaml)
        @config.close
        subject.deploy(@default_options)
        File.read(@tempfile.path).should == "a,b\na=\n"
      end
    end
  end
end
