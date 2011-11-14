require 'puppet'
require 'tempfile'
require 'fileutils'
describe Puppet::Parser::Functions.function(:get_module_path) do
  def tmp_dir(name)
    source = Tempfile.new(name)
    path = source.path
    source.close!
    FileUtils.mkdir_p(path)
    path
  end

  def get_scope(environment = 'production')
    topscope = Puppet::Parser::Scope.new
    topscope.parent = nil
    scope = Puppet::Parser::Scope.new
    scope.compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => environment))
    scope.parent = @topscope
    scope
  end
  it 'should only allow one argument' do
    expect { get_scope.function_get_module_path([]) }.should raise_error(Puppet::ParseError, /Wrong number of arguments, expects one/)
    expect { get_scope.function_get_module_path(['1','2','3']) }.should raise_error(Puppet::ParseError, /Wrong number of arguments, expects one/)
  end
  it 'should raise an exception when the module cannot be found' do
    expect { get_scope.function_get_module_path(['foo']) }.should raise_error(Puppet::ParseError, /Could not find module/)
  end
  describe 'locating a module' do
    before :all do
      @modulepath = tmp_dir('modulepath')
      FileUtils.mkdir(File.join(@modulepath, 'foo'))
    end
    it 'should be able to find modules from the modulepath' do
      Puppet[:modulepath] = @modulepath
      get_scope.function_get_module_path(['foo']).should == File.join(@modulepath, 'foo')
    end
    it 'should be able to find modules when the modulepath is a list' do
      Puppet[:modulepath] = @modulepath + ":/tmp"
      get_scope.function_get_module_path(['foo']).should == File.join(@modulepath, 'foo')
    end
    it 'should be able to find modules from the environment moduepath' do
      @conf_file = Tempfile.new('conffile')
      @conf_file.write("[dansenvironment]\nmodulepath = #{@modulepath}")
      @conf_file.close
      Puppet[:config] = @conf_file.path
      Puppet.parse_config
      get_scope('dansenvironment').function_get_module_path(['foo']).should == File.join(@modulepath, 'foo')
    end
    after :all do
      FileUtils.rm_rf(@modulepath)
    end
  end
end
